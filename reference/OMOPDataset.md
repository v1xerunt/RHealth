# OMOPDataset

A dataset class for handling OMOP CDM (Common Data Model) data. Inherits
from BaseDataset.

## Super class

[`RHealth::BaseDataset`](https://v1xerunt.github.io/RHealth/reference/BaseDataset.md)
-\> `OMOPDataset`

## Methods

### Public methods

- [`OMOPDataset$new()`](#method-OMOPDataset-new)

- [`OMOPDataset$clone()`](#method-OMOPDataset-clone)

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

Initialize the OMOPDataset.

#### Usage

    OMOPDataset$new(
      root,
      tables = character(),
      dataset_name = NULL,
      config_path = NULL,
      dev = FALSE,
      ...
    )

#### Arguments

- `root`:

  Root directory of the dataset.

- `tables`:

  Character vector of extra tables to include.

- `dataset_name`:

  Optional dataset name.

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

    OMOPDataset$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
