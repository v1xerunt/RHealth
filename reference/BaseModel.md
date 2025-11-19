# BaseModel Class

Abstract base class for Torch models in R. This class handles dataset
schema parsing, output size calculation, loss function selection, and
probability conversion for evaluation.

Determines output size based on label processor and task mode. Only
supports single label key for now.

Selects appropriate loss function based on task type in output schema.

Converts logits into predicted probabilities for evaluation. Format
depends on task mode (sigmoid or softmax, or raw). This method takes
`logits` as input, which is a torch tensor with raw model outputs.

## Usage

``` r
BaseModel(dataset)
```

## Arguments

- dataset:

  A dataset object (must have input_schema, output_schema,
  output_processors).

## Value

Integer scalar representing the output dimension.

A function such as nnf_binary_cross_entropy_with_logits or
nnf_cross_entropy.

Torch tensor of probabilities.

## Fields

- `dataset`:

  A dataset object containing input/output schema and processors.

- `feature_keys`:

  Character vector of input feature names.

- `label_keys`:

  Character vector of output label names.

- `device`:

  Device (cpu or cuda) where the model is located.
