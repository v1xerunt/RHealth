# RNN Model Class

A full‑featured classification model that (i) embeds each input feature
with `EmbeddingModel`, (ii) processes each feature sequence through its
own `RNNLayer`, and (iii) concatenates the final hidden states for
prediction.

## Usage

``` r
RNN(dataset = NULL, embedding_dim = 128, hidden_dim = 128, ...)
```

## Arguments

- dataset:

  A `SampleDataset` object providing input/output schema.

- embedding_dim:

  Integer, embedding width for each token. Default 128.

- hidden_dim:

  Integer, hidden size of each RNN. Default 128.

- ...:

  Additional arguments forwarded to each `RNNLayer` (except
  `input_size`/`hidden_size`, which are fixed by `embedding_dim` /
  `hidden_dim`).

## Details

- Works for binary, multi‑class, or regression labels (inferred from
  `dataset`).

- Supports optional `mask` per feature (all‑zero rows are treated as
  padding).

- All internal indices comply with R's 1‑based rule; no device
  mismatches.
