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
#' It supports efficient event-type partitioning, fast time-range slicing, and flexible multi-condition filtering.
#'
#' @details
#' - Data is held as a data.frame.
#' - Events can be retrieved as either raw data frames or Event object lists.
#'
#' @export
Patient <- R6::R6Class(
  "Patient",
  public = list(
    #' @field patient_id Character. Unique identifier for the patient.
    patient_id = NULL,

    #' @field data_source data.frame. All events for this patient, sorted by timestamp.
    data_source = NULL,

    #' @field event_type_partitions List. Mapping event type to corresponding data.frames.
    event_type_partitions = NULL,

    #' @description
    #' Create a Patient object.
    #' @param patient_id Character. Unique patient identifier.
    #' @param data_source data.frame. All events (must include event_type, timestamp columns).
    #' @return A `Patient` object.
    initialize = function(patient_id, data_source) {
      self$patient_id <- patient_id
      self$data_source <- data_source %>% dplyr::arrange(timestamp)
      self$event_type_partitions <- split(self$data_source, self$data_source$event_type)
    },

    #' @description
    #' Filter events by time range (O(n), regular scan).
    #' @param df data.frame. Source event data.
    #' @param start Character/POSIXct. (Optional) Start time.
    #' @param end Character/POSIXct. (Optional) End time.
    #' @return data.frame. Events in specified range.
    filter_by_time_range_regular = function(df, start = NULL, end = NULL) {
      if (!is.null(start)) df <- df %>% dplyr::filter(timestamp >= as.POSIXct(start))
      if (!is.null(end)) df <- df %>% dplyr::filter(timestamp <= as.POSIXct(end))
      df
    },

    #' @description
    #' Efficient time range filter via binary search (O(log n)), requires sorted data.
    #' @param df data.frame. Source event data.
    #' @param start Character/POSIXct. (Optional) Start time.
    #' @param end Character/POSIXct. (Optional) End time.
    #' @return data.frame. Filtered events.
    filter_by_time_range_fast = function(df, start = NULL, end = NULL) {
      if (is.null(start) && is.null(end)) return(df)
      df <- df %>% dplyr::filter(!is.na(timestamp))
      ts_col <- df[["timestamp"]]
      ts_col <- as.POSIXct(ts_col, tz = "UTC")
      start_idx <- 1
      end_idx <- length(ts_col)
      if (!is.null(start)) {
        start <- as.POSIXct(start, tz = "UTC") - 1
        start_idx <- as.integer(findInterval(start, ts_col, left.open = FALSE)) + 1
      }
      if (!is.null(end)) {
        end <- as.POSIXct(end, tz = "UTC") + 1
        end_idx <- as.integer(findInterval(end, ts_col, left.open = TRUE))
      }
      if (start_idx > end_idx) return(df[0,])
      return(df[start_idx:end_idx, ])
    },

    #' @description
    #' Regular event type filter (O(n)).
    #' @param df data.frame.
    #' @param event_type Character. Type of event.
    #' @return data.frame.
    filter_by_event_type_regular = function(df, event_type) {
      if (!is.null(event_type)) {
        df <- df %>% dplyr::filter(event_type == !!event_type)
      }
      df
    },

    #' @description
    #' Fast event type filter (O(1)) using partitioned lookup.
    #' @param df data.frame.
    #' @param event_type Character. Type of event.
    #' @return data.frame. Only the given event type.
    filter_by_event_type_fast = function(df, event_type) {
      if (!is.null(event_type)) {
        if (event_type %in% names(self$event_type_partitions)) {
          return(self$event_type_partitions[[event_type]])
        } else {
          return(df[0,])
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
      for (filt in filters) {
        if (!(is.list(filt) && length(filt) == 3)) stop("Each filter must be a 3-element list: (attr, op, value)")
        attr <- filt[[1]]; op <- filt[[2]]; val <- filt[[3]]
        
        # Build a filter condition for dplyr
        # The column name is constructed, and then we build the expression
        col_name <- sprintf("%s/%s", event_type, attr)
        
        # This is a bit of metaprogramming to build the filter expression
        # It's safer than paste() to avoid SQL injection-like issues, though not a DB here.
        filter_expr <- rlang::call2(op, rlang::sym(col_name), val)
        df <- df %>% dplyr::filter(!!filter_expr)
      }
      
      if (return_df) {
        return(df)
      } else {
        
        datalist <- df
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
