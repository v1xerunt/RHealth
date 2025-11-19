# ConCare Model Class

ConCare model for personalized clinical feature embedding.

## Usage

``` r
ConCare(
  dataset = NULL,
  embedding_dim = 128,
  hidden_dim = 128,
  num_head = 4,
  pe_hidden = 64,
  dropout = 0.5
)
```

## Arguments

- dataset:

  A `SampleDataset` object providing input/output schema

- embedding_dim:

  Integer, embedding dimension. Default 128

- hidden_dim:

  Integer, hidden dimension. Default 128

- num_head:

  Integer, number of attention heads. Default 4

- pe_hidden:

  Integer, positional encoding hidden dimension. Default 64

- dropout:

  Numeric, dropout rate. Default 0.5

## Details

Paper: Ma et al. "ConCare: Personalized clinical feature embedding via
capturing the healthcare context." AAAI 2020.

This model uses channel-wise GRU and contextualized attention to capture
personalized healthcare contexts and feature correlations.
