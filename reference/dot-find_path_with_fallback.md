# Find an existing data file path with fallback for .gz extension.

This function checks for the existence of a path and its alternative
with/without `.gz`. It also determines the separator based on the file
extension (.csv or .tsv).

## Usage

``` r
.find_path_with_fallback(path)
```

## Arguments

- path:

  A character path to a .csv, .csv.gz, .tsv, or .tsv.gz file.

## Value

A list with `path` to an existing file and `separator` (',' or a tab).
