#' @title NextMortalityMIMIC3 Task
#' @description Task for predicting in-hospital mortality using MIMIC-III dataset.
#' This task aims to predict whether the patient will decease in the next
#' hospital visit based on clinical information from the current visit.
#' @import R6
#' @import dplyr
#' @import tidyr
#' @import lubridate
#' @export
NextMortalityMIMIC3 <- R6::R6Class(
  classname = "NextMortalityMIMIC3",
  inherit = BaseTask,
  public = list(
    #' @field label the name of the label column.
    label = NULL,

    #' @description Initialize a new NextMortalityMIMIC3 instance.
    initialize = function() {
      super$initialize(
        task_name = "NextMortalityMIMIC3",
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
        "admissions/hadm_id", "admissions/hospital_expire_flag",
        "diagnoses_icd/icd9_code", "diagnoses_icd/hadm_id",
        "procedures_icd/icd9_code", "procedures_icd/hadm_id",
        "prescriptions/drug", "prescriptions/hadm_id"
      )
      existing_cols <- colnames(df)
      keep_cols <- intersect(required_cols, existing_cols)
      df %>% dplyr::select(dplyr::all_of(keep_cols))
    },

    #' @description Main processing method to generate samples.
    #' @param patient An object with method `get_events(event_type, ...)`.
    #' @return A list of samples.
    call = function(patient) {
      samples <- list()
      admissions <- patient$get_events(event_type = "admissions")

      if (length(admissions) <= 1) {
        return(samples)
      }

      for (i in 1:(length(admissions) - 1)) {
        visit <- admissions[[i]]
        next_visit <- admissions[[i + 1]]

        mortality_label <- as.integer(next_visit$get("hospital_expire_flag"))
        if (is.na(mortality_label) || !mortality_label %in% c(0, 1)) {
          message(paste0(
            "patient_id: ", patient$patient_id,
            ", hadm_id: ", visit$get("hadm_id"),
            ", hospital_expire_flag: '", mortality_label, "'",
            ", class: ", class(mortality_label)
          ))
          mortality_label <- 0
        }
        
        hadm_id <- visit$get("hadm_id")

        diagnoses <- patient$get_events(
          event_type = "diagnoses_icd",
          filters = list(list("hadm_id", "==", hadm_id))
        )
        procedures <- patient$get_events(
          event_type = "procedures_icd",
          filters = list(list("hadm_id", "==", hadm_id))
        )
        prescriptions <- patient$get_events(
          event_type = "prescriptions",
          filters = list(list("hadm_id", "==", hadm_id))
        )

        conditions <- purrr::map_chr(diagnoses, ~ .x$get("icd9_code"))
        procedures_list <- purrr::map_chr(procedures, ~ .x$get("icd9_code"))
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
          hadm_id      = hadm_id,
          patient_id   = patient$patient_id,
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
