#' MortalityPredictionOMOP Task
#'
#' @description
#' Task for predicting mortality using OMOP CDM dataset.
#' Predicts whether a patient has a death record based on clinical information from each visit.
#'
#' @export
MortalityPredictionOMOP <- R6::R6Class(
  "MortalityPredictionOMOP",
  inherit = BaseTask,
  public = list(
    #' @field task_name Name of the task.
    task_name = "MortalityPredictionOMOP",
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
        "visit_occurrence/visit_occurrence_id",
        "condition_occurrence/condition_concept_id", "condition_occurrence/visit_occurrence_id",
        "procedure_occurrence/procedure_concept_id", "procedure_occurrence/visit_occurrence_id",
        "drug_exposure/drug_concept_id", "drug_exposure/visit_occurrence_id"
      )
      existing_cols <- colnames(df)
      keep_cols <- intersect(required_cols, existing_cols)
      df %>% dplyr::select(dplyr::all_of(keep_cols))
    },

    #' @description
    #' Process a single patient to generate samples.
    #' @param patient A Patient object.
    #' @return A list of samples.
    call = function(patient) {
      samples <- list()

      visits <- patient$get_events(event_type = "visit_occurrence")
      death_events <- patient$get_events(event_type = "death")

      if (length(visits) <= 1) {
        return(samples)
      }

      # Get death timestamp if exists
      death_time <- if (length(death_events) > 0) {
        death_events[[1]]$timestamp
      } else {
        NULL
      }

      # Iterate over visits, excluding the last one (no next visit to predict for)
      for (i in 1:(length(visits) - 1)) {
        visit <- visits[[i]]
        next_visit <- visits[[i + 1]]

        visit_id <- visit$get("visit_occurrence_id")
        if (is.null(visit_id)) next

        # Predict mortality before next visit:
        # Label is 1 if patient dies between current visit and next visit, 0 otherwise
        visit_time <- visit$timestamp
        next_visit_time <- next_visit$timestamp

        mortality_label <- if (!is.null(death_time) &&
                               death_time > visit_time &&
                               death_time <= next_visit_time) {
          1
        } else {
          0
        }

        # Filter clinical events linked to this visit
        conditions <- patient$get_events(
          event_type = "condition_occurrence",
          filters = list(list("visit_occurrence_id", "==", visit_id))
        )

        procedures <- patient$get_events(
          event_type = "procedure_occurrence",
          filters = list(list("visit_occurrence_id", "==", visit_id))
        )

        drugs <- patient$get_events(
          event_type = "drug_exposure",
          filters = list(list("visit_occurrence_id", "==", visit_id))
        )

        # Extract codes
        # Use tryCatch or check for NULL to avoid errors if column missing
        get_code <- function(events, key) {
           codes <- unlist(lapply(events, function(e) {
             val <- tryCatch(e$get(key), error = function(err) NULL)
             if (is.null(val)) return(NULL)
             as.character(val)
           }))
           if (is.null(codes)) character(0) else codes
        }

        cond_codes <- get_code(conditions, "condition_concept_id")
        proc_codes <- get_code(procedures, "procedure_concept_id")
        drug_codes <- get_code(drugs, "drug_concept_id")

        # Exclude visits without any clinical codes
        if (length(cond_codes) == 0 && length(proc_codes) == 0 && length(drug_codes) == 0) {
          continue_flag <- TRUE # Emulate continue
        } else {
          continue_flag <- FALSE
        }

        if (continue_flag) next

        samples[[length(samples) + 1]] <- list(
          visit_id = visit_id,
          patient_id = patient$patient_id,
          conditions = cond_codes,
          procedures = proc_codes,
          drugs = drug_codes,
          mortality = mortality_label
        )
      }

      return(samples)
    }
  )
)
