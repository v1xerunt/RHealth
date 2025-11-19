# CNNBlock Class

Convolutional neural network block with residual connection.

## Usage

``` r
CNNBlock(in_channels, out_channels, spatial_dim)
```

## Arguments

- in_channels:

  Number of input channels

- out_channels:

  Number of output channels

- spatial_dim:

  Spatial dimensionality (1, 2, or 3)

## Details

Implements a residual CNN block with two convolutional layers, batch
normalization, and ReLU activation. Supports 1D, 2D, and 3D
convolutions.
