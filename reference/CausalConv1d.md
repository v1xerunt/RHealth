# CausalConv1d Class

Causal 1D convolution layer with proper padding for temporal sequences.

## Usage

``` r
CausalConv1d(
  in_channels,
  out_channels,
  kernel_size,
  stride = 1,
  dilation = 1,
  groups = 1,
  bias = TRUE
)
```

## Arguments

- in_channels:

  (int): Number of channels in the input image

- out_channels:

  (int): Number of channels produced by the convolution

- kernel_size:

  (int or tuple): Size of the convolving kernel

- stride:

  (int or tuple, optional): Stride of the convolution. Default: 1

- dilation:

  (int or tuple, optional): Spacing between kernel elements. Default: 1

- groups:

  (int, optional): Number of blocked connections from input channels to
  output channels. Default: 1

- bias:

  (bool, optional): If `TRUE`, adds a learnable bias to the output.
  Default: `TRUE`

## Details

Ensures that the output at time t only depends on inputs up to time t,
maintaining the causal structure required for time series modeling.
