#' @title Binary Classification Metrics (Python‐style API)
#' @description
#' A configurable evaluator for **binary classification** tasks.  The function
#' reproduces the behaviour of Python’s `binary_metrics_fn`, covering classical
#' discrimination metrics (ROC‑AUC, F1, accuracy, …​) as well as calibration
#' metrics (ECE / adaptive ECE).
#'
#' Supported `metrics` names:
#' * **"pr_auc"**  – Precision‑Recall area under the curve
#' * **"roc_auc"** – Receiver‑Operating‑Characteristic area under the curve
#' * **"accuracy"**, **"balanced_accuracy"**, **"f1"**, **"precision"**, **"recall"**
#' * **"cohen_kappa"** – Cohen’s κ
#' * **"jaccard"**    – Jaccard index (intersection‑over‑union)
#' * **"ECE"**        – Expected Calibration Error (equal‑width bins)
#' * **"ECE_adapt"**  – Adaptive ECE (equal‑size bins)
#'
#' @param y_true Numeric vector of ground‑truth labels (0 / 1).
#' @param y_prob Numeric vector of predicted probabilities for the positive
#'   class.
#' @param metrics Character vector listing which metrics to compute.  Default
#'   is `c("pr_auc","roc_auc","f1")`.
#' @param threshold Numeric decision threshold used to convert probabilities to
#'   hard labels (`y_pred`).  Default `0.5`.
#'
#' @return Named numeric vector with one element per requested metric.
#'
#' @examples
#' set.seed(42)
#' y_true <- rbinom(100, 1, 0.4)
#' y_prob <- runif(100)
#' binary_metrics_fn(y_true, y_prob, metrics = c("accuracy", "ECE"))
#'
#' @importFrom MLmetrics Accuracy F1_Score Precision Recall
#' @importFrom metrica balacc jaccardindex
#' @importFrom psych cohen.kappa
#' @export
binary_metrics_fn <- function(y_true,
                              y_prob,
                              metrics    = NULL,
                              threshold  = 0.5) {
  
  y_true <- to_numeric_vector(y_true)
  y_prob <- to_numeric_vector(y_prob)
  
  stopifnot(length(y_true) == length(y_prob),
            all(y_true %in% c(0, 1)),
            is.numeric(y_prob),
            threshold >= 0 && threshold <= 1)

  if (is.null(metrics)) {
    metrics <- c("pr_auc", "roc_auc", "f1","accuracy", "precision", "recall")
  }

  y_pred <- ifelse(y_prob >= threshold, 1, 0)
  out <- numeric(length(metrics))
  names(out) <- metrics

  has_pos <- any(y_true == 1)
  has_neg <- any(y_true == 0)

  for (m in metrics) {
    out[m] <- switch(
      m,
      pr_auc = {
        has_pos <- any(y_true == 1)
        has_neg <- any(y_true == 0)

        if (!(has_pos && has_neg)) {
          warning("PR AUC undefined: only one class present."); 0
        } else {
          MLmetrics::PRAUC(y_prob, y_true)
        }
      },

      roc_auc = {
        has_pos <- any(y_true == 1)
        has_neg <- any(y_true == 0)

        if (!(has_pos && has_neg)) {
          warning("ROC AUC undefined: only one class present."); 0
        } else {
          MLmetrics::AUC(y_prob, y_true)
        }
      },

      accuracy          = Accuracy(y_pred, y_true),
      balanced_accuracy = as.numeric(balacc(data = data.frame(pred = y_pred, obs = y_true),
                                            pred = "pred",
                                            obs  = "obs",
                                            tidy = FALSE)),
      f1                = F1_Score(y_pred, y_true, positive = 1),
      precision         = Precision(y_pred, y_true, positive = 1),
      recall            = Recall(y_pred, y_true, positive = 1),
      cohen_kappa       = cohen.kappa(table(y_pred, y_true))$kappa,
      jaccard           = as.numeric(jaccardindex(data = data.frame(pred = y_pred, obs = y_true),
                                                  pred = "pred",
                                                  obs  = "obs",
                                                  tidy = FALSE)),
      ECE               = ece_confidence_binary(prob  = y_prob,
                                                label = y_true,
                                                bins  = 20,
                                                adaptive = FALSE),
      ECE_adapt         = ece_confidence_binary(prob  = y_prob,
                                                label = y_true,
                                                bins  = 20,
                                                adaptive = TRUE),
      stop(sprintf("Unknown metric for binary classification: %s", m))
    )
  }

  return(out)
}

to_numeric_vector <- function(x) {
  if (inherits(x, "torch_tensor")) {
    return(as.numeric(x$view(-1)$cpu()))
  } else {
    return(as.numeric(x))
  }
}
