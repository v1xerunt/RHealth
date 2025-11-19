# NextMortalityMIMIC3 Task

Task for predicting in-hospital mortality using MIMIC-III dataset. This
task aims to predict whether the patient will decease in the next
hospital visit based on clinical information from the current visit.

## Super class

[`RHealth::BaseTask`](https://v1xerunt.github.io/RHealth/reference/BaseTask.md)
-\> `NextMortalityMIMIC3`

## Public fields

- `label`:

  the name of the label column.

## Methods

### Public methods

- [`NextMortalityMIMIC3$new()`](#method-NextMortalityMIMIC3-new)

- [`NextMortalityMIMIC3$pre_filter()`](#method-NextMortalityMIMIC3-pre_filter)

- [`NextMortalityMIMIC3$call()`](#method-NextMortalityMIMIC3-call)

- [`NextMortalityMIMIC3$clone()`](#method-NextMortalityMIMIC3-clone)

------------------------------------------------------------------------

### Method `new()`

Initialize a new NextMortalityMIMIC3 instance.

#### Usage

    NextMortalityMIMIC3$new()

------------------------------------------------------------------------

### Method `pre_filter()`

Pre-filter hook to retain only necessary columns for this task.

#### Usage

    NextMortalityMIMIC3$pre_filter(df)

#### Arguments

- `df`:

  A lazy query containing all events.

#### Returns

A filtered LazyFrame with only relevant columns.

------------------------------------------------------------------------

### Method [`call()`](https://rdrr.io/r/base/call.html)

Main processing method to generate samples.

#### Usage

    NextMortalityMIMIC3$call(patient)

#### Arguments

- `patient`:

  An object with method `get_events(event_type, ...)`.

#### Returns

A list of samples.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    NextMortalityMIMIC3$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
