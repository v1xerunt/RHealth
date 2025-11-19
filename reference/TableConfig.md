# TableConfig: Configuration for a single table

Describes the metadata for a data table within the dataset including
file path, patient ID field, timestamp columns, attribute columns, and
join specifications.

## Public fields

- `file_path`:

  Path to the table file (string)

- `patient_id`:

  Optional string identifying the patient ID column

- `timestamp`:

  Optional string or character vector identifying time columns

- `timestamp_format`:

  Optional format string for parsing timestamps

- `attributes`:

  Character vector of attribute column names

- `join`:

  List of JoinConfig objects describing how to join auxiliary tables

## Methods

### Public methods

- [`TableConfig$new()`](#method-TableConfig-new)

- [`TableConfig$validate()`](#method-TableConfig-validate)

- [`TableConfig$clone()`](#method-TableConfig-clone)

------------------------------------------------------------------------

### Method `new()`

Create a new TableConfig instance.

#### Usage

    TableConfig$new(
      file_path,
      patient_id = NULL,
      timestamp = NULL,
      timestamp_format = NULL,
      attributes,
      join = NULL
    )

#### Arguments

- `file_path`:

  Path to the main table file

- `patient_id`:

  Optional column name for patient IDs

- `timestamp`:

  Optional timestamp column(s)

- `timestamp_format`:

  Optional format for timestamps

- `attributes`:

  Character vector of attribute columns

- `join`:

  Optional list of JoinConfig dictionaries or objects

------------------------------------------------------------------------

### Method `validate()`

Validate the fields of TableConfig.

#### Usage

    TableConfig$validate()

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    TableConfig$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
