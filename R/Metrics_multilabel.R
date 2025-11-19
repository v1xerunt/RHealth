#' @title Multilabel Classification Metrics
#' @description
#' A configurable evaluator for **multilabel classification** tasks, where each
#' sample can belong to multiple classes simultaneously. The function computes
#' various discrimination metrics commonly used for multilabel problems.
#'
#' Supported `metrics` names:
#' * **"accuracy"** – Subset accuracy (exact match ratio)
#' * **"hamming_loss"** – Hamming loss (fraction of incorrect labels)
#' * **"f1_micro"** – F1 score, micro averaged across all labels
#' * **"f1_macro"** – F1 score, macro averaged across labels
#' * **"f1_weighted"** – F1 score, weighted averaged by label support
#' * **"f1_samples"** – F1 score, averaged across samples
#' * **"precision_micro"** – Precision, micro averaged
#' * **"precision_macro"** – Precision, macro averaged
#' * **"precision_weighted"** – Precision, weighted averaged
#' * **"precision_samples"** – Precision, averaged across samples
#' * **"recall_micro"** – Recall, micro averaged
#' * **"recall_macro"** – Recall, macro averaged
#' * **"recall_weighted"** – Recall, weighted averaged
#' * **"recall_samples"** – Recall, averaged across samples
#' * **"jaccard_micro"** – Jaccard index, micro averaged
#' * **"jaccard_macro"** – Jaccard index, macro averaged
#' * **"jaccard_weighted"** – Jaccard index, weighted averaged
#' * **"jaccard_samples"** – Jaccard index, averaged across samples
#' * **"roc_auc_micro"** – ROC AUC, micro averaged (requires y_prob)
#' * **"roc_auc_macro"** – ROC AUC, macro averaged (requires y_prob)
#' * **"roc_auc_weighted"** – ROC AUC, weighted averaged (requires y_prob)
#' * **"roc_auc_samples"** – ROC AUC, averaged across samples (requires y_prob)
#' * **"pr_auc_micro"** – PR AUC, micro averaged (requires y_prob)
#' * **"pr_auc_macro"** – PR AUC, macro averaged (requires y_prob)
#' * **"pr_auc_weighted"** – PR AUC, weighted averaged (requires y_prob)
#' * **"pr_auc_samples"** – PR AUC, averaged across samples (requires y_prob)
#'
#' @param y_true Binary matrix or data frame of ground‑truth labels with shape
#'   (n_samples, n_labels), where 1 indicates presence and 0 indicates absence.
#' @param y_prob Numeric matrix of predicted probabilities with shape
#'   (n_samples, n_labels). Will be converted to binary predictions using threshold.
#' @param metrics Character vector listing which metrics to compute.  Default
#'   is `c("accuracy", "f1_micro", "f1_macro")`.
#' @param threshold Numeric threshold for converting probabilities to binary
#'   predictions. Default is 0.5.
#'
#' @return Named numeric vector with one element per requested metric.
#'
#' @examples
#' set.seed(42)
#' n <- 100
#' k <- 5
#' y_true <- matrix(rbinom(n * k, 1, 0.3), nrow = n, ncol = k)
#' y_prob <- matrix(runif(n * k), nrow = n, ncol = k)
#' multilabel_metrics_fn(y_true, y_prob, metrics = c("accuracy", "f1_micro"))
#'
#' @importFrom MLmetrics AUC PRAUC
#' @export
multilabel_metrics_fn <- function(y_true,
                                  y_prob,
                                  metrics = NULL,
                                  threshold = 0.5) {

  # Convert inputs to matrix
  if (inherits(y_true, "torch_tensor")) {
    y_true <- as.matrix(y_true$cpu())
  } else if (!is.matrix(y_true)) {
    y_true <- as.matrix(y_true)
  }

  # Convert y_prob to matrix and generate y_pred
  if (inherits(y_prob, "torch_tensor")) {
    y_prob <- as.matrix(y_prob$cpu())
  } else if (!is.matrix(y_prob)) {
    y_prob <- as.matrix(y_prob)
  }

  # Generate binary predictions from probabilities
  y_pred <- ifelse(y_prob >= threshold, 1, 0)

  stopifnot(nrow(y_true) == nrow(y_pred),
            ncol(y_true) == ncol(y_pred),
            all(y_true %in% c(0, 1)),
            all(y_pred %in% c(0, 1)))

  if (is.null(metrics)) {
    metrics <- c("accuracy", "f1_micro", "f1_macro")
  }

  n_samples <- nrow(y_true)
  n_labels <- ncol(y_true)
  out <- numeric(0)

  for (m in metrics) {
    if (m == "accuracy") {
      # Subset accuracy (exact match)
      out[m] <- mean(apply(y_true == y_pred, 1, all))
    } else if (m == "hamming_loss") {
      out[m] <- mean(y_true != y_pred)
    } else if (m == "f1_micro") {
      out[m] <- .multilabel_f1(y_true, y_pred, average = "micro")
    } else if (m == "f1_macro") {
      out[m] <- .multilabel_f1(y_true, y_pred, average = "macro")
    } else if (m == "f1_weighted") {
      out[m] <- .multilabel_f1(y_true, y_pred, average = "weighted")
    } else if (m == "f1_samples") {
      out[m] <- .multilabel_f1(y_true, y_pred, average = "samples")
    } else if (m == "precision_micro") {
      out[m] <- .multilabel_precision(y_true, y_pred, average = "micro")
    } else if (m == "precision_macro") {
      out[m] <- .multilabel_precision(y_true, y_pred, average = "macro")
    } else if (m == "precision_weighted") {
      out[m] <- .multilabel_precision(y_true, y_pred, average = "weighted")
    } else if (m == "precision_samples") {
      out[m] <- .multilabel_precision(y_true, y_pred, average = "samples")
    } else if (m == "recall_micro") {
      out[m] <- .multilabel_recall(y_true, y_pred, average = "micro")
    } else if (m == "recall_macro") {
      out[m] <- .multilabel_recall(y_true, y_pred, average = "macro")
    } else if (m == "recall_weighted") {
      out[m] <- .multilabel_recall(y_true, y_pred, average = "weighted")
    } else if (m == "recall_samples") {
      out[m] <- .multilabel_recall(y_true, y_pred, average = "samples")
    } else if (m == "jaccard_micro") {
      out[m] <- .multilabel_jaccard(y_true, y_pred, average = "micro")
    } else if (m == "jaccard_macro") {
      out[m] <- .multilabel_jaccard(y_true, y_pred, average = "macro")
    } else if (m == "jaccard_weighted") {
      out[m] <- .multilabel_jaccard(y_true, y_pred, average = "weighted")
    } else if (m == "jaccard_samples") {
      out[m] <- .multilabel_jaccard(y_true, y_pred, average = "samples")
    } else if (m %in% c("roc_auc_micro", "roc_auc_macro", "roc_auc_weighted", "roc_auc_samples")) {
      avg <- sub("roc_auc_", "", m)
      out[m] <- .multilabel_roc_auc(y_true, y_prob, average = avg)
    } else if (m %in% c("pr_auc_micro", "pr_auc_macro", "pr_auc_weighted", "pr_auc_samples")) {
      avg <- sub("pr_auc_", "", m)
      out[m] <- .multilabel_pr_auc(y_true, y_prob, average = avg)
    } else {
      stop(sprintf("Unknown metric for multilabel classification: %s", m))
    }
  }

  return(out)
}


