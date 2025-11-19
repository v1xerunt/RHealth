#' MortalityPredictionEICU Task
#'
#' @description
#' Task for predicting ICU mortality using eICU-CRD dataset.
#' Predicts whether a patient will die during the ICU stay based on clinical
#' information collected during the stay.
#'
#' @details
#' This task uses the unit discharge status from the patient table to determine
#' mortality. The prediction is based on clinical codes from diagnosis, physicalExam
#' (procedures), and medication tables.
#'
#' Label definition:
#' - Label = 1 if unitdischargestatus == "Expired"
#' - Label = 0 otherwise
#'
#' The task excludes:
#' - ICU stays without any clinical codes (conditions, procedures, or drugs)
#'
#' Features:
#' - conditions: ICD-9 codes from diagnosis table
#' - procedures: Physical examination paths from physicalexam table
#' - drugs: Drug names from medication table
#'
#' @examples
#' \dontrun{
#' library(RHealth)
#'
#' # Load eICU dataset
#' eicu_ds <- eICUDataset$new(
#'   root = "/path/to/eicu-crd/2.0",
#'   tables = c("diagnosis", "medication", "physicalexam"),
#'   dev = TRUE
#' )
#'
#' # Set mortality prediction task
#' task <- MortalityPredictionEICU$new()
#' sample_ds <- eicu_ds$set_task(task = task)
#'
#' # View samples
#' head(sample_ds$samples)
#' }
#'
#' @export
MortalityPredictionEICU <- R6::R6Class(
  "MortalityPredictionEICU",
  inherit = BaseTask,
  public = list(
    #' @field task_name Name of the task.
    task_name = "MortalityPredictionEICU",

    #' @field input_schema Input schema.
    input_schema = list(
      conditions = "sequence",
      procedures = "sequence",
      drugs = "sequence"
    ),

    #' @field output_schema Output schema.
    output_schema = list(mortality = "binary"),

    #' @description
    #' Initialize the task.
    initialize = function() {
      super$initialize(
        task_name = self$task_name,
        input_schema = self$input_schema,
        output_schema = self$output_schema
      )
    },

    #' @description
    #' Pre-filter hook to retain only necessary columns.
    #' @param df A lazy query containing all events.
    #' @return A filtered LazyFrame.
    pre_filter = function(df) {
      required_cols <- c(
        "patient_id", "event_type", "timestamp",
        "patient/unitdischargestatus",
        "patient/unitdischargeoffset",
        "diagnosis/icd9code",
        "physicalexam/physicalexampath",
        "medication/drugname"
      )
      existing_cols <- colnames(df)
      keep_cols <- intersect(required_cols, existing_cols)
      df %>% dplyr::select(dplyr::all_of(keep_cols))
    },

    #' @description
    #' Process a single patient (ICU stay) to generate samples.
    #' @param patient A Patient object representing a single ICU stay.
    #' @return A list of samples (typically one sample per ICU stay).
    call = function(patient) {
      samples <- list()

      # Get patient demographic info (one row per ICU stay)
      patient_info <- patient$get_events(event_type = "patient", return_df = TRUE)

      if (nrow(patient_info) == 0) {
        return(samples)
      }

      # Get discharge status for mortality label
      discharge_status <- patient_info$`patient/unitdischargestatus`[1]

      # Skip if discharge status is missing
      if (is.na(discharge_status)) {
        return(samples)
      }

      # Define mortality label
      mortality_label <- if (discharge_status == "Expired") 1 else 0

      # Get clinical events for this ICU stay
      diagnoses <- patient$get_events(event_type = "diagnosis")
      physical_exams <- patient$get_events(event_type = "physicalexam")
      medications <- patient$get_events(event_type = "medication")

      # Extract codes
      get_code <- function(events, key) {
        codes <- unlist(lapply(events, function(e) {
          val <- tryCatch(e$get(key), error = function(err) NULL)
          if (is.null(val) || is.na(val)) return(NULL)
          as.character(val)
        }))
        if (is.null(codes)) character(0) else codes
      }

      cond_codes <- get_code(diagnoses, "icd9code")
      proc_codes <- get_code(physical_exams, "physicalexampath")
      drug_codes <- get_code(medications, "drugname")

      # Exclude ICU stays without ANY of the required clinical codes
      # All three types must be present (multiplication ensures all are non-zero)
      if (length(cond_codes) * length(proc_codes) * length(drug_codes) == 0) {
        return(samples)
      }

      samples[[1]] <- list(
        patient_id = patient$patient_id,
        conditions = cond_codes,
        procedures = proc_codes,
        drugs = drug_codes,
        mortality = mortality_label
      )

      return(samples)
    }
  )
)


