#' Readmission30DaysMIMIC4 Task
#'
#' @description
#' This task processes patient data from MIMIC-IV to predict whether a patient
#' will be readmitted within 30 days after discharge. It uses sequences of
#' conditions, procedures, and drugs as input features.
#'
#' @docType class
#' @format \code{R6Class} object.
#'
#' @section Public Fields:
#' \describe{
#'   \item{\code{task_name}}{Character. The name of the task ("Readmission30DaysMIMIC4").}
#'   \item{\code{input_schema}}{List. Input schema, including:
#'     \itemize{
#'       \item{\code{conditions}: Sequence of condition codes.}
#'       \item{\code{procedures}: Sequence of procedure codes.}
#'       \item{\code{drugs}: Sequence of drug codes.}
#'     }}
#'   \item{\code{output_schema}}{List. Output schema:
#'     \itemize{
#'       \item{\code{readmission}: Binary indicator of readmission within 30 days.}
#'     }}
#' }
#'
#' @section Public Methods:
#' \describe{
#'   \item{\code{initialize()}}{Initializes the task by setting the task name, input and output schema.}
#'   \item{\code{call(patient)}}{
#'     Generate samples from a patient object.
#'     \describe{
#'       \item{\code{patient}}{An object that implements \code{get_events()} for MIMIC-IV.}
#'       \item{Returns}{A list of named lists with features and 30-day readmission label.}
#'     }
#'   }
#' }
#'
#' @examples
#' \dontrun{
#' task <- Readmission30DaysMIMIC4$new()
#' samples <- task$call(patient)
#' }
#'
#' @import R6
#' @export
Readmission30DaysMIMIC4 <- R6::R6Class(
  classname = "Readmission30DaysMIMIC4",
  inherit = BaseTask,
  public = list(
    #' @field label the name of the label column.
    label = NULL,
    #' @description
    #' Initialize the Readmission30DaysMIMIC4 task.
    #' Sets the task name and defines the expected input/output schema.
     initialize = function() {
      self$task_name <- "Readmission30DaysMIMIC4"
      self$label <- "readmission"
      self$input_schema <- list(
        conditions = "sequence",
        procedures = "sequence",
        drugs      = "sequence"
      )
      self$output_schema <- list(
        readmission = "binary"
      )
    },
    #' @description
    #' Generate samples by processing a patient object.
    #' Excludes patients under 18 years old and visits without complete data.
    #' For each valid admission, extracts condition, procedure, and drug codes
    #' as feature sequences and computes a binary readmission label within 30 days.
    #' @param patient An object with a \code{get_events} method for extracting MIMIC-IV events.
    #' @return A list of named lists, each representing one admission sample.
    call = function(patient) {
      samples <- list()

      # Extract patient demographics (assumes one record per patient)
      demographics <- patient$get_events(event_type = "patients")

      if (length(demographics) == 0) {
        warning(sprintf("No patient demographics found for patient_id: %s", patient$patient_id))
        return(list())
      }
      if (length(demographics) != 1) {
        warning(sprintf("Unexpected multiple demographics records for patient_id: %s", patient$patient_id))
        return(list())
      }


      # if (length(demographics) != 1) {
      #   message()("Expected a single patients record per patient")
      # }
      dem <- demographics[[1]]

      anchor_age <- as.integer(dem$get("anchor_age"))


      # Exclude patients under 18 years old
      if (anchor_age < 18) {
        return(samples)
      }

      # Extract admissions
      admissions <- patient$get_events(event_type = "admissions")
      
      # Sort admissions by timestamp to ensure chronological order
      admissions <- admissions[order(sapply(admissions, function(x) x$timestamp))]

      for (i in seq_along(admissions)) {
        admission <- admissions[[i]]
        if (i < length(admissions)) {
          next_admission <- admissions[[i + 1]]
        } else {
          next_admission <- NULL
        }

        # Parse discharge time and calculate duration of stay (in hours)
        admission_dischtime <- as.POSIXct(admission$get("dischtime"), format = "%Y-%m-%d %H:%M:%S", tz = "UTC")
        admission_time <- if (inherits(admission$get("timestamp"), "POSIXct")) {
          admission$get("timestamp")
        } else {
          as.POSIXct(admission$get("timestamp"), format = "%Y-%m-%d %H:%M:%S", tz = "UTC")
        }
        duration_hour <- as.numeric(difftime(admission_dischtime, admission_time, units = "hours"))
        if (duration_hour <= 12) {
          next
        }

        # Determine readmission within 30 days
        if (!is.null(next_admission)) {
          next_adm_time <- if (inherits(next_admission$timestamp, "POSIXct")) {
            next_admission$timestamp
          } else {
            as.POSIXct(next_admission$timestamp, format = "%Y-%m-%d %H:%M:%S", tz = "UTC")
          }
          time_diff_hour <- as.numeric(difftime(next_adm_time, admission_dischtime, units = "hours"))
          # Exclude quick returns (<= 3 hours)
          if (time_diff_hour <= 3) {
            next
          }
          readmission <- if (time_diff_hour < 30 * 24) 1L else 0L
        } else {
          readmission <- 0L
        }

        # Debug print for the first 5 patients
        if (patient$patient_id <= 5) {
          message(sprintf(
            "Patient ID: %s, Admission: %d, Time Diff (h): %.2f, Readmission: %d",
            patient$patient_id, i,
            if (!is.null(next_admission)) time_diff_hour else -1,
            readmission
          ))
        }

        # Retrieve events during the admission period as DataFrames
        diagnoses_icd <- patient$get_events(
          event_type = "diagnoses_icd",
          start = admission_time,
          end = admission_dischtime,
          return_df = TRUE
        )
        procedures_icd <- patient$get_events(
          event_type = "procedures_icd",
          start = admission_time,
          end = admission_dischtime,
          return_df = TRUE
        )
        prescriptions <- patient$get_events(
          event_type = "prescriptions",
          start = admission_time,
          end = admission_dischtime,
          return_df = TRUE
        )

        # Convert to lists of codes using dplyr operations
        conditions <- diagnoses_icd %>%
          dplyr::mutate(code = paste(`diagnoses_icd/icd_version`, `diagnoses_icd/icd_code`, sep = "_")) %>%
          dplyr::pull(code)

        procedures <- procedures_icd %>%
          dplyr::mutate(code = paste(`procedures_icd/icd_version`, `procedures_icd/icd_code`, sep = "_")) %>%
          dplyr::pull(code)

        drugs <- prescriptions %>%
          dplyr::mutate(code = paste(`prescriptions/drug`, sep = "_")) %>%
          dplyr::pull(code)

        # Exclude visits without complete feature data
        if (length(conditions) * length(procedures) * length(drugs) == 0) {
          next
        }
        # Append sample
        samples[[length(samples) + 1]] <- list(
          patient_id = patient$patient_id,
          admission_id = admission$hadm_id,
          conditions = conditions,
          procedures = procedures,
          drugs = drugs,
          readmission = readmission
        )
      }

      return(samples)
    }
  )
)
