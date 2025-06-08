
#' @title InHospitalMortalityMIMIC4 Task
#' @description Task for predicting in-hospital mortality using MIMIC-IV dataset.
#'   Uses lab results from the first 48 hours after admission as input features.
#' @import R6
#' @import dplyr
#' @import tidyr
#' @import lubridate
#' @export
InHospitalMortalityMIMIC4 <- R6::R6Class(
  classname = "InHospitalMortalityMIMIC4",
  inherit = BaseTask,
  public = list(
    #' @field input_window_hours Numeric, number of hours to look back for lab data.
    input_window_hours = NULL,
    #' @field LAB_CATEGORIES Named list mapping lab category to subcategory itemids.
    LAB_CATEGORIES = list(
      "Electrolytes & Metabolic" = list(
        Sodium      = c("50824", "52455", "50983", "52623"),
        Potassium   = c("50822", "52452", "50971", "52610"),
        Chloride    = c("50806", "52434", "50902", "52535"),
        Bicarbonate = c("50803", "50804"),
        Glucose     = c("50809", "52027", "50931", "52569"),
        Calcium     = c("50808", "51624"),
        Magnesium   = c("50960"),
        `Anion Gap` = c("50868", "52500"),
        Osmolality  = c("52031", "50964", "51701"),
        Phosphate   = c("50970")
      )
    ),
    #' @field LABITEMS Character vector of all lab itemids (flattened).
    LABITEMS = NULL,

    #' @description Initialize a new InHospitalMortalityMIMIC4 instance.
    #' @param input_window_hours Numeric, number of hours to look back (default: 48).
    initialize = function(input_window_hours = 48) {
      super$initialize(
        task_name = "InHospitalMortalityMIMIC4",
        input_schema = list(labs = "timeseries"),
        output_schema = list(mortality = "binary")
      )
      self$input_window_hours <- input_window_hours
      # Flatten nested LAB_CATEGORIES into vector of itemids
      self$LABITEMS <- unlist(self$LAB_CATEGORIES, use.names = FALSE)
    },


    #' @description Pre-filter hook to retain only necessary columns for this task.
    #' @param df A polars LazyFrame containing all events.
    #' @return A filtered LazyFrame with only relevant columns.
    pre_filter = function(df) {
      # Define required columns
      required_cols <- c(
        "patient_id", "event_type", "timestamp",  # always required
        "anchor_age",                             # from patients
        "dischtime", "hospital_expire_flag", "hadm_id",  # from admissions
        "labevents/itemid", "labevents/storetime", "labevents/valuenum"  # from labevents
      )

      # Drop other columns, keep only required ones if present
      existing_cols <- names(df$schema)

      keep_cols <- intersect(required_cols, existing_cols)
      exprs <- lapply(keep_cols, pl$col)
      lf <- do.call(df$select, exprs)
      return(lf)
    },



    #' @description Main processing method to generate samples.
    #' @param patient An object with method `get_events(event_type, ...)`.
    #' @return A list of samples. Each sample is a named list containing:
    #'   - patient_id: character
    #'   - admission_id: character or integer
    #'   - labs: a list of [timestamps, lab_values_matrix]
    #'   - mortality: binary indicator (0/1)
    call = function(patient) {
      samples <- list()
      # Get demographics (should be single event)
      demographics <- patient$get_events(event_type = "patients")
      if (length(demographics) != 1) return(samples)
      demo <- demographics[[1]]
      anchor_age <- as.integer(demo$anchor_age)
      # Exclude minors
      if (is.na(anchor_age) || anchor_age < 18) return(samples)

      # Iterate over admissions
      admissions <- patient$get_events(event_type = "admissions")
      for (ad in admissions) {
        admit_time <- lubridate::ymd_hms(ad$timestamp)
        discharge_time <- lubridate::ymd_hms(ad$dischtime)
        duration_hours <- as.numeric(difftime(discharge_time, admit_time, units = "hours"))
        # Only consider stays longer than input_window_hours
        if (duration_hours <= self$input_window_hours) next
        predict_time <- admit_time + lubridate::hours(self$input_window_hours)

        # Extract lab events in the window
        labevents_df <- patient$get_events(
          event_type = "labevents",
          start = admit_time,
          end = predict_time,
          return_df = TRUE
        )
        if (nrow(labevents_df) == 0) next

        # Rename columns, convert types, and filter relevant itemids
        labevents_df <- labevents_df %>%
          dplyr::rename(
            timestamp = timestamp,
            itemid    = `labevents/itemid`,
            storetime = `labevents/storetime`,
            valuenum  = `labevents/valuenum`
          ) %>%
          dplyr::mutate(
            timestamp = lubridate::ymd_hms(timestamp),
            storetime = lubridate::ymd_hms(storetime),
            valuenum  = as.numeric(valuenum)
          ) %>%
          dplyr::filter(
            itemid %in% self$LABITEMS,
            storetime <= predict_time
          )
        if (nrow(labevents_df) == 0) next

        # Pivot to wide format with first aggregation for duplicates
        labevents_wide <- labevents_df %>%
          dplyr::group_by(timestamp, itemid) %>%
          dplyr::summarise(valuenum = dplyr::first(valuenum), .groups = "drop") %>%
          tidyr::pivot_wider(
            names_from = itemid,
            values_from = valuenum
          ) %>%
          dplyr::arrange(timestamp)

        # Add missing columns with NA and reorder
        missing <- setdiff(self$LABITEMS, colnames(labevents_wide))
        if (length(missing) > 0) {
          labevents_wide[missing] <- NA
        }
        labevents_wide <- labevents_wide %>%
          dplyr::select(timestamp, dplyr::all_of(self$LABITEMS))

        # Extract timestamps and numeric matrix
        timestamps <- labevents_wide$timestamp
        lab_values <- as.matrix(labevents_wide %>% dplyr::select(-timestamp))

        # Mortality flag
        mortality_flag <- as.integer(ad$hospital_expire_flag)

        # Append to samples
        samples[[length(samples) + 1]] <- list(
          patient_id   = patient$patient_id,
          admission_id = ad$hadm_id,
          labs         = list(timestamps, lab_values),
          mortality    = mortality_flag
        )
      }
      return(samples)
    }
  )
)
