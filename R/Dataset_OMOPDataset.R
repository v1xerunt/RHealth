#' OMOPDataset
#'
#' @description
#' A dataset class for handling OMOP CDM (Common Data Model) data.
#' Inherits from BaseDataset.
#'
#' @export
OMOPDataset <- R6::R6Class(
  "OMOPDataset",
  inherit = BaseDataset,
  public = list(
    #' @description
    #' Initialize the OMOPDataset.
    #' @param root Root directory of the dataset.
    #' @param tables Character vector of extra tables to include.
    #' @param dataset_name Optional dataset name.
    #' @param config_path Optional path to YAML config file.
    #' @param dev Logical flag for dev mode.
    #' @param ... Additional arguments passed to `BaseDataset$initialize`.
    initialize = function(root,
                          tables = character(),
                          dataset_name = NULL,
                          config_path = NULL,
                          dev = FALSE,
                          ...) {
      if (is.null(config_path)) {
        message("No config path provided, using default OMOP config")
        pkg <- utils::packageName()
        if (is.null(pkg)) {
          # Fallback for dev mode/testing
          config_path <- file.path("inst", "extdata", "configs", "omop.yaml")
          if (!file.exists(config_path)) {
             # Try absolute path if relative fails (e.g. running from root)
             # Assuming standard structure
             config_path <- file.path(getwd(), "inst", "extdata", "configs", "omop.yaml")
          }
        } else {
          config_path <- system.file("extdata", "configs", "omop.yaml", package = pkg)
        }
      }

      default_tables <- c("person", "visit_occurrence", "death")
      all_tables <- unique(c(default_tables, tables))

      super$initialize(
        root = root,
        tables = all_tables,
        dataset_name = dataset_name %||% "omop",
        config_path = config_path,
        dev = dev,
        ...
      )
    }
  )
)
