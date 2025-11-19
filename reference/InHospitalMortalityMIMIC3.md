# InHospitalMortalityMIMIC3 Task

Task for predicting in-hospital mortality using MIMIC-III dataset. This
task leverages lab results from the first 48 hours of an admission to
predict the likelihood of in-hospital mortality.

## Super class

[`RHealth::BaseTask`](https://v1xerunt.github.io/RHealth/reference/BaseTask.md)
-\> `InHospitalMortalityMIMIC3`

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

  A list of lab item IDs used in this task for MIMIC-III.

## Methods

### Public methods

- [`InHospitalMortalityMIMIC3$new()`](#method-InHospitalMortalityMIMIC3-new)

- [`InHospitalMortalityMIMIC3$pre_filter()`](#method-InHospitalMortalityMIMIC3-pre_filter)

- [`InHospitalMortalityMIMIC3$call()`](#method-InHospitalMortalityMIMIC3-call)

- [`InHospitalMortalityMIMIC3$clone()`](#method-InHospitalMortalityMIMIC3-clone)

------------------------------------------------------------------------

### Method `new()`

Initialize a new InHospitalMortalityMIMIC3 instance.

#### Usage

    InHospitalMortalityMIMIC3$new()

------------------------------------------------------------------------

### Method `pre_filter()`

Pre-filter hook to retain only necessary columns for this task.

#### Usage

    InHospitalMortalityMIMIC3$pre_filter(df)

#### Arguments

- `df`:

  A lazy query containing all events.

#### Returns

A filtered LazyFrame with only relevant columns.

------------------------------------------------------------------------

### Method [`call()`](https://rdrr.io/r/base/call.html)

Main processing method to generate samples.

#### Usage

    InHospitalMortalityMIMIC3$call(patient)

#### Arguments

- `patient`:

  An object with method `get_events(event_type, ...)`.

#### Returns

A list of samples.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    InHospitalMortalityMIMIC3$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
