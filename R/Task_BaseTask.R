#' @title BaseTask (Abstract Base Class)
#' @description An abstract base class for all task classes. It defines the task name, input/output schema, a pre-filtering hook, and the main processing interface.
#' @import R6
BaseTask <- R6::R6Class(
  classname = "BaseTask",
  public = list(
    #' @field task_name Name of the task
    task_name = NULL,

    #' @field input_schema Named list specifying the expected input structure (field name -> type)
    input_schema = NULL,

    #' @field output_schema Named list specifying the expected output structure (field name -> type)
    output_schema = NULL,

    #' @description Initialize the task instance. Can be overridden in subclasses.
    #' @param task_name A string specifying the name of the task.
    #' @param input_schema A named list describing the input data schema (optional).
    #' @param output_schema A named list describing the output data schema (optional).
    initialize = function(task_name = NULL, input_schema = NULL, output_schema = NULL) {
      self$task_name <- task_name
      self$input_schema <- input_schema
      self$output_schema <- output_schema
    },

    #' @description Pre-filter hook to modify or filter the input data before main processing.
    #' @param df A data frame or lazy data object (e.g., from dplyr or data.table).
    #' @return A filtered or modified version of the input data.
    pre_filter = function(df) {
      return(df)
    },

    #' @description Main processing function. Must be overridden in subclasses.
    #' @param patient A list or structured object representing a single patient or record.
    #' @return A list of named lists representing the task result.
    call = function(patient) {
      stop("`call()` is an abstract method and must be implemented by a subclass.")
    }
  )
)
