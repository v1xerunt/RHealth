#' @title Event: R6 Class for a Single Clinical Event
#'
#' @description
#' The `Event` class represents a single clinical event of a patient, including the event type, timestamp, and a flexible attribute list for event-specific data.
#'
#' @details
#' This class supports both key-based and attribute-based access to event properties.
#'
#' @export
Event <- R6::R6Class(
  "Event",
  public = list(
    #' @field event_type Character. The type of clinical event (e.g., 'medication', 'diagnosis').
    event_type = NULL,

    #' @field timestamp POSIXct/character. When the event occurred.
    timestamp = NULL,

    #' @field attr_list Named list. Additional event-specific attributes.
    attr_list = NULL,

    #' @description
    #' Create a new Event instance.
    #'
    #' @param event_type Character. Type of the event.
    #' @param timestamp POSIXct/character. Timestamp of the event.
    #' @param attr_list Named list. (Optional) Additional attributes for the event.
    #' @return An `Event` object.
    initialize = function(event_type, timestamp, attr_list = list()) {
      self$event_type <- event_type
      self$timestamp <- timestamp
      self$attr_list <- attr_list
    },

    #' @description
    #' Get a value from the event by key.
    #' @param key Character. The property name ("event_type", "timestamp" or attribute name).
    #' @return Value of the property if exists, otherwise error.
    get = function(key) {
      if (key == "event_type") return(self$event_type)
      if (key == "timestamp") return(self$timestamp)
      full_key <- paste0(self$event_type, "/", key)
      if (full_key %in% names(self$attr_list)) return(self$attr_list[[full_key]])
      stop(sprintf("No such field: %s", key))
    }
  )
)
#' @title from_list: Create Event from row
#' @name Event-from_list
#' @description Creates a new Event object from a named list.
#' @param row Named list of attributes.
#' @param event_type_col Name of column to use as event_type.
#' @param timestamp_col Name of column to use as timestamp.
#' @return An Event R6 object.
#' @seealso \code{\link{Event}}
  Event$from_list <- function(row, event_type_col = "event_type", timestamp_col = "timestamp") {
    event_type <- row[[event_type_col]]
    timestamp <- row[[timestamp_col]]
    attr_names <- setdiff(names(row), c(event_type_col, timestamp_col, "patient_id"))
    attr_list <- as.list(row[attr_names])
    Event$new(event_type = event_type, timestamp = timestamp, attr_list = attr_list)
  }

