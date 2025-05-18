#' Load and Parse Medical Code CSV
#'
#' @description
#' Downloads (if necessary) and reads a medical code CSV for the specified
#' name, returning a tibble with all columns as character.
#'
#' @param name Character(1). Identifier of the medical code CSV (without the
#'   \`.csv\` extension), e.g. \code{"ICD10"} or \code{"CPT"}.
#'
#' @return A tibble (`tibble::tibble`) in which every column is of type
#'   character.
#'
#' @details
#' Internally, this function calls \code{\link{download_medcode}()} to ensure
#' the requested CSV is present in the local cache. It then invokes
#' \code{readr::read_csv()} with \code{col_types = cols(.default = "c")} so
#' that all columns are imported as character.
#'
#' @examples
#' \dontrun{
#' # Load the ICD-10 mapping table
#' icd10_tbl <- load_medcode("ICD10")
#' }
#'
#' @seealso
#' \code{\link{download_medcode}}, \code{\link[readr]{read_csv}}
#'
#' @keywords internal
#' @noRd
#' @importFrom readr read_csv cols
load_medcode <- function(name) {
  path <- download_medcode(name)
  readr::read_csv(path, col_types = readr::cols(.default = "c"))
}
