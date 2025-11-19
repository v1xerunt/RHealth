#' @include Model_BaseModel.R Model_EmbeddingModel.R
#' @title FinalAttentionQKV Class
#' @description Final attention layer using query, key, value mechanism.
#' @details
#' Computes attention weights for the final aggregation of temporal representations.
#' @param attention_input_dim Input dimensionality
#' @param attention_hidden_dim Hidden dimensionality
#' @param attention_type Type of attention ("add", "mul", "concat"). Default "add"
#' @param dropout Dropout rate. Default 0.5
#' @keywords internal
#' @export
#' @importFrom torch nn_module nn_linear nn_parameter nn_dropout nn_tanh torch_zeros torch_randn torch_reshape torch_matmul nnf_softmax

FinalAttentionQKV <- torch::nn_module(
  classname = "FinalAttentionQKV",

  initialize = function(attention_input_dim, attention_hidden_dim,
                       attention_type = "add", dropout = 0.5) {
    self$attention_type <- attention_type
    self$attention_hidden_dim <- attention_hidden_dim
    self$attention_input_dim <- attention_input_dim

    self$W_q <- nn_linear(attention_input_dim, attention_hidden_dim)
    self$W_k <- nn_linear(attention_input_dim, attention_hidden_dim)
    self$W_v <- nn_linear(attention_input_dim, attention_hidden_dim)
    self$W_out <- nn_linear(attention_hidden_dim, 1)

    self$b_in <- nn_parameter(torch_zeros(1))
    self$b_out <- nn_parameter(torch_zeros(1))

    if (attention_type == "concat") {
      self$Wh <- nn_parameter(torch_randn(c(2 * attention_input_dim, attention_hidden_dim)))
      self$Wa <- nn_parameter(torch_randn(c(attention_hidden_dim, 1)))
      self$ba <- nn_parameter(torch_zeros(1))
    }

    self$dropout <- nn_dropout(p = dropout)
    self$tanh <- nn_tanh()
  },

  forward = function(input) {
    batch_size <- input$size(1)
    time_step <- input$size(2)

    input_q <- self$W_q(input[, -1, ])  # [batch, hidden]
    input_k <- self$W_k(input)  # [batch, time, hidden]
    input_v <- self$W_v(input)  # [batch, time, hidden]

    if (self$attention_type == "add") {
      q <- input_q$reshape(c(batch_size, 1, self$attention_hidden_dim))
      h <- q + input_k + self$b_in
      h <- self$tanh(h)
      e <- self$W_out(h)$reshape(c(batch_size, time_step))
    } else if (self$attention_type == "mul") {
      q <- input_q$reshape(c(batch_size, self$attention_hidden_dim, 1))
      e <- torch_matmul(input_k, q)$squeeze(-1)
    } else if (self$attention_type == "concat") {
      q <- input_q$unsqueeze(2)$`repeat`(c(1, time_step, 1))
      k <- input_k
      c <- torch_cat(list(q, k), dim = -1)
      h <- torch_matmul(c, self$Wh)
      h <- self$tanh(h)
      e <- (torch_matmul(h, self$Wa) + self$ba)$reshape(c(batch_size, time_step))
    } else {
      stop(sprintf("Unknown attention type: %s", self$attention_type))
    }

    a <- nnf_softmax(e, dim = -1)
    a <- self$dropout(a)
    v <- torch_matmul(a$unsqueeze(2), input_v)$squeeze(2)

    return(list(v = v, a = a))
  }
)


#' @title ConCare MultiHeadedAttention Class
#' @description Multi-headed attention with DeCov regularization.
#' @param h Number of attention heads
#' @param d_model Model dimensionality
#' @param dropout Dropout rate. Default 0
#' @keywords internal
#' @export
#' @importFrom torch nn_module nn_linear nn_module_list nn_dropout torch_matmul torch_mean torch_mm torch_norm torch_diag

