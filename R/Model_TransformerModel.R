#' @include Model_BaseModel.R Model_EmbeddingModel.R
#' @title Attention Class
#' @description Scaled dot-product attention mechanism.
#' @details
#' Computes attention scores using query, key, and value matrices with
#' optional masking and dropout.
#' @keywords internal
#' @export
#' @importFrom torch nn_module nn_dropout torch_matmul

Attention <- torch::nn_module(
  classname = "Attention",

  initialize = function() {
    # No parameters needed for basic attention
  },

  forward = function(query, key, value, mask = NULL, dropout = NULL) {
    # query, key, value: [batch, heads, len, dim]
    d_k <- query$size(-1)

    # Compute attention scores
    scores <- torch_matmul(query, key$transpose(-2, -1)) / sqrt(as.numeric(d_k))

    # Apply mask if provided
    if (!is.null(mask)) {
      scores <- scores$masked_fill(mask == 0, -1e9)
    }

    # Softmax to get attention probabilities
    p_attn <- scores$softmax(dim = -1)

    # Apply mask again to zero out padded positions
    if (!is.null(mask)) {
      p_attn <- p_attn$masked_fill(mask == 0, 0)
    }

    # Apply dropout if provided
    if (!is.null(dropout)) {
      p_attn <- dropout(p_attn)
    }

    # Apply attention to values
    output <- torch_matmul(p_attn, value)

    return(list(output = output, attention = p_attn))
  }
)


#' @title MultiHeadedAttention Class
#' @description Multi-head attention mechanism for Transformer.
#' @param h Number of attention heads
#' @param d_model Model dimensionality
#' @param dropout Dropout probability
#' @keywords internal
#' @export
#' @importFrom torch nn_module nn_linear nn_dropout nn_module_list

MultiHeadedAttention <- torch::nn_module(
  classname = "MultiHeadedAttention",

  initialize = function(h, d_model, dropout = 0.1) {
    if (d_model %% h != 0) {
      stop("d_model must be divisible by h")
    }

    self$d_k <- d_model %/% h
    self$h <- h
    self$d_model <- d_model

    # Linear layers for Q, K, V projections and output
    self$linear_layers <- nn_module_list(list(
      nn_linear(d_model, d_model, bias = FALSE),
      nn_linear(d_model, d_model, bias = FALSE),
      nn_linear(d_model, d_model, bias = FALSE)
    ))
    self$output_linear <- nn_linear(d_model, d_model, bias = FALSE)

    self$attention <- Attention()
    self$dropout <- nn_dropout(p = dropout)
  },

  forward = function(query, key, value, mask = NULL) {
    batch_size <- query$size(1)

    # 1) Linear projections in batch from d_model => h x d_k
    query <- self$linear_layers[[1]](query)$view(c(batch_size, -1, self$h, self$d_k))$transpose(2, 3)
    key <- self$linear_layers[[2]](key)$view(c(batch_size, -1, self$h, self$d_k))$transpose(2, 3)
    value <- self$linear_layers[[3]](value)$view(c(batch_size, -1, self$h, self$d_k))$transpose(2, 3)

    # 2) Adjust mask for multiple heads
    if (!is.null(mask)) {
      mask <- mask$unsqueeze(2)  # Add head dimension
    }

    # 3) Apply attention
    attn_result <- self$attention(query, key, value, mask = mask, dropout = self$dropout)
    x <- attn_result$output

    # 4) Concat and apply final linear
    x <- x$transpose(2, 3)$contiguous()$view(c(batch_size, -1, self$h * self$d_k))
    output <- self$output_linear(x)

    return(output)
  }
)


#' @title PositionwiseFeedForward Class
#' @description Two-layer feed-forward network with GELU activation.
#' @param d_model Input/output dimensionality
#' @param d_ff Hidden layer dimensionality
#' @param dropout Dropout rate
#' @keywords internal
#' @export
#' @importFrom torch nn_module nn_linear nn_dropout nn_gelu

