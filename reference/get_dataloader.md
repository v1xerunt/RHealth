# Create DataLoader

Creates a torch dataloader with padding-aware collate function.

## Usage

``` r
get_dataloader(dataset, batch_size, shuffle = FALSE)
```

## Arguments

- dataset:

  A torch dataset or dataset_subset object.

- batch_size:

  Integer, number of samples per batch.

- shuffle:

  Logical, whether to shuffle the data. Default: FALSE.

## Value

A torch dataloader object.
