#' @title Abstract Processor Base Classes
#' @description Provides abstract base classes for three levels of data processing:
#' field-level (`FeatureProcessor`), sample-level (`SampleProcessor`), and dataset-level (`DatasetProcessor`).
#' Each processor inherits from a common `Processor` base class which includes optional `save()` and `load()` methods.
#'
#' Concrete implementations should inherit from these and override at least the `process()` method.
#'
#' @importFrom R6 R6Class

# ---------------------------------------------------------------------------
# Abstract Base Processor ---------------------------------------------------
# ---------------------------------------------------------------------------
#' @export
Processor <- R6::R6Class("Processor",
  public = list(
    #' @description Save processor state to disk (optional).
    #' @param path A string file path.
    save = function(path) {
      # Optional hook
    },

    #' @description Load processor state from disk (optional).
    #' @param path A string file path.
    load = function(path) {
      # Optional hook
    }
  )
)

# ---------------------------------------------------------------------------
# FeatureProcessor: Field-level processor -----------------------------------
# ---------------------------------------------------------------------------

#' @title FeatureProcessor: Base class for all data processors
#' @description
#' Abstract class for input/output processors used in `rhealth`. Subclass this
#' to define how raw values (e.g. timestamps, labels) are transformed into
#' model-ready tensors.
#'
#' @section Methods to override:
#' - `process(value)`: Converts input value into tensor
#' - `size()`: Returns output dimensionality
#'
#' @export
#' @name FeatureProcessor
FeatureProcessor <- R6::R6Class("FeatureProcessor",
  inherit = Processor,
  public = list(
    #' @description Fit processor using field values across samples.
    #' @param samples A list of named lists representing sample records.
    #' @param field A string giving the field name to fit on.
    fit = function(samples, field) {
      # Optional, can be overridden
    },

    #' @description Abstract method: Process an individual field value.
    #' @param value A raw value (e.g., character, number, etc).
    #' @return A processed value.
    process = function(value) {
      stop("Method 'process()' must be implemented in subclass of FeatureProcessor.")
    }
  )
)

# ---------------------------------------------------------------------------
# SampleProcessor: Sample-level processor -----------------------------------
# ---------------------------------------------------------------------------
#' @title SampleProcessor: Processor for sample-level transformations
#'
#' @description
#' Optional processor for transformations applied at the whole-sample level
#' (e.g., normalizing an image+label pair).
#'
#' @export
#' @name SampleProcessor
SampleProcessor <- R6::R6Class("SampleProcessor",
  inherit = Processor,
  public = list(
    #' @description Abstract method: Process a single sample (a named list).
    #' @param sample A named list representing one data sample.
    #' @return A processed named list.
    process = function(sample) {
      stop("Method 'process()' must be implemented in subclass of SampleProcessor.")
    }
  )
)

# ---------------------------------------------------------------------------
# DatasetProcessor: Dataset-level processor ---------------------------------
# ---------------------------------------------------------------------------


#' @title DatasetProcessor: Processor applied to entire datasets
#'
#' @description
#' Optional class for processing entire datasets in bulk (e.g., batch statistics).
#'
#' @export
#' @name DatasetProcessor
#' @export
DatasetProcessor <- R6::R6Class("DatasetProcessor",
  inherit = Processor,
  public = list(
    #' @description Abstract method: Process the entire dataset.
    #' @param samples A list of named lists representing all samples.
    #' @return A processed list of named lists.
    process = function(samples) {
      stop("Method 'process()' must be implemented in subclass of DatasetProcessor.")
    }
  )
)