# ============================================================================
# INTERNAL HELPER FUNCTIONS
# ============================================================================

#' @keywords internal
.multilabel_f1 <- function(y_true, y_pred, average = "macro") {
  if (average == "micro") {
    tp <- sum(y_true == 1 & y_pred == 1)
    fp <- sum(y_true == 0 & y_pred == 1)
    fn <- sum(y_true == 1 & y_pred == 0)

    precision <- if (tp + fp > 0) tp / (tp + fp) else 0
    recall <- if (tp + fn > 0) tp / (tp + fn) else 0

    return(if (precision + recall > 0) {
      2 * (precision * recall) / (precision + recall)
    } else {
      0
    })
  } else if (average == "samples") {
    # Average F1 across samples
    f1_per_sample <- numeric(nrow(y_true))
    for (i in seq_len(nrow(y_true))) {
      tp <- sum(y_true[i, ] == 1 & y_pred[i, ] == 1)
      fp <- sum(y_true[i, ] == 0 & y_pred[i, ] == 1)
      fn <- sum(y_true[i, ] == 1 & y_pred[i, ] == 0)

      prec <- if (tp + fp > 0) tp / (tp + fp) else 0
      rec <- if (tp + fn > 0) tp / (tp + fn) else 0

      f1_per_sample[i] <- if (prec + rec > 0) {
        2 * (prec * rec) / (prec + rec)
      } else {
        0
      }
    }
    return(mean(f1_per_sample))
  } else {
    # macro or weighted: average across labels
    f1_per_label <- numeric(ncol(y_true))
    support <- colSums(y_true)

    for (j in seq_len(ncol(y_true))) {
      tp <- sum(y_true[, j] == 1 & y_pred[, j] == 1)
      fp <- sum(y_true[, j] == 0 & y_pred[, j] == 1)
      fn <- sum(y_true[, j] == 1 & y_pred[, j] == 0)

      prec <- if (tp + fp > 0) tp / (tp + fp) else 0
      rec <- if (tp + fn > 0) tp / (tp + fn) else 0

      f1_per_label[j] <- if (prec + rec > 0) {
        2 * (prec * rec) / (prec + rec)
      } else {
        0
      }
    }

    if (average == "macro") {
      return(mean(f1_per_label))
    } else if (average == "weighted") {
      return(sum(f1_per_label * support) / sum(support))
    }
  }

  return(0)
}


