% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Dataset_splitter.R
\name{split_by_visit}
\alias{split_by_visit}
\title{split_by_visit}
\usage{
split_by_visit(dataset, ratios, seed = NULL)
}
\arguments{
\item{dataset}{A \code{SampleDataset} object.}

\item{ratios}{A numeric vector of length 3 indicating train/val/test split ratios. Must sum to 1.}

\item{seed}{Optional integer for reproducibility.}
}
\value{
A list of 3 torch::dataset_subset objects.
}
\description{
split_by_visit
}
