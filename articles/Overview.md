# Descriptions

## RHealth

RHealth is an open-source R package specifically designed to bring
comprehensive deep learning toolkits to the R community for healthcare
predictive modeling. Funded by the [ISC grant from the R
Consortium](https://r-consortium.org/all-projects/2024-group-2.html#deeprhealth-a-deep-learning-toolkit-for-healthcare-predictive-modeling),
RHealth aims to provide an accessible, integrated environment for R
users.

This package is built upon its python version
[PyHealth](https://github.com/sunlabuiuc/PyHealth).

### Citing RHealth :handshake:

Ji Song, Zhixia Ren, Zhenbang Wu, John Wu, Chaoqi Yang, Jimeng Sun,
Liantao Ma, Ewen M Harrison, and Junyi Gao. 2025. “RHealth: A Deep
Learning Toolkit for Healthcare Predictive Modeling”. GitHub.

``` bibtex
@misc{Ji2025,
  author = {Ji Song, Zhixia Ren, Zhenbang Wu, John Wu, Chaoqi Yang, Jimeng Sun, Liantao Ma, Ewen M Harrison, Junyi Gao},
  title = {RHealth},
  year = {2025},
  publisher = {GitHub},
  journal = {GitHub repository},
  howpublished = {\url{https://github.com/v1xerunt/RHealth}}
}
```

### Installation

You can install the development version of RHealth from
[GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("RHealth")
```

Alternatively, using devtools:

``` r
# install.packages("devtools")
devtools::install_github("v1xerunt/RHealth")
```

Once RHealth is installed, you can load the package to access medcode
functionalities:

``` r
library(RHealth)
```

### 1. Dataset Module

The **dataset** module is the foundation of **RHealth**.  
It converts raw, multi‑table Electronic‑Health‑Record (EHR) dumps into
tidy, task‑ready tensors that every downstream deep‑learning model can
consume.

You can download a sample dataset (MIMIC-IV Demo, version 2.2) directly
from PhysioNet using the following link: 👉
<https://physionet.org/content/mimic-iv-demo/2.2/#files-panel>

------------------------------------------------------------------------

#### 1.1 Key Features

[TABLE]

- Built‑in **CSV → Parquet** caching via DuckDB (×10 faster reloads).  
- Optional **dev mode** – keep the first *N patients* for lightning‑fast
  iteration.  
- Parallel sample generation with **future** & **progressr**.

------------------------------------------------------------------------

#### 1.2 Quick‑Start Example

``` r
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

Convert the dataset into a model‑ready `SampleDataset`:

``` r
task    <- Readmission30DaysMIMIC4$new()
samples <- ds$set_task(task)
```

------------------------------------------------------------------------

#### 1.3 YAML Configuration

Every dataset is described by a single YAML file.

``` yaml
version: "1.4"
tables:
  admissions:
    file_path: "ADMISSIONS.csv.gz"
    patient_id: "subject_id"
    timestamp: "admittime"
    attributes:
      - hadm_id
      - admission_type
      - discharge_location
    join:
      - file_path: "ICUSTAYS.csv.gz"
        on: hadm_id
        how: left
        columns: [icustay_id, first_careunit]
```

- **`file_path`** – relative to `root` or an HTTP(S) URL.  
- **`patient_id`** – column containing the subject identifier.  
- **`timestamp`** – single column or list of columns (concatenated).  
- **`attributes`** – columns to expose; automatically renamed to
  `table/column`.  
- **`join`** – optional list of auxiliary tables to merge in one pass.

Load & validate from R:

``` r
cfg <- load_yaml_config("configs/mimic4_ehr.yaml")
print(cfg)
```

------------------------------------------------------------------------

#### 1.4 Patient & Event Classes

``` txt
BaseDataset            # keeper of *all events*
 └── Patient           # one subject’s events (lazy filtered)
      └── Event        # lightweight list of {type, timestamp, attributes}
```

*A `Patient` behaves like a mini‑dataset: you can query visits,
length‑of‑stay, time‑series windows, … without touching any other
patient’s data.*

------------------------------------------------------------------------

#### 1.5 SampleDataset & Torch Integration

`BaseDataset$set_task()` applies a user‑defined **BaseTask**:

1.  **`pre_filter()`** – drop events or patients globally.  
2.  **`call(patient)`** – returns zero, one, or many `(input, target)`
    pairs.  
3.  Each field is converted by its declared **Processor** into a
    `torch_tensor`.

The resulting `SampleDataset` supports:

.\_\_getitem\_\_(i) \# single sample .\_\_len\_\_() \# length

and plugs straight into [torch](https://torch.mlverse.org/docs)’s
[`dataloader()`](https://torch.mlverse.org/docs/reference/dataloader.html).

------------------------------------------------------------------------

#### 1.6 Debugging Tips

``` r
# Inspect the first 20 events
ds$unique_patient_ids()

# Examine one patient
pat <- ds$get_patient("123456")
print(pat)
```

Use `dev = TRUE` during development to keep iteration times under 2 s.

------------------------------------------------------------------------

### 2. Task Moudle

The **task** module sits between the **dataset** layer and your
deep‑learning **models**. A *task* tells RHealth **what** to predict,
**which** slices of data to use, and **how** to turn a patient’s raw
events into `(input, target)` samples.

------------------------------------------------------------------------

#### 2.1 Conceptual Overview

- **BaseDataset** provides lazy access to every patient’s events.  
- A **BaseTask** instance decides:
  1.  *Which* events matter (`pre_filter()`).
  2.  *How* to aggregate a patient’s timeline into one or more
      **samples** ([`call()`](https://rdrr.io/r/base/call.html)).
  3.  The exact **input/output schema** so RHealth can choose the right
      **Processor** and encode data into *torch tensors*.
- The resulting **SampleDataset** plugs straight into
  [torch](https://torch.mlverse.org/docs).

------------------------------------------------------------------------

#### 2.2 `BaseTask` API

| Member                         | Purpose                                                                                                  |
|--------------------------------|----------------------------------------------------------------------------------------------------------|
| `task_name` (*chr*)            | Unique key shown in logs & file names.                                                                   |
| `input_schema` (*named list*)  | Field → *processor type* (`"timeseries"`, `"sequence"`, `"float"`, …).                                   |
| `output_schema` (*named list*) | Usually `"binary"`, `"multiclass"`, `"regression"`, etc.                                                 |
| `pre_filter(df)`               | **Optional**. Receives the *global* event `LazyFrame`; return a pared‑down version to speed up sampling. |
| `call(patient)`                | **Must override**. Converts one `Patient` to zero, one, or many **samples** *(named lists)*.             |

``` r
# Skeleton for your own task ----------------------------------------------
MyCoolTask <- R6::R6Class(
  "MyCoolTask",
  inherit = BaseTask,
  public = list(
    initialize = function() {
      super$initialize(
        task_name     = "MyCoolTask",
        input_schema  = list(labs = "timeseries",
                             diagnoses = "sequence"),
        output_schema = list(outcome = "binary")
      )
    },

    pre_filter = function(df) {
      # keep only labs & diagnoses to save RAM
      df$select(pl$col(c("labevents/valuenum",
                         "diagnoses_icd/icd_code",
                         "timestamp",
                         "patient_id",
                         "event_type")))
    },

    call = function(patient) {
      # ... build samples here ...
    }
  )
)
```

------------------------------------------------------------------------

#### 2.3 Processor Auto‑Selection

During `BaseDataset$set_task(task)` RHealth:

1.  Reads `task$input_schema` / `task$output_schema`.
2.  Calls `get_processor(type)` to instantiate the matching
    **Processor** (`TimeseriesProcessor`, `SequenceProcessor`, …).
3.  Each sample emitted by `task$call()` is **encoded on the fly** into
    `torch_tensor`s before being stored in the `SampleDataset`.

That means you never import [torch](https://torch.mlverse.org/docs)
inside a task – stick to base R objects (`numeric`, `character`,
`matrix`, `data.frame`, lists).

##### Available Processors

| Processor             | Input Type                 | Purpose               | Key Features                                                      |
|-----------------------|----------------------------|-----------------------|-------------------------------------------------------------------|
| `TimeseriesProcessor` | `list(timestamps, matrix)` | Irregular time series | Resampling, imputation (forward-fill/zero), z-score normalization |
| `SequenceProcessor`   | `character vector`         | Categorical sequences | Vocabulary building, integer encoding                             |
| `BinaryProcessor`     | `numeric` (0/1)            | Binary labels         | Converts to float tensor                                          |
| `MulticlassProcessor` | `integer`                  | Multi-class labels    | One-hot encoding                                                  |
| `RegressionProcessor` | `numeric`                  | Continuous values     | Direct conversion to float                                        |

**TimeseriesProcessor normalization:**

The `TimeseriesProcessor` automatically applies z-score normalization to
timeseries data: - Computes feature-wise mean and standard deviation
from training data during `fit()` - Applies `(x - mean) / std` during
`process()` to all samples (train/val/test) - Prevents data leakage by
using only training statistics

------------------------------------------------------------------------

#### 2.4 Built‑in Example Tasks

| Class                       | Target                 | Key Features                                                                                                   |
|-----------------------------|------------------------|----------------------------------------------------------------------------------------------------------------|
| `InHospitalMortalityMIMIC4` | Mortality at discharge | Uses **lab time‑series** from the first 48 h; excludes minors; binary label `mortality`.                       |
| `Readmission30DaysMIMIC4`   | 30‑day readmission     | Sequences of **diagnoses / procedures / drugs**; ignores visits ≤ 12 h; smart exclusion of same‑day transfers. |

``` r
ds      <- MIMIC4Dataset$new(root = "~/mimic4", tables = ...)
mort30  <- InHospitalMortalityMIMIC4$new(input_window_hours = 48)
samples <- ds$set_task(mort30, num_workers = 4)
```

------------------------------------------------------------------------

### 3 Model Module

The **model** module delivers ready‑to‑train neural‑network
architectures and a thin **BaseModel** contract that keeps every model
compatible with the rest of RHealth.

------------------------------------------------------------------------

#### 3.1 BaseModel

Every RHealth model must be able to:

1.  **Understand the dataset** – read the input/output schema and work
    out dimensions automatically.
2.  **Pick the right loss** – binary, multiclass, multilabel,
    regression.
3.  **Turn logits into probabilities** for validation metrics.
4.  Run on **CPU or CUDA** transparently.

`BaseModel` centralises those chores so concrete models can focus on
architecture.

------------------------------------------------------------------------

#### 3.2 `BaseModel` API

| Member                   | Purpose                                                                           |
|--------------------------|-----------------------------------------------------------------------------------|
| **Fields**               |                                                                                   |
| `dataset`                | The `SampleDataset` used for training/validation.                                 |
| `feature_keys`           | Character vector from `dataset$input_schema`.                                     |
| `label_keys`             | Character vector from `dataset$output_schema` (usually length 1).                 |
| **Methods**              |                                                                                   |
| `get_output_size()`      | Returns the dimension expected at the final linear layer.                         |
| `get_loss_function()`    | Picks between `nnf_binary_cross_entropy_with_logits`, `nnf_cross_entropy`, …      |
| `prepare_y_prob(logits)` | Applies `sigmoid` / `softmax` / identity so metrics receive proper probabilities. |

> **Rule of thumb**: if your architecture only needs a *forward* method
> and uses a single label, you can inherit from `BaseModel` and forget
> about loss/prob helpers.

------------------------------------------------------------------------

#### 3.3 Helper building blocks

##### 3.3.1 `EmbeddingModel`

- Converts heterogeneous inputs to a **shared embedding space**.
  - `SequenceProcessor` → `nn_embedding`
  - `TimeseriesProcessor` → `nn_linear`
- Pads sequences with index `0` and safely remaps it to
  `padding_idx = 1`.

##### 3.3.2 `RNNLayer`

A drop‑in GRU/LSTM/RNN layer with:

- 1‑based index safety (important in R!).
- `mask` support so you can mix sequences of different length.
- A learnable `null_hidden` vector for **empty sequences** (avoids
  NaNs).
- Bidirectional option with automatic hidden‑state merging.

------------------------------------------------------------------------

#### 3.4 Reference model – `RNN`

``` txt
inputs  ─▶  EmbeddingModel  ─▶  per‑feature RNNLayer  ─┐
                                                      ├─▶ concat ─▶ FC ─▶ logits
labels   ──────────────────────────────────────────────┘
```

- One `RNNLayer` **per input feature** (diagnoses, procedures, labs …).
- Hidden vectors are concatenated → `nn_linear` → logits.
- Works out‑of‑the‑box for **binary / multi‑class / regression** tasks.

Instantiation:

``` r
model <- RNN(
  dataset       = samples,     # a SampleDataset from `set_task()`
  embedding_dim = 128,
  hidden_dim    = 128
)
```

------------------------------------------------------------------------

#### 3.6 Writing your own model

1.  **Subclass** `BaseModel` (or another concrete model).  
2.  Add layers in [`initialize()`](https://rdrr.io/r/methods/new.html),
    making sure to call `super$initialize(dataset)`.  
3.  Implement `forward(inputs)`.

``` r
MyDense <- torch::nn_module(
  "MyDense",
  inherit = BaseModel,

  initialize = function(dataset, hidden = 256) {
    super$initialize(dataset)
    in_dim  <- sum(purrr::map_int(dataset$input_processors, "size"))
    out_dim <- self$get_output_size()
    self$fc1 <- nn_linear(in_dim, hidden)
    self$fc2 <- nn_linear(hidden, out_dim)
  },

  forward = function(inputs) {
    # Flatten and concat all features
    x <- torch::torch_cat(purrr::flatten(inputs), dim = 2)
    logits <- self$fc2(torch_relu(self$fc1(x)))

    list(
      loss   = self$get_loss_function()(logits, inputs[[self$label_keys]]$to(logits$device)),
      y_prob = self$prepare_y_prob(logits)
    )
  }
)
```

**Checklist**:

Call `super$initialize(dataset)`  

Use `self$get_output_size()` instead of hard‑coding dimensions  

Return a **named list** containing at least `loss`, `y_prob`

------------------------------------------------------------------------

### 4.Trainer

The **Trainer** module provides a batteries‑included training loop for
any RHealth model built on [torch](https://torch.mlverse.org/docs). It
mirrors PyHealth’s Python trainer, bringing familiar conveniences to the
R ecosystem:

- dynamic **`steps_per_epoch`** (loop over a dataloader indefinitely);
- smart **weight‑decay parameter groups** (skip bias / LayerNorm);
- automatic **gradient clipping**;
- experiment folders with **file logging** via `{futile.logger}`;
- optional **CLI progress bars**
  ([`cli::cli_progress_bar()`](https://cli.r-lib.org/reference/cli_progress_bar.html)).

------------------------------------------------------------------------

#### 4.1 Utility helpers

| Function                            | Purpose                                                                                  |
|-------------------------------------|------------------------------------------------------------------------------------------|
| `set_logger(log_path)`              | Initialise `{futile.logger}` to write a timestamped log‑file.                            |
| `is_best(best, current, criterion)` | Compare scores for early‑stopping (criterion = `"max"` or `"min"`).                      |
| `create_directory(dir)`             | Recursive `dir.create` wrapper.                                                          |
| `get_metrics_fn(mode)`              | Returns a metric‑calculation function (`binary_metrics_fn`, `multiclass_metrics_fn`, …). |

------------------------------------------------------------------------

#### 4.2 `Trainer` API

| Member                                             | Description                                                                            |
|----------------------------------------------------|----------------------------------------------------------------------------------------|
| **Fields**                                         |                                                                                        |
| `model`                                            | A [torch](https://torch.mlverse.org/docs) model (inherits from `BaseModel`).           |
| `device`                                           | `"cpu"` or `"cuda"` (auto‑detected if `device = NULL`).                                |
| `metrics`                                          | Character vector passed to the metric function.                                        |
| `exp_path`                                         | Folder where logs & checkpoints are saved (`./output/<timestamp>`).                    |
| **Key methods**                                    |                                                                                        |
| `initialize(model, ...)`                           | Sets device, logging, loads checkpoint if provided.                                    |
| `train(train_dataloader, val_dataloader, …)`       | Full training loop with early‑stopping and test evaluation.                            |
| `inference(dataloader, additional_outputs = NULL)` | Run model in [`eval()`](https://rdrr.io/r/base/eval.html) mode and gather predictions. |
| `evaluate(dataloader)`                             | `inference()` + compute metrics & loss.                                                |
| `save_ckpt(path)` / `load_ckpt(path)`              | Torch native `state_dict` persistence.                                                 |

##### 4.2.1 `train()` arguments (excerpt)

| Argument            | Default           | Meaning                                                                             |
|---------------------|-------------------|-------------------------------------------------------------------------------------|
| `epochs`            | `5`               | Number of passes over the data.                                                     |
| `optimizer_class`   | `optim_adam`      | Any [torch](https://torch.mlverse.org/docs) optimiser constructor.                  |
| `optimizer_params`  | `list(lr = 1e-3)` | Extra args for the optimiser.                                                       |
| `steps_per_epoch`   | `NULL`            | If `NULL` uses `length(train_loader)`; else loops/restarts to hit the target count. |
| `evaluation_steps`  | `1`               | Validate every *n* epochs.                                                          |
| `weight_decay`      | `0`               | L2 penalty (excluded for bias/LayerNorm).                                           |
| `max_grad_norm`     | `NULL`            | Clip gradients if not `NULL`.                                                       |
| `monitor`           | `NULL`            | Metric to watch for best‑model checkpoint.                                          |
| `monitor_criterion` | `"max"`           | `"max"` or `"min"`.                                                                 |
| `use_progress_bar`  | `TRUE`            | Pretty progress bar if [cli](https://cli.r-lib.org) is available.                   |

------------------------------------------------------------------------

#### 4.3 Minimal working example

``` r
library(RHealth)

## 1.  Build dataset & task -----------------------------------------------
ds      <- MIMIC4Dataset$new(root = "~/mimic4",
                             tables = c("patients", "admissions", "labevents"),
                             config_path = system.file("configs/mimic4_ehr.yaml", package = "RHealth"))
task    <- InHospitalMortalityMIMIC4$new(input_window_hours = 48)
samples <- ds$set_task(task)

splits <- split_by_patient(samples, c(0.8, 0.1, 0.1))
train_dl <- get_dataloader(splits[[1]], batch_size = 32, shuffle = TRUE)
val_dl <- get_dataloader(splits[[2]], batch_size = 32)
test_dl <- get_dataloader(splits[[3]], batch_size = 32)

## 2.  Build model ---------------------------------------------------------
model <- RNN(samples, embedding_dim = 128, hidden_dim = 128)

## 3.  Kick off training ---------------------------------------------------
trainer <- Trainer$new(model,
                       metrics      = c("roc_auc", "pr_auc"),
                       output_path  = "experiments",
                       exp_name     = "mortality_rnn")

trainer$train(
              train_dataloader = train_dl,
              val_dataloader = val_dl,
              epochs = 10,
              optimizer_params = list(lr = 1e-3),
              monitor = "roc_auc")
```

Logs & checkpoints:

    experiments/
    └─ mortality_rnn/
       ├─ train.log
       ├─ last.ckpt      # after every epoch
       └─ best.ckpt      # whenever AUROC improves

------------------------------------------------------------------------

#### 4.4 Inference & evaluation

``` r
test_scores <- trainer$evaluate(test_dl)
print(test_scores)
```

------------------------------------------------------------------------

### 5. Medical Code Map

Our medical code mapping module provides tools to map medical codes
between and within various medical coding systems. **This module can be
used independently.**

#### 5.1. Code Lookup with lookup_code()

Retrieve the description for a specific medical code.

``` r
# Example: Look up ICD-9-CM code "428.0"
code_description <- lookup_code(code = "428.0", system = "ICD9CM")
print(code_description)
```

#### 5.2. Hierarchy Navigation

Explore relationships within coding systems. \#### Get Ancestors with
get_ancestors():

``` r
# Example: Find ancestors for ICD-9-CM code "428.22"
ancestor_codes <- get_ancestors(code = "428.22", system = "ICD9CM")
print(ancestor_codes)
```

##### Get Descendants with get_descendants():

``` r
# Example: Find descendants for ICD-9-CM code "428"
descendant_codes <- get_descendants(code = "428", system = "ICD9CM")
print(head(descendant_codes)) # Showing first few for brevity
print(paste("Total descendants for '428':", length(descendant_codes)))
```

#### 5.3. Cross-System Mapping with map_code()

Translate codes from one system to another. First, see available
mappings:

``` r
supported_cross()
```

Then, map a code:

``` r
# Example: Map ICD-9-CM "428.0" to CCSCM
mapped_ccscm_code <- map_code(code = "428.0", from = "ICD9CM", to = "CCSCM")
print(mapped_ccscm_code)
```

#### 5.4. ATC Specific Utilities

##### ATC Level Conversion with atc_convert():

``` r
atc_code <- "L01BA01" # Methotrexate
print(paste("L1 (Anatomical Main Group):", atc_convert(atc_code, level = 1)))
print(paste("L3 (Therapeutic/Pharmacological Subgroup):", atc_convert(atc_code, level = 3)))
print(paste("L4 (Chemical/Therapeutic/Pharmacological Subgroup):", atc_convert(atc_code, level = 4)))
```

##### Drug-Drug Interactions (DDI) with get_ddi():

``` r
ddi_data <- get_ddi()
print("First few known Drug-Drug Interactions (ATC pairs):")
print(head(ddi_data))
```

### 6 Current Development and Future Plans

RHealth is currently under active development. The initial phase focuses
on establishing two foundational modules:

1.  **EHR Database Module:** This module is being developed to provide a
    standardized framework for ingesting, processing, and managing
    diverse Electronic Health Record (EHR) datasets. It aims to support
    public datasets like MIMIC-III, MIMIC-IV, and eICU, as well as
    user-specific data formats such as OMOP-CDM. The goal is to ensure
    data consistency for subsequent modeling tasks.
2.  **EHR Code Mapping Module (medcode):** This module, with its core
    `medcode` component, facilitates mapping between and within various
    medical coding systems (e.g., ICD, NDC, RxNorm). Key functionalities
    like code lookup, hierarchy navigation, cross-system mapping, and
    ATC utilities are already implemented, as demonstrated in the
    examples above.

Looking further ahead, our development roadmap includes the expansion of
RHealth with several key modules and enhancements:

- **Healthcare DL Core Module:** This module will integrate traditional
  machine learning models (e.g., Random Forests, Support Vector
  Machines) and state-of-the-art healthcare-specific deep learning
  models (e.g., RETAIN, AdaCare, Transformers, graph networks,
  convolutional networks, recurrent networks).
- **Prediction Task Module:** This module will be designed to handle
  various clinical prediction tasks using EHR data, including
  patient-level predictions (e.g., mortality, disease risk), intra-visit
  predictions (e.g., length of stay, drug recommendation), and
  inter-visit predictions (e.g., readmission risk, future diagnoses).
- **Support for Multi-modal Data Integration:** Enhancements to handle
  and integrate diverse data types beyond structured EHR data.
- **Clinical Trial Applications:** Developing functionalities to support
  research and analysis in the context of clinical trials.
- **Large Language Model (LLM) Enhancement:** Exploring the integration
  of LLMs to augment package capabilities.

RHealth aims to provide the R community with a powerful and
user-friendly toolkit for healthcare predictive modeling using deep
learning. We are glad to hear your feedbacks and suggestions via email
or submitting issues.
