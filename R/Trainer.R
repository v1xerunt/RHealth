
#' @importFrom futile.logger flog.info flog.warn flog.error flog.appender appender.file

# Set default log file path if not specified
.default_log_path <- "logs/train.log"

#' @title Initialize Logger
#' @description Sets up the logger to write into a specified file using `futile.logger`.
#'
#' @param log_path Character. Path to save log file.
#' @return None
#' @export
set_logger <- function(log_path = NULL) {
  if (is.null(log_path)) {
    log_path <- .default_log_path
  }
  dir.create(dirname(log_path), recursive = TRUE, showWarnings = FALSE)
  futile.logger::flog.appender(futile.logger::appender.file(log_path))
  futile.logger::flog.info("Logger initialized at %s", log_path)
}

#' @title Check if Score is Best
#' @description Compares current score with best score using criterion (max or min).
#'
#' @param best_score Numeric. Current best score.
#' @param score Numeric. New score to compare.
#' @param monitor_criterion Character. Either "max" or "min".
#' @return Logical. TRUE if the new score is better.
#' @export
is_best <- function(best_score, score, monitor_criterion) {
  if (monitor_criterion == "max") {
    return(score > best_score)
  } else if (monitor_criterion == "min") {
    return(score < best_score)
  } else {
    stop(sprintf("Monitor criterion %s is not supported", monitor_criterion))
  }
}

#' @title Create Directory if Not Exists
#' @description Creates a directory recursively if it doesn't exist.
#'
#' @param directory Character. Path to directory.
#' @return None.
#' @export
create_directory <- function(directory) {
  if (!dir.exists(directory)) {
    dir.create(directory, recursive = TRUE)
  }
}

#' @title Get Metrics Function
#' @description Returns appropriate metric function according to task mode.
#'
#' @param mode Character. One of "binary", "multiclass", "multilabel", or "regression".
#' @return Function. Metrics calculation function.
#' @export
get_metrics_fn <- function(mode) {
  if (mode == "binary") {
    return(binary_metrics_fn)
  } else if (mode == "multiclass") {
    return(multiclass_metrics_fn)
  } else if (mode == "multilabel") {
    return(multilabel_metrics_fn)
  } else if (mode == "regression") {
    return(regression_metrics_fn)
  } else {
    stop(sprintf("Mode %s is not supported", mode))
  }
}

