# MIMIC4NoteDataset: Dataset class for MIMIC-IV Clinical Notes

MIMIC4NoteDataset: Dataset class for MIMIC-IV Clinical Notes

MIMIC4NoteDataset: Dataset class for MIMIC-IV Clinical Notes

## Details

This class inherits from BaseDataset and is specialized for handling
MIMIC-IV Clinical Notes data. It includes tables such as discharge,
discharge_detail, and radiology.

## Super class

[`RHealth::BaseDataset`](https://v1xerunt.github.io/RHealth/reference/BaseDataset.md)
-\> `MIMIC4NoteDataset`

## Methods

### Public methods

- [`MIMIC4NoteDataset$new()`](#method-MIMIC4NoteDataset-new)

- [`MIMIC4NoteDataset$clone()`](#method-MIMIC4NoteDataset-clone)

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

Initialize MIMIC4NoteDataset

#### Usage

    MIMIC4NoteDataset$new(
      root,
      tables = character(),
      dataset_name = "mimic4_note",
      config_path = NULL,
      dev = FALSE,
      ...
    )

#### Arguments

- `root`:

  Root directory of the dataset.

- `tables`:

  Character vector of tables to include.

- `dataset_name`:

  Optional dataset name. Default is "mimic4_note".

- `config_path`:

  Optional path to YAML config file.

- `dev`:

  Logical flag for dev mode.

- `...`:

  Additional arguments passed to `BaseDataset$initialize`.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    MIMIC4NoteDataset$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
