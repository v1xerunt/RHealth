# FeatureProcessor: Base class for all data processors

Abstract class for input/output processors used in `rhealth`. Subclass
this to define how raw values (e.g. timestamps, labels) are transformed
into model-ready tensors.

## Methods to override

- `process(value)`: Converts input value into tensor

- `size()`: Returns output dimensionality

## Super class

[`RHealth::Processor`](https://v1xerunt.github.io/RHealth/reference/Processor.md)
-\> `FeatureProcessor`

## Methods

### Public methods

- [`FeatureProcessor$fit()`](#method-FeatureProcessor-fit)

- [`FeatureProcessor$process()`](#method-FeatureProcessor-process)

- [`FeatureProcessor$clone()`](#method-FeatureProcessor-clone)

Inherited methods

- [`RHealth::Processor$load()`](https://v1xerunt.github.io/RHealth/reference/Processor.html#method-load)
- [`RHealth::Processor$save()`](https://v1xerunt.github.io/RHealth/reference/Processor.html#method-save)

------------------------------------------------------------------------

### Method `fit()`

Fit processor using field values across samples.

#### Usage

    FeatureProcessor$fit(samples, field)

#### Arguments

- `samples`:

  A list of named lists representing sample records.

- `field`:

  A string giving the field name to fit on.

------------------------------------------------------------------------

### Method `process()`

Abstract method: Process an individual field value.

#### Usage

    FeatureProcessor$process(value)

#### Arguments

- `value`:

  A raw value (e.g., character, number, etc).

#### Returns

A processed value.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    FeatureProcessor$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
