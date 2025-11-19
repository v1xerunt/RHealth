#' @title Multi-Class Label Processor
#' @description Processor for multi-class classification tasks. Converts string or integer labels
#'              into integer indices, with one output per label.
#'
#' @importFrom R6 R6Class
#' @importFrom torch torch_tensor
#' @export
MultiClassLabelProcessor <- R6::R6Class("MultiClassLabelProcessor",
  inherit = FeatureProcessor,
  public = list(
    #' @field label_vocab A named integer vector mapping labels to indices.
    label_vocab = NULL,

    #' @description Initialize with empty label vocabulary.
    initialize = function() {
      self$label_vocab <- c()
    },

    #' @description Fit the label vocabulary from the given field of all samples.
    #' @param samples A list of named lists representing the dataset.
    #' @param field The name of the field containing labels.
    fit = function(samples, field) {
      labels <- unique(vapply(samples, function(s) s[[field]], FUN.VALUE = samples[[1]][[field]]))
      num_classes <- length(labels)

      if (identical(sort(labels), seq_len(num_classes) - 1)) {
        # Convert 0-based labels to 1-based for R conventions
        self$label_vocab <- setNames(1:num_classes, 0:(num_classes - 1))
      } else {
        labels <- sort(labels)
        self$label_vocab <- setNames(1:num_classes, labels)
      }

      message(sprintf("Label '%s' vocab: %s", field, paste(names(self$label_vocab), collapse = ", ")))
    },

    #' @description Convert a label into a torch long integer tensor (scalar).
    #' @param value The raw label value.
    #' @return An int64 torch tensor.
    process = function(value) {
      index <- self$label_vocab[[as.character(value)]]
      torch::torch_tensor(index, dtype = torch::torch_long())
    },

    #' @description Return number of classes (vocabulary size).
    #' @return Integer
    size = function() {
      length(self$label_vocab)
    },

    #' @description Print a summary of the processor.
    #' @description Print a summary of the processor.
    #' @param ... Ignored.
    print = function(...) {
      cat(sprintf("MultiClassLabelProcessor(label_vocab_size=%d)\n", length(self$label_vocab)))
    }
  )
)
