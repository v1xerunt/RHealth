# Expected Calibration Error for Binary Classification

Calculates **Expected Calibration Error (ECE)** or **Adaptive ECE** for
a binary classifier, reproducing the behaviour of
`pyhealth.metrics.calibration.ece_confidence_binary`.

## Usage

``` r
ece_confidence_binary(prob, label, bins = 20L, adaptive = FALSE)
```

## Arguments

- prob:

  Numeric vector **or** two-column matrix \\ containing predicted
  probabilities for the *positive* class (only the first column is used
  if a matrix is supplied).

- label:

  Numeric vector **or** two-column matrix of true labels \\ encoded as
  `0/1` (only the first column is used if a matrix is supplied).

- bins:

  Integer. Number of bins (default 20).

- adaptive:

  Logical. If `FALSE` (default) equal-width bins \\ spanning `0, 1` are
  used; if `TRUE` each bin contains the \\ same number of samples
  (equal-size bins).

## Value

A single numeric value – the (adaptive) ECE.

## Examples

``` r
set.seed(1)
p  <- runif(1e4)          # predicted probabilities
y  <- rbinom(1e4, 1, 0.4) # ground-truth labels
ece_confidence_binary(p, y)             # standard ECE
#> [1] 0.2618338
ece_confidence_binary(p, y, adaptive=TRUE)  # adaptive ECE
#> [1] 0.261506
```
