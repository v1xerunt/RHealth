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

      indices <- integer(length(value))
      for (i in seq_along(value)) {
        token <- value[[i]]
        if (is.null(token)) {
          indices[i] <- self$code_vocab[["<unk>"]]
        } else {
          key <- as.character(token)
          if (!(key %in% names(self$code_vocab))) {
            self$code_vocab[[key]] <- self$.next_index
            self$.next_index <- self$.next_index + 1
          }
          indices[i] <- self$code_vocab[[key]]
        }
      }

      torch::torch_tensor(indices, dtype = torch::torch_long())
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

