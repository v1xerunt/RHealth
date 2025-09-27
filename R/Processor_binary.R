#' @title Binary Label Processor
#' @description Processor for binary classification labels. Supports numeric (0/1),
#' logical (TRUE/FALSE), or categorical binary labels.
#'
#' @importFrom R6 R6Class
#' @importFrom torch torch_tensor
#' @export
BinaryLabelProcessor <- R6::R6Class("BinaryLabelProcessor",
  inherit = FeatureProcessor,
  public = list(
    #' @field label_vocab A named integer vector representing label-to-index mapping.
    label_vocab = NULL,

    #' @description Initialize the processor with empty vocabulary.
    initialize = function() {
      self$label_vocab <- c()
    },

    #' @description Fit the processor by analyzing all unique labels in the dataset.
    #' @param samples A list of named lists (samples).
    #' @param field The name of the label field to process.
    fit = function(samples, field) {
      if (length(samples) == 0) {
        stop("BinaryLabelProcessor: samples list is empty.", call. = FALSE)
      }

      labels <- unique(vapply(samples, function(s) s[[field]], FUN.VALUE = samples[[1]][[field]]))
      n_labels <- length(labels)

      if (n_labels != 2) {
        stop(sprintf("Expected 2 unique labels, got %d", n_labels), call. = FALSE)
      }

      if (identical(sort(labels), c(0, 1))) {
        self$label_vocab <- c(`0` = 0, `1` = 1)
      } else if (identical(sort(labels), c(FALSE, TRUE))) {
        self$label_vocab <- c(`FALSE` = 0, `TRUE` = 1)
      } else {
        labels <- sort(labels)
        self$label_vocab <- setNames(0:1, labels)
      }

      message(sprintf("Label '%s' vocab: %s", field, paste(names(self$label_vocab), collapse = ", ")))
    },

    #' @description Process a label into a torch tensor `[0]` or `[1]`.
    #' @param value A single label value.
    #' @return A float32 torch tensor of shape `1`.
    process = function(value) {
      index <- self$label_vocab[[as.character(value)]]
      torch::torch_tensor(index, dtype = torch::torch_float())
    },

    #' @description Return the output dimensionality (fixed at 1).
    #' @return Integer 1
    size = function() {
      return(1)
    },

    #' @description Print a summary of the processor.
    #' @param ... Ignored.
    print = function(...) {
      cat(sprintf("BinaryLabelProcessor(label_vocab_size=%d)\n", length(self$label_vocab)))
    }
  )
)