PositionwiseFeedForward <- torch::nn_module(
  classname = "PositionwiseFeedForward",

  initialize = function(d_model, d_ff, dropout = 0.1) {
    self$w_1 <- nn_linear(d_model, d_ff)
    self$w_2 <- nn_linear(d_ff, d_model)
    self$dropout <- nn_dropout(p = dropout)
    self$activation <- nn_gelu()
  },

  forward = function(x, mask = NULL) {
    x <- self$w_2(self$dropout(self$activation(self$w_1(x))))

    # Apply mask if provided
    if (!is.null(mask)) {
      valid_mask <- mask$sum(dim = -1) > 0
      x[!valid_mask, ] <- 0
    }

    return(x)
  }
)


#' @title SublayerConnection Class
#' @description Pre-norm residual connection wrapper.
#' @param size Feature dimensionality
#' @param dropout Dropout rate
#' @keywords internal
#' @export
#' @importFrom torch nn_module nn_layer_norm nn_dropout

SublayerConnection <- torch::nn_module(
  classname = "SublayerConnection",

  initialize = function(size, dropout) {
    self$norm <- nn_layer_norm(size)
    self$dropout <- nn_dropout(p = dropout)
  },

  forward = function(x, sublayer_fn) {
    # Pre-norm: normalize, apply sublayer, add residual
    return(x + self$dropout(sublayer_fn(self$norm(x))))
  }
)


#' @title TransformerBlock Class
#' @description Single Transformer encoder block with multi-head attention and FFN.
#' @param hidden Hidden size
#' @param attn_heads Number of attention heads
#' @param dropout Dropout rate
#' @keywords internal
#' @export
#' @importFrom torch nn_module nn_dropout

TransformerBlock <- torch::nn_module(
  classname = "TransformerBlock",

  initialize = function(hidden, attn_heads, dropout) {
    self$attention <- MultiHeadedAttention(h = attn_heads, d_model = hidden, dropout = dropout)
    self$feed_forward <- PositionwiseFeedForward(d_model = hidden, d_ff = 4 * hidden, dropout = dropout)
    self$input_sublayer <- SublayerConnection(size = hidden, dropout = dropout)
    self$output_sublayer <- SublayerConnection(size = hidden, dropout = dropout)
    self$dropout <- nn_dropout(p = dropout)
  },

  forward = function(x, mask = NULL) {
    # Self-attention sublayer
    x <- self$input_sublayer(x, function(x_norm) {
      self$attention(x_norm, x_norm, x_norm, mask = mask)
    })

    # Feed-forward sublayer
    x <- self$output_sublayer(x, function(x_norm) {
      self$feed_forward(x_norm, mask = mask)
    })

    return(self$dropout(x))
  }
)


#' @title TransformerLayer Class
#' @description Stack of Transformer encoder blocks.
#' @param feature_size Hidden feature size
#' @param heads Number of attention heads
#' @param dropout Dropout rate
#' @param num_layers Number of transformer blocks
#' @keywords internal
#' @export
#' @importFrom torch nn_module nn_module_list

TransformerLayer <- torch::nn_module(
  classname = "TransformerLayer",

  initialize = function(feature_size, heads = 1, dropout = 0.5, num_layers = 1) {
    self$feature_size <- feature_size
    self$heads <- heads
    self$num_layers <- num_layers

    # Stack of transformer blocks
    self$transformer <- nn_module_list(
      lapply(1:num_layers, function(i) {
        TransformerBlock(hidden = feature_size, attn_heads = heads, dropout = dropout)
      })
    )
  },

  forward = function(x, mask = NULL) {
    # x: [batch, seq_len, feature_size]
    # mask: [batch, seq_len] or [batch, seq_len, seq_len]

    # Convert mask to attention mask format if needed
    if (!is.null(mask) && mask$ndim == 2) {
      # Create [batch, seq_len, seq_len] mask
      mask <- torch_einsum("ab,ac->abc", list(mask, mask))
    }

    # Apply each transformer block
    for (i in seq_along(self$transformer)) {
      x <- self$transformer[[i]](x, mask = mask)
    }

    # Extract embeddings
    emb <- x  # Full sequence embeddings
    cls_emb <- x[, 1, ]  # CLS token embedding (first position)

    return(list(emb = emb, cls_emb = cls_emb))
  }
)


