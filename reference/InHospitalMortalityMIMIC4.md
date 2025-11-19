# InHospitalMortalityMIMIC4 Task

Task for predicting in-hospital mortality using MIMIC-IV dataset. This
task leverages lab results from the first 48 hours of an admission to
predict the likelihood of in-hospital mortality.

## Super class

[`RHealth::BaseTask`](https://v1xerunt.github.io/RHealth/reference/BaseTask.md)
-\> `InHospitalMortalityMIMIC4`

## Public fields

- `task_name`:

  The name of the task.

- `input_schema`:

  The schema for input data.

- `output_schema`:

  The schema for output data.

- `label`:

  The name of the label column.

- `LABITEMS`:

  A list of lab item IDs used in this task.

## Methods

### Public methods

- [`InHospitalMortalityMIMIC4$new()`](#method-InHospitalMortalityMIMIC4-new)

- [`InHospitalMortalityMIMIC4$pre_filter()`](#method-InHospitalMortalityMIMIC4-pre_filter)

- [`InHospitalMortalityMIMIC4$call()`](#method-InHospitalMortalityMIMIC4-call)

- [`InHospitalMortalityMIMIC4$clone()`](#method-InHospitalMortalityMIMIC4-clone)

------------------------------------------------------------------------

### Method `new()`

Initialize a new InHospitalMortalityMIMIC4 instance.

#### Usage

    InHospitalMortalityMIMIC4$new()

------------------------------------------------------------------------

### Method `pre_filter()`

Pre-filter hook to retain only necessary columns for this task.

#### Usage

    InHospitalMortalityMIMIC4$pre_filter(df)

#### Arguments

- `df`:

  A lazy query containing all events.

#### Returns

A filtered LazyFrame with only relevant columns.

------------------------------------------------------------------------

### Method [`call()`](https://rdrr.io/r/base/call.html)

Main processing method to generate samples.

#### Usage

    InHospitalMortalityMIMIC4$call(patient)

#### Arguments

- `patient`:

  An object with method `get_events(event_type, ...)`.

#### Returns

A list of samples.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    InHospitalMortalityMIMIC4$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
