# NextMortalityMIMIC4 Task

Task for predicting in-hospital mortality using MIMIC-IV dataset. Uses
lab results from the first 48 hours after admission as input features.

## Super class

[`RHealth::BaseTask`](https://v1xerunt.github.io/RHealth/reference/BaseTask.md)
-\> `NextMortalityMIMIC4`

## Public fields

- `label`:

  the name of the label column.

## Methods

### Public methods

- [`NextMortalityMIMIC4$new()`](#method-NextMortalityMIMIC4-new)

- [`NextMortalityMIMIC4$pre_filter()`](#method-NextMortalityMIMIC4-pre_filter)

- [`NextMortalityMIMIC4$call()`](#method-NextMortalityMIMIC4-call)

- [`NextMortalityMIMIC4$clone()`](#method-NextMortalityMIMIC4-clone)

------------------------------------------------------------------------

### Method `new()`

Initialize a new NextMortalityMIMIC4 instance.

#### Usage

    NextMortalityMIMIC4$new()

------------------------------------------------------------------------

### Method `pre_filter()`

Pre-filter hook to retain only necessary columns for this task.

#### Usage

    NextMortalityMIMIC4$pre_filter(df)

#### Arguments

- `df`:

  A lazy query containing all events.

#### Returns

A filtered LazyFrame with only relevant columns.

------------------------------------------------------------------------

### Method [`call()`](https://rdrr.io/r/base/call.html)

Main processing method to generate samples.

#### Usage

    NextMortalityMIMIC4$call(patient)

#### Arguments

- `patient`:

  An object with method `get_events(event_type, ...)`.

#### Returns

A list of samples.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    NextMortalityMIMIC4$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
