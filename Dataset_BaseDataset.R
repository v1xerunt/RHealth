
#' BaseDataset — R6 infrastructure for clinical event datasets
#'
#' The **BaseDataset** class mirrors rhealth's `BaseDataset`, providing a
#' fully‑featured, YAML driven loader that converts multi‑table electronic
#' health records into a single *event* table.  It supports:
#' \itemize{
#'   \item URL or local‐file ingestion (with automatic `.csv` / `.csv.gz`
#'         fallback).
#'   \item Per‑table joins as declared in the config.
#'   \item Flexible timestamp parsing (single or multi‑column).
#'   \item A \code{dev} mode that caps the number of patients for rapid
#'         prototyping.
#'   \item Multi‑threaded sample generation with progress bars.
#' }
#'


#' Down‑stream, it cooperates with \code{BaseTask} (task definition),
#' \code{Patient} (per‑subject wrapper), and \code{SampleDataset} (collection of
#' input/output pairs).
#'
#' @section Dependencies:
#' Polars is used via the \code{polars} R package.  Parallelism and progress
#' reporting require \code{future}, \code{future.apply}, and \code{progressr}.
#' @importFrom polars pl
#' @importFrom future plan multisession
#' @importFrom future.apply future_lapply
#' @importFrom progressr handlers progressor
#' @importFrom R6 R6Class
#' @export
BaseDataset <- R6::R6Class(
  "BaseDataset",
  public = list(
    #--------------------------------------------------------------------
    # Public fields -----------------------------------------------------
    #' @field root Root directory (or URL prefix) for data files.
    root = NULL,

    #' @field tables Character vector of table names to ingest.
    tables = NULL,

    #' @field dataset_name Human‑readable dataset label.
    dataset_name = NULL,

    #' @field config Parsed YAML configuration list.
    config = NULL,

    #' @field dev Logical flag — when TRUE limits to 1 000 patients.
    dev = FALSE,

    #' @field global_event_df A polars LazyFrame with all events combined.
    global_event_df = NULL,

    #--------------------------------------------------------------------
    # Private‑cache fields ----------------------------------------------
    #' @field .collected_global_event_df Polars dataframe storing all global events.
    .collected_global_event_df = NULL,
    #' @field .unique_patient_ids Character vector of unique patient IDs.
    .unique_patient_ids        = NULL,

    #--------------------------------------------------------------------
    # Constructor -------------------------------------------------------
    #' @description
    #' Instantiate a \code{BaseDataset}.
    #'
    #' @param root Character.  Root directory / URL prefix where CSV files live.
    #' @param tables Character vector of table keys defined in the config.
    #' @param dataset_name Optional custom name; defaults to the R6 class name.
    #' @param config_path Path to YAML or  schema describing each table.
    #' @param dev Logical.  If TRUE, limits to 1 000 patients for speed.
    initialize = function(root,
                          tables,
                          dataset_name = NULL,
                          config_path  = NULL,
                          dev          = FALSE) {

      self$root         <- root
      self$tables       <- unique(tolower(tables))
      self$dataset_name <- if (!is.null(dataset_name)) dataset_name else class(self)[1]
      self$config <- load_yaml_config(config_path)
      self$dev          <- dev

      message(sprintf("Initializing %s (dev = %s)", self$dataset_name, dev))
      self$global_event_df <- self$load_data()
    },

    #--------------------------------------------------------------------
    #' @description
    #' Materialise (collect) the lazy event dataframe.  In dev‑mode only the
    #' first 1 000 patients are kept.
    #' @return A polars DataFrame containing all selected events.
    collected_global_event_df = function() {
    if (is.null(self$.collected_global_event_df)) {
    message("[info] Collecting global event dataframe …")

    df <- self$global_event_df   # LazyFrame

    # ---------------- Development mode: limit to 1 000 patients ----------------
      schema <- df$schema
      dt_cols <- names(
        Filter(function(dtype) {
          tryCatch({
            dtype$kind() == "Datetime"
          }, error = function(e) FALSE)
        }, schema)
      )

      if (length(dt_cols) > 0) {
        cast_exprs <- lapply(dt_cols, function(colname) {
          pl$col(colname)$cast(pl$Utf8)$alias(colname)
        })
        df <- df$with_columns(cast_exprs)
      }

      self$.collected_global_event_df <- df$collect()

      # shp <- self$.collected_global_event_df$shape()
      # message(
      #   sprintf("[info] Collected dataframe shape: (%d rows, %d columns)",
      #           shp[1], shp[2])
      # )
    }

    return(self$.collected_global_event_df)
  },



    #--------------------------------------------------------------------
    #' @description
    #' Load one table, apply joins, lowercase columns, and standardise to the
    #' event schema.
    #' @param table_name Character key present in \code{config$tables}.
    #' @return A polars LazyFrame in event format.
    load_table = function(table_name) {

    if (!(table_name %in% names(self$config$tables)))
      stop(sprintf("Table %s not in config", table_name))

    cfg       <- self$config$tables[[table_name]]
    csv_path  <- .clean_path(file.path(self$root, cfg$file_path))
    parquet_path <- .csv2parquet_path(csv_path)

    # one-time conversion; subsequent runs hit the cached parquet
    .ensure_parquet(csv_path, parquet_path)

    message(sprintf("Scanning %s", parquet_path))
    lf <- pl$scan_parquet(parquet_path, streaming = TRUE)

    # ── optional joins (each join source is treated the same way) ──
    if (!is.null(cfg$join)) {
      for (j in cfg$join) {
        join_csv  <- .clean_path(file.path(self$root, j$file_path))
        join_parq <- .csv2parquet_path(join_csv)
        .ensure_parquet(join_csv, join_parq)

        join_df <- pl$scan_parquet(join_parq, streaming = TRUE)$
          select(j$on, j$columns)

        lf <- lf$join(join_df, on = j$on, how = j$how)
      }
    }

    # ── timestamp expression ─────────────────────────────────────
    ts_expr <- if (!is.null(cfg$timestamp)) {
      if (is.list(cfg$timestamp)) {
        pl$concat_str(lapply(cfg$timestamp, pl$col))
      } else {
        pl$col(cfg$timestamp)
      }
    } else {
      pl$lit(NA_character_)
    }

    # ── patient-id handling ──────────────────────────────────────
    pid_expr <- if (!is.null(cfg$patient_id))
                  pl$col(cfg$patient_id)$cast(pl$Utf8)
                else
                  pl$int_range(0, pl$count())$cast(pl$Utf8)

    # ── attribute columns (prefixed with table name) ─────────────
    attrs <- lapply(cfg$attributes, function(a)
              pl$col(a)$alias(paste0(table_name, "/", a)))

    # ── final event-schema LazyFrame ─────────────────────────────
    exprs_all <- c(
      list(pid_expr$alias("patient_id")),
      list(pl$lit(table_name)$cast(pl$Utf8)$alias("event_type")),
      list(ts_expr$alias("timestamp")),
      attrs
    )

    lf <- lf$select(exprs_all)
    },

    #--------------------------------------------------------------------
    #' @description
    #' Load every configured table, returning a single \emph{lazy} frame.
    #' @return A polars LazyFrame.
    load_data = function() {
      ## 1. build a list of LazyFrames (one per table)
      frames <- lapply(self$tables, self$load_table)  # each item is LazyFrame

      ## 2. concatenate lazily
      #    * "diagonal_relaxed": keeps columns even if some tables lack them
      #    * rechunk = FALSE   : avoid an eager rechunk that can eat memory
      #    * parallel  = TRUE  : allow multi-threaded scan
      df <- pl$concat(
              frames,
              how      = "diagonal_relaxed",
              rechunk  = FALSE,
              parallel = TRUE
            )

      ## 3.  dev-mode: early down-sampling to speed up prototyping
      if (isTRUE(self$dev) && "patient_id" %in% names(df$schema)) {
        message("[dev] Limiting to 1000 patients (early filter)")
        patient_ids <- df$
          select("patient_id")$
          unique()$
          limit(1000)$collect()$to_series()$to_list()
        patient_ids <- unlist(patient_ids)
        df <- df$filter(pl$col("patient_id")$is_in(patient_ids))
      }

      ## 4. return the final LazyFrame
      return(df)
    },

    #--------------------------------------------------------------------
    #' @description
    #' Retrieve (and cache) the vector of unique patient IDs.
    #' @return Character vector of patient IDs.
    unique_patient_ids = function() {
      if (is.null(self$.unique_patient_ids))
        self$.unique_patient_ids <- self$collected_global_event_df()$
          select("patient_id")$unique()$to_series()$to_list()
      self$.unique_patient_ids
    },

    #--------------------------------------------------------------------
    #' @description
    #' Construct a \code{Patient} object for one subject.
    #' @param patient_id Character identifier.
    #' @return A new \code{Patient} R6 instance.
    get_patient = function(patient_id) {
      stopifnot(patient_id %in% self$unique_patient_ids())
      sub_df <- self$collected_global_event_df()$
                 filter(pl$col("patient_id") == patient_id)
      Patient$new(patient_id = patient_id, data_source = sub_df)
    },

    #--------------------------------------------------------------------
    #' @description
    #' Iterate over all patients (optionally a filtered dataframe).
    #' @param df Optional polars DataFrame (already collected).
    #' @return List of \code{Patient} objects.
    iter_patients = function(df = NULL) {
      ids <- self$unique_patient_ids()
      ids <- head(ids, 100)

      progressr::handlers(global = TRUE)
      p <- progressr::progressor(steps = length(ids))

      lapply(seq_along(ids), function(i) {
        id <- ids[[i]]
        percent <- sprintf("%.1f%%", (i / length(ids)) * 100)

        p(message = sprintf("[%s] Processing patient: %s", percent, id))

        Patient$new(
          patient_id = id,
          data_source = df$filter(pl$col("patient_id")$eq(id))
        )
      })
    },


    #--------------------------------------------------------------------
    #' @description
    #' Print dataset‑level statistics.
    #' @return Invisible NULL (called for side‑effects).
    stats = function() {
      df <- self$collected_global_event_df()
      cat(sprintf("Dataset : %s\n", self$dataset_name))
      cat(sprintf("Dev mode : %s\n", self$dev))
      cat(sprintf("Patients : %d\n", length(self$unique_patient_ids())))
      cat(sprintf("Events   : %d\n", df$height))
      invisible(NULL)
    },

    #--------------------------------------------------------------------
    #' @description
    #' Default task placeholder (override in subclass).
    #' @return NULL
    default_task = function() NULL,

    #--------------------------------------------------------------------
    #' @description
    #' Apply a \code{BaseTask} to build a \code{SampleDataset}.
    #' @param task A \code{BaseTask} instance; if NULL, \code{default_task()} is
    #'   used.
    #' @param num_workers Integer ≥ 1.  Number of parallel workers.
    #' @return A populated \code{SampleDataset}.
    set_task = function(task = NULL, num_workers = 1) {
      task <- task %||% self$default_task()

      stopifnot(!is.null(task))
      cat(task$task_name, "\n")
      message(sprintf("Generating samples for task %s", task$task_name))

      df <- self$collected_global_event_df()
      filtered_df <- task$pre_filter(df)

      patients    <- self$iter_patients(filtered_df)

      progressr::handlers(global = TRUE)

      if (num_workers == 1) {
        p <- progressr::progressor(along = patients)
        samples <- unlist(lapply(patients, function(pat) { p(); task$call(pat) }),
                          recursive = FALSE)
      } else {
        future::plan(future::multisession, workers = num_workers)
        samples <- future.apply::future_lapply(patients, task$call)
        samples <- unlist(samples, recursive = FALSE)
      }

      message(sprintf("Generated %d samples", length(samples)))
      result <- SampleDataset(
        samples       = samples,
        input_schema  = task$input_schema,
        output_schema = task$output_schema,
        dataset_name  = self$dataset_name,
        task_name     = task
      )
      message("[info] Task set successfully")
      return(result)
    }
  )
)

