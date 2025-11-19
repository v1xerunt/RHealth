# Map a Code from One System to Another

Looks up the equivalent code(s) in a target coding system for a given
source code, using the built‑in crosswalk CSV tables.

## Usage

``` r
map_code(code, from = "ICD9CM", to = "CCSCM")
```

## Arguments

- code:

  A single `character` string specifying the code to map.

- from:

  A single `character` string naming the source code system (e.g.
  `"ICD9CM"`, `"ATC"`). Must be one of the systems listed in
  [`supported_inner()`](https://v1xerunt.github.io/RHealth/reference/supported_inner.md).

- to:

  A single `character` string naming the target code system (e.g.
  `"CCSCM"`, `"NDC"`). The pair `paste0(from, "_to_", to)` must be one
  of
  [`supported_cross()`](https://v1xerunt.github.io/RHealth/reference/supported_cross.md).

## Value

A character vector of mapped code(s) in the target system. If no match
is found, returns an empty `character` vector.

## See also

[`load_medcode`](https://v1xerunt.github.io/RHealth/reference/load_medcode.md),
[`supported_cross`](https://v1xerunt.github.io/RHealth/reference/supported_cross.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Map an ICD-10 code to its CCS category
map_code("I10", from = "ICD10CM", to = "CCSCM")
} # }
```
