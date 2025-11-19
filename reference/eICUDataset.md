# eICUDataset: Dataset class for eICU-CRD

A dataset class for handling eICU Collaborative Research Database
(eICU-CRD) data. The eICU-CRD is a large dataset of de-identified health
records from ICU patients across multiple hospitals in the United
States. This class inherits from BaseDataset and provides specialized
handling for eICU data structures.

## Details

The eICU dataset is centered around ICU stays (patientunitstayid),
where:

- A patient (uniquepid) can have multiple hospital admissions
  (patienthealthsystemstayid)

- Each hospital admission can have multiple ICU stays
  (patientunitstayid)

- All timestamps are relative offsets (in minutes) from the ICU
  admission time

## Default Tables

The following table is loaded by default:

- **patient**: Core patient demographics and ICU stay information

## Optional Tables

Additional tables can be specified via the `tables` parameter:

- **diagnosis**: ICD-9 diagnoses with diagnosis strings

- **treatment**: Treatment information with treatment strings

- **medication**: Medication orders with drug names and dosages

- **lab**: Laboratory measurements with lab names and results

- **physicalexam**: Physical examination findings

- **admissiondx**: Primary admission diagnoses per APACHE scoring

## Data Source

The eICU-CRD dataset is available at <https://eicu-crd.mit.edu/>. Access
requires completion of the CITI "Data or Specimens Only Research" course
and signing a data use agreement.

## Note on Patient IDs

In the Python pyhealth implementation, patient_id is a composite of
`uniquepid` and `patienthealthsystemstayid` to represent a hospital
admission. In this R implementation, we use `patientunitstayid` as the
primary identifier to represent individual ICU stays, which aligns
better with the event-based architecture of BaseDataset.

## See also

[`BaseDataset`](https://v1xerunt.github.io/RHealth/reference/BaseDataset.md),
[`MIMIC3Dataset`](https://v1xerunt.github.io/RHealth/reference/MIMIC3Dataset.md),
[`OMOPDataset`](https://v1xerunt.github.io/RHealth/reference/OMOPDataset.md)

## Super class

[`RHealth::BaseDataset`](https://v1xerunt.github.io/RHealth/reference/BaseDataset.md)
-\> `eICUDataset`

## Methods

### Public methods

- [`eICUDataset$new()`](#method-eICUDataset-new)

- [`eICUDataset$clone()`](#method-eICUDataset-clone)

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

### Method [`new()`](https://rdrr.io/r/methods/new.html)

Initialize the eICUDataset.

#### Usage

    eICUDataset$new(
      root,
      tables = character(),
      dataset_name = NULL,
      config_path = NULL,
      dev = FALSE,
      ...
    )

#### Arguments

- `root`:

  Character. Root directory of the eICU dataset containing CSV files
  (e.g., patient.csv, diagnosis.csv, etc.).

- `tables`:

  Character vector of additional tables to include beyond the default
  patient table. Available options: "diagnosis", "treatment",
  "medication", "lab", "physicalexam", "admissiondx".

- `dataset_name`:

  Character. Optional custom name for the dataset. Defaults to "eicu".

- `config_path`:

  Character. Optional path to a custom YAML configuration file. If NULL
  (default), uses the built-in eICU configuration.

- `dev`:

  Logical. If TRUE, limits data loading to 1000 patients for rapid
  prototyping and testing. Default is FALSE.

- `...`:

  Additional arguments passed to `BaseDataset$initialize`.

#### Returns

A new `eICUDataset` object.

#### Examples

    \dontrun{
    # Basic initialization
    ds <- eICUDataset$new(
      root = "/data/eicu-crd/2.0"
    )

    # With additional tables and dev mode
    ds <- eICUDataset$new(
      root = "/data/eicu-crd/2.0",
      tables = c("diagnosis", "medication", "lab"),
      dev = TRUE
    )
    }

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    eICUDataset$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# Initialize with default patient table only
dataset <- eICUDataset$new(
  root = "/path/to/eicu-crd/2.0",
  dev = TRUE
)

# Initialize with additional clinical tables
dataset <- eICUDataset$new(
  root = "/path/to/eicu-crd/2.0",
  tables = c("diagnosis", "medication", "lab", "treatment"),
  dev = FALSE
)

# Display dataset statistics
dataset$stats()
} # }


## ------------------------------------------------
## Method `eICUDataset$new`
## ------------------------------------------------

if (FALSE) { # \dontrun{
# Basic initialization
ds <- eICUDataset$new(
  root = "/data/eicu-crd/2.0"
)

# With additional tables and dev mode
ds <- eICUDataset$new(
  root = "/data/eicu-crd/2.0",
  tables = c("diagnosis", "medication", "lab"),
  dev = TRUE
)
} # }
```
