#' MIMIC3Dataset: Dataset class for MIMIC-III
#'
#' This class inherits from BaseDataset and is specialized for handling MIMIC-III data.
#' It ensures key tables like patients, admissions, and icustays are loaded,
#' and allows appending additional tables. Also provides per-table preprocessing.
#'
#' @export
MIMIC3Dataset <- R6::R6Class(
  "MIMIC3Dataset",
  inherit = BaseDataset,
  public = list(
    #' @description initialize MIMIC3Dataset
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
        message("No config path provided, using default config")
        pkg  <- utils::packageName()
        config_path <- file.path(system.file("extdata", package = pkg ), "configs", "mimic3.yaml")
      }

      default_tables <- c("patients", "admissions", "icustays")
      all_tables <- unique(c(default_tables, tables))

      if ("prescriptions" %in% all_tables) {
        warning("Events from prescriptions table only have date timestamp. May affect temporal order.", call. = FALSE)
      }

      super$initialize(
        root = root,
        tables = all_tables,
        dataset_name = dataset_name %||% "mimic3",
        config_path = config_path,
        dev = dev,
        ...
      )
       if ("prescriptions" %in% tables) {
    warning("Timestamp granularity of prescriptions is not enough.")
     }
    }
  )
)
