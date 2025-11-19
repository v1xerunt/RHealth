# Sparsemax Class

Sparsemax activation function as an alternative to softmax.

## Usage

``` r
Sparsemax(dim = NULL)
```

## Arguments

- dim:

  Dimension along which to apply sparsemax. Default -1.

## Details

Produces sparse probability distributions, which can be beneficial for
interpretability by setting low-importance weights to exactly zero.
