library(testthat)
library(torch)
library(R6)

# This test script is designed to verify that the RNN model can learn from a simple,
# synthetically generated dataset. If this test passes, it suggests that the model
# implementation is correct and any training issues might be related to the actual
# data being used.

test_that("RNN model can learn from pseudo-data", {

  # Mock Processor Class
  # A minimal R6 class to mimic the necessary properties of a feature processor,
  # specifically the vocabulary size needed by the EmbeddingModel.
  MockProcessor <- R6::R6Class("MockProcessor",
    inherit = SequenceProcessor,
    public = list(
    vocab_size = NULL,
    initialize = function(vocab_size) {
      self$vocab_size <- vocab_size
      # The EmbeddingModel uses the length of code_vocab to set num_embeddings.
      self$code_vocab <- seq_len(vocab_size)
    }
  ))

  # Mock Dataset
  # A list-based dataset, which is a more standard way to create custom datasets
  # in torch for R. This avoids potential R6 class inheritance issues.
  create_mock_dataset <- function(num_samples = 128) {
    lapply(1:num_samples, function(i) {
      # Create a sequence with a learnable pattern.
      feature_seq <- torch_randint(1, 20, size = c(10), dtype = torch_long())
      # The label is 1 if the first token is > 10, otherwise 0.
      label_val <- ifelse(as.integer(feature_seq[1]$item()) > 10, 1, 0)

      list(
        feature_a = feature_seq,
        # A random binary label (0 or 1), as a float for the loss function.
        label = torch_tensor(label_val, dtype = torch_float())
      )
    })
  }

  mock_data <- create_mock_dataset()
  mock_dataset_generator <- torch::dataset(
      name = "mock_dataset",
      initialize = function() {
        self$input_processors <- list(feature_a = MockProcessor$new(vocab_size = 20))
        self$input_schema <- list(feature_a = "sequence")
        self$output_processors <- list(label = BinaryLabelProcessor$new())
        self$output_schema <- list(label = "binary")
        self$label_keys <- c("label")
        self$feature_keys <- "feature_a"
      },
      .getitem = function(i) mock_data[[i]],
      .length = function() length(mock_data)
  )

  # Add the necessary metadata attributes that the model expects.
  # mock_dataset_instance$input_processors <- list(feature_a = MockProcessor$new(vocab_size = 20))
  # mock_dataset_instance$input_schema <- list(feature_a = "sequence")
  # mock_dataset_instance$output_processors <- list(label = BinaryLabelProcessor$new())
  # mock_dataset_instance$output_schema <- list(label = "binary")
  # mock_dataset_instance$label_keys <- c("label")
  # mock_dataset_instance$feature_keys <- "feature_a"


  # 1. Instantiate the mock dataset.
  mock_dataset_instance <- mock_dataset_generator()

  # 2. Instantiate the RNN model with the mock dataset's schema.
  # We use small dimensions for this test and disable dropout for stability.
  model <- RNN(dataset = mock_dataset_instance, embedding_dim = 128, hidden_dim = 128, dropout = 0)

  # 3. Create a dataloader for the mock dataset.
  dataloader <- dataloader(mock_dataset_instance, batch_size = 32)

  # 4. Initialize the Trainer.
  trainer <- Trainer$new(
    model = model,
    device = "cpu",
    metrics = c("roc_auc", "accuracy")
  )

  # 5. Train the model for a few epochs.
  # We use the same dataloader for training and validation for simplicity.
  # With enough training, the model should be able to overfit to this simple data.
  trainer$train(
    train_dataloader = dataloader,
    val_dataloader = dataloader,
    epochs = 20,
    monitor = "roc_auc",
    use_progress_bar = FALSE
  )

  # 6. Evaluate the trained model.
  result <- trainer$evaluate(dataloader, use_progress_bar = FALSE)
  print("Final evaluation results on pseudo-data:")
  print(result)

  # 7. Assert that the model has learned.
  # A model that has learned should have an ROC AUC significantly > 0.5
  # and an accuracy significantly > 0.5. We'll check for > 0.9 as the pattern is simple.
  expect_gt(result$roc_auc, 0.9, label = "ROC AUC should be greater than 0.9 after training.")
  expect_gt(result$accuracy, 0.9, label = "Accuracy should be greater than 0.9 after training.")

})
