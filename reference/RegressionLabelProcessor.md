# Regression Label Processor

Processor for scalar regression labels. Converts values to a 1D float
tensor.

## Super classes

[`RHealth::Processor`](https://v1xerunt.github.io/RHealth/reference/Processor.md)
-\>
[`RHealth::FeatureProcessor`](https://v1xerunt.github.io/RHealth/reference/FeatureProcessor.md)
-\> `RegressionLabelProcessor`

## Methods

### Public methods

- [`RegressionLabelProcessor$process()`](#method-RegressionLabelProcessor-process)

- [`RegressionLabelProcessor$size()`](#method-RegressionLabelProcessor-size)

- [`RegressionLabelProcessor$print()`](#method-RegressionLabelProcessor-print)

- [`RegressionLabelProcessor$clone()`](#method-RegressionLabelProcessor-clone)

Inherited methods

- [`RHealth::Processor$load()`](https://v1xerunt.github.io/RHealth/reference/Processor.html#method-load)
- [`RHealth::Processor$save()`](https://v1xerunt.github.io/RHealth/reference/Processor.html#method-save)
- [`RHealth::FeatureProcessor$fit()`](https://v1xerunt.github.io/RHealth/reference/FeatureProcessor.html#method-fit)

------------------------------------------------------------------------

### Method `process()`

Process a numeric label into a single-element float tensor.

#### Usage

    RegressionLabelProcessor$process(value)

#### Arguments

- `value`:

  A numeric value.

#### Returns

A torch tensor of shape `[1]`.

------------------------------------------------------------------------

### Method `size()`

Return the size of the processed label (always 1).

#### Usage

    RegressionLabelProcessor$size()

#### Returns

Integer `1`

------------------------------------------------------------------------

### Method [`print()`](https://rdrr.io/r/base/print.html)

Print a string representation.

#### Usage

    RegressionLabelProcessor$print(...)

#### Arguments

- `...`:

  Ignored.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    RegressionLabelProcessor$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