#' @title Transformer Model Class
#' @description
#' Transformer-based model for healthcare prediction tasks.
#' Each feature is embedded and processed through independent Transformer layers.
#' The CLS embeddings are concatenated for final prediction.
#'
#' @details
#' * Supports binary, multi-class, and regression tasks
#' * Uses multi-head self-attention mechanisms
#' * Each feature has its own Transformer encoder stack
#' * CLS token embeddings are used for classification
#'
#' @param dataset A `SampleDataset` object providing input/output schema
#' @param embedding_dim Integer, embedding dimension. Default 128
#' @param heads Integer, number of attention heads. Default 1
#' @param dropout Numeric, dropout rate. Default 0.5
#' @param num_layers Integer, number of transformer blocks. Default 1
#' @export
#' @importFrom torch nn_module nn_linear nn_module_dict torch_cat torch_einsum torch_long

Transformer <- torch::nn_module(
  classname = "Transformer",

  inherit = BaseModel,

  initialize = function(dataset = NULL,
                        embedding_dim = 128,
                        heads = 1,
                        dropout = 0.5,
                        num_layers = 1) {
    super$initialize(dataset)

    self$embedding_dim <- embedding_dim
    self$heads <- heads
    self$dropout <- dropout
    self$num_layers <- num_layers

    stopifnot(length(self$label_keys) == 1)
    self$label_key <- self$label_keys[[1]]
    self$mode <- self$dataset$output_schema[[self$label_key]]

    # Embedding model
    self$embedding_model <- EmbeddingModel(dataset, embedding_dim)

    # Build a dedicated TransformerLayer per input feature
    self$module_list <- list()

    for (feature_key in names(self$dataset$input_processors)) {
      self$module_list[[feature_key]] <- TransformerLayer(
        feature_size = embedding_dim,
        heads = heads,
        dropout = dropout,
        num_layers = num_layers
      )
    }

    self$feature_keys <- names(self$module_list)
    self$transformer <- nn_module_dict(self$module_list)

    # Output layer
    output_size <- self$get_output_size()
    self$fc <- nn_linear(length(self$feature_keys) * embedding_dim, output_size)

    message(sprintf(
      "Transformer model with %d features, embedding_dim=%d, heads=%d, num_layers=%d, output_size=%d",
      length(self$feature_keys), embedding_dim, heads, num_layers, output_size
    ))
  },

  forward = function(inputs) {
    y_true <- inputs[[self$label_key]]
    feature_inputs <- inputs[self$feature_keys]

    # Embed features
    embedded <- self$embedding_model(feature_inputs)

    # Process each feature through its Transformer
    patient_emb <- lapply(self$feature_keys, function(feature_key) {
      x <- embedded[[feature_key]]

      # Ensure x is [batch, seq_len, embedding_dim]
      if (x$ndim == 4) {
        # Handle StageNet-style inputs: [batch, seq_len, inner_len, emb]
        # Sum over inner_len
        x <- x$sum(dim = 3)
      } else if (x$ndim == 2) {
        # Handle single-step inputs: [batch, emb]
        # Add sequence dimension
        x <- x$unsqueeze(2)
      }

      # Create mask: [batch, seq_len]
      mask <- (x$sum(dim = -1)$abs() > 1e-6)$to(dtype = torch_long())

      # Ensure at least one valid position per sample
      invalid_rows <- mask$sum(dim = -1) == 0
      if (invalid_rows$any()$item()) {
        mask[invalid_rows, 1] <- 1
      }

      # Apply transformer
      result <- self$transformer[[feature_key]](x = x, mask = mask)
      result$cls_emb
    })

    # Concatenate CLS embeddings
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
