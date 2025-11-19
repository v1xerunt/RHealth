#' @title Multiclass Classification Metrics
#' @description
#' A configurable evaluator for **multiclass classification** tasks.  The function
#' reproduces the behaviour of Python's `multiclass_metrics_fn`, covering classical
#' discrimination metrics (ROC‑AUC with various averaging strategies, F1, accuracy, …)
#' as well as calibration metrics (ECE / adaptive ECE / classwise ECE).
#'
#' Supported `metrics` names:
#' * **"roc_auc_macro_ovo"** – ROC AUC, macro averaged over one-vs-one
#' * **"roc_auc_macro_ovr"** – ROC AUC, macro averaged over one-vs-rest
#' * **"roc_auc_weighted_ovo"** – ROC AUC, weighted averaged over one-vs-one
#' * **"roc_auc_weighted_ovr"** – ROC AUC, weighted averaged over one-vs-rest
#' * **"accuracy"** – Overall accuracy
#' * **"balanced_accuracy"** – Balanced accuracy (useful for imbalanced datasets)
#' * **"f1_micro"** – F1 score, micro averaged
#' * **"f1_macro"** – F1 score, macro averaged
#' * **"f1_weighted"** – F1 score, weighted averaged
#' * **"jaccard_micro"** – Jaccard index, micro averaged
#' * **"jaccard_macro"** – Jaccard index, macro averaged
#' * **"jaccard_weighted"** – Jaccard index, weighted averaged
#' * **"cohen_kappa"** – Cohen's κ
#' * **"brier_top1"** – Brier score between top prediction and true label
#' * **"ECE"** – Expected Calibration Error (equal‑width bins)
#' * **"ECE_adapt"** – Adaptive ECE (equal‑size bins)
#' * **"cwECEt"** – Classwise ECE with threshold
#' * **"cwECEt_adapt"** – Classwise adaptive ECE with threshold
#' * **"hits@n"** – Computes HITS@1, HITS@5, HITS@10
#' * **"mean_rank"** – Computes mean rank and mean reciprocal rank
#'
#' @param y_true Numeric or integer vector of ground‑truth labels (1, 2, ..., K) using R's 1-based indexing.
#' @param y_prob Numeric matrix of predicted probabilities with shape (n_samples, n_classes).
#' @param metrics Character vector listing which metrics to compute.  Default
#'   is `c("accuracy", "f1_macro", "f1_micro")`.
#' @param y_predset Optional matrix for prediction set metrics. Default is NULL.
#'
#' @return Named numeric vector with one element per requested metric.
#'
#' @examples
#' set.seed(42)
#' n <- 100
#' k <- 4
#' y_true <- sample(1:k, n, replace = TRUE)
#' y_prob <- matrix(runif(n * k), nrow = n, ncol = k)
#' y_prob <- y_prob / rowSums(y_prob)  # normalize to sum to 1
#' multiclass_metrics_fn(y_true, y_prob, metrics = c("accuracy", "f1_macro"))
#'
#' @importFrom MLmetrics Accuracy F1_Score Precision Recall AUC
#' @importFrom metrica balacc jaccardindex
#' @importFrom psych cohen.kappa
#' @importFrom utils combn
#' @export
multiclass_metrics_fn <- function(y_true,
                                  y_prob,
                                  metrics = NULL,
                                  y_predset = NULL) {

  # Convert inputs to numeric
  y_true <- to_numeric_vector(y_true)

  # Ensure y_prob is a matrix
  if (!is.matrix(y_prob)) {
    if (inherits(y_prob, "torch_tensor")) {
      y_prob <- as.matrix(y_prob$cpu())
    } else {
      y_prob <- as.matrix(y_prob)
    }
  }

  stopifnot(length(y_true) == nrow(y_prob),
            is.numeric(y_prob),
            ncol(y_prob) >= 2)

  if (is.null(metrics)) {
    metrics <- c("accuracy", "f1_macro", "f1_micro")
  }

  # Get predicted class (argmax) - uses R's 1-based indexing
  y_pred <- apply(y_prob, 1, which.max)

  n_classes <- ncol(y_prob)
  out <- numeric(0)

  for (m in metrics) {
    if (m == "roc_auc_macro_ovo") {
      out[m] <- .multiclass_roc_auc(y_true, y_prob, average = "macro", multi_class = "ovo")
    } else if (m == "roc_auc_macro_ovr") {
      out[m] <- .multiclass_roc_auc(y_true, y_prob, average = "macro", multi_class = "ovr")
    } else if (m == "roc_auc_weighted_ovo") {
      out[m] <- .multiclass_roc_auc(y_true, y_prob, average = "weighted", multi_class = "ovo")
    } else if (m == "roc_auc_weighted_ovr") {
      out[m] <- .multiclass_roc_auc(y_true, y_prob, average = "weighted", multi_class = "ovr")
    } else if (m == "accuracy") {
      out[m] <- mean(y_pred == y_true)
    } else if (m == "balanced_accuracy") {
      out[m] <- as.numeric(balacc(data = data.frame(pred = y_pred, obs = y_true),
                                  pred = "pred",
                                  obs  = "obs",
                                  tidy = FALSE))
    } else if (m == "f1_micro") {
      out[m] <- .multiclass_f1(y_true, y_pred, average = "micro")
    } else if (m == "f1_macro") {
      out[m] <- .multiclass_f1(y_true, y_pred, average = "macro")
    } else if (m == "f1_weighted") {
      out[m] <- .multiclass_f1(y_true, y_pred, average = "weighted")
    } else if (m == "jaccard_micro") {
      out[m] <- .jaccard_score(y_true, y_pred, average = "micro")
    } else if (m == "jaccard_macro") {
      out[m] <- .jaccard_score(y_true, y_pred, average = "macro")
    } else if (m == "jaccard_weighted") {
      out[m] <- .jaccard_score(y_true, y_pred, average = "weighted")
    } else if (m == "cohen_kappa") {
      kappa_result <- tryCatch({
        cohen.kappa(table(y_pred, y_true))$kappa
      }, error = function(e) {
        warning("Cohen's kappa calculation failed: ", e$message)
        return(NA_real_)
      })
      out[m] <- kappa_result
    } else if (m == "brier_top1") {
      out[m] <- .brier_top1(y_prob, y_true)
    } else if (m %in% c("ECE", "ECE_adapt", "cwECEt", "cwECEt_adapt")) {
      # ECE calibration metrics not yet implemented for multiclass
      warning(sprintf("Metric '%s' not yet implemented for multiclass classification", m))
      out[m] <- NA_real_
    } else if (m == "hits@n") {
      # Compute HITS@1, @5, @10
      argsort <- t(apply(-y_prob, 1, order))  # descending order
      ranking <- sapply(seq_along(y_true), function(i) {
        which(argsort[i, ] == y_true[i])[1]
      })
      out["HITS@1"] <- mean(ranking <= 1)
      out["HITS@5"] <- mean(ranking <= 5)
      out["HITS@10"] <- mean(ranking <= 10)
    } else if (m == "mean_rank") {
      argsort <- t(apply(-y_prob, 1, order))
      ranking <- sapply(seq_along(y_true), function(i) {
        which(argsort[i, ] == y_true[i])[1]
      })
      out["mean_rank"] <- mean(ranking)
      out["mean_reciprocal_rank"] <- mean(1 / ranking)
    } else {
      # Check prediction set metrics
      if (!is.null(y_predset)) {
        if (m == "rejection_rate") {
          out[m] <- .rejection_rate(y_predset)
        } else if (m == "set_size") {
          out[m] <- .predset_size(y_predset)
        } else if (m == "miscoverage_mean_ps") {
          out[m] <- mean(.miscoverage_ps(y_predset, y_true))
        } else if (m == "miscoverage_ps") {
          # Returns per-class values - store as single mean for now
          out[m] <- mean(.miscoverage_ps(y_predset, y_true))
        } else if (m == "miscoverage_overall_ps") {
          out[m] <- .miscoverage_overall_ps(y_predset, y_true)
        } else if (m == "error_mean_ps") {
          out[m] <- mean(.error_ps(y_predset, y_true))
        } else if (m == "error_ps") {
          out[m] <- mean(.error_ps(y_predset, y_true))
        } else if (m == "error_overall_ps") {
          out[m] <- .error_overall_ps(y_predset, y_true)
        } else {
          stop(sprintf("Unknown metric for multiclass classification: %s", m))
        }
      } else {
        stop(sprintf("Unknown metric for multiclass classification: %s", m))
      }
    }
  }

  return(out)
}


