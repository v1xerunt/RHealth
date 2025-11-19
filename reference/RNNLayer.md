# RNNLayer Class

Recurrent neural network layer (GRU/LSTM/RNN) with built‑in
1‑based‑index safety, masking, dropout, bidirectionality and a learnable
fallback hidden vector for empty sequences.

## Usage

``` r
RNNLayer(
  input_size,
  hidden_size,
  rnn_type = "GRU",
  num_layers = 1,
  dropout = 0.5,
  bidirectional = FALSE
)
```

## Arguments

- input_size:

  The number of expected features in the input `x`

- hidden_size:

  The number of features in the hidden state `h`

- rnn_type:

  Character, one of "GRU", "LSTM", or "RNN". Default "GRU".

- num_layers:

  Number of recurrent layers. E.g., setting `num_layers=2` would mean
  stacking two GRUs together to form a `stacked GRU`, with the second
  GRU taking in outputs of the first GRU and computing the final
  results. Default: 1

- dropout:

  If non-zero, introduces a `Dropout` layer on the outputs of each GRU
  layer except the last layer, with dropout probability equal to
  `dropout`. Default: 0

- bidirectional:

  If `TRUE`, becomes a bidirectional GRU. Default: `FALSE`

## Details

**Key design points**

- Accepts `mask` indicating valid time steps (1‑based indexing
  respected).

- Uses `pack_padded_sequence` + `pad_packed_sequence` for efficiency.

- Samples whose sequence length is *zero* (all‑zero rows) are skipped
  during RNN computation **and** later filled with a learnable parameter
  `null_hidden` so downstream layers always receive a hidden vector.

- Works for unidirectional or bidirectional networks. In the
  bidirectional case, the last hidden state is built from the **forward
  last step** and the **backward first step**, then projected back to
  `hidden_size`.