# ─────────────────────────────────────────────────────────────────────────────
# Internal helper wrappers (prefixed with .) ----------------------------------


#' Determines whether a path is an HTTP(S) URL.
#' @param path A character string.
#' @return Logical scalar indicating if it's a valid URL.
#' @keywords internal
.is_url <- function(path) grepl("^(http|https)://", path)

#' Normalizes a local file path or returns the URL unchanged.
#' @param path A character path or URL.
#' @return Normalized character string.
#' @keywords internal
.clean_path <- function(path) {
  if (.is_url(path)) path
  else normalizePath(path, winslash = "/", mustWork = FALSE)
}

#' Tests whether a local path or remote URL exists.
#' @param path A character path or URL.
#' @return Logical scalar indicating existence.
#' @keywords internal
.path_exists <- function(path) {
  if (.is_url(path)) {
    res <- try(httr::HEAD(path, timeout = 5), silent = TRUE)
    !inherits(res, "try-error") && httr::status_code(res) == 200
  } else {
    file.exists(path)
  }
}


#' Lazily loads a `.csv` or `.csv.gz` file and returns a Polars LazyFrame.
#' Automatically tries the alternate extension if the primary path fails.
#' @param path File path or URL ending in `.csv` or `.csv.gz`.
#' @return A polars LazyFrame.
#' @keywords internal
# Load CSV or CSV.GZ as a LazyFrame, with fallback and case-insensitive matching
.scan_csv_gz_or_csv <- function(path) {
  # Attempt to match actual file case (case-insensitive filesystem)
  path <- .match_actual_case(path)

  # If the path exists, scan it using Polars with disabled schema inference
  if (.path_exists(path)) {
    message("Loading file: ", path)
    lf <- pl$scan_csv(path, infer_schema_length = 0, streaming = TRUE,)
  } else {
    # If original path doesn't exist, try fallback between .csv and .csv.gz
    alt <- if (grepl("\\.csv\\.gz$", path, ignore.case = TRUE)) {
      sub("\\.gz$", "", path, ignore.case = TRUE)
    } else if (grepl("\\.csv$", path, ignore.case = TRUE)) {
      paste0(path, ".gz")
    } else {
      stop("Unsupported file extension: ", path)
    }

    alt <- .match_actual_case(alt)

    if (.path_exists(alt)) {
      message("Fallback to: ", alt)
      lf <- pl$scan_csv(alt, infer_schema_length = 0, streaming = TRUE)
      path <- alt  # update to actual path
    } else {
      stop("Neither ", path, " nor ", alt, " exist.")
    }
  }

  # Read the first line of the CSV (header) to extract column names
  con <- gzfile(path, open = "rt")
  header_line <- readLines(con, n = 1)
  close(con)
  col_names <- strsplit(header_line, split = ",")[[1]]

  # Generate Polars expressions with lowercase aliases
  exprs <- lapply(col_names, function(x) {
    pl$col(x)$alias(tolower(x))
  })

  # Return both the LazyFrame and expression list
  return(list(
    lazy_frame = lf,
    exprs = exprs
  ))
}

