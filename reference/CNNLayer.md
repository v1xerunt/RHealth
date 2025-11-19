# CNNLayer Class

Stack of CNN blocks with adaptive pooling.

## Usage

``` r
CNNLayer(input_size, hidden_size, num_layers = 1, spatial_dim = 1)
```

## Arguments

- input_size:

  Number of input channels

- hidden_size:

  Number of hidden channels

- num_layers:

  Number of CNN blocks. Default 1

- spatial_dim:

  Spatial dimensionality (1, 2, or 3). Default 1

## Details

Stacks multiple CNN blocks and applies adaptive average pooling at the
end. Supports 1D, 2D, and 3D spatial dimensions.
