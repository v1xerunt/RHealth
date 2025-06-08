
#' MIMIC4NoteDataset: Dataset class for MIMIC-IV Clinical Notes
#'
#' This class inherits from BaseDataset and is specialized for handling MIMIC-IV Clinical Notes data.
#' It includes tables such as discharge, discharge_detail, and radiology.
#'
#' @docType class
#' @method initialize MIMIC4NoteDataset
#' @usage \method{MIMIC4NoteDataset}{initialize}(...)
#' @export
MIMIC4NoteDataset <- R6::R6Class(
  "MIMIC4NoteDataset",
  inherit = BaseDataset,
  public = list(

    #' @description Initialize MIMIC4NoteDataset
    #' @param root Root directory of the dataset.
    #' @param tables Character vector of tables to include.
    #' @param dataset_name Optional dataset name. Default is "mimic4_note".
    #' @param config_path Optional path to YAML config file.
    #' @param dev Logical flag for dev mode.
    #' @param ... Additional arguments passed to `BaseDataset`.
    initialize = function(root,
                          tables = character(),
                          dataset_name = "mimic4_note",
                          config_path = NULL,
                          dev = FALSE,
                          ...) {

      if (is.null(config_path)) {
           pkg  <- utils::packageName()
        config_path <- file.path(system.file("extdata", package = pkg ), "configs", "mimic4_note.yaml")
        message(sprintf("Using default note config: %s", config_path))
      }

      if ("discharge" %in% tables) {
        warning("Events from discharge table only have date timestamp. This may affect temporal ordering.", call. = FALSE)
      }
      if ("discharge_detail" %in% tables) {
        warning("Events from discharge_detail table only have date timestamp. This may affect temporal ordering.", call. = FALSE)
      }

      log_memory_usage(sprintf("Before initializing %s", dataset_name))

      super$initialize(
        root = root,
        tables = tables,
        dataset_name = dataset_name,
        config_path = config_path,
        dev = dev,
        ...
      )

      log_memory_usage(sprintf("After initializing %s", dataset_name))
    }
  )
)
