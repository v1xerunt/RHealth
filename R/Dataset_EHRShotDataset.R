#' EHRShotDataset: Dataset class for EHRShot Benchmark
#'
#' @description
#' A dataset class for handling EHRShot data. EHRShot is a benchmark for
#' few-shot evaluation on Electronic Health Records (EHR) data, covering
#' multiple predictive tasks including operational outcomes, lab values,
#' new diagnoses, and medical imaging findings.
#'
#' @details
#' The EHRShot benchmark provides standardized evaluation across multiple
#' clinical prediction tasks:
#'
#' \strong{Operational Outcomes:}
#' \itemize{
#'   \item \strong{guo_los}: Length of stay prediction
#'   \item \strong{guo_readmission}: Hospital readmission prediction
#'   \item \strong{guo_icu}: ICU admission prediction
#' }
#'
#' \strong{Lab Values:}
#' \itemize{
#'   \item \strong{lab_thrombocytopenia}: Low platelet count prediction
#'   \item \strong{lab_hyperkalemia}: High potassium level prediction
#'   \item \strong{lab_hypoglycemia}: Low blood sugar prediction
#'   \item \strong{lab_hyponatremia}: Low sodium level prediction
#'   \item \strong{lab_anemia}: Anemia prediction
#' }
#'
#' \strong{New Diagnoses:}
#' \itemize{
#'   \item \strong{new_hypertension}: New hypertension diagnosis
#'   \item \strong{new_hyperlipidemia}: New hyperlipidemia diagnosis
#'   \item \strong{new_pancan}: New pancreatic cancer diagnosis
#'   \item \strong{new_celiac}: New celiac disease diagnosis
#'   \item \strong{new_lupus}: New lupus diagnosis
#'   \item \strong{new_acutemi}: New acute myocardial infarction diagnosis
#' }
#'
#' \strong{Medical Imaging:}
#' \itemize{
#'   \item \strong{chexpert}: CheXpert multi-label chest X-ray finding classification
#' }
#'
#' @section Data Structure:
#' The dataset expects the following CSV files in the root directory:
#' \itemize{
#'   \item \strong{ehrshot.csv}: Main events table with clinical codes
#'   \item \strong{splits.csv}: Train/validation/test split assignments
#'   \item \strong{<task_name>.csv}: Label files for each prediction task
#' }
#'
#' @section Website:
#' For more information, visit: \url{https://som-shahlab.github.io/ehrshot-website/}
#'
#' @examples
#' \dontrun{
#' # Initialize with default ehrshot table only
#' dataset <- EHRShotDataset$new(
#'   root = "/path/to/ehrshot/data",
#'   tables = c("ehrshot", "splits", "guo_los"),
#'   dev = TRUE
#' )
#'
#' # Initialize with multiple task tables
#' dataset <- EHRShotDataset$new(
#'   root = "/path/to/ehrshot/data",
#'   tables = c("ehrshot", "splits", "lab_thrombocytopenia", "new_hypertension"),
#'   dev = FALSE
#' )
#'
#' # Display dataset statistics
#' dataset$stats()
#' }
#'
#' @seealso
#' \code{\link{BaseDataset}}, \code{\link{BenchmarkEHRShot}}
#'
#' @export
EHRShotDataset <- R6::R6Class(
  "EHRShotDataset",
  inherit = BaseDataset,
  public = list(
    #' @description
    #' Initialize the EHRShotDataset.
    #'
    #' @param root Character. Root directory of the EHRShot dataset containing CSV files
    #'   (e.g., ehrshot.csv, splits.csv, task label files).
    #' @param tables Character vector of tables to include. Should include at minimum
    #'   "ehrshot" for events and "splits" for data splitting. Additional task-specific
    #'   label tables can be added (e.g., "guo_los", "lab_thrombocytopenia").
    #'   Available task tables include:
    #'   \itemize{
    #'     \item Operational outcomes: "guo_los", "guo_readmission", "guo_icu"
    #'     \item Lab values: "lab_thrombocytopenia", "lab_hyperkalemia", "lab_hypoglycemia",
    #'           "lab_hyponatremia", "lab_anemia"
    #'     \item New diagnoses: "new_hypertension", "new_hyperlipidemia", "new_pancan",
    #'           "new_celiac", "new_lupus", "new_acutemi"
    #'     \item Imaging: "chexpert"
    #'   }
    #' @param dataset_name Character. Optional custom name for the dataset.
    #'   Defaults to "ehrshot".
    #' @param config_path Character. Optional path to a custom YAML configuration
    #'   file. If NULL (default), uses the built-in EHRShot configuration.
    #' @param dev Logical. If TRUE, limits data loading to 1000 patients for rapid
    #'   prototyping and testing. Default is FALSE.
    #' @param ... Additional arguments passed to \code{BaseDataset$initialize}.
    #'
    #' @return A new \code{EHRShotDataset} object.
    #'
    #' @examples
    #' \dontrun{
    #' # Basic initialization with single task
    #' ds <- EHRShotDataset$new(
    #'   root = "/data/ehrshot",
    #'   tables = c("ehrshot", "splits", "guo_los")
    #' )
    #'
    #' # With multiple tasks and dev mode
    #' ds <- EHRShotDataset$new(
    #'   root = "/data/ehrshot",
    #'   tables = c("ehrshot", "splits", "lab_thrombocytopenia", "new_hypertension"),
    #'   dev = TRUE
    #' )
    #' }
    initialize = function(root,
                          tables,
                          dataset_name = NULL,
                          config_path = NULL,
                          dev = FALSE,
                          ...) {
      # Locate default config if not provided
      if (is.null(config_path)) {
        message("No config path provided, using default EHRShot config")
        pkg <- utils::packageName()
        if (is.null(pkg)) {
          # Fallback for development mode/testing
          config_path <- file.path("inst", "extdata", "configs", "ehrshot.yaml")
          if (!file.exists(config_path)) {
            # Try absolute path if relative fails (e.g., running from root)
            config_path <- file.path(getwd(), "inst", "extdata", "configs", "ehrshot.yaml")
          }
        } else {
          config_path <- system.file("extdata", "configs", "ehrshot.yaml", package = pkg)
        }
      }

      # Validate that required tables are present
      if (!"ehrshot" %in% tables) {
        stop("The 'ehrshot' table must be included in the tables parameter.", call. = FALSE)
      }

      # Validate table names
      valid_tables <- c(
        "ehrshot", "splits",
        # Operational outcomes
        "guo_los", "guo_readmission", "guo_icu",
        # Lab values
        "lab_thrombocytopenia", "lab_hyperkalemia", "lab_hypoglycemia",
        "lab_hyponatremia", "lab_anemia",
        # New diagnoses
        "new_hypertension", "new_hyperlipidemia", "new_pancan",
        "new_celiac", "new_lupus", "new_acutemi",
        # Imaging
        "chexpert"
      )

      invalid_tables <- setdiff(tables, valid_tables)
      if (length(invalid_tables) > 0) {
        warning(sprintf(
          "Invalid table name(s) specified: %s. Valid tables are: %s",
          paste(invalid_tables, collapse = ", "),
          paste(valid_tables, collapse = ", ")
        ), call. = FALSE)
        tables <- intersect(tables, valid_tables)
      }

      # Initialize parent BaseDataset
      super$initialize(
        root = root,
        tables = tables,
        dataset_name = dataset_name %||% "ehrshot",
        config_path = config_path,
        dev = dev,
        ...
      )

      # Informational message about the dataset
      message(paste0(
        "[EHRShot] Initialized EHRShot dataset. ",
        "This benchmark includes multiple prediction tasks across ",
        "operational outcomes, lab values, new diagnoses, and medical imaging."
      ))
    }
  )
)
