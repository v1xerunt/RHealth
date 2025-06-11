#' List Supported Medical Code Systems
#'
#' @description
#' Returns a character vector of the internal code systems currently supported
#' by the package.
#'
#' @return
#' A character vector of supported code system identifiers.
#'
#' @examples
#' supported_inner()
#'
#' @concept MedCode
#'
#' @export
supported_inner <- function() {
  c(
    "ICD9CM", "ICD9PROC", "ICD10CM", "ICD10PROC",
    "ATC", "CCSCM", "CCSPROC", "NDC"
  )
}

#' Lookup a Medical Code Entry
#'
#' @description
#' Retrieves the row(s) in the code table matching a given code.
#'
#' @param code
#'   A single \code{character} string specifying the code to look up.
#' @param system
#'   A single \code{character} string naming the code system, one of
#'   \code{supported_inner()}. Defaults to \code{"ICD9CM"}.
#'
#' @return
#' A \code{data.frame} (or tibble) containing all columns for the matching
#' code. If no match is found, returns an empty data frame with the same
#' columns as the code table.
#'
#' @examples
#' \dontrun{
#' lookup_code("A00", "ICD10CM")
#' }
#'
#' @seealso
#' \code{\link{load_medcode}}, \code{\link{supported_inner}}
#'
#' @concept MedCode
#'
#' @export
lookup_code <- function(code, system = "ICD9CM") {
  df <- load_medcode(system)
  df[df[[1]] == code, , drop = FALSE]
}

#' Get Ancestor Codes in the Hierarchy
#'
#' @description
#' For a given code, returns all ancestor codes by following the
#' \code{parent_code} pointers until the root.
#'
#' @param code
#'   A single \code{character} string specifying the starting code.
#' @param system
#'   A single \code{character} string naming the code system, one of
#'   \code{supported_inner()}. Defaults to \code{"ICD9CM"}.
#'
#' @return
#' A character vector of ancestor codes, ordered from immediate parent up to
#' the highest-level ancestor.
#'
#' @examples
#' \dontrun{
#' get_ancestors("401.9", "ICD9CM")
#' }
#'
#' @seealso
#' \code{\link{get_descendants}}, \code{\link{load_medcode}}
#'
#' @concept MedCode
#'
#' @export
get_ancestors <- function(code, system = "ICD9CM") {
  df <- load_medcode(system)
  parents <- setNames(df$parent_code, df[[1]])
  out <- character()
  cur <- code
  while (!is.na(parents[cur]) && nzchar(parents[cur])) {
    cur <- parents[cur]
    out <- c(out, cur)
  }
  out
}

#' Get Descendant Codes in the Hierarchy
#'
#' @description
#' For a given code,
#' returns all descendant codes
#' (children, grandchildren, etc.)
#' by traversing the hierarchy downward.
#'
#' @param code
#'   A single \code{character} string specifying the starting code.
#' @param system
#'   A single \code{character} string naming the code system, one of
#'   \code{supported_inner()}. Defaults to \code{"ICD9CM"}.
#'
#' @return
#' A character vector of all descendant codes, in no particular order.
#'
#' @examples
#' \dontrun{
#' get_descendants("A00", "ICD10CM")
#' }
#'
#' @seealso
#' \code{\link{get_ancestors}}, \code{\link{load_medcode}}
#'
#' @concept MedCode
#'
#' @export
get_descendants <- function(code, system = "ICD9CM") {
  df <- load_medcode(system)
  parents <- setNames(df$parent_code, df[[1]])
  children <- split(df[[1]], parents)
  out <- character()
  queue <- code
  while (length(queue)) {
    cur <- queue[1]
    queue <- queue[-1]
    kids <- children[[cur]]
    if (!is.null(kids)) {
      out <- c(out, kids)
      queue <- c(queue, kids)
    }
  }
  unique(out)
}
