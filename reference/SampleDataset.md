# SampleDataset

Sample dataset class for handling and processing data samples.

Initialize the dataset

Check that all samples contain required schema fields

Build processors and transform all samples

Get a sample by index

Number of samples

Printable description of dataset

## Usage

``` r
SampleDataset(
  samples,
  input_schema,
  output_schema,
  dataset_name = "",
  task_name = "",
  save_path = NULL
)
```

## Arguments

- samples:

  List of named list records

- input_schema:

  Named list specifying types for inputs

- output_schema:

  Named list specifying types for outputs

- dataset_name:

  Optional dataset name

- task_name:

  Optional task name

- save_path:

  Optional path to save the processed dataset.

## Value

Named list representing the sample

Integer

## Fields

- `samples`:

  List of named list objects (records)

- `input_schema`:

  Named list of input types

- `output_schema`:

  Named list of output types

- `input_processors`:

  List of input processors by field

- `output_processors`:

  List of output processors by field

- `dataset_name`:

  Dataset identifier

- `task_name`:

  Task identifier

- `patient_to_index`:

  Named list mapping patient_id to sample indices

- `record_to_index`:

  Named list mapping record_id to sample indices
