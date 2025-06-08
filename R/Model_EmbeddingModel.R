#' EmbeddingModel
#'
#' @description
#' EmbeddingModel is responsible for creating embedding layers for different types of input data.
#'
#' @details
#' Inherits from BaseModel. For each entry in `dataset$input_processors`, if the processor is a
#' `SequenceProcessor`, an embedding layer (`nn_embedding`) is created; if it is a `TimeseriesProcessor`,
#' a linear layer (`nn_linear`) is created. During the forward pass, each input tensor is moved to the
#' model’s device; if an embedding layer exists for that field, it is applied to the tensor. Otherwise,
#' the tensor is passed through unchanged.
#'
#' @param dataset A SampleDataset object containing input processors named by field. Each processor must
#'   be either a `SequenceProcessor` (with a `code_vocab` vector) or a `TimeseriesProcessor` (with a `size` integer).
#' @param embedding_dim Integer specifying the dimension of the embedding space. Defaults to 128.
#'
#' @field embedding_layers A `nn_module_dict` of submodules, one embedding (or linear) layer per field.
#'
#' @return An `EmbeddingModel` object that inherits from `BaseModel`.
#'
#' @examples
#' \dontrun{
#' # Assume `my_dataset` is a SampleDataset with input_processors that includes
#' # SequenceProcessor and/or TimeseriesProcessor instances.
#'
#' model <- EmbeddingModel(dataset = my_dataset, embedding_dim = 128)
#' # Suppose `inputs` is a named list of torch tensors, e.g.:
#' inputs <- list(
#'   sequence_field   = torch_tensor(matrix(sample(1:100, 16), nrow = 4, ncol = 4)),
#'   timeseries_field = torch_tensor(matrix(rnorm(20), nrow = 5, ncol = 4))
#' )
#' outputs <- model(inputs)
#' # `outputs` is a named list of embedded tensors:
#' #   - For “sequence_field”, a tensor of shape (batch_size, seq_len, embedding_dim)
#' #   - For “timeseries_field”, a tensor of shape (batch_size, embedding_dim)
#' }
#'
#' @export
EmbeddingModel <- torch::nn_module(
  classname = "EmbeddingModel",
  inherit   = BaseModel,

  initialize = function(dataset, embedding_dim = 128) {
    #' @description
    #' Initialize an EmbeddingModel by constructing embedding layers based on input processors.
    #'
    #' @param dataset A SampleDataset object containing input_processors.
    #' @param embedding_dim Integer embedding dimension. Default is 128.
    #' @return None (initializes fields inside the object).

    # Call parent (BaseModel) initializer, which is assumed to set up `self$device` and other internals
    super$initialize(dataset)

    # Create a ModuleDict to hold embedding (or linear) layers for each input field
    self$module_list <- list()

    # For each field in the dataset’s input_processors, add either an nn_embedding or nn_linear layer
    for (field_name in names(dataset$input_processors)) {
      processor <- dataset$input_processors[[field_name]]

      if (inherits(processor, "SequenceProcessor")) {
        # SequenceProcessor: use vocabulary length to build an Embedding layer (padding_idx = 0)
        vocab_size <- length(processor$code_vocab)
        self$module_list[[field_name]] <- nn_embedding(
          num_embeddings = vocab_size + 1,
          embedding_dim  = embedding_dim,
          padding_idx    = 1
        )

      } else if (inherits(processor, "TimeseriesProcessor")) {
        # TimeseriesProcessor: use feature size to build a Linear layer mapping to embedding_dim
        self$module_list[[field_name]] <- nn_linear(
          in_features  = processor$size,
          out_features = embedding_dim
        )
      }
      # If processor is neither a SequenceProcessor nor a TimeseriesProcessor, no layer is added:
      # in forward(), inputs for that field will be passed through unchanged.
    }

        self$embedding_layers <- nn_module_dict(self$module_list)

  },


  forward = function(inputs) {
    #' @description
    #' Perform a forward pass by computing embeddings (or passing through) for each field.
    #'
    #' @param inputs A named list of `torch_tensor` objects, with names matching dataset$input_processors.
    #' @return A named list of `torch_tensor` objects after embedding (or passthrough).

    embedded <- list()

    for (field_name in names(inputs)) {
      tensor <- inputs[[field_name]]

      # 修正非法索引 0（确保 padding_idx = 0 不被作为有效 ID 使用）
      tensor[tensor == 0] <- 1

      # 将输入张量移到 embedding 层的同一设备上
      embed_device <- self$embedding_layers[[field_name]]$weight$device
      tensor <- tensor$to(device = embed_device)

      # 如果有 embedding 层，则嵌入；否则 passthrough
      if (field_name %in% names(self$module_list)) {
        embedded[[field_name]] <- self$embedding_layers[[field_name]](tensor)
      } else {
        embedded[[field_name]] <- tensor
      }
    }
    return(embedded)
  },


  .repr = function() {
    #' @description
    #' Return a concise string representation of the EmbeddingModel, listing its embedding layers.
    #'
    #' @return A character string representation.

    paste0(
      "EmbeddingModel(embedding_layers = {",
      paste(names(self$embedding_layers), collapse = ", "),
      "})"
    )
  }
)
