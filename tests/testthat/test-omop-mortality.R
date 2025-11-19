# Test OMOP dataset and mortality prediction task
library(testthat)

test_that("OMOP dataset initialization works", {
  skip_if_not_installed("torch")
  skip_if_not_installed("dplyr")
  skip_if_not_installed("dbplyr")

  # Get config path from installed package
  config_path <- system.file("extdata/configs/omop.yaml", package = "RHealth")

  # Create temp directory and test data
  test_dir <- file.path(tempdir(), paste0("omop_test_", format(Sys.time(), "%Y%m%d%H%M%S")))
  data_dir <- file.path(test_dir, "data")
  create_omop_test_data(data_dir)
  
  # Initialize dataset
  dataset <- OMOPDataset$new(
    root = data_dir,
    tables = c("condition_occurrence", "procedure_occurrence", "drug_exposure"),
    config_path = config_path,
    dev = FALSE
  )
  
  # Check dataset was created
  expect_s3_class(dataset, "OMOPDataset")
  expect_s3_class(dataset, "BaseDataset")
  
  # Check person table preprocessing
  person_df <- dataset$collected_global_event_df() %>%
    dplyr::filter(event_type == "person") %>%
    dplyr::collect()
  
  expect_true("person/birth_datetime" %in% colnames(person_df))
  expect_equal(nrow(person_df), 2)
  
  # Cleanup
  unlink(test_dir, recursive = TRUE)
})

test_that("MortalityPredictionOMOP task generates correct samples", {
  skip_if_not_installed("torch")
  skip_if_not_installed("dplyr")
  skip_if_not_installed("dbplyr")

  # Get config path from installed package
  config_path <- system.file("extdata/configs/omop.yaml", package = "RHealth")

  # Setup
  test_dir <- file.path(tempdir(), paste0("omop_test_", format(Sys.time(), "%Y%m%d%H%M%S")))
  data_dir <- file.path(test_dir, "data")
  create_omop_test_data(data_dir)
  
  # Initialize dataset
  dataset <- OMOPDataset$new(
    root = data_dir,
    tables = c("condition_occurrence", "procedure_occurrence", "drug_exposure"),
    config_path = config_path,
    dev = FALSE
  )
  
  # Initialize task
  task <- MortalityPredictionOMOP$new()
  
  # Run task
  sample_dataset <- dataset$set_task(task = task)
  
  # Should generate 2 samples (one per patient with >= 2 visits)
  expect_equal(length(sample_dataset$samples), 2)
  
  # Sample 1: visit 101, person_id 1, mortality=1
  # (predicting death before next visit 102; death occurs on 2020-01-15 between visits)
  s1 <- sample_dataset$samples[[1]]
  expect_equal(s1$visit_id, 101)
  expect_equal(s1$patient_id, 1)
  
  mortality_val <- as.numeric(s1$mortality$item())
  expect_equal(mortality_val, 1)
  
  # Check that tensors exist (processed values)
  expect_true(!is.null(s1$conditions))
  expect_true(!is.null(s1$procedures))
  expect_true(!is.null(s1$drugs))
  
  # Sample 2: visit 103, person_id 2, mortality=0
  # (predicting death before next visit 104; no death occurs)
  s2 <- sample_dataset$samples[[2]]
  expect_equal(s2$visit_id, 103)
  expect_equal(s2$patient_id, 2)
  
  mortality_val2 <- as.numeric(s2$mortality$item())
  expect_equal(mortality_val2, 0)
  
  # Check that tensors exist (processed values)
  expect_true(!is.null(s2$conditions))
  expect_true(!is.null(s2$procedures))
  expect_true(!is.null(s2$drugs))
  
  # Cleanup
  unlink(test_dir, recursive = TRUE)
})

test_that("Modeling pipeline works end-to-end", {
  skip_if_not_installed("torch")
  skip_if_not_installed("dplyr")
  skip_if_not_installed("dbplyr")
  skip_on_ci()  # Skip on CI as training can be slow

  # Get config path from installed package
  config_path <- system.file("extdata/configs/omop.yaml", package = "RHealth")

  # Setup
  test_dir <- file.path(tempdir(), paste0("omop_test_", format(Sys.time(), "%Y%m%d%H%M%S")))
  data_dir <- file.path(test_dir, "data")
  create_omop_test_data(data_dir)
  
  # Initialize dataset and task
  dataset <- OMOPDataset$new(
    root = data_dir,
    tables = c("condition_occurrence", "procedure_occurrence", "drug_exposure"),
    config_path = config_path,
    dev = FALSE
  )
  
  task <- MortalityPredictionOMOP$new()
  sample_dataset <- dataset$set_task(task = task)
  
  # Create dataloaders (use same dataset for train and val in this minimal test)
  train_dl <- get_dataloader(sample_dataset, batch_size = 1, shuffle = TRUE)
  val_dl <- get_dataloader(sample_dataset, batch_size = 1)
  
  # Check that we can get a batch
  batch_iter <- train_dl$.iter()
  batch <- batch_iter$.next()
  expect_equal(batch$mortality$size(1), 1)
  
  # Check that length keys are present
  expect_true("conditions_len" %in% names(batch))
  expect_true("procedures_len" %in% names(batch))
  expect_true("drugs_len" %in% names(batch))
  
  # Instantiate model
  model <- RNN(sample_dataset, embedding_dim = 8, hidden_dim = 8)
  expect_s3_class(model, "RNN")
  
  # Set up trainer
  trainer <- Trainer$new(
    model,
    metrics = c("roc_auc", "pr_auc"),
    output_path = test_dir,
    exp_name = "mortality_rnn_test",
    device = "cpu"
  )
  
  expect_s3_class(trainer, "Trainer")
  
  # Train for 2 epochs
  expect_no_error({
    trainer$train(
      train_dataloader = train_dl,
      val_dataloader = val_dl,
      epochs = 2,
      optimizer_params = list(lr = 1e-3),
      monitor = "roc_auc"
    )
  })

  # Cleanup
  unlink(test_dir, recursive = TRUE)
})

