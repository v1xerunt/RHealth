#' @title Sequence Processor
#' @description Feature processor for encoding categorical sequences (e.g., medical codes) into
#'              numerical indices. Supports dynamic vocabulary construction.
#'
#' @importFrom R6 R6Class
#' @importFrom torch torch_tensor
#' @export
SequenceProcessor <- R6::R6Class("SequenceProcessor",
  inherit = FeatureProcessor,
  public = list(
    #' @field code_vocab A named integer vector representing token-to-index mappings.
    code_vocab = NULL,

    #' @field .next_index The next available index for unseen tokens.
    .next_index = NULL,

    #' @description Initialize with default vocabulary for <pad> and <unk>.
    initialize = function() {
      self$code_vocab <- c("<unk>" = -1, "<pad>" = 0)
      self$.next_index <- 1
    },

    #' @description Process a sequence of tokens into a tensor of indices.
    #' @param value A character vector of tokens.
    #' @return A long-type tensor of indices.
    process = function(value) {
      if (!is.vector(value)) {
        stop("Input to SequenceProcessor must be a vector (sequence of tokens).", call. = FALSE)
      }

      # Vectorized handling of NULLs and conversion to character
      if (is.list(value)) {
        is_null_mask <- vapply(value, is.null, FUN.VALUE = logical(1))
        tokens <- as.character(value)
        tokens[is_null_mask] <- "<unk>"
      } else {
        tokens <- as.character(value)
        tokens[is.na(tokens)] <- "<unk>"
      }

      # Find unique tokens that are not yet in the vocabulary
      unique_tokens <- unique(tokens)
      existing_indices <- match(unique_tokens, names(self$code_vocab))
      new_token_mask <- is.na(existing_indices)
      new_tokens <- unique_tokens[new_token_mask]

      # Add new tokens to the vocabulary in one go
      if (length(new_tokens) > 0) {
        new_indices_start <- self$.next_index
        new_indices <- seq.int(from = new_indices_start, length.out = length(new_tokens))
        names(new_indices) <- new_tokens
        self$code_vocab <- c(self$code_vocab, new_indices)
        self$.next_index <- new_indices_start + length(new_tokens)
      }

      # Get indices for all tokens in the original sequence using a single lookup
      indices <- self$code_vocab[tokens]
      torch::torch_tensor(unname(indices), dtype = torch::torch_long())
    },

    #' @description Return size of vocabulary.
    #' @return Integer
    size = function() {
      length(self$code_vocab)
    },

    #' @description Print summary.
    #' @param ... Ignored.
    print = function(...) {
      cat(sprintf("SequenceProcessor(code_vocab_size=%d)\n", length(self$code_vocab)))
    }
  )
)

