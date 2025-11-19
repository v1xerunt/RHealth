# Sequence Processor

Feature processor for encoding categorical sequences (e.g., medical
codes) into numerical indices. Supports dynamic vocabulary construction.

## Super classes

[`RHealth::Processor`](https://v1xerunt.github.io/RHealth/reference/Processor.md)
-\>
[`RHealth::FeatureProcessor`](https://v1xerunt.github.io/RHealth/reference/FeatureProcessor.md)
-\> `SequenceProcessor`

## Public fields

- `code_vocab`:

  A named integer vector representing token-to-index mappings.

- `.next_index`:

  The next available index for unseen tokens.

## Methods

### Public methods

- [`SequenceProcessor$new()`](#method-SequenceProcessor-new)

- [`SequenceProcessor$process()`](#method-SequenceProcessor-process)

- [`SequenceProcessor$size()`](#method-SequenceProcessor-size)

- [`SequenceProcessor$print()`](#method-SequenceProcessor-print)

- [`SequenceProcessor$clone()`](#method-SequenceProcessor-clone)

Inherited methods

- [`RHealth::Processor$load()`](https://v1xerunt.github.io/RHealth/reference/Processor.html#method-load)
- [`RHealth::Processor$save()`](https://v1xerunt.github.io/RHealth/reference/Processor.html#method-save)
- [`RHealth::FeatureProcessor$fit()`](https://v1xerunt.github.io/RHealth/reference/FeatureProcessor.html#method-fit)

------------------------------------------------------------------------

### Method `new()`

Initialize with default vocabulary for and .

#### Usage

    SequenceProcessor$new()

------------------------------------------------------------------------

### Method `process()`

Process a sequence of tokens into a tensor of indices.

#### Usage

    SequenceProcessor$process(value)

#### Arguments

- `value`:

  A character vector of tokens.

#### Returns

A long-type tensor of indices.

------------------------------------------------------------------------

### Method `size()`

Return size of vocabulary.

#### Usage

    SequenceProcessor$size()

#### Returns

Integer

------------------------------------------------------------------------

### Method [`print()`](https://rdrr.io/r/base/print.html)

Print summary.

#### Usage

    SequenceProcessor$print(...)

#### Arguments

- `...`:

  Ignored.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    SequenceProcessor$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
