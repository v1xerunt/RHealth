#' @title Raw Processor
#' @description Processor that returns raw values without any transformation.
#'              Inherits from FeatureProcessor.
#' @importFrom R6 R6Class
#' @export
RawProcessor <- R6::R6Class("RawProcessor",
  inherit = FeatureProcessor,
  public = list(
    #' @description Return the raw input as-is.
    #' @param value A raw field value (any type).
    #' @return The unmodified input.
    process = function(value) {
      return(value)
    },

    #' @description Optional: Return size/dimension of processed output.
    #' @return NULL
    size = function() {
      return(NULL)
    },

    #' @description Print a string representation of the processor.
    #' @param ... Ignored.
    #' @return A character string
    print = function(...) {
      cat("RawProcessor()\n")
    }
  )
)

