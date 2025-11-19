# Load the Drug–Drug Interaction (DDI) Table for ATC Codes

Retrieves the full drug–drug interaction table for ATC codes from the
cached resource. The table contains all pairs of interacting ATC codes.

## Usage

``` r
get_ddi()
```

## Value

A tibble with two character columns:

- ATC_i:

  First ATC code in the interacting pair

- ATC_j:

  Second ATC code in the interacting pair

## See also

[`load_medcode`](https://v1xerunt.github.io/RHealth/reference/load_medcode.md)

## Examples

``` r
ddi_tbl <- get_ddi()
head(ddi_tbl)
#> # A tibble: 6 × 2
#>   ATC_i   ATC_j  
#>   <chr>   <chr>  
#> 1 S01AA19 N01AH01
#> 2 S01AA19 N02AB03
#> 3 J01CA01 N01AH01
#> 4 J01CA01 N02AB03
#> 5 N01AB08 R03DA05
#> 6 J01XX08 J01DH03
```
