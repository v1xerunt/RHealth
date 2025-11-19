# split_by_visit

split_by_visit

## Usage

``` r
split_by_visit(
  dataset,
  ratios,
  seed = NULL,
  stratify = FALSE,
  stratify_by = NULL
)
```

## Arguments

- dataset:

  A `SampleDataset` object.

- ratios:

  A numeric vector of length 3 indicating train/val/test split ratios.
  Must sum to 1.

- seed:

  Optional integer for reproducibility.

- stratify:

  Logical, whether to perform stratified sampling. Default: FALSE.

- stratify_by:

  Character, the name of the field to stratify by (e.g., the label).
  Required if `stratify` is TRUE.

## Value

A list of 3 torch::dataset_subset objects.
