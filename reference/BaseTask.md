# BaseTask (Abstract Base Class)

An abstract base class for all task classes. It defines the task name,
input/output schema, a pre-filtering hook, and the main processing
interface.

## Public fields

- `task_name`:

  Name of the task

- `input_schema`:

  Named list specifying the expected input structure (field name -\>
  type)

- `output_schema`:

  Named list specifying the expected output structure (field name -\>
  type)

## Methods

### Public methods

- [`BaseTask$new()`](#method-BaseTask-new)

- [`BaseTask$pre_filter()`](#method-BaseTask-pre_filter)

- [`BaseTask$call()`](#method-BaseTask-call)

- [`BaseTask$clone()`](#method-BaseTask-clone)

------------------------------------------------------------------------

### Method `new()`

Initialize the task instance. Can be overridden in subclasses.

#### Usage

    BaseTask$new(task_name = NULL, input_schema = NULL, output_schema = NULL)

#### Arguments

- `task_name`:

  A string specifying the name of the task.

- `input_schema`:

  A named list describing the input data schema (optional).

- `output_schema`:

  A named list describing the output data schema (optional).

------------------------------------------------------------------------

### Method `pre_filter()`

Pre-filter hook to modify or filter the input data before main
processing.

#### Usage

    BaseTask$pre_filter(df)

#### Arguments

- `df`:

  A data frame or lazy data object (e.g., from dplyr or data.table).

#### Returns

A filtered or modified version of the input data.

------------------------------------------------------------------------

### Method [`call()`](https://rdrr.io/r/base/call.html)

Main processing function. Must be overridden in subclasses.

#### Usage

    BaseTask$call(patient)

#### Arguments

- `patient`:

  A list or structured object representing a single patient or record.

#### Returns

A list of named lists representing the task result.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    BaseTask$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
