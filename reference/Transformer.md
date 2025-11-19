# Transformer Model Class

Transformer-based model for healthcare prediction tasks. Each feature is
embedded and processed through independent Transformer layers. The CLS
embeddings are concatenated for final prediction.

## Usage

``` r
Transformer(
  dataset = NULL,
  embedding_dim = 128,
  heads = 1,
  dropout = 0.5,
  num_layers = 1
)
```

## Arguments

- dataset:

  A `SampleDataset` object providing input/output schema

- embedding_dim:

  Integer, embedding dimension. Default 128

- heads:

  Integer, number of attention heads. Default 1

- dropout:

  Numeric, dropout rate. Default 0.5

- num_layers:

  Integer, number of transformer blocks. Default 1

## Details

- Supports binary, multi-class, and regression tasks

- Uses multi-head self-attention mechanisms

- Each feature has its own Transformer encoder stack

- CLS token embeddings are used for classification
