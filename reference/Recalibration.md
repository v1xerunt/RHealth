# Recalibration Class

Feature recalibration module using squeeze-and-excitation mechanism.

## Usage

``` r
Recalibration(channel, reduction = 9, activation = "sigmoid")
```

## Arguments

- channel:

  Number of input channels

- reduction:

  Reduction ratio for bottleneck. Default 9

- activation:

  Activation function ("sigmoid", "sparsemax", "softmax"). Default
  "sigmoid"

## Details

Adaptively recalibrates channel-wise feature responses by explicitly
modeling interdependencies between channels.