#' MortalityPredictionEICU2 Task (Alternative Feature Set)
#'
#' @description
#' Alternative task for predicting ICU mortality using eICU-CRD dataset with
#' different feature encoding. Uses diagnosis strings and treatment information
#' instead of ICD codes and physical exams.
#'
#' @details
#' Similar to MortalityPredictionEICU but uses:
#' - conditions: Admission diagnoses paths and diagnosis strings
#' - procedures: Treatment strings
#'
#' Label definition:
#' - Label = 1 if unitdischargestatus == "Expired"
#' - Label = 0 otherwise
#'
#' @examples
#' \dontrun{
#' library(RHealth)
#'
#' # Load eICU dataset
#' eicu_ds <- eICUDataset$new(
#'   root = "/path/to/eicu-crd/2.0",
#'   tables = c("diagnosis", "treatment", "admissiondx"),
#'   dev = TRUE
#' )
#'
#' # Set mortality prediction task
#' task <- MortalityPredictionEICU2$new()
#' sample_ds <- eicu_ds$set_task(task = task)
#' }
#'
#' @export
MortalityPredictionEICU2 <- R6::R6Class(
  "MortalityPredictionEICU2",
  inherit = BaseTask,
  public = list(
    #' @field task_name Name of the task.
    task_name = "MortalityPredictionEICU2",

    #' @field input_schema Input schema.
    input_schema = list(
      conditions = "sequence",
      procedures = "sequence"
    ),

    #' @field output_schema Output schema.
    output_schema = list(mortality = "binary"),

    #' @description
    #' Initialize the task.
    initialize = function() {
      super$initialize(
        task_name = self$task_name,
        input_schema = self$input_schema,
        output_schema = self$output_schema
      )
    },

    #' @description
    #' Pre-filter hook to retain only necessary columns.
    #' @param df A lazy query containing all events.
    #' @return A filtered LazyFrame.
    pre_filter = function(df) {
      required_cols <- c(
        "patient_id", "event_type", "timestamp",
        "patient/unitdischargestatus",
        "diagnosis/diagnosisstring",
        "admissiondx/admitdxpath",
        "treatment/treatmentstring"
      )
      existing_cols <- colnames(df)
      keep_cols <- intersect(required_cols, existing_cols)
      df %>% dplyr::select(dplyr::all_of(keep_cols))
    },

    #' @description
    #' Process a single patient (ICU stay) to generate samples.
    #' @param patient A Patient object representing a single ICU stay.
    #' @return A list of samples.
    call = function(patient) {
      samples <- list()

      # Get patient demographic info
      patient_info <- patient$get_events(event_type = "patient", return_df = TRUE)

      if (nrow(patient_info) == 0) {
        return(samples)
      }

      # Get discharge status for mortality label
      discharge_status <- patient_info$`patient/unitdischargestatus`[1]

      if (is.na(discharge_status)) {
        return(samples)
      }

      mortality_label <- if (discharge_status == "Expired") 1 else 0

      # Get clinical events
      diagnoses <- patient$get_events(event_type = "diagnosis")
      admission_dx <- patient$get_events(event_type = "admissiondx")
      treatments <- patient$get_events(event_type = "treatment")

      # Extract codes
      get_code <- function(events, key) {
        codes <- unlist(lapply(events, function(e) {
          val <- tryCatch(e$get(key), error = function(err) NULL)
          if (is.null(val) || is.na(val)) return(NULL)
          as.character(val)
        }))
        if (is.null(codes)) character(0) else unique(codes)
      }

      diagnosis_strings <- get_code(diagnoses, "diagnosisstring")
      admission_dx_codes <- get_code(admission_dx, "admitdxpath")
      treatment_codes <- get_code(treatments, "treatmentstring")

      # Combine admission diagnoses and diagnosis strings
      conditions <- c(admission_dx_codes, diagnosis_strings)

      # Exclude ICU stays without sufficient codes
      # Both conditions and procedures must be present
      if (length(conditions) * length(treatment_codes) == 0) {
        return(samples)
      }

      samples[[1]] <- list(
        patient_id = patient$patient_id,
        conditions = conditions,
        procedures = treatment_codes,
        mortality = mortality_label
      )

      return(samples)
    }
  )
)
