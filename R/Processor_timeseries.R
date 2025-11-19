#' @title Time Series Processor
#' @description Processor for irregular time series data with missing values.
#'              Supports uniform resampling, two imputation strategies (forward-fill and zero-fill),
#'              and automatic z-score normalization using training data statistics.
#'
#' @details
#' The processor performs three main steps:
#' \enumerate{
#'   \item \strong{Resampling}: Converts irregular time series to uniform time grid based on \code{sampling_rate}
#'   \item \strong{Imputation}: Fills missing values using either forward-fill or zero-fill strategy
#'   \item \strong{Normalization} (default): Applies z-score normalization: \code{(x - mean) / std}
#' }
#'
#' Normalization is enabled by default (\code{normalize = TRUE}):
#' \itemize{
#'   \item Call \code{fit()} on training samples to compute feature-wise mean and standard deviation
#'   \item The same statistics are used for all subsequent \code{process()} calls (train/val/test)
#'   \item This ensures no data leakage between training and validation/test sets
#' }
#'
#' @examples
#' \dontrun{
#' library(torch)
#' library(lubridate)
#'
#' # Create training samples with timeseries data
#' train_samples <- list(
#'   list(
#'     patient_id = 1,
#'     labs = list(
#'       timestamps = as.POSIXct(c("2020-01-01 00:00:00", "2020-01-01 02:00:00"), tz = "UTC"),
#'       values = matrix(c(100, 50, 150, 60), ncol = 2)
#'     )
#'   ),
#'   list(
#'     patient_id = 2,
#'     labs = list(
#'       timestamps = as.POSIXct(c("2020-01-01 00:00:00", "2020-01-01 01:00:00"), tz = "UTC"),
#'       values = matrix(c(120, 55, 180, 65), ncol = 2)
#'     )
#'   )
#' )
#'
#' # Example 1: Default behavior (with normalization)
#' processor <- TimeseriesProcessor$new(
#'   sampling_rate = dhours(1),
#'   impute_strategy = "forward_fill"
#'   # normalize = TRUE by default
#' )
#'
#' # Fit on training data to compute statistics
#' processor$fit(train_samples, "labs")
#'
#' # Process samples (applies normalization)
#' result <- processor$process(train_samples[[1]]$labs)
#'
#' # Check normalization statistics
#' print(processor$feature_means)  # Feature means from training data
#' print(processor$feature_stds)   # Feature standard deviations
#'
#' # Example 2: Disable normalization if needed
#' processor_no_norm <- TimeseriesProcessor$new(
#'   sampling_rate = dhours(1),
#'   impute_strategy = "forward_fill",
#'   normalize = FALSE  # Explicitly disable normalization
#' )
#' result_no_norm <- processor_no_norm$process(train_samples[[1]]$labs)
#' }
#'
#' @importFrom R6 R6Class
#' @importFrom lubridate as.duration dhours
#' @importFrom torch torch_tensor
#' @export
TimeseriesProcessor <- R6::R6Class("TimeseriesProcessor",
  inherit = FeatureProcessor,
  public = list(
    #' @field sampling_rate A lubridate duration indicating the sampling step size.
    sampling_rate = NULL,

    #' @field impute_strategy A character string: 'forward_fill' or 'zero'.
    impute_strategy = NULL,

    #' @field normalize Logical flag indicating whether to apply z-score normalization. Default TRUE.
    normalize = TRUE,

    #' @field feature_means Numeric vector of feature means (computed during fit).
    feature_means = NULL,

    #' @field feature_stds Numeric vector of feature standard deviations (computed during fit).
    feature_stds = NULL,

    #' @field .size Number of features (set on first call to process()).
    .size = NULL,

    #' @description Initialize the processor with a sampling rate, imputation strategy, and normalization option.
    #' @param sampling_rate A lubridate duration (e.g., lubridate::dhours(1)).
    #' @param impute_strategy Either 'forward_fill' or 'zero'.
    #' @param normalize Logical, whether to apply z-score normalization. Default TRUE.
    initialize = function(sampling_rate = lubridate::dhours(1), impute_strategy = "forward_fill", normalize = TRUE) {
      self$sampling_rate <- sampling_rate
      self$impute_strategy <- impute_strategy
      self$normalize <- normalize
      self$feature_means <- NULL
      self$feature_stds <- NULL
      self$.size <- NULL
    },

    #' @description Fit the processor by computing feature-wise mean and std from training data.
    #' @param samples A list of named lists representing sample records.
    #' @param field A string giving the field name to fit on.
    fit = function(samples, field) {
      if (!self$normalize) {
        return(invisible(self))
      }

      # Collect all values from all samples to compute global statistics
      all_values <- list()

      for (sample in samples) {
        if (field %in% names(sample)) {
          value <- sample[[field]]
          if (is.list(value) && length(value) >= 2) {
            timestamps <- value[[1]]
            values <- value[[2]]

            if (length(timestamps) > 0) {
              values <- as.matrix(values)
              # Collect all non-NA values
              all_values[[length(all_values) + 1]] <- values
            }
          }
        }
      }

      if (length(all_values) == 0) {
        warning("No valid timeseries data found during fit. Normalization will be disabled.")
        self$normalize <- FALSE
        return(invisible(self))
      }

      # Combine all values
      combined <- do.call(rbind, all_values)
      num_features <- ncol(combined)

      # Compute mean and std for each feature (column)
      self$feature_means <- numeric(num_features)
      self$feature_stds <- numeric(num_features)

      for (f in seq_len(num_features)) {
        vals <- combined[, f]
        vals <- vals[!is.na(vals)]  # Remove NA values

        if (length(vals) > 0) {
          self$feature_means[f] <- mean(vals)
          self$feature_stds[f] <- sd(vals)

          # Avoid division by zero
          if (is.na(self$feature_stds[f]) || self$feature_stds[f] < 1e-8) {
            self$feature_stds[f] <- 1.0
          }
        } else {
          self$feature_means[f] <- 0.0
          self$feature_stds[f] <- 1.0
        }
      }

      message(sprintf("Fitted TimeseriesProcessor: %d features, means range [%.4f, %.4f], stds range [%.4f, %.4f]",
                      num_features,
                      min(self$feature_means), max(self$feature_means),
                      min(self$feature_stds), max(self$feature_stds)))

      invisible(self)
    },

    #' @description Process irregular time series into uniformly sampled tensor.
    #' Step 1: uniformly sample time points and place values at correct positions.
    #' Step 2: impute missing entries using selected strategy.
    #' Step 3: (optional) apply z-score normalization using training statistics.
    #'
    #' @param value A list: list(timestamps = POSIXct vector, values = matrix).
    #' @return A torch tensor of shape `[T, F]`.
    process = function(value) {
      timestamps <- value[[1]]
      values <- value[[2]]

      if (length(timestamps) == 0) {
        stop("Timestamps list is empty.")
      }

      values <- as.matrix(values)
      num_features <- ncol(values)

      # Step 1: Uniformly sample all time steps with fixed interval
      start_time <- timestamps[1]
      end_time <- timestamps[length(timestamps)]
      interval_sec <- as.numeric(as.duration(self$sampling_rate), units = "secs")
      total_steps <- floor(as.numeric(difftime(end_time, start_time, units = "secs")) / interval_sec) + 1

      sampled_times <- seq(from = start_time, by = interval_sec, length.out = total_steps)
      sampled_values <- matrix(NA_real_, nrow = total_steps, ncol = num_features)

      # Place existing values at aligned sampled indices
      for (i in seq_along(timestamps)) {
        idx <- floor(as.numeric(difftime(timestamps[i], start_time, units = "secs")) / interval_sec) + 1
        if (idx >= 1 && idx <= total_steps) {
          sampled_values[idx, ] <- values[i, ]
        }
      }

      # Step 2: Imputation based on selected strategy
      if (self$impute_strategy == "forward_fill") {
        for (f in seq_len(num_features)) {
          last_val <- 0.0
          for (t in seq_len(total_steps)) {
            if (!is.na(sampled_values[t, f])) {
              last_val <- sampled_values[t, f]
            } else {
              sampled_values[t, f] <- last_val
            }
          }
        }
      } else if (self$impute_strategy == "zero") {
        sampled_values[is.na(sampled_values)] <- 0.0
      } else {
        stop(sprintf("Unsupported imputation strategy: %s", self$impute_strategy), call. = FALSE)
      }

      # Step 3: Apply z-score normalization if enabled
      if (self$normalize && !is.null(self$feature_means) && !is.null(self$feature_stds)) {
        for (f in seq_len(num_features)) {
          sampled_values[, f] <- (sampled_values[, f] - self$feature_means[f]) / self$feature_stds[f]
        }
      }

      if (is.null(self$.size)) {
        self$.size <- num_features
      }

      torch::torch_tensor(sampled_values, dtype = torch::torch_float())
    },

    #' @description Return the number of features.
    #' @return Integer
    size = function() {
      self$.size
    },

    #' @description Print summary
    #' @param ... Ignored.
    print = function(...) {
      norm_str <- if (self$normalize) {
        if (!is.null(self$feature_means)) {
          sprintf(", normalize = TRUE (fitted with %d features)", length(self$feature_means))
        } else {
          ", normalize = TRUE (not fitted)"
        }
      } else {
        ", normalize = FALSE"
      }

      cat(sprintf("TimeseriesProcessor(sampling_rate = %s, impute_strategy = '%s'%s)\n",
                  format(self$sampling_rate), self$impute_strategy, norm_str))
    }
  )
)


