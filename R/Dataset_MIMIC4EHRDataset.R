
#' MIMIC4EHRDataset: Dataset class for MIMIC-IV EHR
#'
#' This class inherits from BaseDataset and is specialized for handling MIMIC-IV EHR data.
#' It ensures key tables like patients, admissions, and icustays are included,
#' and allows appending additional tables. It also logs memory usage if needed.
#' @docType class
#' @method initialize MMIMIC4EHRDataset
#' @usage \method{MIMIC4EHRDataset}{initialize}(...)
#' @export
MIMIC4EHRDataset <- R6::R6Class(
  "MIMIC4EHRDataset",
  inherit = BaseDataset,
  public = list(

    #' @description Initialize MIMIC4EHRDataset
    #' @param root Root directory of the dataset.
    #' @param tables Character vector of extra tables to include.
    #' @param dataset_name Optional dataset name. Default is "mimic4_ehr".
    #' @param config_path Optional path to YAML config file.
    #' @param dev Logical flag for dev mode.
    #' @param ... Additional arguments passed to `BaseDataset`.
    initialize = function(root,
                          tables = character(),
                          dataset_name = "mimic4_ehr",
                          config_path = NULL,
                          dev = FALSE,
                          ...) {

      if (is.null(config_path)) {
        pkg  <- utils::packageName()
        config_path <- file.path(system.file("extdata", package = pkg ), "configs", "mimic4_ehr.yaml")
        message(sprintf("Using default EHR config: %s", config_path))
      }

      log_memory_usage(sprintf("Before initializing %s", dataset_name))
      default_tables <- c("patients", "admissions", "icustays")
      all_tables <- unique(c(tables, default_tables))

      super$initialize(
        root = root,
        tables = all_tables,
        dataset_name = dataset_name,
        config_path = config_path,
        dev = dev,
        ...
      )

      log_memory_usage(sprintf("After initializing %s", dataset_name))
    }
  )
)


#' Logs memory usage (in MB) using ps::ps_memory_info if available.
#' @param tag Optional label for the logging context.
#' @keywords internal
log_memory_usage <- function(tag = "") {
  if (requireNamespace("ps", quietly = TRUE)) {
    mem <- ps::ps_memory_info()
    rss_mb <- mem[["rss"]] / (1024 * 1024)
    message(sprintf("Memory usage %s: %.1f MB", tag, rss_mb))
  } else {
    message(sprintf("Memory tracking requested at %s, but ps package not available", tag))
  }
}


