# Abstract Processor Base Classes

Provides abstract base classes for three levels of data processing:
field-level (`FeatureProcessor`), sample-level (`SampleProcessor`), and
dataset-level (`DatasetProcessor`). Each processor inherits from a
common `Processor` base class which includes optional
[`save()`](https://rdrr.io/r/base/save.html) and
[`load()`](https://rdrr.io/r/base/load.html) methods.

Concrete implementations should inherit from these and override at least
the `process()` method.

## Methods

### Public methods

- [`Processor$save()`](#method-Processor-save)

- [`Processor$load()`](#method-Processor-load)

- [`Processor$clone()`](#method-Processor-clone)

------------------------------------------------------------------------

### Method [`save()`](https://rdrr.io/r/base/save.html)

Save processor state to disk (optional).

#### Usage

    Processor$save(path)

#### Arguments

- `path`:

  A string file path.

------------------------------------------------------------------------

### Method [`load()`](https://rdrr.io/r/base/load.html)

Load processor state from disk (optional).

#### Usage

    Processor$load(path)

#### Arguments

- `path`:

  A string file path.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    Processor$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
