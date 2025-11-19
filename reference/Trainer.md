# Generic Trainer for torch models

An enhanced R6 trainer mirroring PyHealth's Python version. It supports:

- **Dynamic `steps_per_epoch`**: can iterate indefinitely over a
  dataloader to reach a target number of steps, just like Python.

- **Parameter‑group–wise weight decay**: bias and *LayerNorm* parameters
  are excluded from L2 regularisation.

- **Gradient clipping**.

- **Optional progress bar** using
  [`progressr::progressor()`](https://progressr.futureverse.org/reference/progressor.html)
  (falls back to simple logging).

- **Correctly named `additional_outputs`** collection.

## Public fields

- `model`:

  A torch model object.

- `metrics`:

  A list of metric names.

- `device`:

  The computation device ("cpu" or "cuda").

- `exp_path`:

  Path to save logs and checkpoints.

## Methods

### Public methods

- [`Trainer$new()`](#method-Trainer-new)

- [`Trainer$train()`](#method-Trainer-train)

- [`Trainer$inference()`](#method-Trainer-inference)

- [`Trainer$evaluate()`](#method-Trainer-evaluate)

- [`Trainer$save_ckpt()`](#method-Trainer-save_ckpt)

- [`Trainer$load_ckpt()`](#method-Trainer-load_ckpt)

- [`Trainer$clone()`](#method-Trainer-clone)

------------------------------------------------------------------------

### Method [`new()`](https://rdrr.io/r/methods/new.html)

Initialize the Trainer.

#### Usage

    Trainer$new(
      model,
      checkpoint_path = NULL,
      metrics = NULL,
      device = NULL,
      enable_logging = TRUE,
      output_path = NULL,
      exp_name = NULL
    )

#### Arguments

- `model`:

  A torch model.

- `checkpoint_path`:

  Optional checkpoint path to load.

- `metrics`:

  List of metric names.

- `device`:

  Computation device.

- `enable_logging`:

  Whether to enable file logging.

- `output_path`:

  Output directory.

- `exp_name`:

  Optional experiment name.

------------------------------------------------------------------------

### Method `train()`

Train the model.

#### Usage

    Trainer$train(
      train_dataloader,
      val_dataloader = NULL,
      test_dataloader = NULL,
      epochs = 5,
      optimizer_class = optim_adam,
      optimizer_params = list(lr = 0.001),
      steps_per_epoch = NULL,
      evaluation_steps = 1L,
      weight_decay = 0,
      max_grad_norm = NULL,
      monitor = NULL,
      monitor_criterion = "max",
      load_best_model_at_last = TRUE,
      use_progress_bar = TRUE
    )

#### Arguments

- `train_dataloader`:

  Training dataloader.

- `val_dataloader`:

  Optional validation dataloader.

- `test_dataloader`:

  Optional test dataloader.

- `epochs`:

  Number of training epochs.

- `optimizer_class`:

  Optimizer constructor.

- `optimizer_params`:

  Parameters for optimizer.

- `steps_per_epoch`:

  Optional override for steps per epoch.

- `evaluation_steps`:

  Steps between evaluations.

- `weight_decay`:

  Weight decay parameter.

- `max_grad_norm`:

  Optional gradient clipping norm.

- `monitor`:

  Metric name to monitor.

- `monitor_criterion`:

  "max" or "min".

- `load_best_model_at_last`:

  Load best model after training.

- `use_progress_bar`:

  Show training progress.

------------------------------------------------------------------------

### Method `inference()`

Perform inference on a dataloader.

#### Usage

    Trainer$inference(
      dataloader,
      additional_outputs = NULL,
      return_patient_ids = FALSE,
      use_progress_bar = FALSE
    )

#### Arguments

- `dataloader`:

  A dataloader.

- `additional_outputs`:

  Vector of additional outputs to capture.

- `return_patient_ids`:

  Whether to return patient IDs.

- `use_progress_bar`:

  Whether to show a progress bar.

------------------------------------------------------------------------

### Method `evaluate()`

Evaluate the model using a dataloader.

#### Usage

    Trainer$evaluate(dataloader, use_progress_bar = FALSE)

#### Arguments

- `dataloader`:

  A dataloader to evaluate on.

- `use_progress_bar`:

  Whether to show a progress bar.

------------------------------------------------------------------------

### Method `save_ckpt()`

Save model checkpoint.

#### Usage

    Trainer$save_ckpt(path)

#### Arguments

- `path`:

  File path to save checkpoint.

------------------------------------------------------------------------

### Method `load_ckpt()`

Load model checkpoint.

#### Usage

    Trainer$load_ckpt(path)

#### Arguments

- `path`:

  File path to load checkpoint from.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    Trainer$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
