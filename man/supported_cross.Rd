% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Medcode_cross_map.R
\name{supported_cross}
\alias{supported_cross}
\title{List Supported Crosswalk Code Systems}
\usage{
supported_cross()
}
\value{
A character vector of mapping identifiers in the form
\code{"<from>_to_<to>"}, for example
\code{"ICD9CM_to_CCSCM"} or \code{"NDC_to_ATC"}.
}
\description{
Returns the names of all supported code‐to‐code mappings (crosswalks)
provided by the package.
}
\examples{
supported_cross()

}
\concept{MedCode}
