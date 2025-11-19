# Truncate an ATC Code to a Specified Level

Truncates one or more ATC codes to the given number of characters,
corresponding to the desired ATC classification level (e.g., anatomical
main group, therapeutic subgroup, chemical substance).

## Usage

``` r
atc_convert(code, level = 5)
```

## Arguments

- code:

  A character scalar or vector of ATC codes, e.g. `"A01AA01"`.

- level:

  An integer scalar between 1 and 7 indicating how many characters to
  retain. Defaults to `5`.

## Value

A character vector of truncated ATC codes.

## Examples

``` r
atc_convert("A01AA01", level = 3)
#> [1] "A01"
atc_convert(c("B02BA02", "C03CA01"), level = 5)
#> [1] "B02BA" "C03CA"
```