.match_actual_case <- function(path) {
  dir <- dirname(path)
  base <- basename(path)
  files <- list.files(dir)
  match <- files[tolower(files) == tolower(base)]
  if (length(match)==1) return(file.path(dir, match))
  return(path)  # fallback
}


#' @keywords internal
.ensure_parquet <- function(csv_path, parquet_path) {
  if (file.exists(parquet_path) && file.info(parquet_path)$size > 0)
    return(invisible(parquet_path))              # 真正的 parquet 才算缓存命中

  message("[cache] DuckDB COPY → ", basename(parquet_path))
  tmp_parq <- tempfile(fileext = ".parquet")     # 先写临时文件
  on.exit(unlink(tmp_parq), add = TRUE)

  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

  sql <- sprintf(
    "
    COPY (
      SELECT *
      FROM read_csv(
        '%s',
        delim          = ',',
        quote          = '\"',
        escape         = '\"',
        header         = TRUE,
        sample_size    = 10000,
        strict_mode    = FALSE,
        ignore_errors  = TRUE
      )
    )
    TO '%s'
    (FORMAT PARQUET, COMPRESSION ZSTD);
    ",
    normalizePath(csv_path, winslash = "/"),
    normalizePath(tmp_parq, winslash = "/")
  )

  DBI::dbExecute(con, sql)

  ## ---- 仅当写出的 parquet > 0 字节才替换正式缓存 ------------------------
  if (file.info(tmp_parq)$size == 0)
    stop("DuckDB COPY failed; produced empty parquet: ", basename(csv_path))
  dir.create(dirname(parquet_path), showWarnings = FALSE)
  file.rename(tmp_parq, parquet_path)
  invisible(parquet_path)
}



#' Given a *.csv(.gz) path, return *.parquet path in a /subset folder
.csv2parquet_path <- function(csv_path) {
  dir.create(file.path(dirname(csv_path), "subset"), showWarnings = FALSE)
  file.path(dirname(csv_path), "subset",
            sub("\\.csv(\\.gz)?$", ".parquet", basename(csv_path),
                ignore.case = TRUE))
}
