#' @title Text Processor
#' @description Processor for textual input. Inherits from FeatureProcessor and defines a minimal no-op process method.
#' @importFrom R6 R6Class
#' @export
TextProcessor <- R6::R6Class("TextProcessor",
  inherit = FeatureProcessor,
  public = list(
    #' @description Process a raw text input. (Currently a no-op identity function.)
    #' @param value A single text input (character string).
    #' @return The processed text (same as input).
    process = function(value) {
      return(value)
    },

    #' @description Optional: Return size or dimensionality if applicable.
    #' @return NULL by default.
    size = function() {
      return(NULL)
    },

    #' @description Return a printable string representation of the processor.
    #' @param ... Ignored.
    #' @return A character string.
    print = function(...) {
      cat("TextProcessor()\n")
    }
  )
)
