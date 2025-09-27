#' @title NextMortalityMIMIC4 Task
#' @description Task for predicting in-hospital mortality using MIMIC-IV dataset.
#'   Uses lab results from the first 48 hours after admission as input features.
#' @import R6
#' @import dplyr
#' @import tidyr
#' @import lubridate
#' @export
NextMortalityMIMIC4 <- R6::R6Class(
  classname = "NextMortalityMIMIC4",
  inherit = BaseTask,
  public = list(
    #' @field label the name of the label column.
    label = NULL,

    #' @description Initialize a new NextMortalityMIMIC4 instance.
    initialize = function() {
      super$initialize(
        task_name = "NextMortalityMIMIC4",
        input_schema = list(
          conditions = "sequence",
          procedures = "sequence",
          drugs = "sequence"
        ),
        output_schema = list(mortality = "binary")
      )
      self$label <- "mortality"
    },

    #' @description Pre-filter hook to retain only necessary columns for this task.
    #' @param df A lazy query containing all events.
    #' @return A filtered LazyFrame with only relevant columns.
    pre_filter = function(df) {
      required_cols <- c(
        "patient_id", "event_type", "timestamp",
        "patients/anchor_age",
        "admissions/dischtime", "admissions/hospital_expire_flag", "admissions/hadm_id",
        "diagnoses_icd/icd_code",
        "procedures_icd/icd_code",
        "prescriptions/drug"
      )

      existing_cols <- colnames(df)

      keep_cols <- intersect(required_cols, existing_cols)
      df <- df %>% dplyr::select(dplyr::all_of(keep_cols))
      return(df)
    },

    #' @description Main processing method to generate samples.
    #' @param patient An object with method `get_events(event_type, ...)`.
    #' @return A list of samples.
    call = function(patient) {
      samples <- list()
      # Get demographics (should be single event)
      demographics <- patient$get_events(event_type = "patients")
      if (length(demographics) == 0) return(samples)
      demo <- demographics[[1]]
      anchor_age <- as.integer(demo$get("anchor_age"))

      # Exclude minors or patients with invalid age
      if (length(anchor_age) != 1 || is.na(anchor_age) || anchor_age < 18) {
        return(samples)
      }

      # Iterate over admissions
      admissions <- patient$get_events(event_type = "admissions")
      if (length(admissions) <= 1) return(samples)

      for (i in 1:(length(admissions) - 1)) {
        admission <- admissions[[i]]
        next_admission <- admissions[[i + 1]]

        admit_time <- as.POSIXct(admission$timestamp)
        discharge_time <- tryCatch(
          as.POSIXct(admission$get("dischtime")),
          error = function(e) NULL
        )
        if (is.null(discharge_time)) next

        # Get mortality label from the next admission
        mortality_label <- as.integer(next_admission$get("hospital_expire_flag"))
        if (is.na(mortality_label) || !mortality_label %in% c(0, 1)) {
          mortality_label <- 0
        }

        # Get events during the current admission
        diagnoses <- patient$get_events(
          event_type = "diagnoses_icd",
          start = admit_time,
          end = discharge_time
        )
        procedures <- patient$get_events(
          event_type = "procedures_icd",
          start = admit_time,
          end = discharge_time
        )
        prescriptions <- patient$get_events(
          event_type = "prescriptions",
          start = admit_time,
          end = discharge_time
        )

        conditions <- purrr::map_chr(diagnoses, ~ .x$get("icd_code"))
        procedures_list <- purrr::map_chr(procedures, ~ .x$get("icd_code"))
        drugs <- purrr::map_chr(prescriptions, ~ .x$get("drug"))
        
        # Helper to clean sequences
        clean_sequence <- function(seq) {
          seq <- seq[!is.na(seq) & nzchar(trimws(seq))]
          return(seq)
        }
        
        conditions <- clean_sequence(conditions)
        procedures_list <- clean_sequence(procedures_list)
        drugs <- clean_sequence(drugs)

        if (length(conditions) == 0 || length(procedures_list) == 0 || length(drugs) == 0) {
          next
        }

        samples[[length(samples) + 1]] <- list(
          patient_id   = patient$patient_id,
          admission_id = admission$get("hadm_id"),
          conditions   = conditions,
          procedures   = procedures_list,
          drugs        = drugs,
          mortality    = mortality_label
        )
      }
      return(samples)
    }
  )
)