#' @title Patient: R6 Class for a Sequence of Events
#'
#' @description
#' The `Patient` class manages all clinical events for a single patient.
#' It supports efficient event-type partitioning, fast time-range slicing, and flexible multi-condition filtering using rpolars.
#'
#' @details
#' - Data is held as a polars DataFrame.
#' - Events can be retrieved as either raw data frames or Event object lists.
#'
#' @export
Patient <- R6::R6Class(
  "Patient",
  public = list(
    #' @field patient_id Character. Unique identifier for the patient.
    patient_id = NULL,

    #' @field data_source Polars DataFrame. All events for this patient, sorted by timestamp.
    data_source = NULL,

    #' @field event_type_partitions List. Mapping event type to corresponding polars DataFrames.
    event_type_partitions = NULL,

    #' @description
    #' Create a Patient object.
    #' @param patient_id Character. Unique patient identifier.
    #' @param data_source Polars DataFrame. All events (must include event_type, timestamp columns).
    #' @return A `Patient` object.
    initialize = function(patient_id, data_source) {
      self$patient_id <- patient_id
      self$data_source <- data_source$sort("timestamp")
      self$event_type_partitions <- self$data_source$partition_by("event_type", maintain_order = TRUE, include_key    = TRUE, as_nested_list = TRUE)
    },

    #' @description
    #' Filter events by time range (O(n), regular scan).
    #' @param df Polars DataFrame. Source event data.
    #' @param start Character/POSIXct. (Optional) Start time.
    #' @param end Character/POSIXct. (Optional) End time.
    #' @return Polars DataFrame. Events in specified range.
    filter_by_time_range_regular = function(df, start = NULL, end = NULL) {
      if (!is.null(start)) df <- df$filter(pl$col("timestamp") >= as.character(start))
      if (!is.null(end)) df <- df$filter(pl$col("timestamp") <= as.character(end))
      df
    },

    #' @description
    #' Efficient time range filter via binary search (O(log n)), requires sorted data.
    #' @param df Polars DataFrame. Source event data.
    #' @param start Character/POSIXct. (Optional) Start time.
    #' @param end Character/POSIXct. (Optional) End time.
    #' @return Polars DataFrame. Filtered events.
    filter_by_time_range_fast = function(df, start = NULL, end = NULL) {
      if (is.null(start) && is.null(end)) return(df)
      df <- df$filter(pl$col("timestamp")$is_not_null())
      ts_col <- df$to_data_frame()[["timestamp"]]
      ts_col <- as.POSIXct(ts_col, tz = "UTC")
      start_idx <- 0
      end_idx <- length(ts_col)
      if (!is.null(start)) {
        start <- as.POSIXct(start, tz = "UTC") -1
        start_idx <- as.integer(findInterval(start, ts_col, left.open = FALSE))
      }else {
        start_idx <- 0
      }
      if (!is.null(end)) {
        end <- as.POSIXct(end, tz = "UTC") + 1
        end_idx <- as.integer(findInterval(end, ts_col, left.open = TRUE))
      }else {
        end_idx <- length(ts_col)
      }
      return(df$slice(start_idx, end_idx - start_idx))
    },

    #' @description
    #' Regular event type filter (O(n)).
    #' @param df Polars DataFrame.
    #' @param event_type Character. Type of event.
    #' @return Polars DataFrame.
    filter_by_event_type_regular = function(df, event_type) {
      if (!is.null(event_type)) {
        df <- df$filter(pl$col("event_type") == event_type)
      }
      df
    },

    #' @description
    #' Fast event type filter (O(1)) using partitioned lookup.
    #' @param df Polars DataFrame.
    #' @param event_type Character. Type of event.
    #' @return Polars DataFrame. Only the given event type.
    filter_by_event_type_fast = function(df, event_type) {
      if (!is.null(event_type)) {
        keystr <- event_type
        match_idx <- which(sapply(self$event_type_partitions, \(x) x$key$event_type == keystr))

        if (length(match_idx) > 0) {
          return(self$event_type_partitions[[match_idx]]$data)
        } else {
          return(df$slice(0,0))
        }
      } else {
        return(df)
      }
    },

    #' @description
    #' Get events with optional type, time, and custom attribute filters.
    #'
    #' @param event_type Character. (Optional) Filter by event type.
    #' @param start Character/POSIXct. (Optional) Start time for filtering events.
    #' @param end Character/POSIXct. (Optional) End time for filtering events.
    #' @param filters List of lists. (Optional) Each filter: list(attr, op, value) e.g. list(list("dose", ">", 10)).
    #' @param return_df Logical. If TRUE, return as data.frame; else as Event object list.
    #' @return data.frame or list of Event objects.
    get_events = function(event_type = NULL, start = NULL, end = NULL, filters = NULL, return_df = FALSE) {
      # High-efficiency: event type + binary search

      df <- self$filter_by_event_type_fast(self$data_source, event_type)
      df <- self$filter_by_time_range_fast(df, start, end)
      if (is.null(filters)) filters <- list()
      if (length(filters) > 0 && is.null(event_type)) stop("event_type must be provided if filters are used")
      exprs <- list()
      for (filt in filters) {
        if (!(is.list(filt) && length(filt) == 3)) stop("Each filter must be a 3-element list: (attr, op, value)")
        attr <- filt[[1]]; op <- filt[[2]]; val <- filt[[3]]
        col_expr <- pl$col(sprintf("%s/%s", event_type, attr))
        exprs <- append(exprs, switch(
          op,
          "==" = col_expr == val,
          "!=" = col_expr != val,
          "<"  = col_expr < val,
          "<=" = col_expr <= val,
          ">"  = col_expr > val,
          ">=" = col_expr >= val,
          stop(sprintf("Unsupported operator: %s", op))
        ))
      }
      if (length(exprs) > 0) {
        filter_expr <- purrr::reduce(`&`, exprs)
        df <- df$filter(filter_expr)
      }

      if (return_df) {
        return(df)
      } else {

        datalist <- df$to_data_frame()
        if (nrow(datalist) == 0) {
          return(list())
        }
        purrr::map(seq_len(nrow(datalist)), function(i) {
          Event$from_list(as.list(datalist[i, ]))
        })
      }
    }
  )
)
