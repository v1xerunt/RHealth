#' @title Dataset Split Functions
#' @description Provides functions to split a `SampleDataset` object by sample, patient, or visit.
#' @import torch
#' @importFrom purrr map flatten_chr
#' @export

#' @name split_by_sample
#' @param dataset A `SampleDataset` object.
#' @param ratios A numeric vector of length 3 indicating train/val/test split ratios. Must sum to 1.
#' @param seed Optional integer for reproducibility.
#' @param stratify Logical, whether to perform stratified sampling. Default: FALSE.
#' @param stratify_by Character, the name of the field to stratify by (e.g., the label). Required if `stratify` is TRUE.
#' @param get_index Logical, whether to return the indices instead of subsets. Default: FALSE.
#' @return A list of 3 torch::dataset_subset objects or 3 tensors of indices if get_index = TRUE.
#' @export
split_by_sample <- function(dataset, ratios, seed = NULL, stratify = FALSE, stratify_by = NULL, get_index = FALSE) {
  stopifnot(sum(ratios) == 1.0)
  if (!is.null(seed)) set.seed(seed)

  if (stratify) {
    if (is.null(stratify_by)) {
      stop("`stratify_by` must be provided when `stratify` is TRUE.")
    }

    # Extract stratification values
    strata <- purrr::map_vec(dataset$samples, function(s) {
      item <- s[[stratify_by]]
      if (is.list(item) && isTRUE(item$.is_tensor_placeholder)) {
        item <- torch::torch_load(item$path)
      }
      as.numeric(item)
    })

    # Get indices for each stratum
    strata_indices <- split(seq_along(strata), strata)

    train_index <- c()
    val_index <- c()
    test_index <- c()

    for (indices in strata_indices) {
      n_stratum <- length(indices)
      shuffled_indices <- sample(indices)

      train_end <- floor(n_stratum * ratios[[1]])
      val_end <- train_end + floor(n_stratum * ratios[[2]])

      if (train_end > 0) {
        train_index <- c(train_index, shuffled_indices[1:train_end])
      }
      if (val_end > train_end) {
        val_index <- c(val_index, shuffled_indices[(train_end + 1):val_end])
      }
      if (n_stratum > val_end) {
        test_index <- c(test_index, shuffled_indices[(val_end + 1):n_stratum])
      }
    }

    # Shuffle the final indices to mix strata
    train_index <- sample(train_index)
    val_index <- sample(val_index)
    test_index <- sample(test_index)

  } else {
    index <- sample(seq_len(length(dataset)))
    n <- length(index)

    train_index <- index[1:floor(n * ratios[[1]])]
    val_index <- index[(floor(n * ratios[[1]]) + 1):floor(n * (ratios[[1]] + ratios[[2]]))]
    test_index <- index[(floor(n * (ratios[[1]] + ratios[[2]])) + 1):n]
  }

  if (get_index) {
    return(list(
      torch_tensor(train_index),
      torch_tensor(val_index),
      torch_tensor(test_index)
    ))
  }

  list(
    dataset_subset(dataset, indices = train_index),
    dataset_subset(dataset, indices = val_index),
    dataset_subset(dataset, indices = test_index)
  )
}

#' @title split_by_patient
#' @param dataset A `SampleDataset` object.
#' @param ratios A numeric vector of length 3 indicating train/val/test split ratios. Must sum to 1.
#' @param seed Optional integer for reproducibility.
#' @param stratify Logical, whether to perform stratified sampling. Default: FALSE.
#' @param stratify_by Character, the name of the field to stratify by (e.g., the label). Required if `stratify` is TRUE.
#' @param get_index Logical, whether to return the indices instead of subsets. Default: FALSE.
#' @return A list of 3 torch::dataset_subset objects or 3 tensors of indices if get_index = TRUE, split by patient id.
#' @export
split_by_patient <- function(dataset, ratios, seed = NULL, stratify = FALSE, stratify_by = NULL, get_index = FALSE) {
  stopifnot(sum(ratios) == 1.0)
  if (!is.null(seed)) set.seed(seed)

  train_ids <- c()
  val_ids <- c()
  test_ids <- c()

  if (stratify) {
    if (is.null(stratify_by)) {
      stop("`stratify_by` must be provided when `stratify` is TRUE.")
    }

    patient_strata <- list()
    for (i in seq_along(dataset$samples)) {
      sample <- dataset$samples[[i]]
      if (is.null(sample$patient_id)) next
      patient_id <- as.character(as.numeric(sample$patient_id))

      # Assuming higher value is "worse" outcome (e.g., 1 for mortality)
      item <- sample[[stratify_by]]
      if (is.list(item) && isTRUE(item$.is_tensor_placeholder)) {
        item <- torch::torch_load(item$path)
      }
      stratum <- as.numeric(item)

      if (is.null(stratum) || any(is.na(stratum))) next

      if (!patient_id %in% names(patient_strata)) {
        patient_strata[[patient_id]] <- stratum
      } else {
        patient_strata[[patient_id]] <- max(patient_strata[[patient_id]], stratum, na.rm = TRUE)
      }
    }

    strata_groups <- split(names(patient_strata), as.factor(unlist(patient_strata)))

    for (group in strata_groups) {
      n_group <- length(group)
      shuffled_pids <- sample(group)
      train_end <- floor(n_group * ratios[[1]])
      val_end <- train_end + floor(n_group * ratios[[2]])

      if (train_end > 0) {
        train_ids <- c(train_ids, shuffled_pids[1:train_end])
      }
      if (val_end > train_end) {
        val_ids <- c(val_ids, shuffled_pids[(train_end + 1):val_end])
      }
      if (n_group > val_end) {
        test_ids <- c(test_ids, shuffled_pids[(val_end + 1):n_group])
      }
    }
    train_ids <- sample(train_ids)
    val_ids <- sample(val_ids)
    test_ids <- sample(test_ids)
  } else {
    patient_ids <- names(dataset$patient_to_index)
    n <- length(patient_ids)
    shuffled <- sample(patient_ids)
    train_ids <- shuffled[1:floor(n * ratios[[1]])]
    val_ids <- shuffled[(floor(n * ratios[[1]]) + 1):floor(n * (ratios[[1]] + ratios[[2]]))]
    test_ids <- shuffled[(floor(n * (ratios[[1]] + ratios[[2]])) + 1):n]
  }

  flatten_indices <- function(ids) {
    unlist(purrr::map(ids, function(pid) dataset$patient_to_index[[pid]]))
  }

  train_index <- flatten_indices(train_ids)
  val_index <- flatten_indices(val_ids)
  test_index <- flatten_indices(test_ids)

  if (get_index) {
    return(list(
      torch_tensor(train_index),
      torch_tensor(val_index),
      torch_tensor(test_index)
    ))
  }

  list(
    dataset_subset(dataset, indices = train_index),
    dataset_subset(dataset, indices = val_index),
    dataset_subset(dataset, indices = test_index)
  )
}

