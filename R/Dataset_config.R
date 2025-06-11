
#' Dataset Configuration
#'
#' This module defines R6 classes for representing configuration files for PyHealth datasets,
#' including table join specifications, per-table attributes, and the overall dataset structure.
#' It also provides a function to load configuration from a YAML file.
#'
#' @name rhealth.config
#' @import R6 checkmate yaml

library(R6)
library(yaml)
library(checkmate)

#' JoinConfig: Configuration for joining tables in a dataset
#'
#' @description
#' An R6 class that represents the configuration required to join an auxiliary table to the main dataset.
#'
#' @field file_path Path to the join table file (string)
#' @field on Column name to join on (string)
#' @field how Join type: "left", "right", "inner", or "outer" (string)
#' @field columns List of column names to extract from the joined table (character vector)
#'
#' @export
JoinConfig <- R6Class("JoinConfig",
  public = list(
    file_path = NULL,
    on = NULL,
    how = NULL,
    columns = NULL,

    #' @description
    #' Create a new JoinConfig instance.
    #'
    #' @param file_path Path to the join table
    #' @param on Column name to join on
    #' @param how Type of join to perform ("left", "right", "inner", "outer")
    #' @param columns Character vector of column names to extract from the joined table
    initialize = function(file_path, on, how, columns) {
      assert_string(file_path)
      assert_string(on)
      assert_string(how)
      assert_character(columns)
      self$file_path <- file_path
      self$on <- on
      self$how <- how
      self$columns <- columns
    }
  )
)

#' TableConfig: Configuration for a single table
#'
#' @description
#' Describes the metadata for a data table within the dataset including file path, patient ID field,
#' timestamp columns, attribute columns, and join specifications.
#'
#' @field file_path Path to the table file (string)
#' @field patient_id Optional string identifying the patient ID column
#' @field timestamp Optional string or character vector identifying time columns
#' @field timestamp_format Optional format string for parsing timestamps
#' @field attributes Character vector of attribute column names
#' @field join List of JoinConfig objects describing how to join auxiliary tables
#'
#' @export
TableConfig <- R6Class("TableConfig",
  public = list(
    file_path = NULL,
    patient_id = NULL,
    timestamp = NULL,
    timestamp_format = NULL,
    attributes = NULL,
    join = NULL,

    #' @description
    #' Create a new TableConfig instance.
    #'
    #' @param file_path Path to the main table file
    #' @param patient_id Optional column name for patient IDs
    #' @param timestamp Optional timestamp column(s)
    #' @param timestamp_format Optional format for timestamps
    #' @param attributes Character vector of attribute columns
    #' @param join Optional list of JoinConfig dictionaries or objects
    initialize = function(file_path,
                          patient_id = NULL,
                          timestamp = NULL,
                          timestamp_format = NULL,
                          attributes,
                          join = NULL) {
      self$file_path <- file_path
      self$patient_id <- patient_id
      self$timestamp <- timestamp
      self$timestamp_format <- timestamp_format
      self$attributes <- attributes
      self$join <- if (is.null(join)) list() else lapply(join, function(j) {
        if (inherits(j, "JoinConfig")) return(j)
        do.call(JoinConfig$new, j)
      })
      self$validate()
    },

    #' @description
    #' Validate the fields of TableConfig.
    validate = function() {
      assert_string(self$file_path)
      if (!is.null(self$patient_id)) assert_string(self$patient_id)
      if (!is.null(self$timestamp)) assert(check_string(self$timestamp) || check_character(self$timestamp))
      if (!is.null(self$timestamp_format)) assert_string(self$timestamp_format)
      assert_character(self$attributes)
      assert_list(self$join, types = "JoinConfig", null.ok = TRUE)
    }
  )
)

#' DatasetConfig: Root dataset configuration
#'
#' @description
#' Describes the full dataset configuration including version and all table definitions.
#'
#' @field version Version string of the dataset
#' @field tables Named list of TableConfig objects
#'
#' @export
DatasetConfig <- R6Class("DatasetConfig",
  public = list(
    version = NULL,
    tables = NULL,

    #' @description
    #' Create a new DatasetConfig instance.
    #'
    #' @param version Dataset version string
    #' @param tables Named list of TableConfig instances or raw config lists
    initialize = function(version, tables) {
      assert_string(version)
      assert_list(tables, names = "named")
      self$tables <- lapply(tables, function(tbl_cfg) {
        if (inherits(tbl_cfg, "TableConfig")) return(tbl_cfg)
        do.call(TableConfig$new, tbl_cfg)
      })
      self$version <- version
      self$validate()
    },

    #' @description
    #' Validate the DatasetConfig object.
    validate = function() {
      assert_string(self$version)
      assert_list(self$tables, types = "TableConfig", names = "named")
    }
  )
)

#' Load and validate dataset configuration from YAML
#'
#' @description
#' Load a configuration file from disk and parse it into a DatasetConfig object.
#'
#' @param file_path File path to the YAML configuration file
#'
#' @return A \code{DatasetConfig} object
#' @export
load_yaml_config <- function(file_path) {
  assert_file_exists(file_path)
  raw_config <- yaml::read_yaml(file_path)
  DatasetConfig$new(
    version = raw_config$version,
    tables = raw_config$tables
  )
}
