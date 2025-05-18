#' Truncate an ATC Code to a Specified Level
#'
#' @description
#' Truncates one or more ATC codes
#' to the given number of characters,
#' corresponding to
#' the desired ATC classification level
#' (e.g., anatomical main group, therapeutic
#' subgroup, chemical substance).
#'
#' @param code
#'   A character scalar or vector of ATC codes, e.g. \code{"A01AA01"}.
#' @param level
#'   An integer scalar between 1 and 7 indicating how many characters to retain.
#'   Defaults to \code{5}.
#'
#' @return
#' A character vector of truncated ATC codes.
#'
#' @examples
#' atc_convert("A01AA01", level = 3)
#' atc_convert(c("B02BA02", "C03CA01"), level = 5)
#'
#' @export
atc_convert <- function(code, level = 5) {
  substr(code, 1, level)
}


#' Load the Drug–Drug Interaction (DDI) Table for ATC Codes
#'
#' @description
#' Retrieves the full drug–drug interaction table for ATC codes from the
#' cached resource. The table contains all pairs of interacting ATC codes.
#'
#' @return
#' A tibble with two character columns:
#' \describe{
#'   \item{ATC_i}{First ATC code in the interacting pair}
#'   \item{ATC_j}{Second ATC code in the interacting pair}
#' }
#'
#' @examples
#' ddi_tbl <- get_ddi()
#' head(ddi_tbl)
#'
#' @seealso
#' \code{\link{load_medcode}}
#'
#' @export
get_ddi <- function() {
  df <- load_medcode("DDI")
  names(df) <- c("ATC_i", "ATC_j")
  df
}
