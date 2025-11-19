#' @include Model_BaseModel.R
#' @title Sparsemax Class
#' @description Sparsemax activation function as an alternative to softmax.
#' @details
#' Produces sparse probability distributions, which can be beneficial for
#' interpretability by setting low-importance weights to exactly zero.
#' @param dim Dimension along which to apply sparsemax. Default -1.
#' @keywords internal
#' @export
#' @importFrom torch nn_module torch_max torch_sort torch_arange torch_cumsum torch_gt torch_sum torch_zeros_like

Sparsemax <- torch::nn_module(
  classname = "Sparsemax",

  initialize = function(dim = NULL) {
    self$dim <- if (is.null(dim)) -1 else dim
  },

  forward = function(input) {
    original_size <- input$size()
    input_reshaped <- input$view(c(-1, input$size(self$dim)))

    dim <- 2
    number_of_logits <- input_reshaped$size(dim)

    # Shift input
    input_shifted <- input_reshaped - torch_max(input_reshaped, dim = dim, keepdim = TRUE)[[1]]$expand_as(input_reshaped)

    # Sort
    zs <- torch_sort(input_shifted, dim = dim, descending = TRUE)[[1]]
    range_tensor <- torch_arange(1, number_of_logits + 1, dtype = torch_float())$view(c(1, -1))
    range_expanded <- range_tensor$expand_as(zs)

    # Compute bounds
    bound <- 1 + range_expanded * zs
    cumulative_sum_zs <- torch_cumsum(zs, dim)
    is_gt <- torch_gt(bound, cumulative_sum_zs)$to(dtype = input_reshaped$dtype)
    k <- torch_max(is_gt * range_expanded, dim, keepdim = TRUE)[[1]]

    # Compute threshold
    zs_sparse <- is_gt * zs
    taus <- (torch_sum(zs_sparse, dim, keepdim = TRUE) - 1) / k
    taus_expanded <- taus$expand_as(input_reshaped)

    # Apply threshold
    output <- torch_max(torch_zeros_like(input_reshaped), input_reshaped - taus_expanded)
    output <- output$view(original_size)

    return(output)
  }
)


#' @title CausalConv1d Class
#' @description Causal 1D convolution layer with proper padding for temporal sequences.
#' @details
#' Ensures that the output at time t only depends on inputs up to time t,
#' maintaining the causal structure required for time series modeling.
#' @inheritParams torch::nn_conv1d
#' @keywords internal
#' @export
#' @importFrom torch nn_module nn_conv1d

CausalConv1d <- torch::nn_module(
  classname = "CausalConv1d",

  initialize = function(in_channels, out_channels, kernel_size,
                       stride = 1, dilation = 1, groups = 1, bias = TRUE) {
    self$padding_value <- (kernel_size - 1) * dilation

    self$conv <- nn_conv1d(
      in_channels = in_channels,
      out_channels = out_channels,
      kernel_size = kernel_size,
      stride = stride,
      padding = self$padding_value,
      dilation = dilation,
      groups = groups,
      bias = bias
    )
  },

  forward = function(input) {
    result <- self$conv(input)
    if (self$padding_value != 0) {
      return(result[, , 1:(result$size(3) - self$padding_value)])
    }
    return(result)
  }
)


#' @title Recalibration Class
#' @description Feature recalibration module using squeeze-and-excitation mechanism.
#' @details
#' Adaptively recalibrates channel-wise feature responses by explicitly modeling
#' interdependencies between channels.
#' @param channel Number of input channels
#' @param reduction Reduction ratio for bottleneck. Default 9
#' @param activation Activation function ("sigmoid", "sparsemax", "softmax"). Default "sigmoid"
#' @keywords internal
#' @export
#' @importFrom torch nn_module nn_adaptive_avg_pool1d nn_linear nn_relu torch_sigmoid

