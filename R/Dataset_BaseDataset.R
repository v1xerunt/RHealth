
#' BaseDataset — R6 infrastructure for clinical event datasets
#'
#' The **BaseDataset** class mirrors rhealth's `BaseDataset`, providing a
#' fully-featured, YAML driven loader that converts multi-table electronic
#' health records into a single *event* table.  It supports:
#' \itemize{
#'   \item URL or local-file ingestion (with automatic `.csv` / `.csv.gz`
#'         fallback).
#'   \item Per-table joins as declared in the config.
#'   \item Flexible timestamp parsing (single or multi-column).
#'   \item A \code{dev} mode that caps the number of patients for rapid
#'         prototyping.
#'   \item Multi-threaded sample generation with progress bars.
#' }
#'


#' Down-stream, it cooperates with \code{BaseTask} (task definition),
#' \code{Patient} (per-subject wrapper), and \code{SampleDataset} (collection of
#' input/output pairs).
#'
#' @section Dependencies:
#' Polars is used via the \code{polars} R package.  Parallelism and progress
#' reporting require \code{future}, \code{future.apply}, and \code{progressr}.
#' @importFrom R6 R6Class
#' @importFrom dplyr tbl collect filter select mutate left_join union_all distinct pull rename rename_with
#' @importFrom DBI dbConnect dbDisconnect dbExecute dbListTables dbExistsTable dbRemoveTable
#' @importFrom duckdb duckdb
#' @importFrom glue glue
#' @importFrom future plan multisession
#' @importFrom future.apply future_lapply
#' @importFrom progressr handlers progressor
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

    #' @field dataset_name Human-readable dataset label.
    dataset_name = NULL,

    #' @field config Parsed YAML configuration list.
    config = NULL,

    #' @field dev Logical flag — when TRUE limits to 1000 patients.
    dev = FALSE,
    
    #' @field con a duckdb connection
    con = NULL,

    #' @field global_event_df A duckdb lazy query with all events combined.
    global_event_df = NULL,

    #--------------------------------------------------------------------
    # Private-cache fields ----------------------------------------------
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
    #' @param dev Logical.  If TRUE, limits to 1000 patients for speed.
    initialize = function(root,
                          tables,
                          dataset_name = NULL,
                          config_path  = NULL,
                          dev          = FALSE) {
      
      self$con <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
      reg.finalizer(self, function(e) {
        message("Auto-disconnecting duckdb")
        DBI::dbDisconnect(e$con, shutdown = TRUE)
      }, onexit = TRUE)

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
    #' Materialise (collect) the lazy event dataframe.  In dev-mode only the
    #' first 1000 patients are kept.
    #' @return A dataframe containing all selected events.
    collected_global_event_df = function() {
      if (is.null(self$.collected_global_event_df)) {
        message("[info] Collecting global event dataframe ...")
        
        df <- self$global_event_df   # duckdb query
        
        self$.collected_global_event_df <- df %>% dplyr::collect()
      }
      
      return(self$.collected_global_event_df)
    },



    #--------------------------------------------------------------------
    #' @description
    #' Load one table, apply joins, lowercase columns, and standardise to the
    #' event schema.
    #' @param table_name Character key present in \code{config$tables}.
    #' @return A dplyr lazy query in event format.
    load_table = function(table_name) {
      
      if (!(table_name %in% names(self$config$tables)))
        stop(sprintf("Table %s not in config", table_name))
      
      cfg       <- self$config$tables[[table_name]]
      
      base_path <- .clean_path(file.path(self$root, cfg$file_path))
      file_info <- .find_path_with_fallback(base_path)
      csv_path <- file_info$path
      separator <- file_info$separator
      
      parquet_path <- .csv2parquet_path(csv_path)
      
      # one-time conversion; subsequent runs hit the cached parquet
      .ensure_parquet(csv_path, parquet_path, separator = separator)
      
      message(sprintf("Scanning %s", parquet_path))
      
      view_name <- tools::file_path_sans_ext(basename(table_name))
      DBI::dbExecute(self$con, glue::glue("CREATE OR REPLACE VIEW \"{view_name}\" AS SELECT * FROM '{parquet_path}';"))
      lf <- dplyr::tbl(self$con, view_name) %>% dplyr::rename_with(tolower)
      
      #── optional joins (each join source is treated the same way) ──
      if (!is.null(cfg$join)) {
        for (j in cfg$join) {
          join_base_path <- .clean_path(file.path(self$root, j$file_path))
          join_file_info <- .find_path_with_fallback(join_base_path)
          join_csv <- join_file_info$path
          join_separator <- join_file_info$separator
          
          join_parq <- .csv2parquet_path(join_csv)
          .ensure_parquet(join_csv, join_parq, separator = join_separator)
          
          join_table_name <- tools::file_path_sans_ext(basename(j$file_path))
          
          DBI::dbExecute(self$con, glue::glue("CREATE OR REPLACE VIEW \"{join_table_name}\" AS SELECT * FROM '{join_parq}';"))
          
          join_df <- dplyr::tbl(self$con, join_table_name) %>%
            dplyr::rename_with(tolower) %>%
            dplyr::select(dplyr::all_of(j$on), dplyr::all_of(j$columns))
          
          lf <- dplyr::left_join(lf, join_df, by = j$on)
        }
      }
      
      # ── timestamp expression ─────────────────────────────────────
      ts_col <- if (!is.null(cfg$timestamp)) {
        if (is.list(cfg$timestamp)) {
          # This is tricky to replicate directly without more info on what concat_str does.
          # Assuming it concatenates columns to form a string.
          # We can do this with paste. The equivalent in SQL is CONCAT.
          # For now, I will assume it creates a string representation.
          # This might need adjustment based on the exact polars behavior.
          rlang::parse_expr(paste0("paste(", paste0(cfg$timestamp, collapse=", "), ")"))
        } else {
          rlang::sym(cfg$timestamp)
        }
      } else {
        NA_character_
      }
      
      # ── patient-id handling ──────────────────────────────────────
      pid_col <- if (!is.null(cfg$patient_id)) {
        rlang::sym(cfg$patient_id)
      } else {
        # polars `pl$int_range(0, pl$count())` creates a sequence from 0 to N-1
        # The equivalent in dplyr/SQL is row_number() - 1
        rlang::expr(row_number() - 1)
      }
      
      # ── attribute columns (prefixed with table name) ─────────────
      attrs <- cfg$attributes
      
      # ── final event-schema LazyFrame ─────────────────────────────
      lf <- lf %>%
        dplyr::mutate(
          patient_id = !!pid_col,
          event_type = table_name,
          timestamp = !!ts_col
        ) %>%
        dplyr::select(
          dplyr::all_of(c("patient_id", "event_type", "timestamp")),
          dplyr::all_of(attrs)
        ) %>%
        dplyr::rename_with(~paste0(table_name, "/", .x), .cols = dplyr::all_of(attrs))
      
      lf
    },
    
    #--------------------------------------------------------------------
    #' @description
    #' Load every configured table, returning a single \emph{lazy} frame.
    #' @return A duckdb lazy query.
    load_data = function() {
      ## 1. build a list of lazy queries (one per table)
      frames <- lapply(self$tables, self$load_table)
      
      ## 2. concatenate lazily
      all_cols <- unique(unlist(lapply(frames, function(df) colnames(df))))
      
      frames_aligned <- lapply(frames, function(df) {
        missing_cols <- setdiff(all_cols, colnames(df))
        
        add_cols_exprs <- stats::setNames(
          lapply(missing_cols, function(c) rlang::expr(NA)),
          missing_cols
        )
        
        if (length(add_cols_exprs) > 0) {
          df <- df %>% dplyr::mutate(!!!add_cols_exprs)
        }
        
        df %>% dplyr::select(dplyr::all_of(all_cols))
      })
      
      df <- purrr::reduce(frames_aligned, dplyr::union_all)
      
      ## 3.  dev-mode: early down-sampling to speed up prototyping
      if (isTRUE(self$dev) && "patient_id" %in% colnames(df)) {
        message("[dev] Limiting to 1000 patients (early filter)")
        patient_ids <- df %>%
          dplyr::select("patient_id") %>%
          dplyr::distinct() %>%
          head(1000) %>%
          dplyr::pull()
        
        df <- df %>% dplyr::filter(patient_id %in% patient_ids)
      }
      
      df <- df %>% dplyr::arrange(patient_id, timestamp)
      ## 4. return the final lazy query
      return(df)
    },
    
    #--------------------------------------------------------------------
    #' @description
    #' Retrieve (and cache) the vector of unique patient IDs.
    #' @return Character vector of patient IDs.
    unique_patient_ids = function() {
      if (is.null(self$.unique_patient_ids))
        self$.unique_patient_ids <- self$collected_global_event_df() %>%
        dplyr::distinct(patient_id) %>%
        dplyr::pull(patient_id)
      self$.unique_patient_ids
    },
    
    #--------------------------------------------------------------------
    #' @description
    #' Construct a \code{Patient} object for one subject.
    #' @param patient_id Character identifier.
    #' @return A new \code{Patient} R6 instance.
    get_patient = function(patient_id) {
      stopifnot(patient_id %in% self$unique_patient_ids())
      sub_df <- self$collected_global_event_df() %>%
        dplyr::filter(patient_id == !!patient_id)
      Patient$new(patient_id = patient_id, data_source = sub_df)
    },
    
    #--------------------------------------------------------------------
    #' @description
    #' Iterate over all patients (optionally a filtered dataframe).
    #' @param df Optional dataframe (already collected).
    #' @return List of \code{Patient} objects.
    iter_patients = function(df = NULL) {
      if (is.null(df)) {
        df <- self$collected_global_event_df()
      }
      
      # Group by patient_id and split into a list of data frames
      # using group_split
      patient_dfs <- df %>%
        dplyr::group_by(patient_id) %>%
        dplyr::group_split()
      
      if (self$dev) {
        message("[dev] Limiting to 1000 patients for rapid prototyping")
        patient_dfs <- head(patient_dfs, 1000)
      }
      
      p <- progressr::progressor(steps = length(patient_dfs))
      
      # Iterate over the list of data frames
      lapply(seq_along(patient_dfs), function(i) {
        patient_df <- patient_dfs[[i]]
        # All rows in patient_df have the same patient_id, so we can take the first one.
        id <- patient_df$patient_id[1]
        percent <- sprintf("%.1f%%", (i / length(patient_dfs)) * 100)
        
        p(message = sprintf("[%s] Processing patient: %s", percent, id))
        
        Patient$new(
          patient_id = id,
          data_source = patient_df
        )
      })
    },
    
    
    #--------------------------------------------------------------------
    #' @description
    #' Print dataset-level statistics.
    #' @return Invisible NULL (called for side-effects).
    stats = function() {
      df <- self$collected_global_event_df()
      cat(sprintf("Dataset : %s\n", self$dataset_name))
      cat(sprintf("Dev mode : %s\n", self$dev))
      cat(sprintf("Patients : %d\n", length(self$unique_patient_ids())))
      cat(sprintf("Events   : %d\n", nrow(df)))
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
    #' @param num_workers Integer ≥1.  Number of parallel workers.
    #' @param chunk_size Integer. Number of patients to process in each chunk.
    #' @param cache_dir Optional path to a directory for caching samples. If set,
    #'   processed samples will be saved to an `.rds` file and reloaded on
    #'   subsequent runs, skipping the generation step.
    #' @return A populated \code{SampleDataset}.
    set_task = function(task = NULL, num_workers = 1, chunk_size = 1000, cache_dir = NULL) {
      task <- task %||% self$default_task()
      stopifnot(!is.null(task))

      message(sprintf("Setting task %s for %s", task$task_name, self$dataset_name))

      if (!is.null(cache_dir)) {
        cache_file <- file.path(cache_dir, "sd_object.rds")
        if (file.exists(cache_file)) {
          message(sprintf("[cache] Loading cached SampleDataset from %s", cache_dir))
          return(load_sample_dataset(cache_dir))
        }
      }

      message(sprintf("Generating samples for task %s", task$task_name))

      df <- self$collected_global_event_df()
      filtered_df <- task$pre_filter(df)

      patient_ids <- filtered_df %>%
        dplyr::distinct(patient_id) %>%
        dplyr::pull(patient_id)

      if (self$dev) {
        message("[dev] Limiting to 1000 patients for rapid prototyping")
        patient_ids <- head(patient_ids, 1000)
      }

      id_chunks <- split(patient_ids, ceiling(seq_along(patient_ids) / chunk_size))
      all_samples <- list()

      if (num_workers > 1) {
        future::plan(future::multisession, workers = num_workers)
      }

      p <- progressr::progressor(steps = length(id_chunks))

      for (chunk_ids in id_chunks) {
        p(message = sprintf("Processing chunk of %d patients", length(chunk_ids)))

        chunk_df <- filtered_df %>% dplyr::filter(patient_id %in% chunk_ids)

        patient_dfs <- chunk_df %>%
          dplyr::group_by(patient_id) %>%
          dplyr::group_split()

        if (num_workers == 1) {
          patients <- lapply(patient_dfs, function(pdf) {
            Patient$new(patient_id = pdf$patient_id[1], data_source = pdf)
          })
          chunk_samples <- unlist(lapply(patients, task$call), recursive = FALSE)
        } else {
          task_runner <- .create_task_runner(task)
          chunk_samples_list <- future.apply::future_lapply(patient_dfs, task_runner, future.seed = TRUE)
          chunk_samples <- unlist(chunk_samples_list, recursive = FALSE)
        }

        all_samples <- c(all_samples, chunk_samples)
        rm(chunk_df, patient_dfs, chunk_samples)
        if (exists("patients")) rm(patients)
        gc()
      }

      samples <- all_samples

      message(sprintf("Generated %d samples", length(samples)))
      result <- SampleDataset(
        samples       = samples,
        input_schema  = task$input_schema,
        output_schema = task$output_schema,
        dataset_name  = self$dataset_name,
        task_name     = task,
        save_path     = cache_dir
      )
      message("[info] Task set successfully")
      return(result)
    }
  )
)

