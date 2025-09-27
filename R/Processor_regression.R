#' @title Regression Label Processor
#' @description Processor for scalar regression labels. Converts values to a 1D float tensor.
#'
#' @importFrom R6 R6Class
#' @importFrom torch torch_tensor
#' @export
RegressionLabelProcessor <- R6::R6Class("RegressionLabelProcessor",
  inherit = FeatureProcessor,
  public = list(
    #' @description Process a numeric label into a single-element float tensor.
    #' @param value A numeric value.
    #' @return A torch tensor of shape `[1]`.
    process = function(value) {
      torch::torch_tensor(as.numeric(value), dtype = torch::torch_float())
    },

    #' @description Return the size of the processed label (always 1).
    #' @return Integer `1`
    size = function() {
      1
    },

    #' @description Print a string representation.
    #' @param ... Ignored.
    print = function(...) {
      cat("RegressionLabelProcessor()\n")
    }
  )
)