ConCareMultiHeadedAttention <- torch::nn_module(
  classname = "ConCareMultiHeadedAttention",

  initialize = function(h, d_model, dropout = 0) {
    if (d_model %% h != 0) {
      stop("d_model must be divisible by h")
    }

    self$d_k <- d_model %/% h
    self$h <- h
    self$d_model <- d_model

    self$linears <- nn_module_list(list(
      nn_linear(d_model, self$d_k * self$h),
      nn_linear(d_model, self$d_k * self$h),
      nn_linear(d_model, self$d_k * self$h)
    ))
    self$final_linear <- nn_linear(d_model, d_model)
    self$dropout <- nn_dropout(p = dropout)
  },

  cov = function(m) {
    # m: [hidden, batch] - 2D tensor
    m_exp <- torch_mean(m, dim = 2)
    x <- m - m_exp$unsqueeze(2)
    cov_matrix <- (1 / (x$size(2) - 1)) * torch_matmul(x, x$transpose(1, 2))
    return(cov_matrix)
  },

  forward = function(query, key, value, mask = NULL) {
    if (!is.null(mask)) {
      mask <- mask$unsqueeze(2)
    }

    nbatches <- query$size(1)

    # Project to multi-head
    query_proj <- self$linears[[1]](query)$view(c(nbatches, -1, self$h, self$d_k))$transpose(2, 3)
    key_proj <- self$linears[[2]](key)$view(c(nbatches, -1, self$h, self$d_k))$transpose(2, 3)
    value_proj <- self$linears[[3]](value)$view(c(nbatches, -1, self$h, self$d_k))$transpose(2, 3)

    # Scaled dot-product attention
    d_k <- query_proj$size(-1)
    scores <- torch_matmul(query_proj, key_proj$transpose(-2, -1)) / sqrt(as.numeric(d_k))

    if (!is.null(mask)) {
      scores <- scores$masked_fill(mask == 0, -1e9)
    }

    p_attn <- scores$softmax(dim = -1)
    p_attn <- self$dropout(p_attn)

    x <- torch_matmul(p_attn, value_proj)

    # Concatenate heads
    x <- x$transpose(2, 3)$contiguous()$view(c(nbatches, -1, self$h * self$d_k))

    # Calculate DeCov loss
    feature_dim <- x$size(2)
    DeCov_contexts <- x$transpose(1, 2)$transpose(2, 3)  # [features, hidden, batch]
    DeCov_loss <- 0

    for (i in seq_len(feature_dim)) {
      Covs <- self$cov(DeCov_contexts[i, , ])  # Pass 2D tensor [hidden, batch]
      # Frobenius norm: sqrt(sum of squared elements)
      frob_norm_sq <- (Covs * Covs)$sum()
      diag_norm_sq <- (torch_diag(Covs) * torch_diag(Covs))$sum()
      DeCov_loss <- DeCov_loss + 0.5 * (frob_norm_sq - diag_norm_sq)
    }

    output <- self$final_linear(x)
    return(list(output = output, DeCov_loss = DeCov_loss))
  }
)


#' @title ConCare LayerNorm Class
#' @description Layer normalization.
#' @param features Number of features
#' @param eps Small constant for numerical stability. Default 1e-7
#' @keywords internal
#' @export
#' @importFrom torch nn_module nn_parameter torch_ones torch_zeros

ConCareLayerNorm <- torch::nn_module(
  classname = "ConCareLayerNorm",

  initialize = function(features, eps = 1e-7) {
    self$a_2 <- nn_parameter(torch_ones(features))
    self$b_2 <- nn_parameter(torch_zeros(features))
    self$eps <- eps
  },

  forward = function(x) {
    mean <- x$mean(-1, keepdim = TRUE)
    std <- x$std(-1, keepdim = TRUE)
    return(self$a_2 * (x - mean) / (std + self$eps) + self$b_2)
  }
)


#' @title ConCare SublayerConnection Class
#' @description Residual connection with layer norm.
#' @param size Feature size
#' @param dropout Dropout rate
#' @keywords internal
#' @export
#' @importFrom torch nn_module nn_dropout

ConCareSublayerConnection <- torch::nn_module(
  classname = "ConCareSublayerConnection",

  initialize = function(size, dropout) {
    self$norm <- ConCareLayerNorm(size)
    self$dropout <- nn_dropout(p = dropout)
  },

  forward = function(x, sublayer_fn) {
    returned_value <- sublayer_fn(self$norm(x))
    residual_output <- x + self$dropout(returned_value[[1]])
    decov_loss <- returned_value[[2]]
    return(list(output = residual_output, DeCov_loss = decov_loss))
  }
)


#' @title ConCare PositionwiseFeedForward Class
#' @description Position-wise feed-forward network.
#' @param d_model Input/output dimensionality
#' @param d_ff Hidden dimensionality
#' @param dropout Dropout rate. Default 0.1
#' @keywords internal
#' @export
#' @importFrom torch nn_module nn_linear nn_dropout torch_relu