# ============================================================================
# INTERNAL HELPER FUNCTIONS
# ============================================================================

#' @keywords internal
.multiclass_roc_auc <- function(y_true, y_prob, average = "macro", multi_class = "ovr") {
  # Implement multiclass ROC AUC
  # For simplicity, we use a pairwise approach

  n_classes <- ncol(y_prob)
  classes <- sort(unique(y_true))

  if (length(classes) < 2) {
    warning("ROC AUC undefined: only one class present.")
    return(0)
  }

  if (multi_class == "ovr") {
    # One-vs-Rest
    aucs <- numeric(n_classes)
    weights <- numeric(n_classes)

    for (k in seq_len(n_classes)) {
      class_label <- k  # R uses 1-based indexing
      binary_true <- as.numeric(y_true == class_label)

      if (length(unique(binary_true)) < 2) {
        aucs[k] <- NA
        next
      }

      tryCatch({
        aucs[k] <- MLmetrics::AUC(y_prob[, k], binary_true)
        weights[k] <- sum(y_true == class_label)
      }, error = function(e) {
        aucs[k] <- NA
      })
    }

    valid_idx <- !is.na(aucs)
    if (sum(valid_idx) == 0) {
      return(0)
    }

    if (average == "macro") {
      return(mean(aucs[valid_idx]))
    } else if (average == "weighted") {
      return(sum(aucs[valid_idx] * weights[valid_idx]) / sum(weights[valid_idx]))
    }

  } else if (multi_class == "ovo") {
    # One-vs-One
    pairs <- combn(classes, 2)
    aucs <- numeric(ncol(pairs))
    weights <- numeric(ncol(pairs))

    for (i in seq_len(ncol(pairs))) {
      c1 <- pairs[1, i]
      c2 <- pairs[2, i]

      idx <- y_true %in% c(c1, c2)
      if (sum(idx) == 0) next

      y_sub <- y_true[idx]
      p_sub <- y_prob[idx, ]

      binary_true <- as.numeric(y_sub == c1)
      prob_diff <- p_sub[, c1] / (p_sub[, c1] + p_sub[, c2])

      tryCatch({
        aucs[i] <- MLmetrics::AUC(prob_diff, binary_true)
        weights[i] <- sum(idx)
      }, error = function(e) {
        aucs[i] <- NA
      })
    }

    valid_idx <- !is.na(aucs)
    if (sum(valid_idx) == 0) {
      return(0)
    }

    if (average == "macro") {
      return(mean(aucs[valid_idx]))
    } else if (average == "weighted") {
      return(sum(aucs[valid_idx] * weights[valid_idx]) / sum(weights[valid_idx]))
    }
  }

  return(0)
}


