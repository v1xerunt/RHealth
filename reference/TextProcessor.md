# Text Processor

Processor for textual input. Inherits from FeatureProcessor and defines
a minimal no-op process method.

## Super classes

[`RHealth::Processor`](https://v1xerunt.github.io/RHealth/reference/Processor.md)
-\>
[`RHealth::FeatureProcessor`](https://v1xerunt.github.io/RHealth/reference/FeatureProcessor.md)
-\> `TextProcessor`

## Methods

### Public methods

- [`TextProcessor$process()`](#method-TextProcessor-process)

- [`TextProcessor$size()`](#method-TextProcessor-size)

- [`TextProcessor$print()`](#method-TextProcessor-print)

- [`TextProcessor$clone()`](#method-TextProcessor-clone)

Inherited methods

- [`RHealth::Processor$load()`](https://v1xerunt.github.io/RHealth/reference/Processor.html#method-load)
- [`RHealth::Processor$save()`](https://v1xerunt.github.io/RHealth/reference/Processor.html#method-save)
- [`RHealth::FeatureProcessor$fit()`](https://v1xerunt.github.io/RHealth/reference/FeatureProcessor.html#method-fit)

------------------------------------------------------------------------

### Method `process()`

Process a raw text input. (Currently a no-op identity function.)

#### Usage

    TextProcessor$process(value)

#### Arguments

- `value`:

  A single text input (character string).

#### Returns

The processed text (same as input).

------------------------------------------------------------------------

### Method `size()`

Optional: Return size or dimensionality if applicable.

#### Usage

    TextProcessor$size()

#### Returns

NULL by default.

------------------------------------------------------------------------

### Method [`print()`](https://rdrr.io/r/base/print.html)

Return a printable string representation of the processor.

#### Usage

    TextProcessor$print(...)

#### Arguments

- `...`:

  Ignored.

#### Returns

A character string.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    TextProcessor$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
