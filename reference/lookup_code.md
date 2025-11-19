# Lookup a Medical Code Entry

Retrieves the row(s) in the code table matching a given code.

## Usage

``` r
lookup_code(code, system = "ICD9CM")
```

## Arguments

- code:

  A single `character` string specifying the code to look up.

- system:

  A single `character` string naming the code system, one of
  [`supported_inner()`](https://v1xerunt.github.io/RHealth/reference/supported_inner.md).
  Defaults to `"ICD9CM"`.

## Value

A `data.frame` (or tibble) containing all columns for the matching code.
If no match is found, returns an empty data frame with the same columns
as the code table.

## See also

[`load_medcode`](https://v1xerunt.github.io/RHealth/reference/load_medcode.md),
[`supported_inner`](https://v1xerunt.github.io/RHealth/reference/supported_inner.md)

## Examples

``` r
if (FALSE) { # \dontrun{
lookup_code("A00", "ICD10CM")
} # }
```
