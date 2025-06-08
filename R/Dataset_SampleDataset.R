#' @title SampleDataset
#' @description Sample dataset class for handling and processing data samples.
#' @import R6
#' @import torch
#' @export
SampleDataset <- torch::dataset(
    "SampleDataset",
    #' @field samples List of named list objects (records)
    samples = NULL,

    #' @field input_schema Named list of input types
    input_schema = NULL,

    #' @field output_schema Named list of output types
    output_schema = NULL,

    #' @field input_processors List of input processors by field
    input_processors = NULL,

    #' @field output_processors List of output processors by field
    output_processors = NULL,

    #' @field dataset_name Dataset identifier
    dataset_name = NULL,

    #' @field task_name Task identifier
    task_name = NULL,

    #' @field patient_to_index Named list mapping patient_id to sample indices
    patient_to_index = NULL,

    #' @field record_to_index Named list mapping record_id to sample indices
    record_to_index = NULL,

    #' @description Initialize the dataset
    #' @param samples List of named list records
    #' @param input_schema Named list specifying types for inputs
    #' @param output_schema Named list specifying types for outputs
    #' @param dataset_name Optional dataset name
    #' @param task_name Optional task name
    initialize = function(samples,
                          input_schema,
                          output_schema,
                          dataset_name = "",
                          task_name = "") {
      self$samples <- samples
      self$input_schema <- input_schema
      self$output_schema <- output_schema
      self$input_processors <- list()
      self$output_processors <- list()
      self$dataset_name <- dataset_name
      self$task_name <- task_name
      self$patient_to_index <- list()
      self$record_to_index <- list()

      for (i in seq_along(samples)) {
        sample <- samples[[i]]
        patient_id <- sample[["patient_id"]]
        if (!is.null(patient_id)) {
          if (is.null(self$patient_to_index[[patient_id]])) {
            self$patient_to_index[[patient_id]] <- c()
          }
          self$patient_to_index[[patient_id]] <- c(self$patient_to_index[[patient_id]], i)
        }

        record_id <- sample[["record_id"]]
        if (is.null(record_id)) {
          record_id <- sample[["visit_id"]]
        }
        if (!is.null(record_id)) {
          if (is.null(self$record_to_index[[record_id]])) {
            self$record_to_index[[record_id]] <- c()
          }
          self$record_to_index[[record_id]] <- c(self$record_to_index[[record_id]], i)
        }
      }
      self$validate()
      self$build()
      message("samples built")

    },

    #' @description Check that all samples contain required schema fields
    validate = function() {
      input_keys <- names(self$input_schema)
      output_keys <- names(self$output_schema)

      for (sample in self$samples) {
        sample_keys <- names(sample)
        stopifnot(all(input_keys %in% sample_keys))
        stopifnot(all(output_keys %in% sample_keys))
      }
    },

    #' @description Build processors and transform all samples
    build = function() {
      for (k in names(self$input_schema)) {
        processor_type <- self$input_schema[[k]]
        processor <- get_processor(processor_type)$new()
        processor$fit(self$samples, k)
        self$input_processors[[k]] <- processor
      }
      for (k in names(self$output_schema)) {
        processor_type <- self$output_schema[[k]]
        processor <- get_processor(processor_type)$new()
                                        

        processor$fit(self$samples, k)

        self$output_processors[[k]] <- processor

      }
      for (i in seq_along(self$samples)) {
        sample <- self$samples[[i]]
        for (k in names(sample)) {
          if (!is.null(self$input_processors[[k]])) {
            sample[[k]] <- self$input_processors[[k]]$process(sample[[k]])
          } else if (!is.null(self$output_processors[[k]])) {
            sample[[k]] <- self$output_processors[[k]]$process(sample[[k]])
          }
        }
        self$samples[[i]] <- sample
      }
    },

    #' @description Get a sample by index
    #' @param index Integer index
    #' @return Named list representing the sample
    .getitem = function(index) {
      sample <- self$samples[[index]]
      input_keys  <- names(self$input_processors)
      output_keys <- names(self$output_processors)
      selected_keys <- union(input_keys, output_keys)
      filtered_sample <- sample[selected_keys]
      return(filtered_sample)
    },

    #' @description Number of samples
    #' @return Integer
    .length = function() {
      return(length(self$samples))
    },

    #' @description Printable description of dataset
    #' @param ... Ignored
    print = function(...) {
      cat(sprintf("Sample dataset %s %s\n", self$dataset_name, self$task_name))
    }
  
)
