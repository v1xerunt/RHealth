#' @title Dataset Split Functions
#' @description Provides functions to split a `SampleDataset` object by sample, patient, or visit.
#' @import torch
#' @importFrom purrr map flatten_chr
#' @export

#' @name split_by_sample
#' @param dataset A `SampleDataset` object.
#' @param ratios A numeric vector of length 3 indicating train/val/test split ratios. Must sum to 1.
#' @param seed Optional integer for reproducibility.
#' @param get_index Logical, whether to return the indices instead of subsets. Default: FALSE.
#' @return A list of 3 torch::dataset_subset objects or 3 tensors of indices if get_index = TRUE.
#' @export
split_by_sample <- function(dataset, ratios, seed = NULL, get_index = FALSE) {
  stopifnot(sum(ratios) == 1.0)
  if (!is.null(seed)) set.seed(seed)

  index <- sample(seq_len(length(dataset)))
  n <- length(index)

  train_index <- index[1:floor(n * ratios[[1]])]
  val_index <- index[(floor(n * ratios[[1]]) + 1):floor(n * (ratios[[1]] + ratios[[2]]))]
  test_index <- index[(floor(n * (ratios[[1]] + ratios[[2]])) + 1):n]

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
#' @return A list of 3 torch::dataset_subset objects split by patient id.
#' @export
split_by_patient <- function(dataset, ratios, seed = NULL) {
  stopifnot(sum(ratios) == 1.0)
  if (!is.null(seed)) set.seed(seed)

  patient_ids <- names(dataset$patient_to_index)
  n <- length(patient_ids)
  shuffled <- sample(patient_ids)

  train_ids <- shuffled[1:floor(n * ratios[[1]])]
  val_ids <- shuffled[(floor(n * ratios[[1]]) + 1):floor(n * (ratios[[1]] + ratios[[2]]))]
  test_ids <- shuffled[(floor(n * (ratios[[1]] + ratios[[2]])) + 1):n]

  flatten_indices <- function(ids) {
    unlist(purrr::map(ids, function(pid) dataset$patient_to_index[[pid]]))
  }

  train_index <- flatten_indices(train_ids)
  val_index <- flatten_indices(val_ids)
  test_index <- flatten_indices(test_ids)

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
#' @return A list of 3 torch::dataset_subset objects.
#' @export
split_by_visit <- function(dataset, ratios, seed = NULL) {
  stopifnot(sum(ratios) == 1.0)
  if (!is.null(seed)) set.seed(seed)

  index <- sample(seq_len(length(dataset)))
  n <- length(index)

  train_index <- index[1:floor(n * ratios[[1]])]
  val_index <- index[(floor(n * ratios[[1]]) + 1):floor(n * (ratios[[1]] + ratios[[2]]))]
  test_index <- index[(floor(n * (ratios[[1]] + ratios[[2]])) + 1):n]

  list(
    dataset_subset(dataset, indices = train_index),
    dataset_subset(dataset, indices = val_index),
    dataset_subset(dataset, indices = test_index)
  )
}
