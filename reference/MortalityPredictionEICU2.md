# MortalityPredictionEICU2 Task (Alternative Feature Set)

Alternative task for predicting ICU mortality using eICU-CRD dataset
with different feature encoding. Uses diagnosis strings and treatment
information instead of ICD codes and physical exams.

## Details

Similar to MortalityPredictionEICU but uses:

- conditions: Admission diagnoses paths and diagnosis strings

- procedures: Treatment strings

Label definition:

- Label = 1 if unitdischargestatus == "Expired"

- Label = 0 otherwise

## Super class

[`RHealth::BaseTask`](https://v1xerunt.github.io/RHealth/reference/BaseTask.md)
-\> `MortalityPredictionEICU2`

## Public fields

- `task_name`:

  Name of the task.

- `input_schema`:

  Input schema.

- `output_schema`:

  Output schema.

## Methods

### Public methods

- [`MortalityPredictionEICU2$new()`](#method-MortalityPredictionEICU2-new)

- [`MortalityPredictionEICU2$pre_filter()`](#method-MortalityPredictionEICU2-pre_filter)

- [`MortalityPredictionEICU2$call()`](#method-MortalityPredictionEICU2-call)

- [`MortalityPredictionEICU2$clone()`](#method-MortalityPredictionEICU2-clone)

------------------------------------------------------------------------

### Method `new()`

Initialize the task.

#### Usage

    MortalityPredictionEICU2$new()

------------------------------------------------------------------------

### Method `pre_filter()`

Pre-filter hook to retain only necessary columns.

#### Usage

    MortalityPredictionEICU2$pre_filter(df)

#### Arguments

- `df`:

  A lazy query containing all events.

#### Returns

A filtered LazyFrame.

------------------------------------------------------------------------

### Method [`call()`](https://rdrr.io/r/base/call.html)

Process a single patient (ICU stay) to generate samples.

#### Usage

    MortalityPredictionEICU2$call(patient)

#### Arguments

- `patient`:

  A Patient object representing a single ICU stay.

#### Returns

A list of samples.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    MortalityPredictionEICU2$clone(deep = FALSE)

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
  tables = c("diagnosis", "treatment", "admissiondx"),
  dev = TRUE
)

# Set mortality prediction task
task <- MortalityPredictionEICU2$new()
sample_ds <- eicu_ds$set_task(task = task)
} # }
```