test_that("ReadmissionPredictionOMOP task generates correct samples", {
  skip_if_not_installed("torch")
  skip_if_not_installed("dplyr")
  skip_if_not_installed("dbplyr")

  # Get config path from installed package
  config_path <- system.file("extdata/configs/omop.yaml", package = "RHealth")

  # Setup
  test_dir <- file.path(tempdir(), paste0("omop_test_", format(Sys.time(), "%Y%m%d%H%M%S")))
  data_dir <- file.path(test_dir, "data")
  create_omop_test_data(data_dir)

  # Initialize dataset
  dataset <- OMOPDataset$new(
    root = data_dir,
    tables = c("condition_occurrence", "procedure_occurrence", "drug_exposure"),
    config_path = config_path,
    dev = FALSE
  )

  # Initialize task with 15-day time window
  task <- ReadmissionPredictionOMOP$new(time_window = 15)

  # Run task
  sample_dataset <- dataset$set_task(task = task)

  # Should generate 2 samples (one per patient with >= 2 visits)
  expect_equal(length(sample_dataset$samples), 2)

  # Sample 1: visit 101, person_id 1, readmission=0
  # (time gap to next visit is 31 days > 15 days)
  s1 <- sample_dataset$samples[[1]]
  expect_equal(s1$visit_id, 101)
  expect_equal(s1$patient_id, 1)

  readmission_val <- as.numeric(s1$readmission$item())
  expect_equal(readmission_val, 0)

  # Check that tensors exist (processed values)
  expect_true(!is.null(s1$conditions))
  expect_true(!is.null(s1$procedures))
  expect_true(!is.null(s1$drugs))

  # Sample 2: visit 103, person_id 2, readmission=1
  # (time gap to next visit is 10 days < 15 days)
  s2 <- sample_dataset$samples[[2]]
  expect_equal(s2$visit_id, 103)
  expect_equal(s2$patient_id, 2)

  readmission_val2 <- as.numeric(s2$readmission$item())
  expect_equal(readmission_val2, 1)

  # Check that tensors exist (processed values)
  expect_true(!is.null(s2$conditions))
  expect_true(!is.null(s2$procedures))
  expect_true(!is.null(s2$drugs))

  # Cleanup
  unlink(test_dir, recursive = TRUE)
})

test_that("ReadmissionPredictionOMOP task respects time_window parameter", {
  skip_if_not_installed("torch")
  skip_if_not_installed("dplyr")
  skip_if_not_installed("dbplyr")

  # Get config path from installed package
  config_path <- system.file("extdata/configs/omop.yaml", package = "RHealth")

  # Setup
  test_dir <- file.path(tempdir(), paste0("omop_test_", format(Sys.time(), "%Y%m%d%H%M%S")))
  data_dir <- file.path(test_dir, "data")
  create_omop_test_data(data_dir)

  # Initialize dataset
  dataset <- OMOPDataset$new(
    root = data_dir,
    tables = c("condition_occurrence", "procedure_occurrence", "drug_exposure"),
    config_path = config_path,
    dev = FALSE
  )

  # Initialize task with 20-day time window (between 10 and 31 days)
  task <- ReadmissionPredictionOMOP$new(time_window = 20)

  # Run task
  sample_dataset <- dataset$set_task(task = task)

  # Should generate 2 samples
  expect_equal(length(sample_dataset$samples), 2)

  # Person 1: 31 days > 20 days → readmission=0
  s1 <- sample_dataset$samples[[1]]
  readmission_val1 <- as.numeric(s1$readmission$item())
  expect_equal(readmission_val1, 0)

  # Person 2: 10 days < 20 days → readmission=1
  s2 <- sample_dataset$samples[[2]]
  readmission_val2 <- as.numeric(s2$readmission$item())
  expect_equal(readmission_val2, 1)

  # Cleanup
  unlink(test_dir, recursive = TRUE)
})
