% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Model_BaseModel.R
\name{BaseModel}
\alias{BaseModel}
\title{BaseModel Class}
\usage{
BaseModel(dataset)
}
\arguments{
\item{dataset}{A dataset object (must have input_schema, output_schema, output_processors).}

\item{logits}{Torch tensor with raw model outputs.}
}
\value{
Integer scalar representing the output dimension.

A function such as nnf_binary_cross_entropy_with_logits or nnf_cross_entropy.

Torch tensor of probabilities.
}
\description{
Abstract base class for Torch models in R. This class handles dataset schema parsing,
output size calculation, loss function selection, and probability conversion for evaluation.

Determines output size based on label processor and task mode.
Only supports single label key for now.

Selects appropriate loss function based on task type in output schema.

Converts logits into predicted probabilities for evaluation.
Format depends on task mode (sigmoid or softmax, or raw).
}
\section{Fields}{

\describe{
\item{\code{dataset}}{A dataset object containing input/output schema and processors.}

\item{\code{feature_keys}}{Character vector of input feature names.}

\item{\code{label_keys}}{Character vector of output label names.}

\item{\code{device}}{Device (cpu or cuda) where the model is located.}
}}

