% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Processor_BaseProcessor.R
\name{Processor}
\alias{Processor}
\title{Abstract Processor Base Classes}
\description{
Provides abstract base classes for three levels of data processing:
field-level (\code{FeatureProcessor}), sample-level (\code{SampleProcessor}), and dataset-level (\code{DatasetProcessor}).
Each processor inherits from a common \code{Processor} base class which includes optional \code{save()} and \code{load()} methods.

Concrete implementations should inherit from these and override at least the \code{process()} method.
}
\section{Methods}{
\subsection{Public methods}{
\itemize{
\item \href{#method-Processor-save}{\code{Processor$save()}}
\item \href{#method-Processor-load}{\code{Processor$load()}}
\item \href{#method-Processor-clone}{\code{Processor$clone()}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-Processor-save"></a>}}
\if{latex}{\out{\hypertarget{method-Processor-save}{}}}
\subsection{Method \code{save()}}{
Save processor state to disk (optional).
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{Processor$save(path)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{path}}{A string file path.}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-Processor-load"></a>}}
\if{latex}{\out{\hypertarget{method-Processor-load}{}}}
\subsection{Method \code{load()}}{
Load processor state from disk (optional).
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{Processor$load(path)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{path}}{A string file path.}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-Processor-clone"></a>}}
\if{latex}{\out{\hypertarget{method-Processor-clone}{}}}
\subsection{Method \code{clone()}}{
The objects of this class are cloneable with this method.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{Processor$clone(deep = FALSE)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{deep}}{Whether to make a deep clone.}
}
\if{html}{\out{</div>}}
}
}
}
