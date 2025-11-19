# Time Series Processor

Processor for irregular time series data with missing values. Supports
uniform resampling, two imputation strategies (forward-fill and
zero-fill), and automatic z-score normalization using training data
statistics.

## Details

The processor performs three main steps:

1.  **Resampling**: Converts irregular time series to uniform time grid
    based on `sampling_rate`

2.  **Imputation**: Fills missing values using either forward-fill or
    zero-fill strategy

3.  **Normalization** (default): Applies z-score normalization:
    `(x - mean) / std`

Normalization is enabled by default (`normalize = TRUE`):

- Call `fit()` on training samples to compute feature-wise mean and
  standard deviation

- The same statistics are used for all subsequent `process()` calls
  (train/val/test)

- This ensures no data leakage between training and validation/test sets

## Super classes

[`RHealth::Processor`](https://v1xerunt.github.io/RHealth/reference/Processor.md)
-\>
[`RHealth::FeatureProcessor`](https://v1xerunt.github.io/RHealth/reference/FeatureProcessor.md)
-\> `TimeseriesProcessor`

## Public fields

- `sampling_rate`:

  A lubridate duration indicating the sampling step size.

- `impute_strategy`:

  A character string: 'forward_fill' or 'zero'.

- `normalize`:

  Logical flag indicating whether to apply z-score normalization.
  Default TRUE.

- `feature_means`:

  Numeric vector of feature means (computed during fit).

- `feature_stds`:

  Numeric vector of feature standard deviations (computed during fit).

- `.size`:

  Number of features (set on first call to process()).

## Methods

### Public methods

- [`TimeseriesProcessor$new()`](#method-TimeseriesProcessor-new)

- [`TimeseriesProcessor$fit()`](#method-TimeseriesProcessor-fit)

- [`TimeseriesProcessor$process()`](#method-TimeseriesProcessor-process)

- [`TimeseriesProcessor$size()`](#method-TimeseriesProcessor-size)

- [`TimeseriesProcessor$print()`](#method-TimeseriesProcessor-print)

- [`TimeseriesProcessor$clone()`](#method-TimeseriesProcessor-clone)

Inherited methods

- [`RHealth::Processor$load()`](https://v1xerunt.github.io/RHealth/reference/Processor.html#method-load)
- [`RHealth::Processor$save()`](https://v1xerunt.github.io/RHealth/reference/Processor.html#method-save)

------------------------------------------------------------------------

### Method [`new()`](https://rdrr.io/r/methods/new.html)

Initialize the processor with a sampling rate, imputation strategy, and
normalization option.

#### Usage

    TimeseriesProcessor$new(
      sampling_rate = lubridate::dhours(1),
      impute_strategy = "forward_fill",
      normalize = TRUE
    )

#### Arguments

- `sampling_rate`:

  A lubridate duration (e.g., lubridate::dhours(1)).

- `impute_strategy`:

  Either 'forward_fill' or 'zero'.

- `normalize`:

  Logical, whether to apply z-score normalization. Default TRUE.

------------------------------------------------------------------------

### Method `fit()`

Fit the processor by computing feature-wise mean and std from training
data.

#### Usage

    TimeseriesProcessor$fit(samples, field)

#### Arguments

- `samples`:

  A list of named lists representing sample records.

- `field`:

  A string giving the field name to fit on.

------------------------------------------------------------------------

### Method `process()`

Process irregular time series into uniformly sampled tensor. Step 1:
uniformly sample time points and place values at correct positions. Step
2: impute missing entries using selected strategy. Step 3: (optional)
apply z-score normalization using training statistics.

#### Usage

    TimeseriesProcessor$process(value)

#### Arguments

- `value`:

  A list: list(timestamps = POSIXct vector, values = matrix).

#### Returns

A torch tensor of shape `[T, F]`.

------------------------------------------------------------------------

### Method `size()`

Return the number of features.

#### Usage

    TimeseriesProcessor$size()

#### Returns

Integer

------------------------------------------------------------------------

### Method [`print()`](https://rdrr.io/r/base/print.html)

Print summary

#### Usage

    TimeseriesProcessor$print(...)

#### Arguments

- `...`:

  Ignored.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    TimeseriesProcessor$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
library(torch)
library(lubridate)

# Create training samples with timeseries data
train_samples <- list(
  list(
    patient_id = 1,
    labs = list(
      timestamps = as.POSIXct(c("2020-01-01 00:00:00", "2020-01-01 02:00:00"), tz = "UTC"),
      values = matrix(c(100, 50, 150, 60), ncol = 2)
    )
  ),
  list(
    patient_id = 2,
    labs = list(
      timestamps = as.POSIXct(c("2020-01-01 00:00:00", "2020-01-01 01:00:00"), tz = "UTC"),
      values = matrix(c(120, 55, 180, 65), ncol = 2)
    )
  )
)

# Example 1: Default behavior (with normalization)
processor <- TimeseriesProcessor$new(
  sampling_rate = dhours(1),
  impute_strategy = "forward_fill"
  # normalize = TRUE by default
)

# Fit on training data to compute statistics
processor$fit(train_samples, "labs")

# Process samples (applies normalization)
result <- processor$process(train_samples[[1]]$labs)

# Check normalization statistics
print(processor$feature_means)  # Feature means from training data
print(processor$feature_stds)   # Feature standard deviations

# Example 2: Disable normalization if needed
processor_no_norm <- TimeseriesProcessor$new(
  sampling_rate = dhours(1),
  impute_strategy = "forward_fill",
  normalize = FALSE  # Explicitly disable normalization
)
result_no_norm <- processor_no_norm$process(train_samples[[1]]$labs)
} # }
```
