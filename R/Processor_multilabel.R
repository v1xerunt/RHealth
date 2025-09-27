#' @title Multi-Label Processor
#' @description Processor for multi-label classification. Converts a list of active labels into a
#'              one-hot tensor with multiple 1s. Inherits from FeatureProcessor.
#'
#' @importFrom R6 R6Class
#' @importFrom torch torch_tensor
#' @export
MultiLabelProcessor <- R6::R6Class("MultiLabelProcessor",
  inherit = FeatureProcessor,
  public = list(
    #' @field label_vocab A named integer vector mapping label values to index positions.
    label_vocab = NULL,

    #' @description Constructor that initializes the vocabulary.
    initialize = function() {
      self$label_vocab <- c()
    },

    #' @description Fit the processor from all multi-label lists across samples.
    #' @param samples A list of named lists (sample records).
    #' @param field The name of the multi-label field.
    fit = function(samples, field) {
      all_labels <- unique(unlist(lapply(samples, function(s) s[[field]])))
      num_classes <- length(all_labels)

      if (identical(sort(all_labels), seq_len(num_classes) - 1)) {
        self$label_vocab <- setNames(0:(num_classes - 1), 0:(num_classes - 1))
      } else {
        all_labels <- sort(all_labels)
        self$label_vocab <- setNames(0:(num_classes - 1), all_labels)
      }

      message(sprintf("Label '%s' vocab: %s", field, paste(names(self$label_vocab), collapse = ", ")))
    },

    #' @description Process a list of active labels into a one-hot float tensor.
    #' @param value A character or numeric vector of active labels.
    #' @return A torch tensor of shape `num_classes` with 0s and 1s.
    process = function(value) {
      if (!is.vector(value)) {
        stop("Expected a vector (label list) for multilabel task.", call. = FALSE)
      }
      target <- torch::torch_zeros(length(self$label_vocab), dtype = torch::torch_float())
      for (label in value) {
        index <- self$label_vocab[[as.character(label)]]
        target[index + 1] <- 1.0  # +1 because torch is 1-based in R indexing
      }
      target
    },

    #' @description Return number of classes.
    #' @return Integer.
    size = function() {
      length(self$label_vocab)
    },

    #' @description Print a summary of the processor.
    #' @param ... Ignored.
    print = function(...) {
      cat(sprintf("MultiLabelProcessor(label_vocab_size=%d)\n", length(self$label_vocab)))
    }
  )
)

