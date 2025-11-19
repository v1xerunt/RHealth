# BaseDataset — R6 infrastructure for clinical event datasets

BaseDataset — R6 infrastructure for clinical event datasets

BaseDataset — R6 infrastructure for clinical event datasets

## Details

The **BaseDataset** class mirrors rhealth's `BaseDataset`, providing a
fully-featured, YAML driven loader that converts multi-table electronic
health records into a single *event* table. It supports:

- URL or local-file ingestion (with automatic `.csv` / `.csv.gz`
  fallback).

- Per-table joins as declared in the config.

- Flexible timestamp parsing (single or multi-column).

- A `dev` mode that caps the number of patients for rapid prototyping.

- Multi-threaded sample generation with progress bars.

Down-stream, it cooperates with `BaseTask` (task definition), `Patient`
(per-subject wrapper), and `SampleDataset` (collection of input/output
pairs).

## Dependencies

Parallelism and progress reporting require `future`, `future.apply`, and
`progressr`.

## Public fields

- `root`:

  Root directory (or URL prefix) for data files.

- `tables`:

  Character vector of table names to ingest.

- `dataset_name`:

  Human-readable dataset label.

- `config`:

  Parsed YAML configuration list.

- `dev`:

  Logical flag — when TRUE limits to 1000 patients.

- `con`:

  a duckdb connection

- `global_event_df`:

  A duckdb lazy query with all events combined.

- `.collected_global_event_df`:

  dataframe storing all global events.

- `.unique_patient_ids`:

  Character vector of unique patient IDs.

## Methods

### Public methods

- [`BaseDataset$new()`](#method-BaseDataset-new)

- [`BaseDataset$collected_global_event_df()`](#method-BaseDataset-collected_global_event_df)

- [`BaseDataset$load_table()`](#method-BaseDataset-load_table)

- [`BaseDataset$load_data()`](#method-BaseDataset-load_data)

- [`BaseDataset$unique_patient_ids()`](#method-BaseDataset-unique_patient_ids)

- [`BaseDataset$get_patient()`](#method-BaseDataset-get_patient)

- [`BaseDataset$iter_patients()`](#method-BaseDataset-iter_patients)

- [`BaseDataset$stats()`](#method-BaseDataset-stats)

- [`BaseDataset$default_task()`](#method-BaseDataset-default_task)

- [`BaseDataset$set_task()`](#method-BaseDataset-set_task)

- [`BaseDataset$clone()`](#method-BaseDataset-clone)

------------------------------------------------------------------------

### Method `new()`

Instantiate a `BaseDataset`.

#### Usage

    BaseDataset$new(
      root,
      tables,
      dataset_name = NULL,
      config_path = NULL,
      dev = FALSE
    )

#### Arguments

- `root`:

  Character. Root directory / URL prefix where CSV files live.

- `tables`:

  Character vector of table keys defined in the config.

- `dataset_name`:

  Optional custom name; defaults to the R6 class name.

- `config_path`:

  Path to YAML or schema describing each table.

- `dev`:

  Logical. If TRUE, limits to 1000 patients for speed.

------------------------------------------------------------------------

### Method `collected_global_event_df()`

Materialise (collect) the lazy event dataframe. In dev-mode only the
first 1000 patients are kept.

#### Usage

    BaseDataset$collected_global_event_df()

#### Returns

A dataframe containing all selected events.

------------------------------------------------------------------------

### Method `load_table()`

Load one table, apply joins, lowercase columns, and standardise to the
event schema.

#### Usage

    BaseDataset$load_table(table_name)

#### Arguments

- `table_name`:

  Character key present in `config$tables`.

#### Returns

A dplyr lazy query in event format.

------------------------------------------------------------------------

### Method `load_data()`

Load every configured table, returning a single *lazy* frame.

#### Usage

    BaseDataset$load_data()

#### Returns

A duckdb lazy query.

------------------------------------------------------------------------

### Method `unique_patient_ids()`

Retrieve (and cache) the vector of unique patient IDs.

#### Usage

    BaseDataset$unique_patient_ids()

#### Returns

Character vector of patient IDs.

------------------------------------------------------------------------

### Method `get_patient()`

Construct a `Patient` object for one subject.

#### Usage

    BaseDataset$get_patient(patient_id)

#### Arguments

- `patient_id`:

  Character identifier.

#### Returns

A new `Patient` R6 instance.

------------------------------------------------------------------------

### Method `iter_patients()`

Iterate over all patients (optionally a filtered dataframe).

#### Usage

    BaseDataset$iter_patients(df = NULL)

#### Arguments

- `df`:

  Optional dataframe (already collected).

#### Returns

List of `Patient` objects.

------------------------------------------------------------------------

### Method `stats()`

Print dataset-level statistics.

#### Usage

    BaseDataset$stats()

#### Returns

Invisible NULL (called for side-effects).

------------------------------------------------------------------------

### Method `default_task()`

Default task placeholder (override in subclass).

#### Usage

    BaseDataset$default_task()

#### Returns

NULL

------------------------------------------------------------------------

### Method `set_task()`

Apply a `BaseTask` to build a `SampleDataset`.

#### Usage

    BaseDataset$set_task(
      task = NULL,
      num_workers = 1,
      chunk_size = 1000,
      cache_dir = NULL
    )

#### Arguments

- `task`:

  A `BaseTask` instance; if NULL, `default_task()` is used.

- `num_workers`:

  Integer ≥1. Number of parallel workers.

- `chunk_size`:

  Integer. Number of patients to process in each chunk.

- `cache_dir`:

  Optional path to a directory for caching samples. If set, processed
  samples will be saved to an `.rds` file and reloaded on subsequent
  runs, skipping the generation step.

#### Returns

A populated `SampleDataset`.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    BaseDataset$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