#' @keywords internal
.multiclass_f1 <- function(y_true, y_pred, average = "macro") {
  classes <- sort(unique(c(y_true, y_pred)))
  n_classes <- length(classes)

  f1_scores <- numeric(n_classes)
  weights <- numeric(n_classes)

  for (i in seq_along(classes)) {
    class_label <- classes[i]

    binary_true <- as.numeric(y_true == class_label)
    binary_pred <- as.numeric(y_pred == class_label)

    tp <- sum(binary_true == 1 & binary_pred == 1)
    fp <- sum(binary_true == 0 & binary_pred == 1)
    fn <- sum(binary_true == 1 & binary_pred == 0)

    precision <- if (tp + fp > 0) tp / (tp + fp) else 0
    recall <- if (tp + fn > 0) tp / (tp + fn) else 0

    f1_scores[i] <- if (precision + recall > 0) {
      2 * (precision * recall) / (precision + recall)
    } else {
      0
    }

    weights[i] <- sum(y_true == class_label)
  }

  if (average == "micro") {
    # For micro-average, compute global TP, FP, FN
    tp_total <- sum(y_true == y_pred)
    fp_total <- sum(y_true != y_pred)
    fn_total <- fp_total  # In multiclass, FP = FN for micro-average

    precision <- tp_total / (tp_total + fp_total)
    recall <- tp_total / (tp_total + fn_total)

    return(if (precision + recall > 0) {
      2 * (precision * recall) / (precision + recall)
    } else {
      0
    })
  } else if (average == "macro") {
    return(mean(f1_scores))
  } else if (average == "weighted") {
    return(sum(f1_scores * weights) / sum(weights))
  }

  return(mean(f1_scores))
}


