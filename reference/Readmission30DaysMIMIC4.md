# Readmission30DaysMIMIC4 Task

This task processes patient data from MIMIC-IV to predict whether a
patient will be readmitted within 30 days after discharge. It uses
sequences of conditions, procedures, and drugs as input features.

## Format

`R6Class` object.

## Public Fields

- `task_name`:

  Character. The name of the task ("Readmission30DaysMIMIC4").

- `input_schema`:

  List. Input schema, including:

  - `conditions`: Sequence of condition codes.

  - `procedures`: Sequence of procedure codes.

  - `drugs`: Sequence of drug codes.

- `output_schema`:

  List. Output schema:

  - `readmission`: Binary indicator of readmission within 30 days.

## Public Methods

- `initialize()`:

  Initializes the task by setting the task name, input and output
  schema.

- `call(patient)`:

  Generate samples from a patient object.

  `patient`

  :   An object that implements `get_events()` for MIMIC-IV.

  Returns

  :   A list of named lists with features and 30-day readmission label.

## Super class

[`RHealth::BaseTask`](https://v1xerunt.github.io/RHealth/reference/BaseTask.md)
-\> `Readmission30DaysMIMIC4`

## Public fields

- `label`:

  the name of the label column.

## Methods

### Public methods

- [`Readmission30DaysMIMIC4$new()`](#method-Readmission30DaysMIMIC4-new)

- [`Readmission30DaysMIMIC4$call()`](#method-Readmission30DaysMIMIC4-call)

- [`Readmission30DaysMIMIC4$clone()`](#method-Readmission30DaysMIMIC4-clone)

Inherited methods

- [`RHealth::BaseTask$pre_filter()`](https://v1xerunt.github.io/RHealth/reference/BaseTask.html#method-pre_filter)

------------------------------------------------------------------------

### Method `new()`

Initialize the Readmission30DaysMIMIC4 task. Sets the task name and
defines the expected input/output schema.

#### Usage

    Readmission30DaysMIMIC4$new()

------------------------------------------------------------------------

### Method [`call()`](https://rdrr.io/r/base/call.html)

Generate samples by processing a patient object. Excludes patients under
18 years old and visits without complete data. For each valid admission,
extracts condition, procedure, and drug codes as feature sequences and
computes a binary readmission label within 30 days.

#### Usage

    Readmission30DaysMIMIC4$call(patient)

#### Arguments

- `patient`:

  An object with a `get_events` method for extracting MIMIC-IV events.

#### Returns

A list of named lists, each representing one admission sample.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    Readmission30DaysMIMIC4$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
task <- Readmission30DaysMIMIC4$new()
samples <- task$call(patient)
} # }
```
