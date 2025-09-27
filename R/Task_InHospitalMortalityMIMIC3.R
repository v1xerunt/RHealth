#' @title InHospitalMortalityMIMIC3 Task
#' @description Task for predicting in-hospital mortality using MIMIC-III dataset.
#' This task leverages lab results from the first 48 hours of an admission to
#' predict the likelihood of in-hospital mortality.
#' @import R6
#' @import dplyr
#' @import tidyr
#' @import lubridate
#' @export
InHospitalMortalityMIMIC3 <- R6::R6Class(
  classname = "InHospitalMortalityMIMIC3",
  inherit = BaseTask,
  public = list(
    #' @field task_name The name of the task.
    task_name = "InHospitalMortalityMIMIC3",
    #' @field input_schema The schema for input data.
    input_schema = list(labs = "timeseries"),
    #' @field output_schema The schema for output data.
    output_schema = list(mortality = "binary"),
    #' @field label The name of the label column.
    label = "mortality",
    #' @field LABITEMS A list of lab item IDs used in this task for MIMIC-III.
    LABITEMS = c(
      # Electrolytes & Metabolic
      "50824", "52455", "50983", "52623", # Sodium
      "50822", "52452", "50971", "52610", # Potassium
      "50806", "52434", "50902", "52535", # Chloride
      "50803", "50804",                   # Bicarbonate
      "50809", "52027", "50931", "52569", # Glucose
      "50808", "51624",                   # Calcium
      "50960",                           # Magnesium
      "50868", "52500",                   # Anion Gap
      "52031", "50964", "51701",         # Osmolality
      "50970"                            # Phosphate
    ),

    #' @description Initialize a new InHospitalMortalityMIMIC3 instance.
    initialize = function() {
      super$initialize(
        task_name = self$task_name,
        input_schema = self$input_schema,
        output_schema = self$output_schema
      )
    },

    #' @description Pre-filter hook to retain only necessary columns for this task.
    #' @param df A lazy query containing all events.
    #' @return A filtered LazyFrame with only relevant columns.
    pre_filter = function(df) {
      required_cols <- c(
        "patient_id", "event_type", "timestamp",
        "patients/dob",
        "admissions/dischtime", "admissions/hospital_expire_flag", "admissions/hadm_id",
        "labevents/itemid", "labevents/charttime", "labevents/valuenum"
      )
      existing_cols <- colnames(df)
      keep_cols <- intersect(required_cols, existing_cols)
      df %>% dplyr::select(dplyr::all_of(keep_cols))
    },

    #' @description Main processing method to generate samples.
    #' @param patient An object with method `get_events(event_type, ...)`.
    #' @return A list of samples.
    call = function(patient) {
      input_window_hours <- 48
      samples <- list()

      demographics <- patient$get_events(event_type = "patients")
      if (length(demographics) == 0) {
        return(samples)
      }
      dob <- tryCatch(as.POSIXct(demographics[[1]]$get("dob")), error = function(e) NULL)
      if (is.null(dob)) {
        return(samples)
      }

      admissions <- patient$get_events(event_type = "admissions")
      for (admission in admissions) {
        admission_timestamp <- admission$timestamp
        age <- as.numeric(difftime(admission_timestamp, dob, units = "days") / 365.25)

        if (is.na(age) || age < 18) {
          next
        }

        admission_dischtime <- tryCatch(
          as.POSIXct(admission$get("dischtime")),
          error = function(e) NULL
        )
        if (is.null(admission_dischtime)) next

        duration_hour <- as.numeric(difftime(
          admission_dischtime,
          admission_timestamp,
          units = "hours")
        )
        if (duration_hour <= input_window_hours) {
          next
        }
        predict_time <- admission_timestamp + lubridate::hours(input_window_hours)

        labevents <- patient$get_events(
          event_type = "labevents",
          start = admission_timestamp,
          end = predict_time
        )

        if (length(labevents) == 0) next

        labevents_df_list <- purrr::map(labevents, ~{
          itemid <- .x$get("itemid")
          if (!is.null(itemid) && itemid %in% self$LABITEMS) {
            charttime_str <- tryCatch(.x$get("charttime"), error = function(e) NULL)
            if (is.null(charttime_str)) {
              charttime_str <- .x$timestamp
            }
            if (!is.null(charttime_str)) {
                charttime <- tryCatch(as.POSIXct(charttime_str), error = function(e) NULL)
                if (!is.null(charttime) && charttime <= predict_time) {
                    valuenum <- .x$get("valuenum")
                    if (!is.null(valuenum) && !is.na(valuenum)) {
                        return(
                            tibble::tibble(
                                timestamp = .x$timestamp,
                                itemid = as.character(itemid),
                                valuenum = as.numeric(valuenum)
                            )
                        )
                    }
                }
            }
          }
          return(NULL)
        })

        labevents_df <- dplyr::bind_rows(labevents_df_list)

        if (nrow(labevents_df) == 0) next
        
        labevents_df <- labevents_df %>%
          dplyr::filter(!is.na(.data$valuenum)) %>%
          dplyr::group_by(.data$timestamp, .data$itemid) %>%
          dplyr::summarise(valuenum = dplyr::first(.data$valuenum), .groups = "drop") %>%
          tidyr::pivot_wider(
            names_from = .data$itemid,
            values_from = .data$valuenum
          ) %>%
          dplyr::arrange(.data$timestamp)

        existing_cols <- setdiff(colnames(labevents_df), "timestamp")
        missing_cols <- setdiff(self$LABITEMS, existing_cols)

        if (length(missing_cols) > 0) {
          for (col in missing_cols) {
            labevents_df[[col]] <- NA_real_
          }
        }

        labevents_df <- labevents_df %>%
          dplyr::select(timestamp, dplyr::all_of(self$LABITEMS))

        timestamps <- labevents_df$timestamp
        lab_values <- as.matrix(labevents_df[, -1])

        mortality_label <- as.integer(admission$get("hospital_expire_flag"))
        if (is.na(mortality_label) || !mortality_label %in% c(0, 1, "0", "1")) {
          mortality_label <- 0
        }

        samples[[length(samples) + 1]] <- list(
          patient_id   = patient$patient_id,
          admission_id = admission$get("hadm_id"),
          labs         = list(timestamps, lab_values),
          mortality    = mortality_label
        )
      }
      return(samples)
    }
  )
)
