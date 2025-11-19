# Event: R6 Class for a Single Clinical Event

The `Event` class represents a single clinical event of a patient,
including the event type, timestamp, and a flexible attribute list for
event-specific data.

## Details

This class supports both key-based and attribute-based access to event
properties.

## Public fields

- `event_type`:

  Character. The type of clinical event (e.g., 'medication',
  'diagnosis').

- `timestamp`:

  POSIXct/character. When the event occurred.

- `attr_list`:

  Named list. Additional event-specific attributes.

## Methods

### Public methods

- [`Event$new()`](#method-Event-new)

- [`Event$get()`](#method-Event-get)

- [`Event$clone()`](#method-Event-clone)

------------------------------------------------------------------------

### Method `new()`

Create a new Event instance.

#### Usage

    Event$new(event_type, timestamp, attr_list = list())

#### Arguments

- `event_type`:

  Character. Type of the event.

- `timestamp`:

  POSIXct/character. Timestamp of the event.

- `attr_list`:

  Named list. (Optional) Additional attributes for the event.

#### Returns

An `Event` object.

------------------------------------------------------------------------

### Method [`get()`](https://rdrr.io/r/base/get.html)

Get a value from the event by key.

#### Usage

    Event$get(key)

#### Arguments

- `key`:

  Character. The property name ("event_type", "timestamp" or attribute
  name).

#### Returns

Value of the property if exists, otherwise error.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    Event$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
