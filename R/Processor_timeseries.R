#' @title Time Series Processor
#' @description Processor for irregular time series data with missing values.
#'              Supports uniform resampling and two imputation strategies: forward-fill and zero-fill.
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

    #' @field .size Number of features (set on first call to process()).
    .size = NULL,

    #' @description Initialize the processor with a sampling rate and imputation strategy.
    #' @param sampling_rate A lubridate duration (e.g., lubridate::dhours(1)).
    #' @param impute_strategy Either 'forward_fill' or 'zero'.
    initialize = function(sampling_rate = lubridate::dhours(1), impute_strategy = "forward_fill") {
      self$sampling_rate <- sampling_rate
      self$impute_strategy <- impute_strategy
      self$.size <- NULL
    },

    #' @description Process irregular time series into uniformly sampled tensor.
    #' Step 1: uniformly sample time points and place values at correct positions.
    #' Step 2: impute missing entries using selected strategy.
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
      cat(sprintf("TimeseriesProcessor(sampling_rate = %s, impute_strategy = '%s')\n",
                  format(self$sampling_rate), self$impute_strategy))
    }
  )
)


