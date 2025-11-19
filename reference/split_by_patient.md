# split_by_patient

split_by_patient

## Usage

``` r
split_by_patient(
  dataset,
  ratios,
  seed = NULL,
  stratify = FALSE,
  stratify_by = NULL,
  get_index = FALSE
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

- get_index:

  Logical, whether to return the indices instead of subsets. Default:
  FALSE.

## Value

A list of 3 torch::dataset_subset objects or 3 tensors of indices if
get_index = TRUE, split by patient id.