Recalibration <- torch::nn_module(
  classname = "Recalibration",

  initialize = function(channel, reduction = 9, activation = "sigmoid") {
    self$avg_pool <- nn_adaptive_avg_pool1d(1)
    self$activation_type <- activation

    # Ensure scale_dim is at least 1 to avoid zero-dimension layers
    scale_dim <- max(1, channel %/% reduction)
    self$nn_c <- nn_linear(channel, scale_dim)
    self$nn_rescale <- nn_linear(scale_dim, channel)

    if (activation == "sparsemax") {
      self$sparsemax <- Sparsemax(dim = 1)
    }
  },

  forward = function(x) {
    b <- x$size(1)
    c <- x$size(2)
    t <- x$size(3)

    # Squeeze and excitation
    y_origin <- x$permute(c(1, 3, 2))$reshape(c(b * t, c))$contiguous()
    se_c <- self$nn_c(y_origin)
    se_c <- torch_relu(se_c)

    y <- self$nn_rescale(se_c)$view(c(b, t, c))$permute(c(1, 3, 2))$contiguous()

    # Apply activation
    if (self$activation_type == "sigmoid") {
      y <- torch_sigmoid(y)
    } else if (self$activation_type == "sparsemax") {
      y <- self$sparsemax(y)
    } else {  # softmax
      y <- y$softmax(dim = 2)
    }

    # Recalibrate
    output <- x * y$expand_as(x)
    attention <- y$permute(c(1, 3, 2))

    return(list(output = output, attention = attention))
  }
)


#' @title AdaCareLayer Class
#' @description AdaCare layer for scale-adaptive feature extraction and recalibration.
#' @details
#' Paper: Ma et al. "AdaCare: Explainable clinical health status representation
#' learning via scale-adaptive feature extraction and recalibration." AAAI 2020.
#'
#' This layer uses multi-scale causal convolutions with adaptive recalibration
#' to capture temporal patterns at different scales while maintaining interpretability.
#'
#' @param input_dim Input feature dimensionality
#' @param hidden_dim Hidden dimension for GRU. Default 128
#' @param kernel_size Kernel size for causal convolutions. Default 2
#' @param kernel_num Number of kernels per scale. Default 64
#' @param r_v Reduction rate for input recalibration. Default 4
#' @param r_c Reduction rate for conv recalibration. Default 4
#' @param activation Activation for recalibration ("sigmoid", "sparsemax", "softmax"). Default "sigmoid"
#' @param rnn_type Type of RNN ("gru" or "lstm"). Default "gru"
#' @param dropout Dropout rate. Default 0.5
#' @keywords internal
#' @export
#' @importFrom torch nn_module nn_gru nn_lstm nn_dropout nn_relu nn_sigmoid nn_tanh torch_cat

AdaCareLayer <- torch::nn_module(
  classname = "AdaCareLayer",

  initialize = function(input_dim, hidden_dim = 128, kernel_size = 2, kernel_num = 64,
                       r_v = 4, r_c = 4, activation = "sigmoid", rnn_type = "gru", dropout = 0.5) {

    if (!activation %in% c("sigmoid", "softmax", "sparsemax")) {
      stop("Only sigmoid, softmax and sparsemax are supported for activation")
    }
    if (!rnn_type %in% c("gru", "lstm")) {
      stop("Only gru and lstm are supported for rnn_type")
    }

    self$input_dim <- input_dim
    self$hidden_dim <- hidden_dim
    self$kernel_size <- kernel_size
    self$kernel_num <- kernel_num
    self$dropout_rate <- dropout

    # Multi-scale causal convolutions
    self$nn_conv1 <- CausalConv1d(input_dim, kernel_num, kernel_size, stride = 1, dilation = 1)
    self$nn_conv3 <- CausalConv1d(input_dim, kernel_num, kernel_size, stride = 1, dilation = 3)
    self$nn_conv5 <- CausalConv1d(input_dim, kernel_num, kernel_size, stride = 1, dilation = 5)

    # Recalibration modules
    self$nn_convse <- Recalibration(3 * kernel_num, r_c, activation = "sigmoid")
    self$nn_inputse <- Recalibration(input_dim, r_v, activation = activation)

    # RNN
    if (rnn_type == "gru") {
      self$rnn <- nn_gru(input_size = input_dim + 3 * kernel_num, hidden_size = hidden_dim, batch_first = TRUE)
    } else {
      self$rnn <- nn_lstm(input_size = input_dim + 3 * kernel_num, hidden_size = hidden_dim, batch_first = TRUE)
    }

    self$nn_dropout <- nn_dropout(p = dropout)
    self$relu <- nn_relu()
  },

  forward = function(x, mask = NULL) {
    # x: [batch, time, features]

    # Apply multi-scale convolutions
    conv_input <- x$permute(c(1, 3, 2))  # [batch, features, time]
    conv_res1 <- self$nn_conv1(conv_input)
    conv_res3 <- self$nn_conv3(conv_input)
    conv_res5 <- self$nn_conv5(conv_input)

    conv_res <- torch_cat(list(conv_res1, conv_res3, conv_res5), dim = 2)
    conv_res <- self$relu(conv_res)

    # Recalibration
    convse_result <- self$nn_convse(conv_res)
    convse_res <- convse_result$output
    convatt <- convse_result$attention

    inputse_result <- self$nn_inputse(x$permute(c(1, 3, 2)))
    inputse_res <- inputse_result$output
    inputatt <- inputse_result$attention

    # Concatenate and apply RNN
    concat_input <- torch_cat(list(convse_res, inputse_res), dim = 2)$permute(c(1, 3, 2))
    rnn_output <- self$rnn(concat_input)
    output <- rnn_output[[1]]

    # Get last valid output
    if (!is.null(mask)) {
      lengths <- mask$sum(dim = -1)$to(dtype = torch_long())
      batch_size <- output$size(1)
      H <- output$size(3)
      index <- lengths$view(c(batch_size, 1, 1))$expand(c(batch_size, 1, H))
      last_output <- output$gather(dim = 2, index = index)$squeeze(2)
    } else {
      last_output <- output[, -1, ]
    }

    if (self$dropout_rate > 0.0) {
      last_output <- self$nn_dropout(last_output)
    }

    return(list(
      last_output = last_output,
      output = output,
      inputatt = inputatt,
      convatt = convatt
    ))
  }
)


