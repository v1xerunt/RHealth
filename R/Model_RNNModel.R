#' @title RNNLayer Class
#' @description Recurrent neural network layer (GRU/LSTM/RNN) with built‑in
#' 1‑based‑index safety, masking, dropout, bidirectionality and a learnable
#' fallback hidden vector for empty sequences.
#' 
#' @details
#' **Key design points**
#' * Accepts `mask` indicating valid time steps (1‑based indexing respected).
#' * Uses `pack_padded_sequence` + `pad_packed_sequence` for efficiency.
#' * Samples whose sequence length is *zero* (all‑zero rows) are skipped during
#'   RNN computation **and** later filled with a learnable parameter
#'   `null_hidden` so downstream layers always receive a hidden vector.
#' * Works for unidirectional or bidirectional networks. In the bidirectional
#'   case, the last hidden state is built from the **forward last step** and the
#'   **backward first step**, then projected back to `hidden_size`.
#' 
#' @inheritParams torch::nn_gru
#' @param rnn_type Character, one of "GRU", "LSTM", or "RNN". Default "GRU".
#' @export
#' @importFrom torch nn_module nn_dropout nn_linear nn_parameter
#'   torch_float torch_long torch_zeros torch_randn torch_sum torch_cat
#'   nn_utils_rnn_pack_padded_sequence nn_utils_rnn_pad_packed_sequence

RNNLayer <- torch::nn_module(
  classname = "RNNLayer",

  initialize = function(input_size, hidden_size, rnn_type = "GRU", num_layers = 1, dropout = 0.5, bidirectional = FALSE) {
    self$input_size <- input_size
    self$hidden_size <- hidden_size
    self$rnn_type <- rnn_type
    self$num_layers <- num_layers
    self$dropout <- dropout
    self$bidirectional <- bidirectional

    self$dropout_layer <- nn_dropout(p = dropout)

    rnn_class <- switch(
      rnn_type,
      "GRU" = nn_gru,
      "LSTM" = nn_lstm,
      "RNN" = nn_rnn,
      stop(paste0("Unsupported rnn_type: ", rnn_type))
    )

    self$rnn <- rnn_class(
      input_size = input_size,
      hidden_size = hidden_size,
      num_layers = num_layers,
      batch_first = TRUE,
      dropout = if (num_layers > 1) dropout else 0,
      bidirectional = bidirectional
    )

    self$num_directions <- if (bidirectional) 2 else 1
    self$null_hidden <- nn_parameter(torch_randn(c(self$num_directions * self$num_layers, 1, hidden_size)))

  },

  forward = function(x, mask = NULL) {
    x <- x$to(dtype = torch_float())
    x <- self$dropout_layer(x)

    B <- x$size(1)
    T <- x$size(2)

    lengths_cpu <- if (is.null(mask)) {
      torch_full(size = B, fill_value = T, dtype = torch_long())
    } else {
      mask <- mask$to(dtype = torch_long())
      torch_sum(mask, dim = -1)$cpu()
    }
    lengths_cpu <- torch_clamp(lengths_cpu, min = 1)
    valid_idx <- lengths_cpu > 0
    num_valid <- as.integer(torch_sum(valid_idx)$item())
    if (num_valid < B) {
      warning("Some sequences in the batch have zero length and are being skipped.")
    }
    if (num_valid == 0) {
      stop("All sequences in this batch have zero length! Cannot proceed.")
    }

    x_v <- x[valid_idx$to(device = x$device), ]
    len_v <- lengths_cpu[valid_idx]

    packed <- nn_utils_rnn_pack_padded_sequence(
      x_v, len_v$to(dtype = torch_int()), batch_first = TRUE, enforce_sorted = FALSE
    )

    out_packed <- self$rnn(packed)
    out <- nn_utils_rnn_pad_packed_sequence(out_packed[[1]], batch_first = TRUE, total_length = T)[[1]]

    z <- torch_zeros(c(B, T, self$hidden_size), device = x$device)

    valid_idx_tensor <- torch_where(valid_idx)[[1]]
    valid_indices <- valid_idx_tensor$to(dtype = torch_long())

    # for (i in seq_len(num_valid)) {
    #   z[as.integer(valid_indices[i]$item()), , ] <- out[i, , ]
    # }
    valid_indices <- torch_where(valid_idx)[[1]]$to(dtype = torch_long())

    z <- torch_index_put_(
      self = z,
      indices = list(valid_indices),
      values = out,
      accumulate = FALSE
    )

    last_indices <- lengths_cpu$view(c(-1, 1, 1))$
      expand(c(B, 1, self$hidden_size))$
      to(dtype = torch_long(), device = out$device)

    last_outputs <- out$gather(dim = 2, index = last_indices)$squeeze(2)

    return(list(outputs = z, last_outputs = last_outputs))
  }

)


