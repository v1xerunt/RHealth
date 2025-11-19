# EHRShotDataset: Dataset class for EHRShot Benchmark

A dataset class for handling EHRShot data. EHRShot is a benchmark for
few-shot evaluation on Electronic Health Records (EHR) data, covering
multiple predictive tasks including operational outcomes, lab values,
new diagnoses, and medical imaging findings.

## Details

The EHRShot benchmark provides standardized evaluation across multiple
clinical prediction tasks:

**Operational Outcomes:**

- **guo_los**: Length of stay prediction

- **guo_readmission**: Hospital readmission prediction

- **guo_icu**: ICU admission prediction

**Lab Values:**

- **lab_thrombocytopenia**: Low platelet count prediction

- **lab_hyperkalemia**: High potassium level prediction

- **lab_hypoglycemia**: Low blood sugar prediction

- **lab_hyponatremia**: Low sodium level prediction

- **lab_anemia**: Anemia prediction

**New Diagnoses:**

- **new_hypertension**: New hypertension diagnosis

- **new_hyperlipidemia**: New hyperlipidemia diagnosis

- **new_pancan**: New pancreatic cancer diagnosis

- **new_celiac**: New celiac disease diagnosis

- **new_lupus**: New lupus diagnosis

- **new_acutemi**: New acute myocardial infarction diagnosis

**Medical Imaging:**

- **chexpert**: CheXpert multi-label chest X-ray finding classification

## Data Structure

The dataset expects the following CSV files in the root directory:

- **ehrshot.csv**: Main events table with clinical codes

- **splits.csv**: Train/validation/test split assignments

- **\<task_name\>.csv**: Label files for each prediction task

## Website

For more information, visit:
<https://som-shahlab.github.io/ehrshot-website/>

## See also

[`BaseDataset`](https://v1xerunt.github.io/RHealth/reference/BaseDataset.md),
[`BenchmarkEHRShot`](https://v1xerunt.github.io/RHealth/reference/BenchmarkEHRShot.md)

## Super class

[`RHealth::BaseDataset`](https://v1xerunt.github.io/RHealth/reference/BaseDataset.md)
-\> `EHRShotDataset`

## Methods

### Public methods

- [`EHRShotDataset$new()`](#method-EHRShotDataset-new)

- [`EHRShotDataset$clone()`](#method-EHRShotDataset-clone)

Inherited methods

- [`RHealth::BaseDataset$collected_global_event_df()`](https://v1xerunt.github.io/RHealth/reference/BaseDataset.html#method-collected_global_event_df)
- [`RHealth::BaseDataset$default_task()`](https://v1xerunt.github.io/RHealth/reference/BaseDataset.html#method-default_task)
- [`RHealth::BaseDataset$get_patient()`](https://v1xerunt.github.io/RHealth/reference/BaseDataset.html#method-get_patient)
- [`RHealth::BaseDataset$iter_patients()`](https://v1xerunt.github.io/RHealth/reference/BaseDataset.html#method-iter_patients)
- [`RHealth::BaseDataset$load_data()`](https://v1xerunt.github.io/RHealth/reference/BaseDataset.html#method-load_data)
- [`RHealth::BaseDataset$load_table()`](https://v1xerunt.github.io/RHealth/reference/BaseDataset.html#method-load_table)
- [`RHealth::BaseDataset$set_task()`](https://v1xerunt.github.io/RHealth/reference/BaseDataset.html#method-set_task)
- [`RHealth::BaseDataset$stats()`](https://v1xerunt.github.io/RHealth/reference/BaseDataset.html#method-stats)
- [`RHealth::BaseDataset$unique_patient_ids()`](https://v1xerunt.github.io/RHealth/reference/BaseDataset.html#method-unique_patient_ids)

------------------------------------------------------------------------

### Method `new()`

Initialize the EHRShotDataset.

#### Usage

    EHRShotDataset$new(
      root,
      tables,
      dataset_name = NULL,
      config_path = NULL,
      dev = FALSE,
      ...
    )

#### Arguments

- `root`:

  Character. Root directory of the EHRShot dataset containing CSV files
  (e.g., ehrshot.csv, splits.csv, task label files).

- `tables`:

  Character vector of tables to include. Should include at minimum
  "ehrshot" for events and "splits" for data splitting. Additional
  task-specific label tables can be added (e.g., "guo_los",
  "lab_thrombocytopenia"). Available task tables include:

  - Operational outcomes: "guo_los", "guo_readmission", "guo_icu"

  - Lab values: "lab_thrombocytopenia", "lab_hyperkalemia",
    "lab_hypoglycemia", "lab_hyponatremia", "lab_anemia"

  - New diagnoses: "new_hypertension", "new_hyperlipidemia",
    "new_pancan", "new_celiac", "new_lupus", "new_acutemi"

  - Imaging: "chexpert"

- `dataset_name`:

  Character. Optional custom name for the dataset. Defaults to
  "ehrshot".

- `config_path`:

  Character. Optional path to a custom YAML configuration file. If NULL
  (default), uses the built-in EHRShot configuration.

- `dev`:

  Logical. If TRUE, limits data loading to 1000 patients for rapid
  prototyping and testing. Default is FALSE.

- `...`:

  Additional arguments passed to `BaseDataset$initialize`.

#### Returns

A new `EHRShotDataset` object.

#### Examples

    \dontrun{
    # Basic initialization with single task
    ds <- EHRShotDataset$new(
      root = "/data/ehrshot",
      tables = c("ehrshot", "splits", "guo_los")
    )

    # With multiple tasks and dev mode
    ds <- EHRShotDataset$new(
      root = "/data/ehrshot",
      tables = c("ehrshot", "splits", "lab_thrombocytopenia", "new_hypertension"),
      dev = TRUE
    )
    }

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    EHRShotDataset$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# Initialize with default ehrshot table only
dataset <- EHRShotDataset$new(
  root = "/path/to/ehrshot/data",
  tables = c("ehrshot", "splits", "guo_los"),
  dev = TRUE
)

# Initialize with multiple task tables
dataset <- EHRShotDataset$new(
  root = "/path/to/ehrshot/data",
  tables = c("ehrshot", "splits", "lab_thrombocytopenia", "new_hypertension"),
  dev = FALSE
)

# Display dataset statistics
dataset$stats()
} # }


## ------------------------------------------------
## Method `EHRShotDataset$new`
## ------------------------------------------------

if (FALSE) { # \dontrun{
# Basic initialization with single task
ds <- EHRShotDataset$new(
  root = "/data/ehrshot",
  tables = c("ehrshot", "splits", "guo_los")
)

# With multiple tasks and dev mode
ds <- EHRShotDataset$new(
  root = "/data/ehrshot",
  tables = c("ehrshot", "splits", "lab_thrombocytopenia", "new_hypertension"),
  dev = TRUE
)
} # }
```
