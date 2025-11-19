# MortalityPredictionEICU Task

Task for predicting ICU mortality using eICU-CRD dataset. Predicts
whether a patient will die during the ICU stay based on clinical
information collected during the stay.

## Details

This task uses the unit discharge status from the patient table to
determine mortality. The prediction is based on clinical codes from
diagnosis, physicalExam (procedures), and medication tables.

Label definition:

- Label = 1 if unitdischargestatus == "Expired"

- Label = 0 otherwise

The task excludes:

- ICU stays without any clinical codes (conditions, procedures, or
  drugs)

Features:

- conditions: ICD-9 codes from diagnosis table

- procedures: Physical examination paths from physicalexam table

- drugs: Drug names from medication table

## Super class

[`RHealth::BaseTask`](https://v1xerunt.github.io/RHealth/reference/BaseTask.md)
-\> `MortalityPredictionEICU`

## Public fields

- `task_name`:

  Name of the task.

- `input_schema`:

  Input schema.

- `output_schema`:

  Output schema.

## Methods

### Public methods

- [`MortalityPredictionEICU$new()`](#method-MortalityPredictionEICU-new)

- [`MortalityPredictionEICU$pre_filter()`](#method-MortalityPredictionEICU-pre_filter)

- [`MortalityPredictionEICU$call()`](#method-MortalityPredictionEICU-call)

- [`MortalityPredictionEICU$clone()`](#method-MortalityPredictionEICU-clone)

------------------------------------------------------------------------

### Method `new()`

Initialize the task.

#### Usage

    MortalityPredictionEICU$new()

------------------------------------------------------------------------

### Method `pre_filter()`

Pre-filter hook to retain only necessary columns.

#### Usage

    MortalityPredictionEICU$pre_filter(df)

#### Arguments

- `df`:

  A lazy query containing all events.

#### Returns

A filtered LazyFrame.

------------------------------------------------------------------------

### Method [`call()`](https://rdrr.io/r/base/call.html)

Process a single patient (ICU stay) to generate samples.

#### Usage

    MortalityPredictionEICU$call(patient)

#### Arguments

- `patient`:

  A Patient object representing a single ICU stay.

#### Returns

A list of samples (typically one sample per ICU stay).

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    MortalityPredictionEICU$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
library(RHealth)

# Load eICU dataset
eicu_ds <- eICUDataset$new(
  root = "/path/to/eicu-crd/2.0",
  tables = c("diagnosis", "medication", "physicalexam"),
  dev = TRUE
)

# Set mortality prediction task
task <- MortalityPredictionEICU$new()
sample_ds <- eicu_ds$set_task(task = task)

# View samples
head(sample_ds$samples)
} # }
```