#' @title Generic Trainer for torch models
#' @description An enhanced R6 trainer mirroring PyHealth's Python version. It supports:
#' * **Dynamic `steps_per_epoch`**: can iterate indefinitely over a dataloader to reach a target number of steps, just like Python.
#' * **Parameter‑group–wise weight decay**: bias and *LayerNorm* parameters are excluded from L2 regularisation.
#' * **Gradient clipping**.
#' * **Optional progress bar** using `progressr::progressor()` (falls back to simple logging).
#' * **Correctly named `additional_outputs`** collection.
#'
#' @export
Trainer <- R6::R6Class(
  classname = "Trainer",
  public = list(
    #' @field model A torch model object.
    model = NULL,

    #' @field metrics A list of metric names.
    metrics = NULL,

    #' @field device The computation device ("cpu" or "cuda").
    device = NULL,

    #' @field exp_path Path to save logs and checkpoints.
    exp_path = NULL,


    #' @description
    #' Initialize the Trainer.
    #' @param model A torch model.
    #' @param checkpoint_path Optional checkpoint path to load.
    #' @param metrics List of metric names.
    #' @param device Computation device.
    #' @param enable_logging Whether to enable file logging.
    #' @param output_path Output directory.
    #' @param exp_name Optional experiment name.
    initialize = function(model,
                          checkpoint_path = NULL,
                          metrics = NULL,
                          device = NULL,
                          enable_logging = TRUE,
                          output_path = NULL,
                          exp_name = NULL) {
      # Device ----------------------------------------------------------------
      if (is.null(device)) device <- if (cuda_is_available()) "cuda" else "cpu"
      self$device  <- device
      self$model   <- model$to(device = device)
      self$metrics <- metrics
      # Logging ----------------------------------------------------------------
      if (enable_logging) {
        if (is.null(output_path)) output_path <- file.path(getwd(), "output")
        if (is.null(exp_name))   exp_name   <- format(Sys.time(), "%Y%m%d-%H%M%S")
        self$exp_path <- file.path(output_path, exp_name)
        set_logger(file.path(self$exp_path, "train.log"))
      }
      flog.info("Initialised model on %s", self$device)
      flog.info(paste(capture.output(self$model), collapse = "\n"))
      flog.info("Metrics: %s", paste(self$metrics, collapse = ", "))

      # Checkpoint --------------------------------------------------------------
      if (!is.null(checkpoint_path)) {
        flog.info("Loading checkpoint: %s", checkpoint_path)
        self$load_ckpt(checkpoint_path)
      }
    },

    #' @description
    #' Train the model.
    #' @param train_dataloader Training dataloader.
    #' @param val_dataloader Optional validation dataloader.
    #' @param test_dataloader Optional test dataloader.
    #' @param epochs Number of training epochs.
    #' @param optimizer_class Optimizer constructor.
    #' @param optimizer_params Parameters for optimizer.
    #' @param steps_per_epoch Optional override for steps per epoch.
    #' @param evaluation_steps Steps between evaluations.
    #' @param weight_decay Weight decay parameter.
    #' @param max_grad_norm Optional gradient clipping norm.
    #' @param monitor Metric name to monitor.
    #' @param monitor_criterion "max" or "min".
    #' @param load_best_model_at_last Load best model after training.
    #' @param use_progress_bar Show training progress.
    train = function(train_dataloader,
                     val_dataloader   = NULL,
                     test_dataloader  = NULL,
                     epochs           = 5,
                     optimizer_class  = optim_adam,
                     optimizer_params = list(lr = 1e-3),
                     steps_per_epoch  = NULL,
                     evaluation_steps = 1L,
                     weight_decay     = 0,
                     max_grad_norm    = NULL,
                     monitor          = NULL,
                     monitor_criterion = "max",
                     load_best_model_at_last = TRUE,
                     use_progress_bar = TRUE) {

      # Ensure monitor metric is in metrics list
      if (!is.null(monitor)) {
        if (is.null(self$metrics)) {
          self$metrics <- c(monitor)
        } else if (!(monitor %in% self$metrics)) {
          self$metrics <- c(self$metrics, monitor)
        }
      }

      flog.info("Training:")
      flog.info("Batch size: %d", train_dataloader$batch_size)
      flog.info("Optimizer: %s", deparse(substitute(optimizer_class)))
      flog.info("Optimizer params: %s", paste(names(optimizer_params), optimizer_params, sep = "=", collapse = ", "))
      flog.info("Weight decay: %f", weight_decay)
      flog.info("Max grad norm: %s", if (is.null(max_grad_norm)) "NULL" else max_grad_norm)
      flog.info("Val dataloader: %s", if (is.null(val_dataloader)) "NULL" else "provided")
      flog.info("Monitor: %s", if (is.null(monitor)) "NULL" else monitor)
      flog.info("Monitor criterion: %s", monitor_criterion)
      flog.info("Epochs: %d", epochs)

      # ---------- parameter grouping (bias / LayerNorm excluded) ---------------
      all_named <- self$model$named_parameters()
      no_decay_keys <- c("bias", "LayerNorm.weight", "LayerNorm.bias")
      params_wd  <- list()
      params_nowd <- list()
      for (nm in names(all_named)) {
        if (any(vapply(no_decay_keys, function(key) grepl(key, nm, fixed = TRUE), logical(1)))) {
          params_nowd[[length(params_nowd)+1]] <- all_named[[nm]]
        } else {
          params_wd[[length(params_wd)+1]] <- all_named[[nm]]
        }
      }
      param_groups <- list(
        list(params = params_wd,   weight_decay = weight_decay),
        list(params = params_nowd, weight_decay = 0)
      )
      optimizer <- do.call(optimizer_class, c(list(param_groups), optimizer_params))

      # Steps per epoch ---------------------------------------------------------
      if (is.null(steps_per_epoch)) steps_per_epoch <- length(train_dataloader)
      best_score <- if (monitor_criterion == "max") -Inf else  Inf
      global_step <- 0L
      for (epoch in seq_len(epochs)) {
        self$model$train()

        epoch_losses <- numeric()
        # Create iterator that can restart ------------------------------------
        iter <- torch::dataloader_make_iter(train_dataloader)
        # Progress bar ---------------------------------------------------------
        if (use_progress_bar) {
            p <- progressr::progressor(steps = steps_per_epoch)
        }

        for (step in seq_len(steps_per_epoch)) {
          # fetch (loops if iterator is exhausted) ----------------------------

          batch <- torch::dataloader_next(iter, completed = NULL)
          if (is.null(batch)) {
            iter <- torch::dataloader_make_iter(train_dataloader)
            batch <- torch::dataloader_next(iter)
          }

          optimizer$zero_grad()
          output <- self$model(batch)
          loss   <- output$loss
          loss$backward()

          if (!is.null(max_grad_norm)) nn_utils_clip_grad_norm_(self$model$parameters, max_grad_norm)
          optimizer$step()

          epoch_losses <- c(epoch_losses, loss$item())
          global_step  <- global_step + 1L

          if (use_progress_bar) p(message = sprintf("Epoch %d", epoch))
        }
        train_header <- sprintf("--- Train epoch-%d, step-%d ---", epoch, global_step)
        flog.info(train_header)
        message(train_header)
        train_loss <- paste(sprintf("loss: %.4f", mean(epoch_losses)), collapse = "\n")
        flog.info(train_loss)
        message(train_loss)
        flog.info("loss: %.4f", mean(epoch_losses))

        # Save last ckpt --------------------------------------------------------
        if (!is.null(self$exp_path)) self$save_ckpt(file.path(self$exp_path, "last.ckpt"))

        # Validation ------------------------------------------------------------
        if (!is.null(val_dataloader)) {
          scores <- self$evaluate(val_dataloader, use_progress_bar)
          eval_header <- sprintf("--- Eval epoch-%d, step-%d ---", epoch, global_step)
          flog.info(eval_header)
          message(eval_header)
          scores_log <- paste(sprintf("%s: %.4f", names(scores), scores), collapse = "\n")
          flog.info(scores_log)
          message(scores_log)
          if (!is.null(monitor)) {
            current <- scores[[monitor]]
            if (is.null(current) || length(current) == 0 || is.na(current)) {
              warning(sprintf("Monitor metric '%s' not found or invalid in scores", monitor))
            } else if (is_best(best_score, current, monitor_criterion)) {
              best_score <- current
              flog.info("New best %s score (%.4f) at epoch-%d, step-%d",
                        monitor, current, epoch, global_step)
              message(sprintf("New best %s score (%.4f) at epoch-%d, step-%d",
                              monitor, current, epoch, global_step))
              if (!is.null(self$exp_path)) self$save_ckpt(file.path(self$exp_path, "best.ckpt"))
            }
          }
        }
      }

      # Reload best -------------------------------------------------------------
      best_path <- file.path(self$exp_path, "best.ckpt")
      if (load_best_model_at_last && file.exists(best_path)) {
        flog.info("Loaded best model")
        message("Loaded best model")
        self$load_ckpt(best_path)
      }

      # Test -------------------------------------------------------------------
      if (!is.null(test_dataloader)) {
        scores <- self$evaluate(test_dataloader, use_progress_bar)
        flog.info("--- Test ---")
        message("--- Test ---")
        scores_log <- paste(sprintf("%s: %.4f", names(scores), scores), collapse = "\n")
        flog.info(scores_log)
        message(scores_log)
      }
    },

    #' @description
    #' Perform inference on a dataloader.
    #' @param dataloader A dataloader.
    #' @param additional_outputs Vector of additional outputs to capture.
    #' @param return_patient_ids Whether to return patient IDs.
    #' @param use_progress_bar Whether to show a progress bar.
    inference = function(dataloader,
                         additional_outputs = NULL,
                         return_patient_ids = FALSE,
                         use_progress_bar = FALSE) {
      losses <- c()
      y_true_batches <- list()
      y_prob_batches <- list()
      
      if (!is.null(additional_outputs)) {
        add_outputs <- setNames(lapply(additional_outputs, function(x) list()), additional_outputs)
      }
      pids <- c()
      
      self$model$eval()
      
      if (use_progress_bar) {
        p <- progressr::progressor(steps = length(dataloader))
      }
      
      torch::with_no_grad({
        
        coro::loop(for (batch in dataloader) {
          
          out <- self$model(batch)
          
          losses <- c(losses, out$loss$item())
          
          y_true_batches[[length(y_true_batches) + 1]] <- out$y_true$cpu()
          y_prob_batches[[length(y_prob_batches) + 1]] <- out$y_prob$cpu()
          
          if (!is.null(additional_outputs)) {
            for (nm in additional_outputs) {
              add_outputs[[nm]][[length(add_outputs[[nm]]) + 1]] <-
                as_array(out[[nm]]$cpu())
            }
          }
          
          if (return_patient_ids && "patient_id" %in% names(batch)) {
            pids <- c(pids, batch$patient_id)
          }
          if (use_progress_bar) p()
        })
      })
      
      
      res <- list(
        y_true = torch::torch_cat(y_true_batches, dim = 1),
        y_prob = torch::torch_cat(y_prob_batches, dim = 1),
        loss   = mean(losses)
      )
      if (!is.null(additional_outputs)) res$additional <- lapply(add_outputs, function(x) do.call(rbind, x))
      if (return_patient_ids) res$patient_id <- pids
      return(res)
    },

    #' @description
    #' Evaluate the model using a dataloader.
    #' @param dataloader A dataloader to evaluate on.
    #' @param use_progress_bar Whether to show a progress bar.
    evaluate = function(dataloader, use_progress_bar = FALSE) {
      inf <- self$inference(dataloader, use_progress_bar = use_progress_bar)
      if (!is.null(self$model$mode)) {
        fn <- get_metrics_fn(self$model$mode)
        scores <- fn(inf$y_true, inf$y_prob, metrics = self$metrics)
      } else {
        scores <- list()
      }

      scores <- as.list(scores)
      scores$loss <- inf$loss

      scores
    },

    #' @description
    #' Save model checkpoint.
    #' @param path File path to save checkpoint.
    save_ckpt = function(path) torch_save(self$model$state_dict(), path),

    #' @description
    #' Load model checkpoint.
    #' @param path File path to load checkpoint from.
    load_ckpt = function(path) {
      sd <- torch_load(path, device = self$device)
      self$model$load_state_dict(sd)
    }
  )
)
