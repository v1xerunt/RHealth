
<!-- README.md is generated from README.Rmd. Please edit that file -->

# RHealth

[![docs](https://github.com/v1xerunt/RHealth/actions/workflows/docs.yaml/badge.svg)](https://github.com/v1xerunt/RHealth/actions/workflows/docs.yaml)

- **Sign up for our mailing list!** We’ll email any significant RHealth
  changes that are soon to come! [Subscribe to the RHealth mailing list
  here](https://docs.google.com/forms/d/e/1FAIpQLSdiKClW5bNcnXFvWG94xF1CZko029JhxSZi0UYgwVRdW8qb0w/viewform?usp=sharing&ouid=102638312788753756103)
- **Link to our R/Medicine 2025 talk slides**
  [slides](https://drive.google.com/file/d/1yXbkBtopfN4EKxQLOxr-O008tPvOkbbT/view?usp=sharing)

**RHealth** is an open-source R package designed to bring a
comprehensive deep learning toolkit to the R community for healthcare
predictive modeling. It provides an accessible, integrated environment
for R users to build, train, and evaluate complex models on EHR data.
This package is the R counterpart to the popular Python library
[PyHealth](https://github.com/sunlabuiuc/PyHealth).

RHealth is funded by the [ISC grant from the R
Consortium](https://r-consortium.org/all-projects/2024-group-2.html#deeprhealth-a-deep-learning-toolkit-for-healthcare-predictive-modeling).

- [Installation](https://www.google.com/search?q=%23installation)
- [Modules](https://www.google.com/search?q=%23modules)
  - [1. Dataset
    Module](https://www.google.com/search?q=%231-dataset-module)
  - [2. Task Module](https://www.google.com/search?q=%232-task-module)
  - [3. Model Module](https://www.google.com/search?q=%233-model-module)
  - [4. Trainer
    Module](https://www.google.com/search?q=%234-trainer-module)
  - [5. Medical Code
    Module](https://www.google.com/search?q=%235-medical-code-module)
- [Future Plans](https://www.google.com/search?q=%23future-plans)
- [Citing RHealth](https://www.google.com/search?q=%23citing-rhealth)

The detailed documentations are at [RHealth
Documentation](https://v1xerunt.github.io/RHealth/)

------------------------------------------------------------------------

## ✍️ Citing RHealth

If you use RHealth in your research, please cite our work:

``` bibtex
@misc{RHealth2025,
  author = {Ji Song, Zhixia Ren, Zhenbang Wu, John Wu, Chaoqi Yang, Jimeng Sun, Liantao Ma, Ewen M Harrison, and Junyi Gao},
  title = {RHealth: A Deep Learning Toolkit for Healthcare Predictive Modeling},
  year = {2025},
  publisher = {GitHub},
  journal = {GitHub repository},
  howpublished = {\url{[https://github.com/v1xerunt/RHealth](https://github.com/v1xerunt/RHealth)}}
}
```

------------------------------------------------------------------------

## 📥 Installation

Install the development version from [GitHub](https://github.com/):

``` r
# install.packages("pak")
pak::pak("v1xerunt/RHealth")

# Or using devtools:
# install.packages("devtools")
devtools::install_github("v1xerunt/RHealth")
```

Once installed, load the package to access its functionalities:

``` r
library(RHealth)
```

------------------------------------------------------------------------

## 🧱 Modules

RHealth is organized into several powerful, interconnected modules.

### ⚕️ 1. Medical Code Module

This standalone module helps map medical codes between different
systems.

**Code Lookup:**

``` r
lookup_code(code = "428.0", system = "ICD9CM")
```

**Find Ancestors/Descendants:**

``` r
# Get all parent codes
get_ancestors(code = "428.22", system = "ICD9CM")

# Get all child codes
get_descendants(code = "428", system = "ICD9CM")
```

**Cross-System Mapping:**

``` r
# Map from ICD-9 to CCS
map_code(code = "428.0", from = "ICD9CM", to = "CCSCM")
# Map from ICD-9 to ICD-10
map_code(code = "589", from = "ICD9CM", to = "ICD10CM")
```

### 🛢️ 2. Dataset Module

The **Dataset** module is the foundation of RHealth. It transforms raw,
multi-table Electronic Health Record (EHR) dumps into tidy, task-ready
tensors that any downstream model can consume.

**Key Features:**

- **Data Harmonisation**: Merges heterogeneous tables into a single,
  canonical event table.
- **Built-in Caching**: Uses DuckDB for CSV → Parquet caching, enabling
  up to 10x faster reloads.
- **Dev Mode**: Allows for lightning-fast iteration by using a small
  subset of patients.

You can download a sample dataset (MIMIC-IV Demo, version 2.2) directly
from PhysioNet using the following link:

👉 <https://physionet.org/content/mimic-iv-demo/2.2/#files-panel>

**Quick Start:**

Define a dataset from your source files using a YAML configuration.

``` r
# The YAML config defines tables, patient IDs, timestamps, and attributes
# See the full documentation for details on the YAML structure.

# Load the dataset
data_dir <- "/Users/yourname/datasets/mimiciv/"

ds <- MIMIC4EHRDataset$new(
  root = data_dir,
  tables = c("patients", "admissions", "diagnoses_icd", "procedures_icd", "prescriptions"),
  dataset_name = "mimic4_ehr",
  dev = TRUE
)

ds$stats()
#> Dataset : mimic4_ehr
#> Dev mode : TRUE
#> Patients : 1 000
#> Events   : 2 187 540
```

### 🎯 3. Task Module

The **Task** module defines the prediction problem. It tells RHealth
*what* to predict, *which* data to use, and *how* to generate
`(input, target)` samples from a patient’s event timeline.

A task is defined by subclassing `BaseTask` and implementing the
`call()` method.

**Example Task Definition:**

``` r
MyReadmissionTask <- R6::R6Class(
  "MyReadmissionTask",
  inherit = BaseTask,
  public = list(
    initialize = function() {
      super$initialize(
        task_name     = "MyReadmissionTask",
        input_schema  = list(diagnoses = "sequence", procedures = "sequence"),
        output_schema = list(outcome = "binary")
      )
    },
    call = function(patient) {
      # Your logic to generate samples for a single patient...
      # This should return a list or list-of-lists with named fields
      # matching the input/output schemas.
      
      # Example:
      # list(
      #   diagnoses = c("401.9", "250.00"),
      #   procedures = c("88.72"),
      #   outcome = 1
      # )
    }
  )
)
```

**Generating Samples:**

Once a task is defined, use it with your dataset to create a
`SampleDataset` compatible with `{torch}`.

``` r
task    <- InHospitalMortalityMIMIC4$new() # A built-in task
samples <- ds$set_task(task)
```

### 🧠 4. Model Module

The **Model** module provides ready-to-use neural network architectures.
All models inherit from a `BaseModel`, which automates dimension
calculation, loss function selection, and device management (CPU/GPU).

**Built-in Models:**

RHealth includes reference implementations like `RNN`, which can be
instantiated in one line:

``` r
model <- RNN(
  dataset       = samples, # The SampleDataset from set_task()
  embedding_dim = 128,
  hidden_dim    = 128
)
```

**Custom Models:**

You can easily write your own model by inheriting from `BaseModel`.

``` r
MyDenseNet <- torch::nn_module(
  "MyDenseNet",
  inherit = BaseModel,
  initialize = function(dataset, hidden_dim = 256) {
    super$initialize(dataset) # IMPORTANT: handles schema setup
    
    # Calculate input/output dimensions automatically
    in_dim  <- sum(purrr::map_int(dataset$input_processors, "size"))
    out_dim <- self$get_output_size()

    self$fc1 <- nn_linear(in_dim, hidden_dim)
    self$fc2 <- nn_linear(hidden_dim, out_dim)
  },
  forward = function(inputs) {
    # Flatten and concatenate all input features
    x <- torch::torch_cat(purrr::flatten(inputs), dim = 2)
    logits <- self$fc2(torch_relu(self$fc1(x)))

    # Return loss and probabilities
    list(
      loss   = self$get_loss_function()(logits, inputs[[self$label_keys]]),
      y_prob = self$prepare_y_prob(logits)
    )
  }
)
```

### 💪 5. Trainer Module

The **Trainer** module provides a high-level, configurable training loop
that handles logging, checkpointing, evaluation, and progress bars.

**Example Training Workflow:**

``` r
# 1. Create data loaders
splits <- split_by_patient(samples, c(0.8, 0.1, 0.1), stratify = TRUE, stratify_by = 'mortality')
train_dl <- get_dataloader(splits[[1]], batch_size = 32, shuffle = TRUE)
val_dl <- get_dataloader(splits[[2]], batch_size = 32)
test_dl <- get_dataloader(splits[[3]], batch_size = 32)

# 2. Instantiate a model
model <- RNN(train_dl, embedding_dim = 128, hidden_dim = 128)

# 3. Set up the trainer
trainer <- Trainer$new(
    model,
    metrics     = c("auroc", "auprc"),
    output_path = "experiments",
    exp_name    = "mortality_rnn"
)

# 4. Start training
trainer$train(
  train_dataloader = train_dl,
  val_dataloader = val_dl,
  epochs = 10,
  optimizer_params = list(lr = 1e-3),
  monitor = "roc_auc"
)
```

Logs and model checkpoints (`best.ckpt`, `last.ckpt`) are saved
automatically to `experiments/mortality_rnn/`.

------------------------------------------------------------------------

## 🚀 Future Plans

RHealth is under active development. Our roadmap includes:

- **Healthcare DL Core Module**: Adding more SoTA models like RETAIN,
  AdaCare, and Transformers.
- **Prediction Task Module**: Adding built-in tasks for common clinical
  predictions (e.g., length of stay, readmission risk).
- **Multi-modal Data**: Enhancing support for integrating imaging,
  genomics, and clinical notes.
- **LLM Integration**: Augmenting package capabilities with Large
  Language Models.

We welcome feedback and contributions! Please submit an issue on GitHub
or contact the maintainers.
