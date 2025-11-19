# BenchmarkEHRShot: Benchmark predictive tasks using EHRShot

Task class for running benchmark evaluations on the EHRShot dataset.
Supports multiple categories of prediction tasks including operational
outcomes, lab value predictions, new diagnoses, and medical imaging
findings.

## Details

The BenchmarkEHRShot task class implements predictive modeling tasks
from the EHRShot benchmark. Each task uses clinical codes from the
ehrshot table as features and generates predictions based on
task-specific labels.

**Operational Outcomes (Binary Classification):**

- **guo_los**: Predicts if length of stay exceeds a threshold

- **guo_readmission**: Predicts hospital readmission

- **guo_icu**: Predicts ICU admission

**Lab Values (Multiclass Classification):**

- **lab_thrombocytopenia**: Predicts low platelet count severity

- **lab_hyperkalemia**: Predicts high potassium level severity

- **lab_hypoglycemia**: Predicts low blood sugar severity

- **lab_hyponatremia**: Predicts low sodium level severity

- **lab_anemia**: Predicts anemia severity

**New Diagnoses (Binary Classification):**

- **new_hypertension**: Predicts new hypertension diagnosis

- **new_hyperlipidemia**: Predicts new hyperlipidemia diagnosis

- **new_pancan**: Predicts new pancreatic cancer diagnosis

- **new_celiac**: Predicts new celiac disease diagnosis

- **new_lupus**: Predicts new lupus diagnosis

- **new_acutemi**: Predicts new acute myocardial infarction diagnosis

**Medical Imaging (Multilabel Classification):**

- **chexpert**: Predicts multiple chest X-ray findings simultaneously
  (14 possible findings from the CheXpert dataset)

## Features

The task uses clinical codes from the ehrshot table as features.
Optionally, you can filter events by OMOP table type using the
`omop_tables` parameter to focus on specific types of clinical data
(e.g., conditions, procedures, drugs).

## Data Split

The task automatically assigns samples to train/validation/test splits
based on the splits table in the EHRShot dataset.

## See also

