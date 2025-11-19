# Get Metrics Function

Returns appropriate metric function according to task mode.

## Usage

``` r
get_metrics_fn(mode)
```

## Arguments

- mode:

  Character. One of "binary", "multiclass", "multilabel", or
  "regression".

## Value

Function. Metrics calculation function.