#' @keywords internal
.multilabel_precision <- function(y_true, y_pred, average = "macro") {
  if (average == "micro") {
    tp <- sum(y_true == 1 & y_pred == 1)
    fp <- sum(y_true == 0 & y_pred == 1)
    return(if (tp + fp > 0) tp / (tp + fp) else 0)
  } else if (average == "samples") {
    prec_per_sample <- numeric(nrow(y_true))
    for (i in seq_len(nrow(y_true))) {
      tp <- sum(y_true[i, ] == 1 & y_pred[i, ] == 1)
      fp <- sum(y_true[i, ] == 0 & y_pred[i, ] == 1)
      prec_per_sample[i] <- if (tp + fp > 0) tp / (tp + fp) else 0
    }
    return(mean(prec_per_sample))
  } else {
    prec_per_label <- numeric(ncol(y_true))
    support <- colSums(y_true)

    for (j in seq_len(ncol(y_true))) {
      tp <- sum(y_true[, j] == 1 & y_pred[, j] == 1)
      fp <- sum(y_true[, j] == 0 & y_pred[, j] == 1)
      prec_per_label[j] <- if (tp + fp > 0) tp / (tp + fp) else 0
    }

    if (average == "macro") {
      return(mean(prec_per_label))
    } else if (average == "weighted") {
      return(sum(prec_per_label * support) / sum(support))
    }
  }

  return(0)
}


#' @keywords internal
.multilabel_recall <- function(y_true, y_pred, average = "macro") {
  if (average == "micro") {
    tp <- sum(y_true == 1 & y_pred == 1)
    fn <- sum(y_true == 1 & y_pred == 0)
    return(if (tp + fn > 0) tp / (tp + fn) else 0)
  } else if (average == "samples") {
    rec_per_sample <- numeric(nrow(y_true))
    for (i in seq_len(nrow(y_true))) {
      tp <- sum(y_true[i, ] == 1 & y_pred[i, ] == 1)
      fn <- sum(y_true[i, ] == 1 & y_pred[i, ] == 0)
      rec_per_sample[i] <- if (tp + fn > 0) tp / (tp + fn) else 0
    }
    return(mean(rec_per_sample))
  } else {
    rec_per_label <- numeric(ncol(y_true))
    support <- colSums(y_true)

    for (j in seq_len(ncol(y_true))) {
      tp <- sum(y_true[, j] == 1 & y_pred[, j] == 1)
      fn <- sum(y_true[, j] == 1 & y_pred[, j] == 0)
      rec_per_label[j] <- if (tp + fn > 0) tp / (tp + fn) else 0
    }

    if (average == "macro") {
      return(mean(rec_per_label))
    } else if (average == "weighted") {
      return(sum(rec_per_label * support) / sum(support))
    }
  }

  return(0)
}


