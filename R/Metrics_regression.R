#' @title Regression Metrics
#' @description
#' A configurable evaluator for **regression** tasks. The function computes
#' various regression metrics, particularly useful for reconstruction tasks
#' (e.g., autoencoders). Reproduces the behaviour of Python's
#' `regression_metrics_fn`.
#'
#' Supported `metrics` names:
#' * **"kl_divergence"** – Kullback-Leibler divergence
#' * **"mse"** – Mean Squared Error
#' * **"mae"** – Mean Absolute Error
#'
#' @param x Numeric vector, matrix, or torch tensor of true target data sample.
#' @param x_rec Numeric vector, matrix, or torch tensor of reconstructed data sample.
#' @param metrics Character vector listing which metrics to compute.  Default
#'   is `c("kl_divergence", "mse", "mae")`.
#'
#' @return Named numeric vector with one element per requested metric.
#'
#' @examples
#' set.seed(42)
#' x <- runif(1000)
#' x_rec <- runif(1000)
#' regression_metrics_fn(x, x_rec, metrics = c("mse", "mae"))
#'
#' @importFrom MLmetrics MAE MSE
#' @export
regression_metrics_fn <- function(x,
                                  x_rec,
                                  metrics = NULL) {

  # Convert inputs to numeric vectors and flatten
  x <- to_numeric_vector(x)
  x_rec <- to_numeric_vector(x_rec)

  stopifnot(length(x) == length(x_rec),
            is.numeric(x),
            is.numeric(x_rec))

  if (is.null(metrics)) {
    metrics <- c("kl_divergence", "mse", "mae")
  }

  out <- numeric(0)

  for (m in metrics) {
    if (m == "kl_divergence") {
      out[m] <- .kl_divergence(x, x_rec)
    } else if (m == "mse") {
      out[m] <- mean((x - x_rec)^2)
    } else if (m == "mae") {
      out[m] <- mean(abs(x - x_rec))
    } else {
      stop(sprintf("Unknown metric for regression task: %s", m))
    }
  }

  return(out)
}


# ============================================================================
# INTERNAL HELPER FUNCTIONS
# ============================================================================

#' @keywords internal
.kl_divergence <- function(x, x_rec) {
  # Kullback-Leibler divergence
  # KL(x_rec || x) = sum(x_rec * log(x_rec / x))

  # Clip small values to avoid log(0)
  x[x < 1e-6] <- 1e-6
  x_rec[x_rec < 1e-6] <- 1e-6

  # Normalize to make them probability distributions
  x <- x / sum(x)
  x_rec <- x_rec / sum(x_rec)

  # Calculate KL divergence
  kl <- sum(x_rec * log(x_rec / x))

  return(kl)
}
