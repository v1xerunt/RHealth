# AdaCare Model Class (Version 2 - With Timeseries Support)

AdaCare model for explainable clinical health status representation
learning. Supports both code-based features (with embedding) and
timeseries features (direct).

## Usage

``` r
AdaCare(
  dataset = NULL,
  embedding_dim = 128,
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

- dataset:

  A `SampleDataset` object providing input/output schema

- embedding_dim:

  Integer, embedding dimension for code features. Default 128

- hidden_dim:

  Integer, hidden dimension for RNN. Default 128

- kernel_size:

  Integer, kernel size for convolutions. Default 2

- kernel_num:

  Integer, number of kernels per scale. Default 64

- r_v:

  Integer, reduction rate for input recalibration. Default 4

- r_c:

  Integer, reduction rate for conv recalibration. Default 4

- activation:

  Character, activation function. Default "sigmoid"

- rnn_type:

  Character, RNN type ("gru" or "lstm"). Default "gru"

- dropout:

  Numeric, dropout rate. Default 0.5

## Details

Paper: Ma et al. "AdaCare: Explainable clinical health status
representation learning via scale-adaptive feature extraction and
recalibration." AAAI 2020.

This model automatically detects feature types and processes them
appropriately:

- SequenceProcessor: Code-based features → Embedding → AdaCareLayer

- TimeseriesProcessor: Numerical features → AdaCareLayer (direct)

Returns attention weights for interpretability.
