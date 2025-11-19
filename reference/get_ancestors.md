# Get Ancestor Codes in the Hierarchy

For a given code, returns all ancestor codes by following the
`parent_code` pointers until the root.

## Usage

``` r
get_ancestors(code, system = "ICD9CM")
```

## Arguments

- code:

  A single `character` string specifying the starting code.

- system:

  A single `character` string naming the code system, one of
  [`supported_inner()`](https://v1xerunt.github.io/RHealth/reference/supported_inner.md).
  Defaults to `"ICD9CM"`.

## Value

A character vector of ancestor codes, ordered from immediate parent up
to the highest-level ancestor.

## See also

[`get_descendants`](https://v1xerunt.github.io/RHealth/reference/get_descendants.md),
[`load_medcode`](https://v1xerunt.github.io/RHealth/reference/load_medcode.md)

## Examples

``` r
if (FALSE) { # \dontrun{
get_ancestors("401.9", "ICD9CM")
} # }
```
