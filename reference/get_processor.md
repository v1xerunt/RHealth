# Get Processor Class (Hardcoded Version)

Retrieves a registered processor class by lowercase name. This version
uses explicit `if` statements instead of a dynamic map. This is less
scalable but more explicit and avoids global object lookup.

## Usage

``` r
get_processor(name)
```

## Arguments

- name:

  Character. The processor type key (e.g., "text", "regression").

## Value

An R6ClassGenerator object corresponding to the requested processor.

## Examples

``` r
get_processor("text")$new()
#> TextProcessor()
get_processor("multilabel")$new()
#> MultiLabelProcessor(label_vocab_size=0)
```
