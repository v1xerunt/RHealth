# EmbeddingModel

EmbeddingModel is responsible for creating embedding layers for
different types of input data.

Initialize an EmbeddingModel by constructing embedding layers based on
input processors.

Perform a forward pass by computing embeddings (or passing through) for
each field. This method takes `inputs`, a named list of `torch_tensor`
objects, with names matching dataset\$input_processors.

Return a concise string representation of the EmbeddingModel, listing
its embedding layers.

## Usage

``` r
EmbeddingModel(dataset, embedding_dim = 128)
```

## Arguments

- dataset:

  A SampleDataset object containing input_processors.

- embedding_dim:

  Integer embedding dimension. Default is 128.

## Value

An `EmbeddingModel` object that inherits from `BaseModel`.

None (initializes fields inside the object).

A named list of `torch_tensor` objects after embedding (or passthrough).

A character string representation.

## Details

Inherits from BaseModel. For each entry in `dataset$input_processors`,
if the processor is a `SequenceProcessor`, an embedding layer
(`nn_embedding`) is created; if it is a `TimeseriesProcessor`, a linear
layer (`nn_linear`) is created. During the forward pass, each input
tensor is moved to the model’s device; if an embedding layer exists for
that field, it is applied to the tensor. Otherwise, the tensor is passed
through unchanged.

## Fields

- `embedding_layers`:

  A `nn_module_dict` of submodules, one embedding (or linear) layer per
  field.

## Examples

``` r
if (FALSE) { # \dontrun{
# Assume `my_dataset` is a SampleDataset with input_processors that includes
# SequenceProcessor and/or TimeseriesProcessor instances.

model <- EmbeddingModel(dataset = my_dataset, embedding_dim = 128)
# Suppose `inputs` is a named list of torch tensors, e.g.:
inputs <- list(
  sequence_field   = torch_tensor(matrix(sample(1:100, 16), nrow = 4, ncol = 4)),
  timeseries_field = torch_tensor(matrix(rnorm(20), nrow = 5, ncol = 4))
)
outputs <- model(inputs)
# `outputs` is a named list of embedded tensors:
#   - For “sequence_field”, a tensor of shape (batch_size, seq_len, embedding_dim)
#   - For “timeseries_field”, a tensor of shape (batch_size, embedding_dim)
} # }
```
