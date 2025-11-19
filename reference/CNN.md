# CNN Model Class

Convolutional neural network model for healthcare prediction tasks. Each
feature is embedded and processed through independent CNN layers. The
pooled representations are concatenated for final prediction.

## Usage

``` r
CNN(dataset = NULL, embedding_dim = 128, hidden_dim = 128, num_layers = 1)
```

## Arguments

- dataset:

  A `SampleDataset` object providing input/output schema

- embedding_dim:

  Integer, embedding dimension. Default 128

- hidden_dim:

  Integer, number of CNN channels. Default 128

- num_layers:

  Integer, number of CNN blocks. Default 1

## Details

- Supports binary, multi-class, and regression tasks

- Each feature has its own CNN encoder

- Handles sequence, timeseries, and tensor inputs

- Automatically determines spatial dimensions based on processor type
