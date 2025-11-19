# SampleProcessor: Processor for sample-level transformations

Optional processor for transformations applied at the whole-sample level
(e.g., normalizing an image+label pair).

## Super class

[`RHealth::Processor`](https://v1xerunt.github.io/RHealth/reference/Processor.md)
-\> `SampleProcessor`

## Methods

### Public methods

- [`SampleProcessor$process()`](#method-SampleProcessor-process)

- [`SampleProcessor$clone()`](#method-SampleProcessor-clone)

Inherited methods

- [`RHealth::Processor$load()`](https://v1xerunt.github.io/RHealth/reference/Processor.html#method-load)
- [`RHealth::Processor$save()`](https://v1xerunt.github.io/RHealth/reference/Processor.html#method-save)

------------------------------------------------------------------------

### Method `process()`

Abstract method: Process a single sample (a named list).

#### Usage

    SampleProcessor$process(sample)

#### Arguments

- `sample`:

  A named list representing one data sample.

#### Returns

A processed named list.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    SampleProcessor$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
