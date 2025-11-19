#' @include Model_BaseModel.R Model_EmbeddingModel.R
#' @title CNNBlock Class
#' @description Convolutional neural network block with residual connection.
#' @details
#' Implements a residual CNN block with two convolutional layers,
#' batch normalization, and ReLU activation. Supports 1D, 2D, and 3D convolutions.
#'
#' @param in_channels Number of input channels
#' @param out_channels Number of output channels
#' @param spatial_dim Spatial dimensionality (1, 2, or 3)
#' @keywords internal
#' @export
#' @importFrom torch nn_module nn_conv1d nn_conv2d nn_conv3d nn_batch_norm1d nn_batch_norm2d nn_batch_norm3d nn_relu nn_sequential

CNNBlock <- torch::nn_module(
  classname = "CNNBlock",

  initialize = function(in_channels, out_channels, spatial_dim) {
    if (!spatial_dim %in% c(1, 2, 3)) {
      stop(sprintf("Unsupported spatial dimension: %d", spatial_dim))
    }

    self$in_channels <- in_channels
    self$out_channels <- out_channels
    self$spatial_dim <- spatial_dim

    # Select appropriate conv and batch norm layers based on spatial_dim
    if (spatial_dim == 1) {
      conv_fn <- nn_conv1d
      bn_fn <- nn_batch_norm1d
    } else if (spatial_dim == 2) {
      conv_fn <- nn_conv2d
      bn_fn <- nn_batch_norm2d
    } else {
      conv_fn <- nn_conv3d
      bn_fn <- nn_batch_norm3d
    }

    # First conv block
    self$conv1 <- nn_sequential(
      conv_fn(in_channels, out_channels, kernel_size = 3, padding = 1),
      bn_fn(out_channels),
      nn_relu()
    )

    # Second conv block
    self$conv2 <- nn_sequential(
      conv_fn(out_channels, out_channels, kernel_size = 3, padding = 1),
      bn_fn(out_channels)
    )

    # Downsample for residual if needed
    self$downsample <- NULL
    if (in_channels != out_channels) {
      self$downsample <- nn_sequential(
        conv_fn(in_channels, out_channels, kernel_size = 1),
        bn_fn(out_channels)
      )
    }

    self$relu <- nn_relu()
  },

  forward = function(x) {
    residual <- x

    # First conv
    out <- self$conv1(x)

    # Second conv
    out <- self$conv2(out)

    # Adjust residual if needed
    if (!is.null(self$downsample)) {
      residual <- self$downsample(x)
    }

    # Add residual
    out <- out + residual
    out <- self$relu(out)

    return(out)
  }
)


#' @title CNNLayer Class
#' @description Stack of CNN blocks with adaptive pooling.
#' @details
#' Stacks multiple CNN blocks and applies adaptive average pooling
#' at the end. Supports 1D, 2D, and 3D spatial dimensions.
#'
#' @param input_size Number of input channels
#' @param hidden_size Number of hidden channels
#' @param num_layers Number of CNN blocks. Default 1
#' @param spatial_dim Spatial dimensionality (1, 2, or 3). Default 1
#' @keywords internal
#' @export
#' @importFrom torch nn_module nn_module_list nn_adaptive_avg_pool1d nn_adaptive_avg_pool2d nn_adaptive_avg_pool3d

CNNLayer <- torch::nn_module(
  classname = "CNNLayer",

  initialize = function(input_size, hidden_size, num_layers = 1, spatial_dim = 1) {
    if (!spatial_dim %in% c(1, 2, 3)) {
      stop(sprintf("Unsupported spatial dimension: %d", spatial_dim))
    }

    self$input_size <- input_size
    self$hidden_size <- hidden_size
    self$num_layers <- num_layers
    self$spatial_dim <- spatial_dim

    # Stack CNN blocks
    self$cnn <- nn_module_list()
    in_channels <- input_size

    for (i in seq_len(num_layers)) {
      self$cnn$append(CNNBlock(in_channels, hidden_size, spatial_dim))
      in_channels <- hidden_size
    }

    # Adaptive pooling
    if (spatial_dim == 1) {
      self$pooling <- nn_adaptive_avg_pool1d(1)
    } else if (spatial_dim == 2) {
      self$pooling <- nn_adaptive_avg_pool2d(c(1, 1))
    } else {
      self$pooling <- nn_adaptive_avg_pool3d(c(1, 1, 1))
    }
  },

  forward = function(x) {
    # Apply CNN blocks
    for (i in seq_along(self$cnn)) {
      x <- self$cnn[[i]](x)
    }

    outputs <- x

    # Apply pooling
    pooled <- self$pooling(x)
    pooled_outputs <- pooled$reshape(c(x$size(1), -1))

    return(list(outputs = outputs, pooled_outputs = pooled_outputs))
  }
)


