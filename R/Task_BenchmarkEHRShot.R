#' BenchmarkEHRShot: Benchmark predictive tasks using EHRShot
#'
#' @description
#' Task class for running benchmark evaluations on the EHRShot dataset.
#' Supports multiple categories of prediction tasks including operational outcomes,
#' lab value predictions, new diagnoses, and medical imaging findings.
#'
#' @details
#' The BenchmarkEHRShot task class implements predictive modeling tasks from
#' the EHRShot benchmark. Each task uses clinical codes from the ehrshot table
#' as features and generates predictions based on task-specific labels.
#'
#' \strong{Operational Outcomes (Binary Classification):}
#' \itemize{
#'   \item \strong{guo_los}: Predicts if length of stay exceeds a threshold
#'   \item \strong{guo_readmission}: Predicts hospital readmission
#'   \item \strong{guo_icu}: Predicts ICU admission
#' }
#'
#' \strong{Lab Values (Multiclass Classification):}
#' \itemize{
#'   \item \strong{lab_thrombocytopenia}: Predicts low platelet count severity
#'   \item \strong{lab_hyperkalemia}: Predicts high potassium level severity
#'   \item \strong{lab_hypoglycemia}: Predicts low blood sugar severity
#'   \item \strong{lab_hyponatremia}: Predicts low sodium level severity
#'   \item \strong{lab_anemia}: Predicts anemia severity
#' }
#'
#' \strong{New Diagnoses (Binary Classification):}
#' \itemize{
#'   \item \strong{new_hypertension}: Predicts new hypertension diagnosis
#'   \item \strong{new_hyperlipidemia}: Predicts new hyperlipidemia diagnosis
#'   \item \strong{new_pancan}: Predicts new pancreatic cancer diagnosis
#'   \item \strong{new_celiac}: Predicts new celiac disease diagnosis
#'   \item \strong{new_lupus}: Predicts new lupus diagnosis
#'   \item \strong{new_acutemi}: Predicts new acute myocardial infarction diagnosis
#' }
#'
#' \strong{Medical Imaging (Multilabel Classification):}
#' \itemize{
#'   \item \strong{chexpert}: Predicts multiple chest X-ray findings simultaneously
#'         (14 possible findings from the CheXpert dataset)
#' }
#'
#' @section Features:
#' The task uses clinical codes from the ehrshot table as features. Optionally,
#' you can filter events by OMOP table type using the \code{omop_tables} parameter
#' to focus on specific types of clinical data (e.g., conditions, procedures, drugs).
#'
#' @section Data Split:
#' The task automatically assigns samples to train/validation/test splits based
#' on the splits table in the EHRShot dataset.
#'
#' @examples
#' \dontrun{
#' library(RHealth)
#'
#' # Example 1: Binary classification task (operational outcome)
#' dataset <- EHRShotDataset$new(
#'   root = "/path/to/ehrshot",
#'   tables = c("ehrshot", "splits", "guo_los"),
#'   dev = TRUE
#' )
#' task <- BenchmarkEHRShot$new(task = "guo_los")
#' samples <- dataset$set_task(task = task)
#'
#' # Example 2: Multiclass classification task (lab values)
#' dataset <- EHRShotDataset$new(
#'   root = "/path/to/ehrshot",
#'   tables = c("ehrshot", "splits", "lab_thrombocytopenia"),
#'   dev = TRUE
#' )
#' task <- BenchmarkEHRShot$new(task = "lab_thrombocytopenia")
#' samples <- dataset$set_task(task = task)
#'
#' # Example 3: Multilabel classification task (medical imaging)
#' dataset <- EHRShotDataset$new(
#'   root = "/path/to/ehrshot",
#'   tables = c("ehrshot", "splits", "chexpert"),
#'   dev = FALSE
#' )
#' task <- BenchmarkEHRShot$new(task = "chexpert")
#' samples <- dataset$set_task(task = task)
#'
#' # Example 4: Filter by specific OMOP tables
#' task <- BenchmarkEHRShot$new(
#'   task = "new_hypertension",
#'   omop_tables = c("condition_occurrence", "drug_exposure")
#' )
#' samples <- dataset$set_task(task = task)
#' }
#'
#' @seealso
#' \code{\link{EHRShotDataset}}, \code{\link{BaseTask}}
#'
#' @export
BenchmarkEHRShot <- R6::R6Class(
  "BenchmarkEHRShot",
  inherit = BaseTask,
  public = list(
    #' @field task Name of the specific benchmark task.
    task = NULL,

    #' @field omop_tables Optional vector of OMOP table names to filter events.
    omop_tables = NULL,

    #' @field max_seq_length Maximum sequence length for codes.
    max_seq_length = NULL,

    #' @field truncation_count Counter for truncated sequences.
    truncation_count = 0,

    #' @field task_name Full task name (BenchmarkEHRShot/task).
    task_name = NULL,

    #' @field input_schema Input schema specification.
    input_schema = NULL,

    #' @field output_schema Output schema specification.
    output_schema = NULL,

    #' @field tasks_by_category List of available tasks organized by category.
    tasks_by_category = list(
      operational_outcomes = c("guo_los", "guo_readmission", "guo_icu"),
      lab_values = c("lab_thrombocytopenia", "lab_hyperkalemia", "lab_hypoglycemia",
                     "lab_hyponatremia", "lab_anemia"),
      new_diagnoses = c("new_hypertension", "new_hyperlipidemia", "new_pancan",
                        "new_celiac", "new_lupus", "new_acutemi"),
      chexpert = c("chexpert")
    ),

    #' @description
    #' Initialize the BenchmarkEHRShot task.
    #'
    #' @param task Character. The specific benchmark task to run. Must be one of:
    #'   \itemize{
    #'     \item Operational outcomes: "guo_los", "guo_readmission", "guo_icu"
    #'     \item Lab values: "lab_thrombocytopenia", "lab_hyperkalemia",
    #'           "lab_hypoglycemia", "lab_hyponatremia", "lab_anemia"
    #'     \item New diagnoses: "new_hypertension", "new_hyperlipidemia", "new_pancan",
    #'           "new_celiac", "new_lupus", "new_acutemi"
    #'     \item Medical imaging: "chexpert"
    #'   }
    #' @param omop_tables Optional character vector. Names of OMOP tables to filter
    #'   input events. If specified, only events from ehrshot with matching
    #'   \code{omop_table} values will be included as features. Common values include:
    #'   "condition_occurrence", "procedure_occurrence", "drug_exposure",
    #'   "measurement", "observation".
    #' @param max_seq_length Integer. Maximum sequence length for clinical codes.
    #'   Sequences longer than this will be truncated to the most recent codes.
    #'   Default is 2000. Set to NULL for no limit (not recommended for large datasets).
    #'
    #' @return A new \code{BenchmarkEHRShot} task object.
    #'
    #' @examples
    #' \dontrun{
    #' # Basic task initialization
    #' task <- BenchmarkEHRShot$new(task = "guo_los")
    #'
    #' # With OMOP table filtering
    #' task <- BenchmarkEHRShot$new(
    #'   task = "new_hypertension",
    #'   omop_tables = c("condition_occurrence", "drug_exposure")
    #' )
    #'
    #' # With custom max sequence length
    #' task <- BenchmarkEHRShot$new(task = "guo_los", max_seq_length = 5000)
    #' }
    initialize = function(task, omop_tables = NULL, max_seq_length = 2000) {
      # Validate task name
      all_tasks <- unlist(self$tasks_by_category, use.names = FALSE)
      if (!(task %in% all_tasks)) {
        stop(sprintf(
          "Invalid task '%s'. Must be one of: %s",
          task,
          paste(all_tasks, collapse = ", ")
        ), call. = FALSE)
      }

      self$task <- task
      self$omop_tables <- omop_tables
      self$max_seq_length <- max_seq_length
      self$task_name <- paste0("BenchmarkEHRShot/", task)

      # Define input schema (always sequence of codes)
      self$input_schema <- list(feature = "sequence")

      # Define output schema based on task category
      if (task %in% self$tasks_by_category$operational_outcomes) {
        self$output_schema <- list(label = "binary")
      } else if (task %in% self$tasks_by_category$lab_values) {
        self$output_schema <- list(label = "multiclass")
      } else if (task %in% self$tasks_by_category$new_diagnoses) {
        self$output_schema <- list(label = "binary")
      } else if (task %in% self$tasks_by_category$chexpert) {
        self$output_schema <- list(label = "multilabel")
      }

      # Call parent initializer
      super$initialize(
        task_name = self$task_name,
        input_schema = self$input_schema,
        output_schema = self$output_schema
      )

      message(sprintf(
        "[BenchmarkEHRShot] Initialized task: %s (output type: %s)",
        task,
        self$output_schema$label
      ))
    },

    #' @description
    #' Pre-filter hook to retain only necessary columns and optionally filter
    #' by OMOP tables.
    #'
    #' @param df A lazy query or data frame containing all events.
    #' @return A filtered data frame.
    pre_filter = function(df) {
      # Define required columns
      required_cols <- c(
        "patient_id", "event_type", "timestamp",
        "ehrshot/code", "ehrshot/omop_table",
        paste0(self$task, "/value"),
        "splits/split"
      )

      existing_cols <- colnames(df)
      keep_cols <- intersect(required_cols, existing_cols)

      # Select only needed columns
      df <- df %>% dplyr::select(dplyr::all_of(keep_cols))

      # Filter by OMOP tables if specified
      if (!is.null(self$omop_tables)) {
        df <- df %>%
          dplyr::filter(
            event_type != "ehrshot" |
            `ehrshot/omop_table` %in% self$omop_tables
          )
      }

      return(df)
    },

    #' @description
    #' Process a single patient to generate samples.
    #'
    #' @param patient A Patient object.
    #' @return A list of samples, where each sample contains:
    #'   \itemize{
    #'     \item \strong{patient_id}: Patient identifier
    #'     \item \strong{feature}: Vector of clinical codes
    #'     \item \strong{label}: Label value (type depends on task)
    #'     \item \strong{split}: Data split assignment ("train", "val", or "test")
    #'   }
    call = function(patient) {
      samples <- list()

      # Get split assignment for this patient
      split_events <- patient$get_events(event_type = "splits", return_df = TRUE)

      if (nrow(split_events) == 0) {
        return(samples)
      }

      # There should be exactly one split per patient
      if (nrow(split_events) != 1) {
        warning(sprintf(
          "Patient %s has %d split assignments (expected 1). Using first split.",
          patient$patient_id,
          nrow(split_events)
        ), call. = FALSE)
      }

      split_value <- split_events[[paste0("splits/split")]][1]

      # Get label events for this task
      label_events <- patient$get_events(event_type = self$task, return_df = TRUE)

      if (nrow(label_events) == 0) {
        return(samples)
      }

      # Process each label (prediction point)
      for (i in seq_len(nrow(label_events))) {
        label_time <- label_events$timestamp[i]
        label_value <- label_events[[paste0(self$task, "/value")]][i]

        # Skip if label is missing
        if (is.na(label_value)) {
          next
        }

        # Get ehrshot events up to the prediction time
        ehrshot_events <- patient$get_events(
          event_type = "ehrshot",
          end = label_time,
          return_df = TRUE
        )

        if (nrow(ehrshot_events) == 0) {
          next
        }

        # Extract codes from ehrshot events
        codes <- ehrshot_events[[paste0("ehrshot/code")]]
        codes <- codes[!is.na(codes)]

        if (length(codes) == 0) {
          next
        }

        # Truncate to max_seq_length (keep most recent codes)
        if (!is.null(self$max_seq_length) && length(codes) > self$max_seq_length) {
          self$truncation_count <- self$truncation_count + 1
          # Keep the last max_seq_length codes (most recent)
          codes <- tail(codes, self$max_seq_length)
        }

        # Process label based on task type
        if (self$task == "chexpert") {
          # Convert integer to multilabel format (list of positive indices)
          # The value is stored as an integer representing a binary string
          label_int <- as.integer(label_value)
          # Find which bits are set (14 possible labels for CheXpert)
          positive_labels <- which(sapply(0:13, function(i) bitwAnd(label_int, bitwShiftL(1, i)) > 0))
          # Reverse order to match Python implementation
          # which() returns 1-based indices (1 to 14), so use 14 - positive_labels to get (13 to 0)
          positive_labels <- 14 - positive_labels
          label_value <- positive_labels
        }

        # Create sample
        sample <- list(
          patient_id = patient$patient_id,
          feature = as.character(codes),
          label = label_value,
          split = split_value
        )

        samples[[length(samples) + 1]] <- sample
      }

      return(samples)
    }
  )
)
