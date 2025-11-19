# Binary Classification Metrics (Python‐style API)

A configurable evaluator for **binary classification** tasks. The
function reproduces the behaviour of Python’s `binary_metrics_fn`,
covering classical discrimination metrics (ROC‑AUC, F1, accuracy, …​) as
well as calibration metrics (ECE / adaptive ECE).

Supported `metrics` names:

- **"pr_auc"**  – Precision‑Recall area under the curve

- **"roc_auc"** – Receiver‑Operating‑Characteristic area under the curve

- **"accuracy"**, **"balanced_accuracy"**, **"f1"**, **"precision"**,
  **"recall"**

- **"cohen_kappa"** – Cohen’s κ

- **"jaccard"** – Jaccard index (intersection‑over‑union)

- **"ECE"** – Expected Calibration Error (equal‑width bins)

- **"ECE_adapt"** – Adaptive ECE (equal‑size bins)

## Usage

``` r
binary_metrics_fn(y_true, y_prob, metrics = NULL, threshold = 0.5)
```

## Arguments

- y_true:

  Numeric vector of ground‑truth labels (0 / 1).

- y_prob:

  Numeric vector of predicted probabilities for the positive class.

- metrics:

  Character vector listing which metrics to compute. Default is
  `c("pr_auc","roc_auc","f1")`.

- threshold:

  Numeric decision threshold used to convert probabilities to hard
  labels (`y_pred`). Default `0.5`.

## Value

Named numeric vector with one element per requested metric.

## Examples

``` r
set.seed(42)
y_true <- rbinom(100, 1, 0.4)
y_prob <- runif(100)
binary_metrics_fn(y_true, y_prob, metrics = c("accuracy", "ECE"))
#>  accuracy       ECE 
#> 0.5400000 0.3084428 
```