#' @title CNN Model Class
#' @description
#' Convolutional neural network model for healthcare prediction tasks.
#' Each feature is embedded and processed through independent CNN layers.
#' The pooled representations are concatenated for final prediction.
#'
#' @details
#' * Supports binary, multi-class, and regression tasks
#' * Each feature has its own CNN encoder
#' * Handles sequence, timeseries, and tensor inputs
#' * Automatically determines spatial dimensions based on processor type
#'
#' @param dataset A `SampleDataset` object providing input/output schema
#' @param embedding_dim Integer, embedding dimension. Default 128
#' @param hidden_dim Integer, number of CNN channels. Default 128
#' @param num_layers Integer, number of CNN blocks. Default 1
#' @export
#' @importFrom torch nn_module nn_linear nn_module_dict torch_cat torch_long

CNN <- torch::nn_module(
  classname = "CNN",

  inherit = BaseModel,

  initialize = function(dataset = NULL,
                        embedding_dim = 128,
                        hidden_dim = 128,
                        num_layers = 1) {
    super$initialize(dataset)

    self$embedding_dim <- embedding_dim
    self$hidden_dim <- hidden_dim
    self$num_layers <- num_layers

    stopifnot(length(self$label_keys) == 1)
    self$label_key <- self$label_keys[[1]]
    self$mode <- self$dataset$output_schema[[self$label_key]]

    # Embedding model
    self$embedding_model <- EmbeddingModel(dataset, embedding_dim)

    # Determine spatial dimensions and build CNN layers
    self$feature_conv_dims <- list()
    self$module_list <- list()

    for (feature_key in names(self$dataset$input_processors)) {
      processor <- self$dataset$input_processors[[feature_key]]

      # Determine spatial dimension based on processor type
      # For sequence/timeseries data, use 1D convolution
      spatial_dim <- 1  # Default to 1D

      self$feature_conv_dims[[feature_key]] <- spatial_dim

      # For 1D convolution, input channels = embedding_dim
      input_channels <- embedding_dim

      # Create CNN layer
      self$module_list[[feature_key]] <- CNNLayer(
        input_size = input_channels,
        hidden_size = hidden_dim,
        num_layers = num_layers,
        spatial_dim = spatial_dim
      )
    }

    self$feature_keys <- names(self$module_list)
    self$cnn <- nn_module_dict(self$module_list)

    # Output layer
    output_size <- self$get_output_size()
    self$fc <- nn_linear(length(self$feature_keys) * hidden_dim, output_size)

    message(sprintf(
      "CNN model with %d features, embedding_dim=%d, hidden_dim=%d, num_layers=%d, output_size=%d",
      length(self$feature_keys), embedding_dim, hidden_dim, num_layers, output_size
    ))
  },

  forward = function(inputs) {
    y_true <- inputs[[self$label_key]]
    feature_inputs <- inputs[self$feature_keys]

    # Embed features
    embedded <- self$embedding_model(feature_inputs)

    # Process each feature through its CNN
    patient_emb <- lapply(self$feature_keys, function(feature_key) {
      x <- embedded[[feature_key]]
      spatial_dim <- self$feature_conv_dims[[feature_key]]

      # Ensure x is in the right format for CNN
      # For 1D CNN: [batch, channels, length]
      # For 2D CNN: [batch, channels, height, width]
      # For 3D CNN: [batch, channels, depth, height, width]

      if (spatial_dim == 1) {
        # Expected: [batch, seq_len, embedding_dim]
        if (x$ndim == 4) {
          # Handle StageNet-style inputs: [batch, seq_len, inner_len, emb]
          # Sum over inner_len
          x <- x$sum(dim = 3)
        } else if (x$ndim == 2) {
          # Handle single-step inputs: [batch, emb]
          # Add sequence dimension
          x <- x$unsqueeze(2)
        }

        # Permute to [batch, embedding_dim, seq_len] for 1D conv
        if (x$ndim == 3) {
          x <- x$permute(c(1, 3, 2))
        }
      }

      # Ensure float type
      x <- x$to(dtype = torch_float())

      # Apply CNN
      result <- self$cnn[[feature_key]](x)
      result$pooled_outputs
    })

    # Concatenate pooled embeddings
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
      logit = logits
    )

    if (!is.null(inputs$embed) && inputs$embed) {
      results$embed <- patient_vec
    }

    return(results)
  }
)
