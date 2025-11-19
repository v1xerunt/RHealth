# FinalAttentionQKV Class

Final attention layer using query, key, value mechanism.

## Usage

``` r
FinalAttentionQKV(
  attention_input_dim,
  attention_hidden_dim,
  attention_type = "add",
  dropout = 0.5
)
```

## Arguments

- attention_input_dim:

  Input dimensionality

- attention_hidden_dim:

  Hidden dimensionality

- attention_type:

  Type of attention ("add", "mul", "concat"). Default "add"

- dropout:

  Dropout rate. Default 0.5

## Details

Computes attention weights for the final aggregation of temporal
representations.
