test_that("multiclass_metrics_fn works correctly", {
  set.seed(42)
  n <- 100
  k <- 4

  # Generate test data
  y_true <- sample(0:(k-1), n, replace = TRUE)
  y_prob <- matrix(runif(n * k), nrow = n, ncol = k)
  y_prob <- y_prob / rowSums(y_prob)  # normalize to sum to 1

  # Test basic metrics
  result <- multiclass_metrics_fn(
    y_true,
    y_prob,
    metrics = c("accuracy", "f1_macro", "f1_micro")
  )

  expect_type(result, "double")
  expect_named(result, c("accuracy", "f1_macro", "f1_micro"))
  expect_true(all(result >= 0 & result <= 1))

  # Test ROC AUC metrics
  result_auc <- multiclass_metrics_fn(
    y_true,
    y_prob,
    metrics = c("roc_auc_macro_ovr", "roc_auc_weighted_ovr")
  )

  expect_type(result_auc, "double")
  expect_true(all(result_auc >= 0 & result_auc <= 1))
})


test_that("multilabel_metrics_fn works correctly", {
  set.seed(42)
  n <- 100
  k <- 5

  # Generate test data
  y_true <- matrix(rbinom(n * k, 1, 0.3), nrow = n, ncol = k)
  y_prob <- matrix(runif(n * k), nrow = n, ncol = k)
  y_pred <- ifelse(y_prob > 0.5, 1, 0)

  # Test basic metrics
  result <- multilabel_metrics_fn(
    y_true,
    y_prob,
    metrics = c("accuracy", "f1_micro", "f1_macro")
  )

  expect_type(result, "double")
  expect_named(result, c("accuracy", "f1_micro", "f1_macro"))
  expect_true(all(result >= 0 & result <= 1))

  # Test with probabilities
  result_prob <- multilabel_metrics_fn(
    y_true,
    y_prob,
    metrics = c("accuracy", "hamming_loss", "roc_auc_macro")
  )

  expect_type(result_prob, "double")
  expect_true(all(result_prob >= 0 & result_prob <= 1, na.rm = TRUE))
})


test_that("binary_metrics_fn still works", {
  set.seed(42)
  y_true <- rbinom(100, 1, 0.4)
  y_prob <- runif(100)

  result <- binary_metrics_fn(
    y_true,
    y_prob,
    metrics = c("accuracy", "roc_auc", "f1")
  )

  expect_type(result, "double")
  expect_named(result, c("accuracy", "roc_auc", "f1"))
  expect_true(all(result >= 0 & result <= 1))
})
