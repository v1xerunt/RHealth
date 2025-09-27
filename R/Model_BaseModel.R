
#' @title BaseModel Class
#' @description Abstract base class for Torch models in R. This class handles dataset schema parsing,
#' output size calculation, loss function selection, and probability conversion for evaluation.
#' @import torch
#' @importFrom glue glue
#' @field dataset A dataset object containing input/output schema and processors.
#' @field feature_keys Character vector of input feature names.
#' @field label_keys Character vector of output label names.
#' @field device Device (cpu or cuda) where the model is located.
#' @export
BaseModel <- torch::nn_module(
  classname = "BaseModel",

  #' @param dataset A dataset object (must have input_schema, output_schema, output_processors).
  initialize = function(dataset) {
    self$dataset <- dataset

    self$feature_keys <- names(dataset$input_schema)
    self$label_keys <- names(dataset$output_schema)
  },

  get_output_size = function() {
    #' @title Get Output Size
    #' @description Determines output size based on label processor and task mode.
    #' Only supports single label key for now.
    #' @return Integer scalar representing the output dimension.
    stopifnot(length(self$label_keys) == 1)
    key <- self$label_keys[[1]]
    output_size <- self$dataset$output_processors[[key]]$size()
    return(output_size)
  },

  get_loss_function = function() {
    #' @title Get Loss Function
    #' @description Selects appropriate loss function based on task type in output schema.
    #' @return A function such as nnf_binary_cross_entropy_with_logits or nnf_cross_entropy.
    stopifnot(length(self$label_keys) == 1)
    label_key <- self$label_keys[[1]]
    mode <- self$dataset$output_schema[[label_key]]

    if (mode == "binary") {
      return(torch::nnf_binary_cross_entropy_with_logits)
    } else if (mode == "multiclass") {
      return(torch::nnf_cross_entropy)
    } else if (mode == "multilabel") {
      return(torch::nnf_binary_cross_entropy_with_logits)
    } else if (mode == "regression") {
      return(torch::nnf_mse_loss)
    } else {
      stop(glue::glue("Invalid mode: {mode}"))
    }
  },

  #' @title Prepare Predicted Probabilities
  #' @description Converts logits into predicted probabilities for evaluation.
  #' Format depends on task mode (sigmoid or softmax, or raw).
  #' This method takes `logits` as input, which is a torch tensor with raw model outputs.
  #' @return Torch tensor of probabilities.
  prepare_y_prob = function(logits) {
    stopifnot(length(self$label_keys) == 1)
    key <- self$label_keys[[1]]
    mode <- self$dataset$output_schema[[key]]

    if (mode == "binary") {
      y_prob <- torch::torch_sigmoid(logits)
    } else if (mode == "multiclass") {
      y_prob <- torch::nnf_softmax(logits, dim = -1)
    } else if (mode == "multilabel") {
      y_prob <- torch::torch_sigmoid(logits)
    } else if (mode == "regression") {
      y_prob <- logits
    } else {
      stop("Unsupported mode in prepare_y_prob()")
    }

    return(y_prob)
  }
)
