% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Medcode_download.R
\name{download_medcode}
\alias{download_medcode}
\title{Download and Cache Medical Code CSV}
\usage{
download_medcode(name)
}
\arguments{
\item{name}{A single \code{character} string specifying the code name
(without \code{".csv"}), e.g. \code{"ICD10"} or \code{"CPT"}.}
}
\value{
A single \code{character} string giving the full path to the downloaded
or previously cached CSV file.
}
\description{
Fetches a CSV file for the specified medical code from a remote server,
caches it locally, and returns the path to the cached file.
}
\details{
By default, when the package is loaded, \code{.onLoad()} sets
\code{options(RHealth.medcode_base)} to
\code{"https://storage.googleapis.com/pyhealth/resource/"}.
The CSV will be downloaded from
\code{file.path(getOption("RHealth.medcode_base"),
paste0(name, ".csv"))}.

To override the download location, set your own base URL before calling:
\preformatted{
options(RHealth.medcode_base = "https://your.server/medcode/")
}

Cached files are stored under:
\code{file.path(rappdirs::user_cache_dir("RHealth"), "medcode")}.
}
\examples{
\dontrun{
# Use default server
path1 <- download_medcode("ICD10")

# Use a custom server
options(RHealth.medcode_base = "https://internal.example.com/medcode/")
path2 <- download_medcode("CPT")
}

}
\seealso{
\code{\link[fs]{path}}, \code{\link[fs]{dir_create}},
\code{\link[rappdirs]{user_cache_dir}},
\code{\link[httr]{GET}}, \code{\link[httr]{write_disk}}
}
\concept{MedCode}
\keyword{internal}