#' @title split_by_visit
#' @param dataset A `SampleDataset` object.
#' @param ratios A numeric vector of length 3 indicating train/val/test split ratios. Must sum to 1.
#' @param seed Optional integer for reproducibility.
#' @param stratify Logical, whether to perform stratified sampling. Default: FALSE.
#' @param stratify_by Character, the name of the field to stratify by (e.g., the label). Required if `stratify` is TRUE.
#' @return A list of 3 torch::dataset_subset objects.
#' @export
split_by_visit <- function(dataset, ratios, seed = NULL, stratify = FALSE, stratify_by = NULL) {
  stopifnot(sum(ratios) == 1.0)
  if (!is.null(seed)) set.seed(seed)

  if (stratify) {
    if (is.null(stratify_by)) {
      stop("`stratify_by` must be provided when `stratify` is TRUE.")
    }

    visit_strata <- list()
    for (i in seq_along(dataset$samples)) {
      sample <- dataset$samples[[i]]
      visit_id <- sample[["record_id"]] %||% sample[["visit_id"]] %||% sample[["admission_id"]] %||% NA
      if (is.na(visit_id)) next
      visit_id <- as.character(visit_id)

      item <- sample[[stratify_by]]
      if (is.list(item) && isTRUE(item$.is_tensor_placeholder)) {
        item <- torch::torch_load(item$path)
      }
      stratum <- as.numeric(item)

      if (is.null(stratum) || any(is.na(stratum))) next

      if (!visit_id %in% names(visit_strata)) {
        visit_strata[[visit_id]] <- stratum
      } else {
        visit_strata[[visit_id]] <- max(visit_strata[[visit_id]], stratum, na.rm = TRUE)
      }
    }

    strata_groups <- split(names(visit_strata), as.factor(unlist(visit_strata)))

    train_ids <- c()
    val_ids <- c()
    test_ids <- c()

    for (group in strata_groups) {
      n_group <- length(group)
      shuffled_vids <- sample(group)
      train_end <- floor(n_group * ratios[[1]])
      val_end <- train_end + floor(n_group * ratios[[2]])

      if (train_end > 0) {
        train_ids <- c(train_ids, shuffled_vids[1:train_end])
      }
      if (val_end > train_end) {
        val_ids <- c(val_ids, shuffled_vids[(train_end + 1):val_end])
      }
      if (n_group > val_end) {
        test_ids <- c(test_ids, shuffled_vids[(val_end + 1):n_group])
      }
    }
    train_ids <- sample(train_ids)
    val_ids <- sample(val_ids)
    test_ids <- sample(test_ids)

    flatten_indices <- function(ids) {
      unlist(purrr::map(ids, function(vid) dataset$record_to_index[[vid]]))
    }

    train_index <- flatten_indices(train_ids)
    val_index <- flatten_indices(val_ids)
    test_index <- flatten_indices(test_ids)
  } else {
    index <- sample(seq_len(length(dataset)))
    n <- length(index)

    train_index <- index[1:floor(n * ratios[[1]])]
    val_index <- index[(floor(n * ratios[[1]]) + 1):floor(n * (ratios[[1]] + ratios[[2]]))]
    test_index <- index[(floor(n * (ratios[[1]] + ratios[[2]])) + 1):n]
  }

  list(
    dataset_subset(dataset, indices = train_index),
    dataset_subset(dataset, indices = val_index),
    dataset_subset(dataset, indices = test_index)
  )
}
