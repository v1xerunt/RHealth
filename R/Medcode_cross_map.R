#' List Supported Crosswalk Code Systems
#'
#' @description
#' Returns the names of all supported code‐to‐code mappings (crosswalks)
#' provided by the package.
#'
#' @return
#' A character vector of mapping identifiers in the form
#' \code{"<from>_to_<to>"}, for example
#' \code{"ICD9CM_to_CCSCM"} or \code{"NDC_to_ATC"}.
#'
#' @concept MedCode
#'
#' @examples
#' supported_cross()
#'
#' @export
supported_cross <- function() {
  c(
    "ICD9CM_to_CCSCM", "ICD9PROC_to_CCSPROC",
    "ICD10CM_to_CCSCM", "ICD10PROC_to_CCSPROC", "NDC_to_ATC"
  )
}

#' Map a Code from One System to Another
#'
#' @description
#' Looks up the equivalent code(s) in a target coding system for a given
#' source code, using the built‑in crosswalk CSV tables.
#'
#' @param code   A single \code{character} string specifying the code to map.
#' @param from   A single \code{character} string naming the source code system
#'               (e.g. \code{"ICD9CM"}, \code{"ATC"}). Must be one of the
#'               systems listed in \code{supported_inner()}.
#' @param to     A single \code{character} string naming the target code system
#'               (e.g. \code{"CCSCM"}, \code{"NDC"}). The pair
#'               \code{paste0(from, "_to_", to)} must be one of
#'               \code{supported_cross()}.
#'
#' @return
#' A character vector of mapped code(s) in the target system. If no match
#' is found, returns an empty \code{character} vector.
#'
#' @examples
#' \dontrun{
#' # Map an ICD-10 code to its CCS category
#' map_code("I10", from = "ICD10CM", to = "CCSCM")
#' }
#'
#' @concept MedCode
#'
#' @seealso
#' \code{\link{load_medcode}}, \code{\link{supported_cross}}
#'
#' @export
map_code <- function(code, from = "ICD9CM", to = "CCSCM") {
  name <- paste0(from, "_to_", to)
  df <- load_medcode(name)
  df[df[[1]] == code, 2, drop = TRUE]
}
