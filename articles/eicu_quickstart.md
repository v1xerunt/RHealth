# Getting Started with eICU-CRD Dataset

## Introduction

The **eICU Collaborative Research Database (eICU-CRD)** is a large,
publicly available critical care database containing de-identified
health data from ICU patients across multiple hospitals in the United
States. This vignette demonstrates how to use the `eICUDataset` class in
RHealth to load and work with eICU data.

### Dataset Access

The eICU-CRD dataset is available at <https://eicu-crd.mit.edu/>. To
access the data, you need to:

1.  Complete the CITI “Data or Specimens Only Research” course
2.  Sign a data use agreement with PhysioNet
3.  Download the dataset (version 2.0 recommended)

## Basic Usage

### Step 1: Initialize Dataset with Patient Table

The simplest way to start is by loading only the patient table, which
contains core demographics and ICU stay information:

``` r
library(RHealth)

# Initialize with default patient table only
# Use dev = TRUE to limit to 1000 patients for rapid prototyping
## Not run:
eicu_ds <- eICUDataset$new(root = "/path/to/eicu-crd/2.0", dev = TRUE)
## End(Not run)

# Display dataset statistics
eicu_ds$stats()
```

### Step 2: Load Multiple Clinical Tables

For more comprehensive analysis, you can load additional clinical event
tables:

``` r
eicu_full <- eICUDataset$new(
  root = "/path/to/eicu-crd/2.0",
  tables = c(
    "diagnosis",      # ICD-9 diagnoses with diagnosis strings
    "medication",     # Medication orders with drug names
    "lab",            # Laboratory measurements
    "treatment",      # Treatment information
    "physicalexam",   # Physical examination findings
    "admissiondx"     # Primary admission diagnoses (APACHE)
  ),
  dev = FALSE  # Load full dataset
)

eicu_full$stats()
```

### Step 3: Access Patient Data

``` r
# Get all patient IDs (ICU stay IDs)
patient_ids <- eicu_full$unique_patient_ids()
cat("Total ICU stays:", length(patient_ids), "\n")

# Get a specific patient's data
patient <- eicu_full$get_patient(patient_ids[1])
print(patient)
```

## Understanding eICU Data Structure

### Patient Identifiers

The eICU database has three levels of patient identification:

- **uniquepid**: Unique patient identifier (across multiple admissions)
- **patienthealthsystemstayid**: Hospital admission identifier
- **patientunitstayid**: ICU stay identifier (used as primary ID in
  RHealth)

### Timestamps

All timestamps in eICU are **relative offsets in minutes** from the ICU
admission time:

- **Positive offsets**: Events after ICU admission
- **Negative offsets**: Events before ICU admission (e.g., during
  hospital stay)
- **Zero**: ICU admission time

``` r
# Example: View events with their offset timestamps
events <- eicu_full$collected_global_event_df()
head(events[, c("patient_id", "event_type", "timestamp")])
```

## Working with Compressed Files

The `eICUDataset` automatically handles both `.csv` and `.csv.gz` files.
No special configuration needed:

``` r
# Works with both patient.csv and patient.csv.gz
eicu_gz <- eICUDataset$new(
  root = "/path/to/eicu-crd/2.0",  # Can contain .csv.gz files
  tables = c("diagnosis", "medication"),
  dev = TRUE
)
```

## Advanced Usage

### Custom Configuration

You can provide a custom YAML configuration file to:

- Add custom tables
- Modify attributes to extract
- Change join relationships

``` r
eicu_custom <- eICUDataset$new(
  root = "/path/to/eicu-crd/2.0",
  tables = c("diagnosis", "lab"),
  config_path = "/path/to/custom_eicu_config.yaml",
  dataset_name = "eicu_custom",
  dev = TRUE
)
```

### Iterate Over All Patients

Process all patients for custom analyses:

``` r
# Returns a list of Patient objects
patients <- eicu_full$iter_patients()

# Example: Count events per patient
event_counts <- sapply(patients, function(p) {
  nrow(p$data_source)
})

summary(event_counts)
```

