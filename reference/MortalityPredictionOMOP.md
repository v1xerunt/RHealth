# MortalityPredictionOMOP Task

Task for predicting mortality using OMOP CDM dataset. Predicts whether a
patient has a death record based on clinical information from each
visit.

## Super class

[`RHealth::BaseTask`](https://v1xerunt.github.io/RHealth/reference/BaseTask.md)
-\> `MortalityPredictionOMOP`

## Public fields

- `task_name`:

  Name of the task.

- `input_schema`:

  Input schema.

- `output_schema`:

  Output schema.

## Methods

### Public methods

- [`MortalityPredictionOMOP$new()`](#method-MortalityPredictionOMOP-new)

- [`MortalityPredictionOMOP$pre_filter()`](#method-MortalityPredictionOMOP-pre_filter)

- [`MortalityPredictionOMOP$call()`](#method-MortalityPredictionOMOP-call)

- [`MortalityPredictionOMOP$clone()`](#method-MortalityPredictionOMOP-clone)

------------------------------------------------------------------------

### Method `new()`

Initialize the task.

#### Usage

    MortalityPredictionOMOP$new()

------------------------------------------------------------------------

### Method `pre_filter()`

Pre-filter hook to retain only necessary columns.

#### Usage

    MortalityPredictionOMOP$pre_filter(df)

#### Arguments

- `df`:

  A lazy query containing all events.

#### Returns

A filtered LazyFrame.

------------------------------------------------------------------------

### Method [`call()`](https://rdrr.io/r/base/call.html)

Process a single patient to generate samples.

#### Usage

    MortalityPredictionOMOP$call(patient)

#### Arguments

- `patient`:

  A Patient object.

#### Returns

A list of samples.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    MortalityPredictionOMOP$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
