# Changelog

## RHealth 0.2.0

### Initial CRAN Release

This is the first CRAN submission of RHealth, a comprehensive deep
learning toolkit for healthcare predictive modeling in R.

#### Major Features

##### Dataset Module

- Support for multiple EHR database formats:
  - MIMIC-III and MIMIC-IV datasets
  - eICU Collaborative Research Database
  - OMOP Common Data Model
  - EHRShot benchmark datasets
- Built-in data harmonization and caching with DuckDB
- Dev mode for rapid prototyping with patient subsets
- Flexible dataset splitting by patient, visit, or sample
- YAML-based configuration for custom datasets

##### Model Module

- Implementation of state-of-the-art deep learning architectures:
  - RNN (Recurrent Neural Networks)
  - CNN (Convolutional Neural Networks)
  - Transformer models with multi-head attention
  - AdaCare (Adaptive feature correlation and feature-aware attention)
  - ConCare (Personalized clinical predictions via attention mechanisms)
- Embedding layers for medical code representations
- Automatic dimension calculation and loss function selection
- CPU and GPU support via torch

##### Task Module

- Pre-built prediction tasks:
  - In-hospital mortality prediction (MIMIC-III, MIMIC-IV)
  - Next-period mortality prediction
  - 30-day readmission prediction (MIMIC-IV, OMOP)
  - Mortality prediction for eICU and OMOP datasets
  - EHRShot benchmark tasks
- Extensible base classes for custom task definitions
- Support for multiple input/output schemas (binary, multiclass,
  multilabel, regression)

##### Medical Code Module

- Medical terminology lookup and hierarchical navigation
- Cross-system code mapping:
  - ICD-9-CM ↔︎ ICD-10-CM
  - ICD-9-CM/ICD-10-CM → CCS (Clinical Classifications Software)
  - NDC → ATC (Anatomical Therapeutic Chemical)
  - RxNorm → ATC
- Ancestor and descendant code retrieval
- Drug-drug interaction checking

##### Trainer Module

- Unified training interface with validation and testing
- Multiple evaluation metrics (AUROC, AUPRC, accuracy, F1, calibration)
- Early stopping and model checkpointing
- Support for custom metrics and loss functions
- Progress tracking and logging

##### Data Processing

- Flexible processors for different data types:
  - Time series sequences
  - Binary, multiclass, and multilabel labels
  - Text data
  - Feature tensors
- Automatic padding and batching with DataLoader integration

#### Infrastructure

- R6-based object-oriented design
- Integration with torch ecosystem
- Comprehensive documentation and vignettes
- Unit tests for core functionality
- GitHub repository with CI/CD workflows

#### Funding

RHealth is funded by the [ISC grant from the R
Consortium](https://r-consortium.org/all-projects/2024-group-2.html#deeprhealth-a-deep-learning-toolkit-for-healthcare-predictive-modeling).

#### Related Work

RHealth is the R counterpart to the Python library
[PyHealth](https://github.com/sunlabuiuc/PyHealth).