### Working with Event Data

``` r
# Get the full event dataframe
all_events <- eicu_full$collected_global_event_df()

# Filter specific event types
diagnoses <- all_events[all_events$event_type == "diagnosis", ]
medications <- all_events[all_events$event_type == "medication", ]
labs <- all_events[all_events$event_type == "lab", ]

# Summary by event type
table(all_events$event_type)
```

## Integration with Prediction Tasks

The `eICUDataset` can be integrated with task-specific processors for
various prediction tasks:

### Mortality Prediction

#### Option 1: Using ICD codes and standard features

``` r
# Load dataset with relevant tables
eicu_mortality <- eICUDataset$new(
  root = "/path/to/eicu-crd/2.0",
  tables = c("diagnosis", "medication", "physicalexam"),
  dev = FALSE
)

# Define and set mortality prediction task
mortality_task <- MortalityPredictionEICU$new()
sample_dataset <- eicu_mortality$set_task(task = mortality_task)

# Split dataset
splits <- split_by_patient(sample_dataset, c(0.8, 0.1, 0.1))

# Get dataloaders
train_dl <- get_dataloader(splits[[1]], batch_size = 32, shuffle = TRUE)
val_dl <- get_dataloader(splits[[2]], batch_size = 32)
test_dl <- get_dataloader(splits[[3]], batch_size = 32)

# Build and train model
model <- RNN(
  dataset = sample_dataset,
  embedding_dim = 128,
  rnn_type = "GRU",
  num_layers = 1
)

trainer <- Trainer$new(model = model)
trainer$train(
  train_dataloader = train_dl,
  val_dataloader = val_dl,
  epochs = 10,
  monitor = "roc_auc"
)

# Evaluate on test set
results <- trainer$evaluate(test_dl)
print(results)
```

#### Option 2: Using diagnosis strings and treatments

``` r
# Load dataset with alternative tables
eicu_mortality2 <- eICUDataset$new(
  root = "/path/to/eicu-crd/2.0",
  tables = c("diagnosis", "treatment", "admissiondx"),
  dev = FALSE
)

# Use alternative mortality task
mortality_task2 <- MortalityPredictionEICU2$new()
sample_dataset2 <- eicu_mortality2$set_task(task = mortality_task2)

# Continue with model training as above...
```

## Performance Tips

1.  **Use dev mode for prototyping**: Set `dev = TRUE` to limit to 1000
    patients
2.  **Data caching**: Data is automatically cached as Parquet files for
    faster subsequent loads
3.  **Lazy evaluation**: Data is loaded lazily using DuckDB until
    explicitly collected
4.  **Memory management**: Use `collected_global_event_df()` only when
    you need the full dataset in memory

## Available Tables

The following tables are supported in the default eICU configuration:

| Table          | Description                                 | Key Fields                               |
|----------------|---------------------------------------------|------------------------------------------|
| `patient`      | Core patient demographics and ICU stay info | gender, age, ethnicity, discharge status |
| `diagnosis`    | ICD-9 diagnoses                             | icd9code, diagnosisstring                |
| `treatment`    | Treatment information                       | treatmentstring                          |
| `medication`   | Medication orders                           | drugname, dosage, route                  |
| `lab`          | Laboratory measurements                     | labname, labresult                       |
| `physicalexam` | Physical examination findings               | physicalexampath, physicalexamvalue      |
| `admissiondx`  | Primary admission diagnoses                 | admitdxpath, admitdxname                 |

## See Also

- [BaseDataset
  documentation](https://your-package-url.com/reference/BaseDataset.html)
- [MIMIC-III
  Dataset](https://your-package-url.com/articles/mimic3_quickstart.html)
- [OMOP
  Dataset](https://your-package-url.com/articles/omop_quickstart.html)
- [eICU-CRD official documentation](https://eicu-crd.mit.edu/)
