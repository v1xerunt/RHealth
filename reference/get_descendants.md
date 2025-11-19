# Get Descendant Codes in the Hierarchy

For a given code, returns all descendant codes (children, grandchildren,
etc.) by traversing the hierarchy downward.

## Usage

``` r
get_descendants(code, system = "ICD9CM")
```

## Arguments

- code:

  A single `character` string specifying the starting code.

- system:

  A single `character` string naming the code system, one of
  [`supported_inner()`](https://v1xerunt.github.io/RHealth/reference/supported_inner.md).
  Defaults to `"ICD9CM"`.

## Value

A character vector of all descendant codes, in no particular order.

## See also

[`get_ancestors`](https://v1xerunt.github.io/RHealth/reference/get_ancestors.md),
[`load_medcode`](https://v1xerunt.github.io/RHealth/reference/load_medcode.md)

## Examples

``` r
if (FALSE) { # \dontrun{
get_descendants("A00", "ICD10CM")
} # }
```
