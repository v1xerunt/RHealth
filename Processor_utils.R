#' @title Get Processor Class (Hardcoded Version)
#'
#' @description
#' Retrieves a registered processor class by lowercase name. This version uses explicit `if` statements
#' instead of a dynamic map. This is less scalable but more explicit and avoids global object lookup.
#'
#' @param name Character. The processor type key (e.g., "text", "regression").
#' @return An R6ClassGenerator object corresponding to the requested processor.
#' @export
#'
#' @examples
#' get_processor("text")$new()
#' get_processor("multilabel")$new()
get_processor <- function(name) {
  if (!is.character(name) || length(name) != 1) {
    stop("`name` must be a single string.")
  }

  name <- tolower(name)

  if (name == "text") {
    return(TextProcessor)
  } else if (name == "timeseries") {
    return(TimeseriesProcessor)
  } else if (name == "sample") {
    return(SampleProcessor)
  } else if (name == "raw") {
    return(RawProcessor)
  } else if (name == "dataset") {
    return(DatasetProcessor)
  } else if (name == "feature") {
    return(FeatureProcessor)
  } else if (name == "sequence") {
    return(SequenceProcessor)
  } else if (name == "binary") {
    return(BinaryLabelProcessor)
  } else if (name == "multilabel") {
    return(MultiLabelProcessor)
  } else if (name == "multiclass") {
    return(MultiClassLabelProcessor)
  } else if (name == "regression") {
    return(RegressionLabelProcessor)
  } else {
    stop(sprintf("Unknown processor type: '%s'", name))
  }
}