[`EHRShotDataset`](https://v1xerunt.github.io/RHealth/reference/EHRShotDataset.md),
[`BaseTask`](https://v1xerunt.github.io/RHealth/reference/BaseTask.md)

## Super class

[`RHealth::BaseTask`](https://v1xerunt.github.io/RHealth/reference/BaseTask.md)
-\> `BenchmarkEHRShot`

## Public fields

- `task`:

  Name of the specific benchmark task.

- `omop_tables`:

  Optional vector of OMOP table names to filter events.

- `max_seq_length`:

  Maximum sequence length for codes.

- `truncation_count`:

  Counter for truncated sequences.

- `task_name`:

  Full task name (BenchmarkEHRShot/task).

- `input_schema`:

  Input schema specification.

- `output_schema`:

  Output schema specification.

- `tasks_by_category`:

  List of available tasks organized by category.

## Methods

### Public methods

- [`BenchmarkEHRShot$new()`](#method-BenchmarkEHRShot-new)

- [`BenchmarkEHRShot$pre_filter()`](#method-BenchmarkEHRShot-pre_filter)

- [`BenchmarkEHRShot$call()`](#method-BenchmarkEHRShot-call)

- [`BenchmarkEHRShot$clone()`](#method-BenchmarkEHRShot-clone)

------------------------------------------------------------------------

### Method `new()`

Initialize the BenchmarkEHRShot task.

#### Usage

    BenchmarkEHRShot$new(task, omop_tables = NULL, max_seq_length = 2000)

#### Arguments

- `task`:

  Character. The specific benchmark task to run. Must be one of:

  - Operational outcomes: "guo_los", "guo_readmission", "guo_icu"

  - Lab values: "lab_thrombocytopenia", "lab_hyperkalemia",
    "lab_hypoglycemia", "lab_hyponatremia", "lab_anemia"

  - New diagnoses: "new_hypertension", "new_hyperlipidemia",
    "new_pancan", "new_celiac", "new_lupus", "new_acutemi"

  - Medical imaging: "chexpert"

- `omop_tables`:

  Optional character vector. Names of OMOP tables to filter input
  events. If specified, only events from ehrshot with matching
  `omop_table` values will be included as features. Common values
  include: "condition_occurrence", "procedure_occurrence",
  "drug_exposure", "measurement", "observation".

- `max_seq_length`:

  Integer. Maximum sequence length for clinical codes. Sequences longer
  than this will be truncated to the most recent codes. Default is 2000.
  Set to NULL for no limit (not recommended for large datasets).

#### Returns

A new `BenchmarkEHRShot` task object.

#### Examples

    \dontrun{
    # Basic task initialization
    task <- BenchmarkEHRShot$new(task = "guo_los")

    # With OMOP table filtering
    task <- BenchmarkEHRShot$new(
      task = "new_hypertension",
      omop_tables = c("condition_occurrence", "drug_exposure")
    )

    # With custom max sequence length
    task <- BenchmarkEHRShot$new(task = "guo_los", max_seq_length = 5000)
    }

------------------------------------------------------------------------

### Method `pre_filter()`

Pre-filter hook to retain only necessary columns and optionally filter
by OMOP tables.

#### Usage

    BenchmarkEHRShot$pre_filter(df)

#### Arguments

- `df`:

  A lazy query or data frame containing all events.

#### Returns

A filtered data frame.

------------------------------------------------------------------------

### Method [`call()`](https://rdrr.io/r/base/call.html)

Process a single patient to generate samples.

#### Usage

    BenchmarkEHRShot$call(patient)

#### Arguments

- `patient`:

  A Patient object.

#### Returns

A list of samples, where each sample contains:

- **patient_id**: Patient identifier

- **feature**: Vector of clinical codes

- **label**: Label value (type depends on task)

- **split**: Data split assignment ("train", "val", or "test")

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    BenchmarkEHRShot$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
library(RHealth)

# Example 1: Binary classification task (operational outcome)
dataset <- EHRShotDataset$new(
  root = "/path/to/ehrshot",
  tables = c("ehrshot", "splits", "guo_los"),
  dev = TRUE
)
task <- BenchmarkEHRShot$new(task = "guo_los")
samples <- dataset$set_task(task = task)

# Example 2: Multiclass classification task (lab values)
dataset <- EHRShotDataset$new(
  root = "/path/to/ehrshot",
  tables = c("ehrshot", "splits", "lab_thrombocytopenia"),
  dev = TRUE
)
task <- BenchmarkEHRShot$new(task = "lab_thrombocytopenia")
samples <- dataset$set_task(task = task)

# Example 3: Multilabel classification task (medical imaging)
dataset <- EHRShotDataset$new(
  root = "/path/to/ehrshot",
  tables = c("ehrshot", "splits", "chexpert"),
  dev = FALSE
)
task <- BenchmarkEHRShot$new(task = "chexpert")
samples <- dataset$set_task(task = task)

# Example 4: Filter by specific OMOP tables
task <- BenchmarkEHRShot$new(
  task = "new_hypertension",
  omop_tables = c("condition_occurrence", "drug_exposure")
)
samples <- dataset$set_task(task = task)
} # }


## ------------------------------------------------
## Method `BenchmarkEHRShot$new`
## ------------------------------------------------

if (FALSE) { # \dontrun{
# Basic task initialization
task <- BenchmarkEHRShot$new(task = "guo_los")

# With OMOP table filtering
task <- BenchmarkEHRShot$new(
  task = "new_hypertension",
  omop_tables = c("condition_occurrence", "drug_exposure")
)

# With custom max sequence length
task <- BenchmarkEHRShot$new(task = "guo_los", max_seq_length = 5000)
} # }
```