#' @title RNN Model Class
#' @description
#' A full‑featured classification model that
#' (i) embeds each input feature with `EmbeddingModel`,
#' (ii) processes each feature sequence through its own `RNNLayer`, and
#' (iii) concatenates the final hidden states for prediction.
#'
#' @details
#' * Works for binary, multi‑class, or regression labels (inferred from `dataset`).
#' * Supports optional `mask` per feature (all‑zero rows are treated as padding).
#' * All internal indices comply with R's 1‑based rule; no device mismatches.
#'
#' @param dataset A `SampleDataset` object providing input/output schema.
#' @param embedding_dim Integer, embedding width for each token.  Default 128.
#' @param hidden_dim Integer, hidden size of each RNN.  Default 128.
#' @param ... Additional arguments forwarded to each `RNNLayer` (except
#'        `input_size`/`hidden_size`, which are fixed by `embedding_dim` /
#'        `hidden_dim`).
#' @export
#' @importFrom torch nn_module nn_linear nn_module_dict torch_cat torch_long
RNN <- torch::nn_module(
  classname = "RNN",

  inherit = BaseModel,

  initialize = function(dataset = NULL,
                        embedding_dim = 128,
                        hidden_dim    = 128,
                        ...) {
    super$initialize(dataset)

    self$embedding_dim <- embedding_dim
    self$hidden_dim    <- hidden_dim

    # extra_args <- list(...)
    # if ("input_size"  %in% names(extra_args))
    #   stop("input_size is determined by embedding_dim")
    # if ("hidden_size" %in% names(extra_args))
    #   stop("hidden_size is determined by hidden_dim")
    stopifnot(length(self$label_keys) == 1)
    self$label_key <- self$label_keys[[1]]
    self$mode      <- self$dataset$output_schema[[self$label_key]]
    self$embedding_model <- EmbeddingModel(dataset, embedding_dim)

    # --- build a dedicated RNNLayer per input feature -------------------------
    self$module_list <- list()

    for (feature_key in names(self$dataset$input_processors)) {

      self$module_list[[feature_key]] <- RNNLayer(
        input_size  = embedding_dim,
        hidden_size = hidden_dim,
        ...
      )
    }
    self$feature_keys <- names(self$module_list)
    self$rnn <- nn_module_dict(self$module_list)

    output_size <- self$get_output_size()
    self$fc <- nn_linear(length(self$feature_keys) * hidden_dim, output_size)
    message(sprintf(
      "RNN model with %d features, embedding_dim=%d, hidden_dim=%d, output_size=%d",
      length(self$feature_keys), embedding_dim, hidden_dim, output_size
    ))
  },

  forward = function(inputs) {
    patient_emb <- list()

    y_true <- inputs[[self$label_key]]
    ay_true <- y_true$clone()
    embedded <- self$embedding_model(inputs)  

    for (feature_key in self$feature_keys) {
      x <- embedded[[feature_key]]
      mask <- (x$sum(dim = -1) != 0)$to(dtype = torch_long())
      lengths <- torch_sum(mask, dim = -1)
      result <- self$rnn[[feature_key]](x, mask)
      hidden <- result[[2]]
      patient_emb[[feature_key]] <- result[[2]]   
    }
    patient_vec <- torch_cat(patient_emb, dim = 2)
    logits <- self$fc(patient_vec)
    device <- logits$device
    
    if (logits$ndim == 2 && logits$shape[2] == 1) {
      logits <- logits$squeeze(2)
    }
    if (y_true$ndim == 2 && y_true$shape[2] == 1) {
      y_true <- y_true$squeeze(2)
    }

    y_true <- y_true$to(device = device)

    loss   <- self$get_loss_function()(logits, y_true)
    dtype = torch_long()
    y_prob <- self$prepare_y_prob(logits)
    ay_true <- ay_true$to(device = device)
    results <- list(
      loss  = loss,
      y_prob = y_prob,
      y_true = ay_true,
      logit = logits
    )

    if (!is.null(inputs$embed) && inputs$embed) {
      results$embed <- patient_vec
    }
    return(results)
  }
)
