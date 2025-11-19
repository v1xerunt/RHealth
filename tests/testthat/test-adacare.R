library(testthat)
library(torch)
library(R6)

# Test script to verify that the AdaCare model can learn from synthetic data

test_that("AdaCare model can learn from pseudo-data with mixed features", {

  # Mock Sequence Processor Class
  MockSequenceProcessor <- R6::R6Class("MockSequenceProcessor",
    inherit = SequenceProcessor,
    public = list(
      vocab_size = NULL,
      initialize = function(vocab_size) {
        self$vocab_size <- vocab_size
        self$code_vocab <- seq_len(vocab_size)
      }
    ))

  # Mock Timeseries Processor Class
  MockTimeseriesProcessor <- R6::R6Class("MockTimeseriesProcessor",
    inherit = TimeseriesProcessor,
    public = list(
      n_channels = NULL,
      initialize = function(n_channels) {
        self$n_channels <- n_channels
      }
    ))

  # Mock Dataset with both sequence and timeseries features
  create_mock_dataset <- function(num_samples = 128) {
    lapply(1:num_samples, function(i) {
      # Sequence feature: medical codes
      feature_seq <- torch_randint(1, 20, size = c(10), dtype = torch_long())

      # Timeseries feature: vital signs (time_steps x channels)
      feature_ts <- torch_randn(c(10, 3))  # 10 timesteps, 3 channels

      # Label based on both features
      seq_val <- as.integer(feature_seq[1]$item())
      ts_val <- as.numeric(feature_ts[1, 1]$item())
      label_val <- ifelse(seq_val > 10 || ts_val > 0, 1, 0)

      list(
        feature_seq = feature_seq,
        feature_ts = feature_ts,
        label = torch_tensor(label_val, dtype = torch_float())
      )
    })
  }

  mock_data <- create_mock_dataset()
  mock_dataset_generator <- torch::dataset(
    name = "mock_dataset",
    initialize = function() {
      self$input_processors <- list(
        feature_seq = MockSequenceProcessor$new(vocab_size = 20),
        feature_ts = MockTimeseriesProcessor$new(n_channels = 3)
      )
      self$input_schema <- list(
        feature_seq = "sequence",
        feature_ts = "timeseries"
      )
      self$output_processors <- list(label = BinaryLabelProcessor$new())
      self$output_schema <- list(label = "binary")
      self$label_keys <- c("label")
      self$feature_keys <- c("feature_seq", "feature_ts")
    },
    .getitem = function(i) mock_data[[i]],
    .length = function() length(mock_data)
  )

  mock_dataset_instance <- mock_dataset_generator()

  # Instantiate the AdaCare model
  model <- AdaCare(
    dataset = mock_dataset_instance,
    embedding_dim = 64,
    hidden_dim = 64,
    kernel_size = 2,
    kernel_num = 32,
    dropout = 0
  )

  # Create a dataloader
  dataloader <- dataloader(mock_dataset_instance, batch_size = 32)

  # Initialize the Trainer
  trainer <- Trainer$new(
    model = model,
    device = "cpu",
    metrics = c("roc_auc", "accuracy")
  )

  # Train the model
  trainer$train(
    train_dataloader = dataloader,
    val_dataloader = dataloader,
    epochs = 10,
    monitor = "roc_auc",
    use_progress_bar = FALSE
  )

  # Evaluate the trained model
  result <- trainer$evaluate(dataloader, use_progress_bar = FALSE)
  print("AdaCare evaluation results:")
  print(result)

})
