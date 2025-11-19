# Multilabel Classification Metrics

A configurable evaluator for **multilabel classification** tasks, where
each sample can belong to multiple classes simultaneously. The function
computes various discrimination metrics commonly used for multilabel
problems.

Supported `metrics` names:

- **"accuracy"** – Subset accuracy (exact match ratio)

- **"hamming_loss"** – Hamming loss (fraction of incorrect labels)

- **"f1_micro"** – F1 score, micro averaged across all labels

- **"f1_macro"** – F1 score, macro averaged across labels

- **"f1_weighted"** – F1 score, weighted averaged by label support

- **"f1_samples"** – F1 score, averaged across samples

- **"precision_micro"** – Precision, micro averaged

- **"precision_macro"** – Precision, macro averaged

- **"precision_weighted"** – Precision, weighted averaged

- **"precision_samples"** – Precision, averaged across samples

- **"recall_micro"** – Recall, micro averaged

- **"recall_macro"** – Recall, macro averaged

- **"recall_weighted"** – Recall, weighted averaged

- **"recall_samples"** – Recall, averaged across samples

- **"jaccard_micro"** – Jaccard index, micro averaged

- **"jaccard_macro"** – Jaccard index, macro averaged

- **"jaccard_weighted"** – Jaccard index, weighted averaged

- **"jaccard_samples"** – Jaccard index, averaged across samples

- **"roc_auc_micro"** – ROC AUC, micro averaged (requires y_prob)

- **"roc_auc_macro"** – ROC AUC, macro averaged (requires y_prob)

- **"roc_auc_weighted"** – ROC AUC, weighted averaged (requires y_prob)

- **"roc_auc_samples"** – ROC AUC, averaged across samples (requires
  y_prob)

- **"pr_auc_micro"** – PR AUC, micro averaged (requires y_prob)

- **"pr_auc_macro"** – PR AUC, macro averaged (requires y_prob)

- **"pr_auc_weighted"** – PR AUC, weighted averaged (requires y_prob)

- **"pr_auc_samples"** – PR AUC, averaged across samples (requires
  y_prob)

## Usage

``` r
multilabel_metrics_fn(y_true, y_prob, metrics = NULL, threshold = 0.5)
```

## Arguments

- y_true:

  Binary matrix or data frame of ground‑truth labels with shape
  (n_samples, n_labels), where 1 indicates presence and 0 indicates
  absence.

- y_prob:

  Numeric matrix of predicted probabilities with shape (n_samples,
  n_labels). Will be converted to binary predictions using threshold.

- metrics:

  Character vector listing which metrics to compute. Default is
  `c("accuracy", "f1_micro", "f1_macro")`.

- threshold:

  Numeric threshold for converting probabilities to binary predictions.
  Default is 0.5.

## Value

Named numeric vector with one element per requested metric.

## Examples

``` r
set.seed(42)
n <- 100
k <- 5
y_true <- matrix(rbinom(n * k, 1, 0.3), nrow = n, ncol = k)
y_prob <- matrix(runif(n * k), nrow = n, ncol = k)
multilabel_metrics_fn(y_true, y_prob, metrics = c("accuracy", "f1_micro"))
#>  accuracy  f1_micro 
#> 0.0400000 0.3264249 
```
