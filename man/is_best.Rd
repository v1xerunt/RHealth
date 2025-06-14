% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Trainer.R
\name{is_best}
\alias{is_best}
\title{Check if Score is Best}
\usage{
is_best(best_score, score, monitor_criterion)
}
\arguments{
\item{best_score}{Numeric. Current best score.}

\item{score}{Numeric. New score to compare.}

\item{monitor_criterion}{Character. Either "max" or "min".}
}
\value{
Logical. TRUE if the new score is better.
}
\description{
Compares current score with best score using criterion (max or min).
}
