# Multi-Label Processor

Processor for multi-label classification. Converts a list of active
labels into a one-hot tensor with multiple 1s. Inherits from
FeatureProcessor.

## Super classes

[`RHealth::Processor`](https://v1xerunt.github.io/RHealth/reference/Processor.md)
-\>
[`RHealth::FeatureProcessor`](https://v1xerunt.github.io/RHealth/reference/FeatureProcessor.md)
-\> `MultiLabelProcessor`

## Public fields

- `label_vocab`:

  A named integer vector mapping label values to index positions.

## Methods

### Public methods

- [`MultiLabelProcessor$new()`](#method-MultiLabelProcessor-new)

- [`MultiLabelProcessor$fit()`](#method-MultiLabelProcessor-fit)

- [`MultiLabelProcessor$process()`](#method-MultiLabelProcessor-process)

- [`MultiLabelProcessor$size()`](#method-MultiLabelProcessor-size)

- [`MultiLabelProcessor$print()`](#method-MultiLabelProcessor-print)

- [`MultiLabelProcessor$clone()`](#method-MultiLabelProcessor-clone)

Inherited methods

- [`RHealth::Processor$load()`](https://v1xerunt.github.io/RHealth/reference/Processor.html#method-load)
- [`RHealth::Processor$save()`](https://v1xerunt.github.io/RHealth/reference/Processor.html#method-save)

------------------------------------------------------------------------

### Method `new()`

Constructor that initializes the vocabulary.

#### Usage

    MultiLabelProcessor$new()

------------------------------------------------------------------------

### Method `fit()`

Fit the processor from all multi-label lists across samples.

#### Usage

    MultiLabelProcessor$fit(samples, field)

#### Arguments

- `samples`:

  A list of named lists (sample records).

- `field`:

  The name of the multi-label field.

------------------------------------------------------------------------

### Method `process()`

Process a list of active labels into a one-hot float tensor.

#### Usage

    MultiLabelProcessor$process(value)

#### Arguments

- `value`:

  A character or numeric vector of active labels.

#### Returns

A torch tensor of shape `num_classes` with 0s and 1s.

------------------------------------------------------------------------

### Method `size()`

Return number of classes.

#### Usage

    MultiLabelProcessor$size()

#### Returns

Integer.

------------------------------------------------------------------------

### Method [`print()`](https://rdrr.io/r/base/print.html)

Print a summary of the processor.

#### Usage

    MultiLabelProcessor$print(...)

#### Arguments

- `...`:

  Ignored.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    MultiLabelProcessor$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