ConCarePositionwiseFeedForward <- torch::nn_module(
  classname = "ConCarePositionwiseFeedForward",

  initialize = function(d_model, d_ff, dropout = 0.1) {
    self$w_1 <- nn_linear(d_model, d_ff)
    self$w_2 <- nn_linear(d_ff, d_model)
    self$dropout <- nn_dropout(p = dropout)
  },

  forward = function(x) {
    output <- self$w_2(self$dropout(torch_relu(self$w_1(x))))
    return(list(output = output, DeCov_loss = 0))
  }
)


#' @title ConCareLayer Class
#' @description ConCare layer for personalized clinical feature embedding.
#' @details
#' Paper: Ma et al. "ConCare: Personalized clinical feature embedding via
#' capturing the healthcare context." AAAI 2020.
#'
#' This layer uses channel-wise GRU and multi-head attention to capture
#' feature-level and temporal dependencies in clinical data.
#'
#' @param input_dim Dynamic feature size
#' @param static_dim Static feature size. Default 0 (no static features)
#' @param hidden_dim Hidden dimension. Default 128
#' @param num_head Number of attention heads. Default 4
#' @param pe_hidden Positional encoding hidden dimension. Default 64
#' @param dropout Dropout rate. Default 0.5
#' @keywords internal
#' @export
#' @importFrom torch nn_module nn_gru nn_module_list nn_linear nn_dropout nn_tanh torch_zeros torch_cat torch_relu

ConCareLayer <- torch::nn_module(
  classname = "ConCareLayer",

  initialize = function(input_dim, static_dim = 0, hidden_dim = 128,
                       num_head = 4, pe_hidden = 64, dropout = 0.5) {
    self$input_dim <- input_dim
    self$hidden_dim <- hidden_dim
    self$num_head <- num_head
    self$pe_hidden <- pe_hidden
    self$dropout_rate <- dropout
    self$static_dim <- static_dim

    if (hidden_dim %% num_head != 0) {
      stop("hidden_dim must be divisible by num_head")
    }

    # Channel-wise GRUs
    self$GRUs <- nn_module_list(lapply(seq_len(input_dim), function(i) {
      nn_gru(input_size = 1, hidden_size = hidden_dim, batch_first = TRUE)
    }))

    # Final attention
    self$FinalAttentionQKV <- FinalAttentionQKV(
      hidden_dim, hidden_dim,
      attention_type = "mul",
      dropout = dropout
    )

    # Multi-head attention
    self$MultiHeadedAttention <- ConCareMultiHeadedAttention(
      num_head, hidden_dim, dropout = dropout
    )

    # Sublayer connection
    self$SublayerConnection <- ConCareSublayerConnection(hidden_dim, dropout = dropout)

    # Position-wise feed-forward
    self$PositionwiseFeedForward <- ConCarePositionwiseFeedForward(
      hidden_dim, pe_hidden, dropout = 0.1
    )

    if (static_dim > 0) {
      self$demo_proj_main <- nn_linear(static_dim, hidden_dim)
    }

    self$dropout <- nn_dropout(p = dropout)
    self$tanh <- nn_tanh()
  },

  forward = function(x, static = NULL, mask = NULL) {
    # x: [batch, time, features]
    batch_size <- x$size(1)
    time_step <- x$size(2)
    feature_dim <- x$size(3)

    # Process each feature through its own GRU
    GRU_output <- self$GRUs[[1]](
      x[, , 1]$unsqueeze(-1),
      torch_zeros(c(1, batch_size, self$hidden_dim))$to(device = x$device)
    )[[1]]

    Attention_embeded_input <- GRU_output[, -1, ]$unsqueeze(2)  # Last time step

    for (i in seq_len(feature_dim - 1)) {
      embeded_input <- self$GRUs[[i + 1]](
        x[, , i + 1]$unsqueeze(-1),
        torch_zeros(c(1, batch_size, self$hidden_dim))$to(device = x$device)
      )[[1]]

      last_step <- embeded_input[, -1, ]$unsqueeze(2)
      Attention_embeded_input <- torch_cat(list(Attention_embeded_input, last_step), dim = 2)
    }

    # Add static features if provided
    if (self$static_dim > 0 && !is.null(static)) {
      demo_main <- self$tanh(self$demo_proj_main(static))$unsqueeze(2)
      Attention_embeded_input <- torch_cat(list(Attention_embeded_input, demo_main), dim = 2)
    }

    posi_input <- self$dropout(Attention_embeded_input)

    # Apply multi-head attention
    contexts_result <- self$SublayerConnection(posi_input, function(x) {
      self$MultiHeadedAttention(posi_input, posi_input, posi_input, NULL)
    })

    contexts <- contexts_result$output
    DeCov_loss <- contexts_result$DeCov_loss

    # Apply position-wise feed-forward
    contexts <- self$SublayerConnection(contexts, function(x) {
      self$PositionwiseFeedForward(contexts)
    })$output

    # Final attention
    final_result <- self$FinalAttentionQKV(contexts)
    weighted_contexts <- final_result$v
    attention_weights <- final_result$a  # Attention scores

    weighted_contexts <- self$dropout(weighted_contexts)

    return(list(
      output = weighted_contexts,
      DeCov_loss = DeCov_loss,
      attention = attention_weights  # Return attention for interpretability
    ))
  }
)