#' @title AdaCare Model Class (Version 2 - With Timeseries Support)
#' @description
#' AdaCare model for explainable clinical health status representation learning.
#' Supports both code-based features (with embedding) and timeseries features (direct).
#'
#' @details
#' Paper: Ma et al. "AdaCare: Explainable clinical health status representation
#' learning via scale-adaptive feature extraction and recalibration." AAAI 2020.
#'
#' This model automatically detects feature types and processes them appropriately:
#' - SequenceProcessor: Code-based features → Embedding → AdaCareLayer
#' - TimeseriesProcessor: Numerical features → AdaCareLayer (direct)
#'
#' Returns attention weights for interpretability.
#'
#' @param dataset A `SampleDataset` object providing input/output schema
#' @param embedding_dim Integer, embedding dimension for code features. Default 128
#' @param hidden_dim Integer, hidden dimension for RNN. Default 128
#' @param kernel_size Integer, kernel size for convolutions. Default 2
#' @param kernel_num Integer, number of kernels per scale. Default 64
#' @param r_v Integer, reduction rate for input recalibration. Default 4
#' @param r_c Integer, reduction rate for conv recalibration. Default 4
#' @param activation Character, activation function. Default "sigmoid"
#' @param rnn_type Character, RNN type ("gru" or "lstm"). Default "gru"
#' @param dropout Numeric, dropout rate. Default 0.5
#' @export
#' @importFrom torch nn_module nn_linear nn_module_dict nn_embedding torch_cat torch_long torch_float with_no_grad torch_tensor