# ─────────────────────────────────────────────────────────────────────────────
# Internal helper wrappers (prefixed with .) ----------------------------------


#' Helper function to create a clean closure for parallel processing
#'
#' This function acts as a factory. It creates and returns another function
#' (a closure) that is suitable for use with `future.apply`. The returned
#' function's environment is intentionally minimal, containing only the `task`
#' object. This prevents large objects from the parent environment (like the
#' full event dataframe) from being accidentally exported to parallel workers.
#'
#' @param task The task object to be used inside the closure.
#' @return A function that takes a patient dataframe (`pdf`) and applies the task.
#' @keywords internal
.create_task_runner <- function(task) {
  force(task) # Ensure task is evaluated in this clean environment
  function(pdf) {
    # This function now has a very small closure environment,
    # only containing 'task'. 'Patient' is found in the global scope.
    patient <- Patient$new(patient_id = pdf$patient_id[1], data_source = pdf)
    task$call(patient)
  }
}


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


.match_actual_case <- function(path) {
  dir <- dirname(path)
  base <- basename(path)
  files <- list.files(dir)
  match <- files[tolower(files) == tolower(base)]
  if (length(match)==1) return(file.path(dir, match))
  return(path)  # fallback
}


#' @keywords internal
.ensure_parquet <- function(csv_path, parquet_path, separator = ",") {
  if (file.exists(parquet_path) && file.info(parquet_path)$size > 0)
    return(invisible(parquet_path))

  message("[cache] DuckDB COPY -> ", basename(parquet_path))
  tmp_parq <- tempfile(fileext = ".parquet")
  on.exit(unlink(tmp_parq), add = TRUE)

  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

  # duckdb's read_csv needs tabs to be escaped as '\\t' in the sprintf format string
  db_separator <- if (separator == "\t") "\\t" else separator
  sql <- sprintf(
    "
    COPY (
      SELECT *
      FROM read_csv(
        '%s',
        delim          = '%s',
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
    db_separator,
    normalizePath(tmp_parq, winslash = "/")
  )

  DBI::dbExecute(con, sql)

  if (file.info(tmp_parq)$size == 0)
    stop("DuckDB COPY failed; produced empty parquet: ", basename(csv_path))
  dir.create(dirname(parquet_path), showWarnings = FALSE)
  file.rename(tmp_parq, parquet_path)
  invisible(parquet_path)
}



#' Given a *.csv(.gz) path, return *.parquet path in a /subset folder
#' @param csv_path Path to the csv file.
#' @return A character string.
#' @keywords internal
.csv2parquet_path <- function(csv_path) {
  dir.create(file.path(dirname(csv_path), "subset"), showWarnings = FALSE)
  file.path(dirname(csv_path), "subset",
            sub("\\.csv(\\.gz)?$", ".parquet", basename(csv_path),
                ignore.case = TRUE))
}


#' Find an existing data file path with fallback for .gz extension.
#'
#' This function checks for the existence of a path and its alternative with/without
#' `.gz`. It also determines the separator based on the file extension (.csv or .tsv).
#'
#' @param path A character path to a .csv, .csv.gz, .tsv, or .tsv.gz file.
#' @return A list with `path` to an existing file and `separator` (',' or a tab).
#' @keywords internal
.find_path_with_fallback <- function(path) {

  scan_file <- function(file_path) {
    if (.path_exists(file_path)) {
      separator <- if (grepl("\\.tsv", file_path, ignore.case = TRUE)) "\t" else ","
      return(list(path = file_path, separator = separator))
    }
    return(NULL)
  }

  result <- scan_file(path)
  if (!is.null(result)) {
    return(result)
  }

  # Try the alternative extension
  alt_path <- NULL
  if (endsWith(path, ".csv.gz")) {
    alt_path <- sub("\\.gz$", "", path)  # Remove .gz -> try .csv
  } else if (endsWith(path, ".csv")) {
    alt_path <- paste0(path, ".gz")      # Add .gz -> try .csv.gz
  } else if (endsWith(path, ".tsv.gz")) {
    alt_path <- sub("\\.gz$", "", path)  # Remove .gz -> try .tsv
  } else if (endsWith(path, ".tsv")) {
    alt_path <- paste0(path, ".gz")      # Add .gz -> try .tsv.gz
  } else {
    stop(sprintf("Path does not have expected extension: %s", path))
  }

  alt_result <- scan_file(alt_path)
  if (!is.null(alt_result)) {
    message(sprintf("Original path does not exist. Using alternative: %s", alt_path))
    return(alt_result)
  }

  stop(sprintf("Neither path exists: %s or %s", path, alt_path))
}

