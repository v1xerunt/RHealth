% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Processor_binary.R
\name{BinaryLabelProcessor}
\alias{BinaryLabelProcessor}
\title{Binary Label Processor}
\description{
Processor for binary classification labels. Supports numeric (0/1),
logical (TRUE/FALSE), or categorical binary labels.
}
\section{Super classes}{
\code{RHealth::Processor} -> \code{RHealth::FeatureProcessor} -> \code{BinaryLabelProcessor}
}
\section{Public fields}{
\if{html}{\out{<div class="r6-fields">}}
\describe{
\item{\code{label_vocab}}{A named integer vector representing label-to-index mapping.}
}
\if{html}{\out{</div>}}
}
\section{Methods}{
\subsection{Public methods}{
\itemize{
\item \href{#method-BinaryLabelProcessor-new}{\code{BinaryLabelProcessor$new()}}
\item \href{#method-BinaryLabelProcessor-fit}{\code{BinaryLabelProcessor$fit()}}
\item \href{#method-BinaryLabelProcessor-process}{\code{BinaryLabelProcessor$process()}}
\item \href{#method-BinaryLabelProcessor-size}{\code{BinaryLabelProcessor$size()}}
\item \href{#method-BinaryLabelProcessor-print}{\code{BinaryLabelProcessor$print()}}
\item \href{#method-BinaryLabelProcessor-clone}{\code{BinaryLabelProcessor$clone()}}
}
}
\if{html}{\out{
<details open><summary>Inherited methods</summary>
<ul>
<li><span class="pkg-link" data-pkg="RHealth" data-topic="Processor" data-id="load"><a href='../../RHealth/html/Processor.html#method-Processor-load'><code>RHealth::Processor$load()</code></a></span></li>
<li><span class="pkg-link" data-pkg="RHealth" data-topic="Processor" data-id="save"><a href='../../RHealth/html/Processor.html#method-Processor-save'><code>RHealth::Processor$save()</code></a></span></li>
</ul>
</details>
}}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-BinaryLabelProcessor-new"></a>}}
\if{latex}{\out{\hypertarget{method-BinaryLabelProcessor-new}{}}}
\subsection{Method \code{new()}}{
Initialize the processor with empty vocabulary.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{BinaryLabelProcessor$new()}\if{html}{\out{</div>}}
}

}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-BinaryLabelProcessor-fit"></a>}}
\if{latex}{\out{\hypertarget{method-BinaryLabelProcessor-fit}{}}}
\subsection{Method \code{fit()}}{
Fit the processor by analyzing all unique labels in the dataset.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{BinaryLabelProcessor$fit(samples, field)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{samples}}{A list of named lists (samples).}

\item{\code{field}}{The name of the label field to process.}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-BinaryLabelProcessor-process"></a>}}
\if{latex}{\out{\hypertarget{method-BinaryLabelProcessor-process}{}}}
\subsection{Method \code{process()}}{
Process a label into a torch tensor \link{0} or \link{1}.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{BinaryLabelProcessor$process(value)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{value}}{A single label value.}
}
\if{html}{\out{</div>}}
}
\subsection{Returns}{
A float32 torch tensor of shape \link{1}.
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-BinaryLabelProcessor-size"></a>}}
\if{latex}{\out{\hypertarget{method-BinaryLabelProcessor-size}{}}}
\subsection{Method \code{size()}}{
Return the output dimensionality (fixed at 1).
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{BinaryLabelProcessor$size()}\if{html}{\out{</div>}}
}

\subsection{Returns}{
Integer 1
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-BinaryLabelProcessor-print"></a>}}
\if{latex}{\out{\hypertarget{method-BinaryLabelProcessor-print}{}}}
\subsection{Method \code{print()}}{
Print a summary of the processor.


Print a summary of the processor.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{BinaryLabelProcessor$print(...)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{...}}{Ignored.}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-BinaryLabelProcessor-clone"></a>}}
\if{latex}{\out{\hypertarget{method-BinaryLabelProcessor-clone}{}}}
\subsection{Method \code{clone()}}{
The objects of this class are cloneable with this method.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{BinaryLabelProcessor$clone(deep = FALSE)}\if{html}{\out{</div>}}
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
