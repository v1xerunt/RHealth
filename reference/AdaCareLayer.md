# AdaCareLayer Class

AdaCare layer for scale-adaptive feature extraction and recalibration.

## Usage

``` r
AdaCareLayer(
  input_dim,
  hidden_dim = 128,
  kernel_size = 2,
  kernel_num = 64,
  r_v = 4,
  r_c = 4,
  activation = "sigmoid",
  rnn_type = "gru",
  dropout = 0.5
)
```

## Arguments

- input_dim:

  Input feature dimensionality

- hidden_dim:

  Hidden dimension for GRU. Default 128

- kernel_size:

  Kernel size for causal convolutions. Default 2

- kernel_num:

  Number of kernels per scale. Default 64

- r_v:

  Reduction rate for input recalibration. Default 4

- r_c:

  Reduction rate for conv recalibration. Default 4

- activation:

  Activation for recalibration ("sigmoid", "sparsemax", "softmax").
  Default "sigmoid"

- rnn_type:

  Type of RNN ("gru" or "lstm"). Default "gru"

- dropout:

  Dropout rate. Default 0.5

## Details

Paper: Ma et al. "AdaCare: Explainable clinical health status
representation learning via scale-adaptive feature extraction and
recalibration." AAAI 2020.

This layer uses multi-scale causal convolutions with adaptive
recalibration to capture temporal patterns at different scales while
maintaining interpretability.