AdaCare <- torch::nn_module(
  classname = "AdaCare",

  inherit = BaseModel,

  initialize = function(dataset = NULL,
                        embedding_dim = 128,
                        hidden_dim = 128,
                        kernel_size = 2,
                        kernel_num = 64,
                        r_v = 4,
                        r_c = 4,
                        activation = "sigmoid",
                        rnn_type = "gru",
                        dropout = 0.5) {
    super$initialize(dataset)

    self$embedding_dim <- embedding_dim
    self$hidden_dim <- hidden_dim

    stopifnot(length(self$label_keys) == 1)
    self$label_key <- self$label_keys[[1]]
    self$mode <- self$dataset$output_schema[[self$label_key]]

    # Detect feature types and create appropriate layers
    self$feature_types <- list()
    embeddings_list <- list()
    self$module_list <- list()

    for (feature_key in names(self$dataset$input_processors)) {
      processor <- self$dataset$input_processors[[feature_key]]

      if (inherits(processor, "SequenceProcessor")) {
        # Code-based feature: needs embedding
        self$feature_types[[feature_key]] <- "sequence"
        vocab_size <- length(processor$code_vocab)
        embeddings_list[[feature_key]] <- nn_embedding(vocab_size + 1, embedding_dim, padding_idx = 1)

        self$module_list[[feature_key]] <- AdaCareLayer(
          input_dim = embedding_dim,
          hidden_dim = hidden_dim,
          kernel_size = kernel_size,
          kernel_num = kernel_num,
          r_v = r_v,
          r_c = r_c,
          activation = activation,
          rnn_type = rnn_type,
          dropout = dropout
        )
      } else if (inherits(processor, "TimeseriesProcessor")) {
        # Timeseries feature: use directly
        self$feature_types[[feature_key]] <- "timeseries"
        # input_dim is the number of channels in timeseries
        # This will be determined from data in forward pass
        self$module_list[[feature_key]] <- AdaCareLayer(
          input_dim = processor$n_channels,  # Assume processor has n_channels
          hidden_dim = hidden_dim,
          kernel_size = kernel_size,
          kernel_num = kernel_num,
          r_v = r_v,
          r_c = r_c,
          activation = activation,
          rnn_type = rnn_type,
          dropout = dropout
        )
      } else {
        stop(sprintf("Unsupported processor type for feature '%s': %s",
                    feature_key, class(processor)[1]))
      }
    }

    self$feature_keys <- names(self$module_list)
    self$adacare <- nn_module_dict(self$module_list)
    if (length(embeddings_list) > 0) {
      self$embeddings <- nn_module_dict(embeddings_list)

      # Manually zero out padding embeddings (padding_idx = 1)
      for (feature_key in names(embeddings_list)) {
        with_no_grad({
          self$embeddings[[feature_key]]$weight[1, ] <- 0
        })
      }
    }

    # Output layer
    output_size <- self$get_output_size()
    self$fc <- nn_linear(length(self$feature_keys) * hidden_dim, output_size)

    message(sprintf(
      "AdaCare model with %d features (types: %s), embedding_dim=%d, hidden_dim=%d, output_size=%d",
      length(self$feature_keys),
      paste(unlist(self$feature_types), collapse=", "),
      embedding_dim,
      hidden_dim,
      output_size
    ))
  },

  forward = function(inputs) {
    y_true <- inputs[[self$label_key]]
    feature_inputs <- inputs[self$feature_keys]

    # Process each feature based on its type
    patient_emb <- list()
    feature_importance <- list()

    for (feature_key in self$feature_keys) {
      x_raw <- feature_inputs[[feature_key]]

      if (self$feature_types[[feature_key]] == "sequence") {
        # Code-based: apply embedding first
        if (!inherits(x_raw, "torch_tensor")) {
          x_raw <- torch_tensor(x_raw, dtype = torch_long())
        }
        x_raw <- x_raw$to(device = self$device)
        # Correct illegal index 0 (map to padding_idx = 1)
        x_raw[x_raw == 0] <- 1
        x <- self$embeddings[[feature_key]](x_raw)
      } else {
        # Timeseries: use directly
        if (!inherits(x_raw, "torch_tensor")) {
          x_raw <- torch_tensor(x_raw, dtype = torch_float())
        }
        x <- x_raw$to(device = self$device)

        # Ensure shape is [batch, time, channels]
        if (x$ndim == 2) {
          x <- x$unsqueeze(-1)  # Add channel dimension if missing
        }
      }

      # Create mask
      mask <- (x$sum(dim = -1)$abs() > 1e-6)$to(dtype = torch_long())

      # Apply AdaCare layer
      result <- self$adacare[[feature_key]](x = x, mask = mask)
      patient_emb[[feature_key]] <- result$last_output

      # Store feature importance (input attention only)
      feature_importance[[feature_key]] <- result$inputatt
    }

    # Concatenate embeddings
    patient_vec <- torch_cat(patient_emb, dim = 2)
    logits <- self$fc(patient_vec)
    device <- logits$device

    # Squeeze dimensions if needed
    if (logits$ndim == 2 && logits$shape[2] == 1) {
      logits <- logits$squeeze(2)
    }
    if (y_true$ndim == 2 && y_true$shape[2] == 1) {
      y_true <- y_true$squeeze(2)
    }

    y_true <- y_true$to(device = device)

    # Compute loss and predictions
    loss <- self$get_loss_function()(logits, y_true)
    y_prob <- self$prepare_y_prob(logits)

    results <- list(
      loss = loss,
      y_prob = y_prob,
      y_true = y_true,
      logit = logits,
      feature_importance = feature_importance  # NEW: Return attention weights
    )

    if (!is.null(inputs$embed) && inputs$embed) {
      results$embed <- patient_vec
    }

    return(results)
  }
)
