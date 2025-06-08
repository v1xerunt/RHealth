#' @title Expected Calibration Error for Binary Classification
#' @description
#' Calculates **Expected Calibration Error (ECE)** or **Adaptive ECE**
#' for a binary classifier, reproducing the behaviour of
#' `pyhealth.metrics.calibration.ece_confidence_binary`.
#'
#' @param prob Numeric vector **or** two-column matrix \
#'   containing predicted probabilities for the *positive* class
#'   (only the first column is used if a matrix is supplied).
#' @param label Numeric vector **or** two-column matrix of true labels \
#'   encoded as 0/1 (only the first column is used if a matrix is supplied).
#' @param bins Integer. Number of bins (default 20).
#' @param adaptive Logical. If `FALSE` (default) equal-width bins \
#'   spanning \\([0,1]\\) are used; if `TRUE` each bin contains the \
#'   same number of samples (equal-size bins).
#'
#' @return A single numeric value – the (adaptive) ECE.
#'
#' @examples
#' set.seed(1)
#' p  <- runif(1e4)          # predicted probabilities
#' y  <- rbinom(1e4, 1, 0.4) # ground-truth labels
#' ece_confidence_binary(p, y)             # standard ECE
#' ece_confidence_binary(p, y, adaptive=TRUE)  # adaptive ECE
#'
#' @export
ece_confidence_binary <- function(prob,
                                  label,
                                  bins      = 20L,
                                  adaptive  = FALSE) {

  # ------------------------------------------------------------
  # Normalise inputs ------------------------------------------------
  # ------------------------------------------------------------
  if (is.matrix(prob))  prob  <- prob[ , 1L]
  if (is.matrix(label)) label <- label[ , 1L]
  stopifnot(length(prob)  == length(label),
            length(prob)  >  0L,
            is.numeric(prob),
            is.numeric(label))

  df <- data.frame(
    conf = as.numeric(prob),
    acc  = as.numeric(label)
  )

  ece <- .ECE_confidence(df, bins, adaptive)$ece
  return(ece)
}


# ---------------------------------------------------------------------
# INTERNAL HELPERS -----------------------------------------------------
# (Not exported – they are called only by ece_confidence_binary)
# ---------------------------------------------------------------------

.get_bins <- function(bins) {
  ## Equivalent to the Python helper _get_bins ------------------------
  if (length(bins) == 1L && is.numeric(bins)) {
    return(seq(0, 1, length.out = bins + 1L))
  }
  return(bins)   # assume user supplied a numeric vector
}

.assign_bin <- function(sorted_conf,
                        bins,
                        adaptive = FALSE) {
  ## Assign each confidence score to a bin (vector of integers) ------
  n <- length(sorted_conf)

  if (adaptive) {
    # Equal-size bins: distribute samples as evenly as possible
    stopifnot(is.numeric(bins), length(bins) == 1L, bins > 0L)
    step  <- floor(n / bins)
    nvals <- rep(step, bins)
    if (n %% bins) {
      nvals[(bins - (n %% bins) + 1L):bins] <-
        nvals[(bins - (n %% bins) + 1L):bins] + 1L
    }
    bin_vec <- rep.int(seq_len(bins) - 1L, times = nvals)

    # Optional: create pseudo-boundary values (mid-points) for record
    cum_idx <- cumsum(nvals)
    edges   <- c(sorted_conf[1L],
                 vapply(cum_idx, function(i) sorted_conf[i], numeric(1L)))
    edges[length(edges)] <- 1.0
  } else {
    # Equal-width bins over [0,1]
    edges   <- .get_bins(bins)                 # vector of bin edges
    bin_vec <- findInterval(sorted_conf, edges, rightmost.closed = TRUE) - 1L
  }

  list(bin = bin_vec, bins = edges)
}

.ECE_loss <- function(summary_df) {
  ## Weighted absolute difference between accuracy and confidence ----
  w <- summary_df$cnt / sum(summary_df$cnt)
  return(sum(w * abs(summary_df$conf - summary_df$acc)))
}

.ECE_confidence <- function(df, bins = 20L, adaptive = FALSE) {
  ## Core routine mirroring the Python implementation ---------------
  df <- df[order(df$conf), ]                     # sort by confidence
  bin_info <- .assign_bin(df$conf, bins, adaptive)
  df$bin   <- bin_info$bin

  # Per-bin averages
  agg <- aggregate(df[ , c("acc", "conf")],
                   by   = list(bin = df$bin),
                   FUN  = mean)
  cnt <- as.numeric(table(df$bin))

  summary_df <- cbind(agg, cnt = cnt)
  ece_value  <- .ECE_loss(summary_df)

  return(list(summary = summary_df, ece = ece_value))
}