#' @keywords internal
.multilabel_jaccard <- function(y_true, y_pred, average = "macro") {
  if (average == "micro") {
    intersection <- sum(y_true == 1 & y_pred == 1)
    union <- sum(y_true == 1 | y_pred == 1)
    return(if (union > 0) intersection / union else 0)
  } else if (average == "samples") {
    jacc_per_sample <- numeric(nrow(y_true))
    for (i in seq_len(nrow(y_true))) {
      intersection <- sum(y_true[i, ] == 1 & y_pred[i, ] == 1)
      union <- sum(y_true[i, ] == 1 | y_pred[i, ] == 1)
      jacc_per_sample[i] <- if (union > 0) intersection / union else 0
    }
    return(mean(jacc_per_sample))
  } else {
    jacc_per_label <- numeric(ncol(y_true))
    support <- colSums(y_true)

    for (j in seq_len(ncol(y_true))) {
      intersection <- sum(y_true[, j] == 1 & y_pred[, j] == 1)
      union <- sum(y_true[, j] == 1 | y_pred[, j] == 1)
      jacc_per_label[j] <- if (union > 0) intersection / union else 0
    }

    if (average == "macro") {
      return(mean(jacc_per_label))
    } else if (average == "weighted") {
      return(sum(jacc_per_label * support) / sum(support))
    }
  }

  return(0)
}


#' @keywords internal
.multilabel_roc_auc <- function(y_true, y_prob, average = "macro") {
  if (average == "micro") {
    # Flatten and compute single AUC
    y_true_flat <- as.vector(y_true)
    y_prob_flat <- as.vector(y_prob)

    if (length(unique(y_true_flat)) < 2) {
      warning("ROC AUC undefined: only one class present in micro-average")
      return(0)
    }

    tryCatch({
      return(MLmetrics::AUC(y_prob_flat, y_true_flat))
    }, error = function(e) {
      warning("ROC AUC calculation failed: ", e$message)
      return(0)
    })
  } else if (average == "samples") {
    # Not commonly used, but compute per-sample AUC
    warning("ROC AUC with 'samples' averaging is not well-defined for multilabel")
    return(NA_real_)
  } else {
    # macro or weighted: average across labels
    auc_per_label <- numeric(ncol(y_true))
    support <- colSums(y_true)

    for (j in seq_len(ncol(y_true))) {
      if (length(unique(y_true[, j])) < 2) {
        auc_per_label[j] <- NA
        next
      }

      tryCatch({
        auc_per_label[j] <- MLmetrics::AUC(y_prob[, j], y_true[, j])
      }, error = function(e) {
        auc_per_label[j] <- NA
      })
    }

    valid_idx <- !is.na(auc_per_label)
    if (sum(valid_idx) == 0) {
      return(0)
    }

    if (average == "macro") {
      return(mean(auc_per_label[valid_idx]))
    } else if (average == "weighted") {
      return(sum(auc_per_label[valid_idx] * support[valid_idx]) / sum(support[valid_idx]))
    }
  }

  return(0)
}


#' @keywords internal
.multilabel_pr_auc <- function(y_true, y_prob, average = "macro") {
  if (average == "micro") {
    # Flatten and compute single PR AUC
    y_true_flat <- as.vector(y_true)
    y_prob_flat <- as.vector(y_prob)

    if (length(unique(y_true_flat)) < 2) {
      warning("PR AUC undefined: only one class present in micro-average")
      return(0)
    }

    tryCatch({
      return(MLmetrics::PRAUC(y_prob_flat, y_true_flat))
    }, error = function(e) {
      warning("PR AUC calculation failed: ", e$message)
      return(0)
    })
  } else if (average == "samples") {
    warning("PR AUC with 'samples' averaging is not well-defined for multilabel")
    return(NA_real_)
  } else {
    # macro or weighted: average across labels
    prauc_per_label <- numeric(ncol(y_true))
    support <- colSums(y_true)

    for (j in seq_len(ncol(y_true))) {
      if (length(unique(y_true[, j])) < 2) {
        prauc_per_label[j] <- NA
        next
      }

      tryCatch({
        prauc_per_label[j] <- MLmetrics::PRAUC(y_prob[, j], y_true[, j])
      }, error = function(e) {
        prauc_per_label[j] <- NA
      })
    }

    valid_idx <- !is.na(prauc_per_label)
    if (sum(valid_idx) == 0) {
      return(0)
    }

    if (average == "macro") {
      return(mean(prauc_per_label[valid_idx]))
    } else if (average == "weighted") {
      return(sum(prauc_per_label[valid_idx] * support[valid_idx]) / sum(support[valid_idx]))
    }
  }

  return(0)
}
