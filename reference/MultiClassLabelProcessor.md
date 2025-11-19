# Multi-Class Label Processor

Processor for multi-class classification tasks. Converts string or
integer labels into integer indices, with one output per label.

## Super classes

[`RHealth::Processor`](https://v1xerunt.github.io/RHealth/reference/Processor.md)
-\>
[`RHealth::FeatureProcessor`](https://v1xerunt.github.io/RHealth/reference/FeatureProcessor.md)
-\> `MultiClassLabelProcessor`

## Public fields

- `label_vocab`:

  A named integer vector mapping labels to indices.

## Methods

### Public methods

- [`MultiClassLabelProcessor$new()`](#method-MultiClassLabelProcessor-new)

- [`MultiClassLabelProcessor$fit()`](#method-MultiClassLabelProcessor-fit)

- [`MultiClassLabelProcessor$process()`](#method-MultiClassLabelProcessor-process)

- [`MultiClassLabelProcessor$size()`](#method-MultiClassLabelProcessor-size)

- [`MultiClassLabelProcessor$print()`](#method-MultiClassLabelProcessor-print)

- [`MultiClassLabelProcessor$clone()`](#method-MultiClassLabelProcessor-clone)

Inherited methods

- [`RHealth::Processor$load()`](https://v1xerunt.github.io/RHealth/reference/Processor.html#method-load)
- [`RHealth::Processor$save()`](https://v1xerunt.github.io/RHealth/reference/Processor.html#method-save)

------------------------------------------------------------------------

### Method `new()`

Initialize with empty label vocabulary.

#### Usage

    MultiClassLabelProcessor$new()

------------------------------------------------------------------------

### Method `fit()`

Fit the label vocabulary from the given field of all samples.

#### Usage

    MultiClassLabelProcessor$fit(samples, field)

#### Arguments

- `samples`:

  A list of named lists representing the dataset.

- `field`:

  The name of the field containing labels.

------------------------------------------------------------------------

### Method `process()`

Convert a label into a torch long integer tensor (scalar).

#### Usage

    MultiClassLabelProcessor$process(value)

#### Arguments

- `value`:

  The raw label value.

#### Returns

An int64 torch tensor.

------------------------------------------------------------------------

### Method `size()`

Return number of classes (vocabulary size).

#### Usage

    MultiClassLabelProcessor$size()

#### Returns

Integer

------------------------------------------------------------------------

### Method [`print()`](https://rdrr.io/r/base/print.html)

Print a summary of the processor.

Print a summary of the processor.

#### Usage

    MultiClassLabelProcessor$print(...)

#### Arguments

- `...`:

  Ignored.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    MultiClassLabelProcessor$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