#' @title ConCare Model Class
#' @description
#' ConCare model for personalized clinical feature embedding.
#'
#' @details
#' Paper: Ma et al. "ConCare: Personalized clinical feature embedding via
#' capturing the healthcare context." AAAI 2020.
#'
#' This model uses channel-wise GRU and contextualized attention to capture
#' personalized healthcare contexts and feature correlations.
#'
#' @param dataset A `SampleDataset` object providing input/output schema
#' @param embedding_dim Integer, embedding dimension. Default 128
#' @param hidden_dim Integer, hidden dimension. Default 128
#' @param num_head Integer, number of attention heads. Default 4
#' @param pe_hidden Integer, positional encoding hidden dimension. Default 64
#' @param dropout Numeric, dropout rate. Default 0.5
#' @export
#' @importFrom torch nn_module nn_linear nn_module_dict torch_cat torch_long torch_float with_no_grad torch_tensor

ConCare <- torch::nn_module(
  classname = "ConCare",

  inherit = BaseModel,

  initialize = function(dataset = NULL,
                        embedding_dim = 128,
                        hidden_dim = 128,
                        num_head = 4,
                        pe_hidden = 64,
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

        self$module_list[[feature_key]] <- ConCareLayer(
          input_dim = embedding_dim,  # After embedding
          static_dim = 0,
          hidden_dim = hidden_dim,
          num_head = num_head,
          pe_hidden = pe_hidden,
          dropout = dropout
        )
      } else if (inherits(processor, "TimeseriesProcessor")) {
        # Timeseries feature: use directly (channel-wise)
        self$feature_types[[feature_key]] <- "timeseries"
        self$module_list[[feature_key]] <- ConCareLayer(
          input_dim = processor$n_channels,  # Number of channels
          static_dim = 0,
          hidden_dim = hidden_dim,
          num_head = num_head,
          pe_hidden = pe_hidden,
          dropout = dropout
        )
      } else {
        stop(sprintf("Unsupported processor type for feature '%s': %s",
                    feature_key, class(processor)[1]))
      }
    }

    self$feature_keys <- names(self$module_list)
    self$concare <- nn_module_dict(self$module_list)
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
      "ConCare model with %d features, embedding_dim=%d, hidden_dim=%d, output_size=%d",
      length(self$feature_keys), embedding_dim, hidden_dim, output_size
    ))
  },

  forward = function(inputs) {
    y_true <- inputs[[self$label_key]]
    feature_inputs <- inputs[self$feature_keys]

    # Process each feature based on its type
    patient_emb <- list()
    feature_importance <- list()
    total_decov_loss <- 0

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

      # Ensure correct format
      if (x$ndim == 4) {
        x <- x$sum(dim = 3)
      } else if (x$ndim == 2) {
        x <- x$unsqueeze(2)
      }

      # Create mask
      mask <- (x$sum(dim = -1)$abs() > 1e-6)$to(dtype = torch_long())

      # Apply ConCare layer
      result <- self$concare[[feature_key]](x = x, static = NULL, mask = mask)
      patient_emb[[feature_key]] <- result$output

      # Store feature importance (attention weights)
      feature_importance[[feature_key]] <- result$attention

      # Accumulate DeCov loss
      total_decov_loss <- total_decov_loss + result$DeCov_loss
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
      feature_importance = feature_importance,  # NEW: Return attention weights
      decov_loss = total_decov_loss  # NEW: Return DeCov loss
    )

    if (!is.null(inputs$embed) && inputs$embed) {
      results$embed <- patient_vec
    }

    return(results)
  }
)
