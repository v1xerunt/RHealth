#' @title Collate Function with Padding
#' @description Collates a batch of samples (list of named lists) into a single list with padded tensors.
#' @param batch A list of named lists, each representing a sample.
#' @return A named list with padded tensors or lists.
#' @import torch
#' @export
collate_fn_dict_with_padding <- function(batch) {
  collated <- list()
  keys <- names(batch[[1]])

  for (key in keys) {
    values <- lapply(batch, function(sample) sample[[key]])

    if (inherits(values[[1]], "torch_tensor")) {
      shapes <- lapply(values, function(v) v$shape)
      same_shape <- all(sapply(shapes, function(s) all(s == shapes[[1]])))

      if (same_shape) {
        collated[[key]] <- torch_stack(values)
      } else {
        if (values[[1]]$dim() == 0) {
          collated[[key]] <- torch_stack(values)
        } else if (values[[1]]$dim() >= 1) {
          collated[[key]] <- nn_utils_rnn_pad_sequence(values, batch_first = TRUE, padding_value = 0)
        } else {
          stop(sprintf("Unsupported tensor shape: %s", paste0(values[[1]]$shape, collapse = ",")))
        }
      }
    } else {
      collated[[key]] <- values
    }
  }

  collated
}

#' @title Create DataLoader
#' @description Creates a torch dataloader with padding-aware collate function.
#' @param dataset A torch dataset or dataset_subset object.
#' @param batch_size Integer, number of samples per batch.
#' @param shuffle Logical, whether to shuffle the data. Default: FALSE.
#' @return A torch dataloader object.
#' @import torch
#' @export
get_dataloader <- function(dataset, batch_size, shuffle = FALSE) {
  dataloader(
    dataset = dataset,
    batch_size = batch_size,
    shuffle = shuffle,
    collate_fn = collate_fn_dict_with_padding
  )
}
