# Multiclass Classification Metrics

A configurable evaluator for **multiclass classification** tasks. The
function reproduces the behaviour of Python's `multiclass_metrics_fn`,
covering classical discrimination metrics (ROC‑AUC with various
averaging strategies, F1, accuracy, …) as well as calibration metrics
(ECE / adaptive ECE / classwise ECE).

Supported `metrics` names:

- **"roc_auc_macro_ovo"** – ROC AUC, macro averaged over one-vs-one

- **"roc_auc_macro_ovr"** – ROC AUC, macro averaged over one-vs-rest

- **"roc_auc_weighted_ovo"** – ROC AUC, weighted averaged over
  one-vs-one

- **"roc_auc_weighted_ovr"** – ROC AUC, weighted averaged over
  one-vs-rest

- **"accuracy"** – Overall accuracy

- **"balanced_accuracy"** – Balanced accuracy (useful for imbalanced
  datasets)

- **"f1_micro"** – F1 score, micro averaged

- **"f1_macro"** – F1 score, macro averaged

- **"f1_weighted"** – F1 score, weighted averaged

- **"jaccard_micro"** – Jaccard index, micro averaged

- **"jaccard_macro"** – Jaccard index, macro averaged

- **"jaccard_weighted"** – Jaccard index, weighted averaged

- **"cohen_kappa"** – Cohen's κ

- **"brier_top1"** – Brier score between top prediction and true label

- **"ECE"** – Expected Calibration Error (equal‑width bins)

- **"ECE_adapt"** – Adaptive ECE (equal‑size bins)

- **"cwECEt"** – Classwise ECE with threshold

- **"cwECEt_adapt"** – Classwise adaptive ECE with threshold

- **"hits@n"** – Computes HITS@1, HITS@5, HITS@10

- **"mean_rank"** – Computes mean rank and mean reciprocal rank

## Usage

``` r
multiclass_metrics_fn(y_true, y_prob, metrics = NULL, y_predset = NULL)
```

## Arguments

- y_true:

  Numeric or integer vector of ground‑truth labels (1, 2, ..., K) using
  R's 1-based indexing.

- y_prob:

  Numeric matrix of predicted probabilities with shape (n_samples,
  n_classes).

- metrics:

  Character vector listing which metrics to compute. Default is
  `c("accuracy", "f1_macro", "f1_micro")`.

- y_predset:

  Optional matrix for prediction set metrics. Default is NULL.

## Value

Named numeric vector with one element per requested metric.

## Examples

``` r
set.seed(42)
n <- 100
k <- 4
y_true <- sample(1:k, n, replace = TRUE)
y_prob <- matrix(runif(n * k), nrow = n, ncol = k)
y_prob <- y_prob / rowSums(y_prob)  # normalize to sum to 1
multiclass_metrics_fn(y_true, y_prob, metrics = c("accuracy", "f1_macro"))
#>  accuracy  f1_macro 
#> 0.2100000 0.2047787 
```
