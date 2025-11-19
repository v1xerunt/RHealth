# ConCareLayer Class

ConCare layer for personalized clinical feature embedding.

## Usage

``` r
ConCareLayer(
  input_dim,
  static_dim = 0,
  hidden_dim = 128,
  num_head = 4,
  pe_hidden = 64,
  dropout = 0.5
)
```

## Arguments

- input_dim:

  Dynamic feature size

- static_dim:

  Static feature size. Default 0 (no static features)

- hidden_dim:

  Hidden dimension. Default 128

- num_head:

  Number of attention heads. Default 4

- pe_hidden:

  Positional encoding hidden dimension. Default 64

- dropout:

  Dropout rate. Default 0.5

## Details

Paper: Ma et al. "ConCare: Personalized clinical feature embedding via
capturing the healthcare context." AAAI 2020.

This layer uses channel-wise GRU and multi-head attention to capture
feature-level and temporal dependencies in clinical data.