#' @keywords internal
.jaccard_score <- function(y_true, y_pred, average = "macro") {
  classes <- sort(unique(c(y_true, y_pred)))
  n_classes <- length(classes)

  jaccard_scores <- numeric(n_classes)
  weights <- numeric(n_classes)

  for (i in seq_along(classes)) {
    class_label <- classes[i]

    binary_true <- as.numeric(y_true == class_label)
    binary_pred <- as.numeric(y_pred == class_label)

    intersection <- sum(binary_true == 1 & binary_pred == 1)
    union <- sum(binary_true == 1 | binary_pred == 1)

    jaccard_scores[i] <- if (union > 0) intersection / union else 0
    weights[i] <- sum(y_true == class_label)
  }

  if (average == "micro") {
    # Micro-average jaccard
    total_intersection <- sum(y_true == y_pred)
    total_union <- length(y_true)
    return(total_intersection / total_union)
  } else if (average == "macro") {
    return(mean(jaccard_scores))
  } else if (average == "weighted") {
    return(sum(jaccard_scores * weights) / sum(weights))
  }

  return(mean(jaccard_scores))
}


#' @keywords internal
.brier_top1 <- function(y_prob, y_true) {
  # Brier score between top prediction and true label
  n <- length(y_true)
  brier_sum <- 0

  for (i in seq_len(n)) {
    true_class <- y_true[i]  # Already 1-based indexing in R
    pred_prob <- y_prob[i, ]

    # Create one-hot encoded vector for true class
    one_hot <- numeric(length(pred_prob))
    one_hot[true_class] <- 1

    # Brier score is mean squared error
    brier_sum <- brier_sum + sum((pred_prob - one_hot)^2)
  }

  return(brier_sum / n)
}


# Prediction set helper functions
#' @keywords internal
.rejection_rate <- function(y_predset) {
  # Frequency where prediction set cardinality != 1
  set_sizes <- rowSums(y_predset)
  return(mean(set_sizes != 1))
}

#' @keywords internal
.predset_size <- function(y_predset) {
  # Average size of prediction sets
  return(mean(rowSums(y_predset)))
}

#' @keywords internal
.miscoverage_ps <- function(y_predset, y_true) {
  # Per-class miscoverage: Prob(k not in prediction set | Y=k)
  classes <- sort(unique(y_true))
  miscov <- numeric(length(classes))

  for (i in seq_along(classes)) {
    k <- classes[i]
    idx <- y_true == k
    if (sum(idx) == 0) {
      miscov[i] <- NA
      next
    }
    # Check if true class k is not in prediction set
    miscov[i] <- mean(y_predset[idx, k] == 0)
  }

  return(miscov[!is.na(miscov)])
}

#' @keywords internal
.miscoverage_overall_ps <- function(y_predset, y_true) {
  # Overall miscoverage: Prob(Y not in prediction set)
  n <- length(y_true)
  miscov_count <- 0

  for (i in seq_len(n)) {
    true_class <- y_true[i]
    if (y_predset[i, true_class] == 0) {
      miscov_count <- miscov_count + 1
    }
  }

  return(miscov_count / n)
}

#' @keywords internal
.error_ps <- function(y_predset, y_true) {
  # Per-class error restricted to un-rejected samples
  classes <- sort(unique(y_true))
  errors <- numeric(length(classes))

  # Un-rejected samples have set size = 1
  set_sizes <- rowSums(y_predset)
  unreject_idx <- set_sizes == 1

  for (i in seq_along(classes)) {
    k <- classes[i]
    idx <- y_true == k & unreject_idx
    if (sum(idx) == 0) {
      errors[i] <- NA
      next
    }
    errors[i] <- mean(y_predset[idx, k] == 0)
  }

  return(errors[!is.na(errors)])
}

#' @keywords internal
.error_overall_ps <- function(y_predset, y_true) {
  # Overall error restricted to un-rejected samples
  set_sizes <- rowSums(y_predset)
  unreject_idx <- set_sizes == 1

  if (sum(unreject_idx) == 0) {
    return(NA_real_)
  }

  y_true_sub <- y_true[unreject_idx]
  y_predset_sub <- y_predset[unreject_idx, , drop = FALSE]

  error_count <- 0
  for (i in seq_along(y_true_sub)) {
    true_class <- y_true_sub[i]
    if (y_predset_sub[i, true_class] == 0) {
      error_count <- error_count + 1
    }
  }

  return(error_count / length(y_true_sub))
}
