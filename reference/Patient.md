# Patient: R6 Class for a Sequence of Events

The `Patient` class manages all clinical events for a single patient. It
supports efficient event-type partitioning, fast time-range slicing, and
flexible multi-condition filtering.

## Details

- Data is held as a data.frame.

- Events can be retrieved as either raw data frames or Event object
  lists.

## Public fields

- `patient_id`:

  Character. Unique identifier for the patient.

- `data_source`:

  data.frame. All events for this patient, sorted by timestamp.

- `event_type_partitions`:

  List. Mapping event type to corresponding data.frames.

## Methods

### Public methods

- [`Patient$new()`](#method-Patient-new)

- [`Patient$filter_by_time_range_regular()`](#method-Patient-filter_by_time_range_regular)

- [`Patient$filter_by_time_range_fast()`](#method-Patient-filter_by_time_range_fast)

- [`Patient$filter_by_event_type_regular()`](#method-Patient-filter_by_event_type_regular)

- [`Patient$filter_by_event_type_fast()`](#method-Patient-filter_by_event_type_fast)

- [`Patient$get_events()`](#method-Patient-get_events)

- [`Patient$clone()`](#method-Patient-clone)

------------------------------------------------------------------------

### Method `new()`

Create a Patient object.

#### Usage

    Patient$new(patient_id, data_source)

#### Arguments

- `patient_id`:

  Character. Unique patient identifier.

- `data_source`:

  data.frame. All events (must include event_type, timestamp columns).

#### Returns

A `Patient` object.

------------------------------------------------------------------------

### Method `filter_by_time_range_regular()`

Filter events by time range (O(n), regular scan).

#### Usage

    Patient$filter_by_time_range_regular(df, start = NULL, end = NULL)

#### Arguments

- `df`:

  data.frame. Source event data.

- `start`:

  Character/POSIXct. (Optional) Start time.

- `end`:

  Character/POSIXct. (Optional) End time.

#### Returns

data.frame. Events in specified range.

------------------------------------------------------------------------

### Method `filter_by_time_range_fast()`

Efficient time range filter via binary search (O(log n)), requires
sorted data.

#### Usage

    Patient$filter_by_time_range_fast(df, start = NULL, end = NULL)

#### Arguments

- `df`:

  data.frame. Source event data.

- `start`:

  Character/POSIXct. (Optional) Start time.

- `end`:

  Character/POSIXct. (Optional) End time.

#### Returns

data.frame. Filtered events.

------------------------------------------------------------------------

### Method `filter_by_event_type_regular()`

Regular event type filter (O(n)).

#### Usage

    Patient$filter_by_event_type_regular(df, event_type)

#### Arguments

- `df`:

  data.frame.

- `event_type`:

  Character. Type of event.

#### Returns

data.frame.

------------------------------------------------------------------------

### Method `filter_by_event_type_fast()`

Fast event type filter (O(1)) using partitioned lookup.

#### Usage

    Patient$filter_by_event_type_fast(df, event_type)

#### Arguments

- `df`:

  data.frame.

- `event_type`:

  Character. Type of event.

#### Returns

data.frame. Only the given event type.

------------------------------------------------------------------------

### Method `get_events()`

Get events with optional type, time, and custom attribute filters.

#### Usage

    Patient$get_events(
      event_type = NULL,
      start = NULL,
      end = NULL,
      filters = NULL,
      return_df = FALSE
    )

#### Arguments

- `event_type`:

  Character. (Optional) Filter by event type.

- `start`:

  Character/POSIXct. (Optional) Start time for filtering events.

- `end`:

  Character/POSIXct. (Optional) End time for filtering events.

- `filters`:

  List of lists. (Optional) Each filter: list(attr, op, value) e.g.
  list(list("dose", "\>", 10)).

- `return_df`:

  Logical. If TRUE, return as data.frame; else as Event object list.

#### Returns

data.frame or list of Event objects.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    Patient$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
