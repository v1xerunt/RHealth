# JoinConfig: Configuration for joining tables in a dataset

An R6 class that represents the configuration required to join an
auxiliary table to the main dataset.

## Public fields

- `file_path`:

  Path to the join table file (string)

- `on`:

  Column name to join on (string)

- `how`:

  Join type: "left", "right", "inner", or "outer" (string)

- `columns`:

  List of column names to extract from the joined table (character
  vector)

## Methods

### Public methods

- [`JoinConfig$new()`](#method-JoinConfig-new)

- [`JoinConfig$clone()`](#method-JoinConfig-clone)

------------------------------------------------------------------------

### Method `new()`

Create a new JoinConfig instance.

#### Usage

    JoinConfig$new(file_path, on, how, columns)

#### Arguments

- `file_path`:

  Path to the join table

- `on`:

  Column name to join on

- `how`:

  Type of join to perform ("left", "right", "inner", "outer")

- `columns`:

  Character vector of column names to extract from the joined table

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    JoinConfig$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
