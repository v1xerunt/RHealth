# DatasetConfig: Root dataset configuration

Describes the full dataset configuration including version and all table
definitions.

## Public fields

- `version`:

  Version string of the dataset

- `tables`:

  Named list of TableConfig objects

## Methods

### Public methods

- [`DatasetConfig$new()`](#method-DatasetConfig-new)

- [`DatasetConfig$validate()`](#method-DatasetConfig-validate)

- [`DatasetConfig$clone()`](#method-DatasetConfig-clone)

------------------------------------------------------------------------

### Method `new()`

Create a new DatasetConfig instance.

#### Usage

    DatasetConfig$new(version, tables)

#### Arguments

- `version`:

  Dataset version string

- `tables`:

  Named list of TableConfig instances or raw config lists

------------------------------------------------------------------------

### Method `validate()`

Validate the DatasetConfig object.

#### Usage

    DatasetConfig$validate()

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    DatasetConfig$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
