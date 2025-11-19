# Load and Parse Medical Code CSV

Downloads (if necessary) and reads a medical code CSV for the specified
name, returning a tibble with all columns as character.

## Usage

``` r
load_medcode(name)
```

## Arguments

- name:

  Character(1). Identifier of the medical code CSV (without the '.csv'
  extension), e.g. `"ICD10"` or `"CPT"`.

## Value

A tibble
([`tibble::tibble`](https://tibble.tidyverse.org/reference/tibble.html))
in which every column is of type character.

## Details

Internally, this function calls
[`download_medcode()`](https://v1xerunt.github.io/RHealth/reference/download_medcode.md)
to ensure the requested CSV is present in the local cache. It then
invokes
[`readr::read_csv()`](https://readr.tidyverse.org/reference/read_delim.html)
with `col_types = cols(.default = "c")` so that all columns are imported
as character.

## See also

[`download_medcode`](https://v1xerunt.github.io/RHealth/reference/download_medcode.md),
[`read_csv`](https://readr.tidyverse.org/reference/read_delim.html)

## Examples

``` r
if (FALSE) { # \dontrun{
# Load the ICD-10 mapping table
icd10_tbl <- load_medcode("ICD10")
} # }
```
