# ReadmissionPredictionOMOP Task

Task for predicting hospital readmission using OMOP CDM dataset.
Predicts whether a patient will be readmitted within a specified time
window based on clinical information from the current visit.

## Details

This task predicts whether a patient will be readmitted to the hospital
within a specified time window (default 15 days) after the current
visit. The prediction is based on clinical codes (conditions,
procedures, drugs) from the current visit.

Label definition:

- Label = 1 if the time gap between current visit and next visit \<
  time_window

- Label = 0 otherwise

The task excludes:

- Patients with only one visit (no next visit to predict)

- Visits without any clinical codes (conditions, procedures, or drugs)

## Super class

[`RHealth::BaseTask`](https://v1xerunt.github.io/RHealth/reference/BaseTask.md)
-\> `ReadmissionPredictionOMOP`

## Public fields

- `task_name`:

  Name of the task.

- `input_schema`:

  Input schema.

- `output_schema`:

  Output schema.

- `time_window`:

  Time window in days for readmission prediction.

## Methods

### Public methods

- [`ReadmissionPredictionOMOP$new()`](#method-ReadmissionPredictionOMOP-new)

- [`ReadmissionPredictionOMOP$pre_filter()`](#method-ReadmissionPredictionOMOP-pre_filter)

- [`ReadmissionPredictionOMOP$call()`](#method-ReadmissionPredictionOMOP-call)

- [`ReadmissionPredictionOMOP$clone()`](#method-ReadmissionPredictionOMOP-clone)

------------------------------------------------------------------------

### Method `new()`

Initialize the task.

#### Usage

    ReadmissionPredictionOMOP$new(time_window = 15)

#### Arguments

- `time_window`:

  Time window in days (default 15). Label is 1 if readmitted within this
  window.

------------------------------------------------------------------------

### Method `pre_filter()`

Pre-filter hook to retain only necessary columns.

#### Usage

    ReadmissionPredictionOMOP$pre_filter(df)

#### Arguments

- `df`:

  A lazy query containing all events.

#### Returns

A filtered LazyFrame.

------------------------------------------------------------------------

### Method [`call()`](https://rdrr.io/r/base/call.html)

Process a single patient to generate samples.

#### Usage

    ReadmissionPredictionOMOP$call(patient)

#### Arguments

- `patient`:

  A Patient object.

#### Returns

A list of samples.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    ReadmissionPredictionOMOP$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
