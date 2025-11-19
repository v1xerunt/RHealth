#' eICUDataset: Dataset class for eICU-CRD
#'
#' @description
#' A dataset class for handling eICU Collaborative Research Database (eICU-CRD) data.
#' The eICU-CRD is a large dataset of de-identified health records from ICU patients
#' across multiple hospitals in the United States. This class inherits from BaseDataset
#' and provides specialized handling for eICU data structures.
#'
#' @details
#' The eICU dataset is centered around ICU stays (patientunitstayid), where:
#' \itemize{
#'   \item A patient (uniquepid) can have multiple hospital admissions (patienthealthsystemstayid)
#'   \item Each hospital admission can have multiple ICU stays (patientunitstayid)
#'   \item All timestamps are relative offsets (in minutes) from the ICU admission time
#' }
#'
#' @section Default Tables:
#' The following table is loaded by default:
#' \itemize{
#'   \item \strong{patient}: Core patient demographics and ICU stay information
#' }
#'
#' @section Optional Tables:
#' Additional tables can be specified via the \code{tables} parameter:
#' \itemize{
#'   \item \strong{diagnosis}: ICD-9 diagnoses with diagnosis strings
#'   \item \strong{treatment}: Treatment information with treatment strings
#'   \item \strong{medication}: Medication orders with drug names and dosages
#'   \item \strong{lab}: Laboratory measurements with lab names and results
#'   \item \strong{physicalexam}: Physical examination findings
#'   \item \strong{admissiondx}: Primary admission diagnoses per APACHE scoring
#' }
#'
#' @section Data Source:
#' The eICU-CRD dataset is available at \url{https://eicu-crd.mit.edu/}.
#' Access requires completion of the CITI "Data or Specimens Only Research" course
#' and signing a data use agreement.
#'
#' @section Note on Patient IDs:
#' In the Python pyhealth implementation, patient_id is a composite of
#' \code{uniquepid} and \code{patienthealthsystemstayid} to represent a hospital
#' admission. In this R implementation, we use \code{patientunitstayid} as the
#' primary identifier to represent individual ICU stays, which aligns better with
#' the event-based architecture of BaseDataset.
#'
#' @examples
#' \dontrun{
#' # Initialize with default patient table only
#' dataset <- eICUDataset$new(
#'   root = "/path/to/eicu-crd/2.0",
#'   dev = TRUE
#' )
#'
#' # Initialize with additional clinical tables
#' dataset <- eICUDataset$new(
#'   root = "/path/to/eicu-crd/2.0",
#'   tables = c("diagnosis", "medication", "lab", "treatment"),
#'   dev = FALSE
#' )
#'
#' # Display dataset statistics
#' dataset$stats()
#' }
#'
#' @seealso
#' \code{\link{BaseDataset}}, \code{\link{MIMIC3Dataset}}, \code{\link{OMOPDataset}}
#'
#' @export
eICUDataset <- R6::R6Class(
  "eICUDataset",
  inherit = BaseDataset,
  public = list(
    #' @description
    #' Initialize the eICUDataset.
    #'
    #' @param root Character. Root directory of the eICU dataset containing CSV files
    #'   (e.g., patient.csv, diagnosis.csv, etc.).
    #' @param tables Character vector of additional tables to include beyond the
    #'   default patient table. Available options: "diagnosis", "treatment",
    #'   "medication", "lab", "physicalexam", "admissiondx".
    #' @param dataset_name Character. Optional custom name for the dataset.
    #'   Defaults to "eicu".
    #' @param config_path Character. Optional path to a custom YAML configuration
    #'   file. If NULL (default), uses the built-in eICU configuration.
    #' @param dev Logical. If TRUE, limits data loading to 1000 patients for rapid
    #'   prototyping and testing. Default is FALSE.
    #' @param ... Additional arguments passed to \code{BaseDataset$initialize}.
    #'
    #' @return A new \code{eICUDataset} object.
    #'
    #' @examples
    #' \dontrun{
    #' # Basic initialization
    #' ds <- eICUDataset$new(
    #'   root = "/data/eicu-crd/2.0"
    #' )
    #'
    #' # With additional tables and dev mode
    #' ds <- eICUDataset$new(
    #'   root = "/data/eicu-crd/2.0",
    #'   tables = c("diagnosis", "medication", "lab"),
    #'   dev = TRUE
    #' )
    #' }
    initialize = function(root,
                          tables = character(),
                          dataset_name = NULL,
                          config_path = NULL,
                          dev = FALSE,
                          ...) {
      # Locate default config if not provided
      if (is.null(config_path)) {
        message("No config path provided, using default eICU config")
        pkg <- utils::packageName()
        if (is.null(pkg)) {
          # Fallback for development mode/testing
          config_path <- file.path("inst", "extdata", "configs", "eicu.yaml")
          if (!file.exists(config_path)) {
            # Try absolute path if relative fails (e.g., running from root)
            config_path <- file.path(getwd(), "inst", "extdata", "configs", "eicu.yaml")
          }
        } else {
          config_path <- system.file("extdata", "configs", "eicu.yaml", package = pkg)
        }
      }

      # Ensure patient table is always loaded as it contains core information
      default_tables <- c("patient")
      all_tables <- unique(c(default_tables, tables))

      # Validate table names
      valid_tables <- c("patient", "diagnosis", "treatment", "medication",
                        "lab", "physicalexam", "admissiondx")
      invalid_tables <- setdiff(all_tables, valid_tables)
      if (length(invalid_tables) > 0) {
        warning(sprintf(
          "Invalid table name(s) specified: %s. Valid tables are: %s",
          paste(invalid_tables, collapse = ", "),
          paste(valid_tables, collapse = ", ")
        ), call. = FALSE)
        all_tables <- intersect(all_tables, valid_tables)
      }

      # Initialize parent BaseDataset
      super$initialize(
        root = root,
        tables = all_tables,
        dataset_name = dataset_name %||% "eicu",
        config_path = config_path,
        dev = dev,
        ...
      )

      # Informational message about timestamp offsets
      if (length(all_tables) > 1) {
        message(paste0(
          "[eICU] Note: All timestamps in eICU are relative offsets (in minutes) ",
          "from the ICU admission time. Events with negative offsets occurred ",
          "before ICU admission (e.g., during hospital admission)."
        ))
      }
    }
  )
)
