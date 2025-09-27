#' @title SampleDataset
#' @description Sample dataset class for handling and processing data samples.
#' @import R6
#' @import torch
#' @importFrom progressr progressor
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
    #' @param save_path Optional path to save the processed dataset.
    initialize = function(samples,
                          input_schema,
                          output_schema,
                          dataset_name = "",
                          task_name = "",
                          save_path = NULL) {
      self$samples <- samples
      self$input_schema <- input_schema
      self$output_schema <- output_schema
      self$input_processors <- list()
      self$output_processors <- list()
      self$dataset_name <- dataset_name
      self$task_name <- task_name
      self$patient_to_index <- list()
      self$record_to_index <- list()

      # Efficiently create the patient_to_index mapping
      if (length(samples) > 0) {
        patient_ids <- sapply(samples, function(s) as.character(s[["patient_id"]]))
        self$patient_to_index <- split(seq_along(samples), patient_ids)

        record_ids <- sapply(samples, function(s) {
          s[["record_id"]] %||% s[["visit_id"]] %||% s[["admission_id"]] %||% NA
        })
        valid_indices <- !is.na(record_ids)
        if (any(valid_indices)) {
          self$record_to_index <- split(seq_along(samples)[valid_indices],
                                        as.character(record_ids[valid_indices]))
        }
      }

      self$validate()
      self$build_and_process(save_path = save_path)
      message("samples built")
    },

    #' @description Check that all samples contain required schema fields
    validate = function() {
      if (length(self$samples) == 0) return()
      input_keys <- names(self$input_schema)
      output_keys <- names(self$output_schema)
      sample_keys <- names(self$samples[[1]])
      stopifnot(all(input_keys %in% sample_keys))
      stopifnot(all(output_keys %in% sample_keys))
    },

    #' @description Build processors and transform all samples
    build_and_process = function(save_path = NULL) {
      # Build processors
      message("Building input processors...")
      p_input <- progressr::progressor(steps = length(names(self$input_schema)))
      for (k in names(self$input_schema)) {
        processor_type <- self$input_schema[[k]]
        processor <- get_processor(processor_type)$new()
        processor$fit(self$samples, k)
        self$input_processors[[k]] <- processor
        p_input()
      }

      message("Building output processors...")
      p_output <- progressr::progressor(steps = length(names(self$output_schema)))
      for (k in names(self$output_schema)) {
        processor_type <- self$output_schema[[k]]
        processor <- get_processor(processor_type)$new()
        processor$fit(self$samples, k)
        self$output_processors[[k]] <- processor
        p_output()
      }

      tensors_path <- NULL
      if (!is.null(save_path)) {
        if (!dir.exists(save_path)) {
          dir.create(save_path, recursive = TRUE)
        }
        tensors_path <- file.path(save_path, "tensors")
        if (!dir.exists(tensors_path)) {
          dir.create(tensors_path)
        }
      }

      # Process all samples upfront
      message("Processing samples...")
      p <- progressr::progressor(steps = length(self$samples))
      samples_for_saving <- rlang::duplicate(self$samples, shallow = FALSE)

      for (i in seq_along(self$samples)) {
        sample <- self$samples[[i]]
        sample_for_save <- samples_for_saving[[i]]

        for (k in names(sample)) {
          processed_val <- NULL
          if (!is.null(self$input_processors[[k]])) {
            processed_val <- self$input_processors[[k]]$process(sample[[k]])
          } else if (!is.null(self$output_processors[[k]])) {
            processed_val <- self$output_processors[[k]]$process(sample[[k]])
          }

          if (!is.null(processed_val)) {
            sample[[k]] <- processed_val # Keep tensor in memory
            if (!is.null(save_path) && inherits(processed_val, "torch_tensor")) {
              tensor_file <- file.path(tensors_path, paste0("sample_", i, "_", k, ".pt"))
              torch::torch_save(processed_val, tensor_file)
              sample_for_save[[k]] <- list(.is_tensor_placeholder = TRUE, path = tensor_file)
            } else {
              sample_for_save[[k]] <- processed_val
            }
          }
        }
        self$samples[[i]] <- sample
        samples_for_saving[[i]] <- sample_for_save
        p()
      }

      if (!is.null(save_path)) {
        clone <- self$clone()
        clone$samples <- samples_for_saving
        saveRDS(clone, file.path(save_path, "sd_object.rds"))
        message(sprintf("SampleDataset saved to: %s", save_path))
      }
    },

    #' @description Get a sample by index
    #' @return Named list representing the sample
    .getitem = function(index) {
      sample <- self$samples[[index]]

      for (k in names(sample)) {
        item <- sample[[k]]
        if (is.list(item) && isTRUE(item$.is_tensor_placeholder)) {
          sample[[k]] <- torch::torch_load(item$path)
        }
      }

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
    print = function(...) {
      cat(sprintf("Sample dataset %s %s\n", self$dataset_name, self$task_name))
    },
    public = list(
      save_to_disk = function(path) {
        if (!dir.exists(path)) {
          dir.create(path, recursive = TRUE)
        }
        tensors_path <- file.path(path, "tensors")
        if (!dir.exists(tensors_path)) {
          dir.create(tensors_path)
        }

        clone <- self$clone()

        message("Saving tensors...")
        p <- progressr::progressor(steps = length(clone$samples))
        for (i in seq_along(clone$samples)) {
          for (k in names(clone$samples[[i]])) {
            if (inherits(clone$samples[[i]][[k]], "torch_tensor")) {
              tensor_file <- file.path(tensors_path, paste0("sample_", i, "_", k, ".pt"))
              torch::torch_save(clone$samples[[i]][[k]], tensor_file)
              clone$samples[[i]][[k]] <- list(.is_tensor_placeholder = TRUE, path = tensor_file)
            }
          }
          p()
        }

        saveRDS(clone, file.path(path, "sd_object.rds"))
        message(sprintf("SampleDataset saved to: %s", path))
      }
    )
)

#' @title Load a SampleDataset object from a directory
#' @description This function reconstructs a SampleDataset object from a directory.
#' @param path The directory path from where to load the dataset.
#' @return The reconstructed SampleDataset object.
#' @export
load_sample_dataset <- function(path) {
  rds_file <- file.path(path, "sd_object.rds")
  if (!file.exists(rds_file)) {
    stop("Saved SampleDataset object not found at the specified path: ", rds_file)
  }

  sd_object <- readRDS(rds_file)

  message("Loading tensors...")
  p <- progressr::progressor(steps = length(sd_object$samples))
  for (i in seq_along(sd_object$samples)) {
    for (k in names(sd_object$samples[[i]])) {
      item <- sd_object$samples[[i]][[k]]
      if (is.list(item) && isTRUE(item$.is_tensor_placeholder)) {
        sd_object$samples[[i]][[k]] <- torch::torch_load(item$path)
      }
    }
    p()
  }

  message("SampleDataset loaded successfully.")
  return(sd_object)
}
