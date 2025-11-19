# DatasetProcessor: Processor applied to entire datasets

Optional class for processing entire datasets in bulk (e.g., batch
statistics).

## Super class

[`RHealth::Processor`](https://v1xerunt.github.io/RHealth/reference/Processor.md)
-\> `DatasetProcessor`

## Methods

### Public methods

- [`DatasetProcessor$process()`](#method-DatasetProcessor-process)

- [`DatasetProcessor$clone()`](#method-DatasetProcessor-clone)

Inherited methods

- [`RHealth::Processor$load()`](https://v1xerunt.github.io/RHealth/reference/Processor.html#method-load)
- [`RHealth::Processor$save()`](https://v1xerunt.github.io/RHealth/reference/Processor.html#method-save)

------------------------------------------------------------------------

### Method `process()`

Abstract method: Process the entire dataset.

#### Usage

    DatasetProcessor$process(samples)

#### Arguments

- `samples`:

  A list of named lists representing all samples.

#### Returns

A processed list of named lists.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    DatasetProcessor$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
