# Package index

## Dataset

Classes for representing EHR datasets and configuration.

- [`BaseDataset`](https://v1xerunt.github.io/RHealth/reference/BaseDataset.md)
  : BaseDataset — R6 infrastructure for clinical event datasets
- [`SampleDataset()`](https://v1xerunt.github.io/RHealth/reference/SampleDataset.md)
  : SampleDataset
- [`MIMIC3Dataset`](https://v1xerunt.github.io/RHealth/reference/MIMIC3Dataset.md)
  : MIMIC3Dataset: Dataset class for MIMIC-III
- [`MIMIC4EHRDataset`](https://v1xerunt.github.io/RHealth/reference/MIMIC4EHRDataset.md)
  : MIMIC4EHRDataset: Dataset class for MIMIC-IV EHR
- [`MIMIC4NoteDataset`](https://v1xerunt.github.io/RHealth/reference/MIMIC4NoteDataset.md)
  : MIMIC4NoteDataset: Dataset class for MIMIC-IV Clinical Notes
- [`OMOPDataset`](https://v1xerunt.github.io/RHealth/reference/OMOPDataset.md)
  : OMOPDataset
- [`eICUDataset`](https://v1xerunt.github.io/RHealth/reference/eICUDataset.md)
  : eICUDataset: Dataset class for eICU-CRD
- [`EHRShotDataset`](https://v1xerunt.github.io/RHealth/reference/EHRShotDataset.md)
  : EHRShotDataset: Dataset class for EHRShot Benchmark
- [`Patient`](https://v1xerunt.github.io/RHealth/reference/Patient.md) :
  Patient: R6 Class for a Sequence of Events
- [`Event`](https://v1xerunt.github.io/RHealth/reference/Event.md) :
  Event: R6 Class for a Single Clinical Event
- [`DatasetConfig`](https://v1xerunt.github.io/RHealth/reference/DatasetConfig.md)
  : DatasetConfig: Root dataset configuration
- [`load_yaml_config()`](https://v1xerunt.github.io/RHealth/reference/load_yaml_config.md)
  : Load and validate dataset configuration from YAML
- [`get_dataloader()`](https://v1xerunt.github.io/RHealth/reference/get_dataloader.md)
  : Create DataLoader
- [`split_by_patient()`](https://v1xerunt.github.io/RHealth/reference/split_by_patient.md)
  : split_by_patient
- [`split_by_visit()`](https://v1xerunt.github.io/RHealth/reference/split_by_visit.md)
  : split_by_visit
- [`split_by_sample()`](https://v1xerunt.github.io/RHealth/reference/split_by_sample.md)
  : Dataset Split Functions
- [`load_sample_dataset()`](https://v1xerunt.github.io/RHealth/reference/load_sample_dataset.md)
  : Load a SampleDataset object from a directory

## Processors

Preprocessors for handling input/output features.

- [`Processor`](https://v1xerunt.github.io/RHealth/reference/Processor.md)
  : Abstract Processor Base Classes
- [`DatasetProcessor`](https://v1xerunt.github.io/RHealth/reference/DatasetProcessor.md)
  : DatasetProcessor: Processor applied to entire datasets
- [`SampleProcessor`](https://v1xerunt.github.io/RHealth/reference/SampleProcessor.md)
  : SampleProcessor: Processor for sample-level transformations
- [`FeatureProcessor`](https://v1xerunt.github.io/RHealth/reference/FeatureProcessor.md)
  : FeatureProcessor: Base class for all data processors
- [`TextProcessor`](https://v1xerunt.github.io/RHealth/reference/TextProcessor.md)
  : Text Processor
- [`SequenceProcessor`](https://v1xerunt.github.io/RHealth/reference/SequenceProcessor.md)
  : Sequence Processor
- [`TimeseriesProcessor`](https://v1xerunt.github.io/RHealth/reference/TimeseriesProcessor.md)
  : Time Series Processor
- [`BinaryLabelProcessor`](https://v1xerunt.github.io/RHealth/reference/BinaryLabelProcessor.md)
  : Binary Label Processor
- [`MultiClassLabelProcessor`](https://v1xerunt.github.io/RHealth/reference/MultiClassLabelProcessor.md)
  : Multi-Class Label Processor
- [`MultiLabelProcessor`](https://v1xerunt.github.io/RHealth/reference/MultiLabelProcessor.md)
  : Multi-Label Processor
- [`RegressionLabelProcessor`](https://v1xerunt.github.io/RHealth/reference/RegressionLabelProcessor.md)
  : Regression Label Processor
- [`RawProcessor`](https://v1xerunt.github.io/RHealth/reference/RawProcessor.md)
  : Raw Processor
- [`get_processor()`](https://v1xerunt.github.io/RHealth/reference/get_processor.md)
  : Get Processor Class (Hardcoded Version)

## Tasks

Benchmark prediction tasks for various EHR datasets.

- [`BaseTask`](https://v1xerunt.github.io/RHealth/reference/BaseTask.md)
  : BaseTask (Abstract Base Class)
- [`InHospitalMortalityMIMIC3`](https://v1xerunt.github.io/RHealth/reference/InHospitalMortalityMIMIC3.md)
  : InHospitalMortalityMIMIC3 Task
- [`InHospitalMortalityMIMIC4`](https://v1xerunt.github.io/RHealth/reference/InHospitalMortalityMIMIC4.md)
  : InHospitalMortalityMIMIC4 Task
- [`NextMortalityMIMIC3`](https://v1xerunt.github.io/RHealth/reference/NextMortalityMIMIC3.md)
  : NextMortalityMIMIC3 Task
- [`NextMortalityMIMIC4`](https://v1xerunt.github.io/RHealth/reference/NextMortalityMIMIC4.md)
  : NextMortalityMIMIC4 Task
- [`Readmission30DaysMIMIC4`](https://v1xerunt.github.io/RHealth/reference/Readmission30DaysMIMIC4.md)
  : Readmission30DaysMIMIC4 Task
- [`MortalityPredictionOMOP`](https://v1xerunt.github.io/RHealth/reference/MortalityPredictionOMOP.md)
  : MortalityPredictionOMOP Task
- [`ReadmissionPredictionOMOP`](https://v1xerunt.github.io/RHealth/reference/ReadmissionPredictionOMOP.md)
  : ReadmissionPredictionOMOP Task
- [`MortalityPredictionEICU`](https://v1xerunt.github.io/RHealth/reference/MortalityPredictionEICU.md)
  : MortalityPredictionEICU Task
- [`MortalityPredictionEICU2`](https://v1xerunt.github.io/RHealth/reference/MortalityPredictionEICU2.md)
  : MortalityPredictionEICU2 Task (Alternative Feature Set)
- [`BenchmarkEHRShot`](https://v1xerunt.github.io/RHealth/reference/BenchmarkEHRShot.md)
  : BenchmarkEHRShot: Benchmark predictive tasks using EHRShot

## Models

Neural network models built on torch.

- [`BaseModel()`](https://v1xerunt.github.io/RHealth/reference/BaseModel.md)
  : BaseModel Class
- [`EmbeddingModel()`](https://v1xerunt.github.io/RHealth/reference/EmbeddingModel.md)
  : EmbeddingModel
- [`RNN()`](https://v1xerunt.github.io/RHealth/reference/RNN.md) : RNN
  Model Class
- [`Transformer()`](https://v1xerunt.github.io/RHealth/reference/Transformer.md)
  : Transformer Model Class
- [`CNN()`](https://v1xerunt.github.io/RHealth/reference/CNN.md) : CNN
  Model Class
- [`AdaCare()`](https://v1xerunt.github.io/RHealth/reference/AdaCare.md)
  : AdaCare Model Class (Version 2 - With Timeseries Support)
- [`ConCare()`](https://v1xerunt.github.io/RHealth/reference/ConCare.md)
  : ConCare Model Class

## Training & Evaluation

Trainer class and supporting functions for training deep learning
models.

- [`Trainer`](https://v1xerunt.github.io/RHealth/reference/Trainer.md) :
  Generic Trainer for torch models
- [`collate_fn_dict_with_padding()`](https://v1xerunt.github.io/RHealth/reference/collate_fn_dict_with_padding.md)
  : Collate Function with Padding
- [`get_metrics_fn()`](https://v1xerunt.github.io/RHealth/reference/get_metrics_fn.md)
  : Get Metrics Function
- [`binary_metrics_fn()`](https://v1xerunt.github.io/RHealth/reference/binary_metrics_fn.md)
  : Binary Classification Metrics (Python‐style API)
- [`multiclass_metrics_fn()`](https://v1xerunt.github.io/RHealth/reference/multiclass_metrics_fn.md)
  : Multiclass Classification Metrics
- [`multilabel_metrics_fn()`](https://v1xerunt.github.io/RHealth/reference/multilabel_metrics_fn.md)
  : Multilabel Classification Metrics
- [`regression_metrics_fn()`](https://v1xerunt.github.io/RHealth/reference/regression_metrics_fn.md)
  : Regression Metrics
- [`is_best()`](https://v1xerunt.github.io/RHealth/reference/is_best.md)
  : Check if Score is Best
- [`set_logger()`](https://v1xerunt.github.io/RHealth/reference/set_logger.md)
  : Initialize Logger
- [`ece_confidence_binary()`](https://v1xerunt.github.io/RHealth/reference/ece_confidence_binary.md)
  : Expected Calibration Error for Binary Classification

## MedCode

Tools in the MedCode Module.

- [`atc_convert()`](https://v1xerunt.github.io/RHealth/reference/atc_convert.md)
  : Truncate an ATC Code to a Specified Level
- [`get_ancestors()`](https://v1xerunt.github.io/RHealth/reference/get_ancestors.md)
  : Get Ancestor Codes in the Hierarchy
- [`get_ddi()`](https://v1xerunt.github.io/RHealth/reference/get_ddi.md)
  : Load the Drug–Drug Interaction (DDI) Table for ATC Codes
- [`get_descendants()`](https://v1xerunt.github.io/RHealth/reference/get_descendants.md)
  : Get Descendant Codes in the Hierarchy
- [`lookup_code()`](https://v1xerunt.github.io/RHealth/reference/lookup_code.md)
  : Lookup a Medical Code Entry
- [`map_code()`](https://v1xerunt.github.io/RHealth/reference/map_code.md)
  : Map a Code from One System to Another
- [`supported_cross()`](https://v1xerunt.github.io/RHealth/reference/supported_cross.md)
  : List Supported Crosswalk Code Systems
- [`supported_inner()`](https://v1xerunt.github.io/RHealth/reference/supported_inner.md)
  : List Supported Medical Code Systems

## Utilities

Other tools.

- [`create_directory()`](https://v1xerunt.github.io/RHealth/reference/create_directory.md)
  : Create Directory if Not Exists
- [`Event-from_list`](https://v1xerunt.github.io/RHealth/reference/Event-from_list.md)
  : from_list: Create Event from row
- [`JoinConfig`](https://v1xerunt.github.io/RHealth/reference/JoinConfig.md)
  : JoinConfig: Configuration for joining tables in a dataset
- [`rhealth.config`](https://v1xerunt.github.io/RHealth/reference/rhealth.config.md)
  : Dataset Configuration
- [`TableConfig`](https://v1xerunt.github.io/RHealth/reference/TableConfig.md)
  : TableConfig: Configuration for a single table
