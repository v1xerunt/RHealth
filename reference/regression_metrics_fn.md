# Regression Metrics

A configurable evaluator for **regression** tasks. The function computes
various regression metrics, particularly useful for reconstruction tasks
(e.g., autoencoders). Reproduces the behaviour of Python's
`regression_metrics_fn`.

Supported `metrics` names:

- **"kl_divergence"** – Kullback-Leibler divergence

- **"mse"** – Mean Squared Error

- **"mae"** – Mean Absolute Error

## Usage

``` r
regression_metrics_fn(x, x_rec, metrics = NULL)
```

## Arguments

- x:

  Numeric vector, matrix, or torch tensor of true target data sample.

- x_rec:

  Numeric vector, matrix, or torch tensor of reconstructed data sample.

- metrics:

  Character vector listing which metrics to compute. Default is
  `c("kl_divergence", "mse", "mae")`.

## Value

Named numeric vector with one element per requested metric.

## Examples

``` r
set.seed(42)
x <- runif(1000)
x_rec <- runif(1000)
regression_metrics_fn(x, x_rec, metrics = c("mse", "mae"))
#>       mse       mae 
#> 0.1726048 0.3409409 
```
