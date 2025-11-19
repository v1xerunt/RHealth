# Raw Processor

Processor that returns raw values without any transformation. Inherits
from FeatureProcessor.

## Super classes

[`RHealth::Processor`](https://v1xerunt.github.io/RHealth/reference/Processor.md)
-\>
[`RHealth::FeatureProcessor`](https://v1xerunt.github.io/RHealth/reference/FeatureProcessor.md)
-\> `RawProcessor`

## Methods

### Public methods

- [`RawProcessor$process()`](#method-RawProcessor-process)

- [`RawProcessor$size()`](#method-RawProcessor-size)

- [`RawProcessor$print()`](#method-RawProcessor-print)

- [`RawProcessor$clone()`](#method-RawProcessor-clone)

Inherited methods

- [`RHealth::Processor$load()`](https://v1xerunt.github.io/RHealth/reference/Processor.html#method-load)
- [`RHealth::Processor$save()`](https://v1xerunt.github.io/RHealth/reference/Processor.html#method-save)
- [`RHealth::FeatureProcessor$fit()`](https://v1xerunt.github.io/RHealth/reference/FeatureProcessor.html#method-fit)

------------------------------------------------------------------------

### Method `process()`

Return the raw input as-is.

#### Usage

    RawProcessor$process(value)

#### Arguments

- `value`:

  A raw field value (any type).

#### Returns

The unmodified input.

------------------------------------------------------------------------

### Method `size()`

Optional: Return size/dimension of processed output.

#### Usage

    RawProcessor$size()

#### Returns

NULL

------------------------------------------------------------------------

### Method [`print()`](https://rdrr.io/r/base/print.html)

Print a string representation of the processor.

#### Usage

    RawProcessor$print(...)

#### Arguments

- `...`:

  Ignored.

#### Returns

A character string

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    RawProcessor$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
