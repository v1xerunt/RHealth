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
    "ICD10CM_to_CCSCM", "ICD10PROC_to_CCSPROC", "NDC_to_ATC",
    "ICD10CM_to_ICD9CM", "ICD9CM_to_ICD10CM",
    "ICD10PCS_to_ICD9PCS", "ICD9PCS_to_ICD10PCS",
    "ICD10CMPCS_to_ICD9CM"
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
#' @importFrom stringr str_pad
map_code <- function(code, from = "ICD9CM", to = "CCSCM") {
  name <- paste0(from, "_to_", to)
  df <- load_medcode(name)
  
  # Pad numeric-only ICD9 codes with leading zeros, stripping decimals
  if (from == "ICD9CM" && grepl("^[0-9.]+$", code)) {
    code <- gsub("\\.", "", code)
    code <- stringr::str_pad(code, 5, pad = "0", side = "left")
  } else if (from == "ICD9PCS" && grepl("^[0-9.]+$", code)) {
    code <- gsub("\\.", "", code)
    code <- stringr::str_pad(code, 4, pad = "0", side = "left")
  }
  
  # Normalize column names for broader compatibility
  from_col <- tolower(gsub("[^A-Za-z0-9]", "", from))
  to_col <- tolower(gsub("[^A-Za-z0-9]", "", to))
  df_cols <- tolower(gsub("[^A-Za-z0-9]", "", names(df)))
  
  from_idx <- match(from_col, df_cols)
  to_idx <- match(to_col, df_cols)
  
  # Fallback to original column names if not found
  if (is.na(from_idx)) from_idx <- match(from, names(df))
  if (is.na(to_idx)) to_idx <- match(to, names(df))
  
  # Fallback to default column positions if names don't match
  if (is.na(from_idx) || is.na(to_idx)) {
    from_idx <- 1
    to_idx <- 2
  }
  
  # Perform the lookup
  matches <- df[[from_idx]] == code
  if (any(matches, na.rm = TRUE)) {
    return(df[matches, to_idx, drop = TRUE])
  }
  
  character(0)
}
