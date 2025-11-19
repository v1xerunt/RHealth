# Binary Label Processor

Processor for binary classification labels. Supports numeric (0/1),
logical (TRUE/FALSE), or categorical binary labels.

## Super classes

[`RHealth::Processor`](https://v1xerunt.github.io/RHealth/reference/Processor.md)
-\>
[`RHealth::FeatureProcessor`](https://v1xerunt.github.io/RHealth/reference/FeatureProcessor.md)
-\> `BinaryLabelProcessor`

## Public fields

- `label_vocab`:

  A named integer vector representing label-to-index mapping.

## Methods

### Public methods

- [`BinaryLabelProcessor$new()`](#method-BinaryLabelProcessor-new)

- [`BinaryLabelProcessor$fit()`](#method-BinaryLabelProcessor-fit)

- [`BinaryLabelProcessor$process()`](#method-BinaryLabelProcessor-process)

- [`BinaryLabelProcessor$size()`](#method-BinaryLabelProcessor-size)

- [`BinaryLabelProcessor$print()`](#method-BinaryLabelProcessor-print)

- [`BinaryLabelProcessor$clone()`](#method-BinaryLabelProcessor-clone)

Inherited methods

- [`RHealth::Processor$load()`](https://v1xerunt.github.io/RHealth/reference/Processor.html#method-load)
- [`RHealth::Processor$save()`](https://v1xerunt.github.io/RHealth/reference/Processor.html#method-save)

------------------------------------------------------------------------

### Method `new()`

Initialize the processor with empty vocabulary.

#### Usage

    BinaryLabelProcessor$new()

------------------------------------------------------------------------

### Method `fit()`

Fit the processor by analyzing all unique labels in the dataset.

#### Usage

    BinaryLabelProcessor$fit(samples, field)

#### Arguments

- `samples`:

  A list of named lists (samples).

- `field`:

  The name of the label field to process.

------------------------------------------------------------------------

### Method `process()`

Process a label into a torch tensor `[0]` or `[1]`.

#### Usage

    BinaryLabelProcessor$process(value)

#### Arguments

- `value`:

  A single label value.

#### Returns

A float32 torch tensor of shape `1`.

------------------------------------------------------------------------

### Method `size()`

Return the output dimensionality (fixed at 1).

#### Usage

    BinaryLabelProcessor$size()

#### Returns

Integer 1

------------------------------------------------------------------------

### Method [`print()`](https://rdrr.io/r/base/print.html)

Print a summary of the processor.

#### Usage

    BinaryLabelProcessor$print(...)

#### Arguments

- `...`:

  Ignored.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    BinaryLabelProcessor$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
