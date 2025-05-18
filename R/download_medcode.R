#' Download and Cache Medical Code CSV
#'
#' @description
#' Fetches a CSV file for the specified medical code from a remote server,
#' caches it locally, and returns the path to the cached file.
#'
#' @param name  A single \code{character} string specifying the code name
#'   (without \code{".csv"}), e.g. \code{"ICD10"} or \code{"CPT"}.
#'
#' @return
#' A single \code{character} string giving the full path to the downloaded
#' or previously cached CSV file.
#'
#' @details
#' By default, when the package is loaded, \code{.onLoad()} sets
#' \code{options(RHealth.medcode_base)} to
#' \code{"https://storage.googleapis.com/pyhealth/resource/"}.
#' The CSV will be downloaded from
#' \code{file.path(getOption("RHealth.medcode_base"),
#' paste0(name, ".csv"))}.
#'
#' To override the download location, set your own base URL before calling:
#' \preformatted{
#' options(RHealth.medcode_base = "https://your.server/medcode/")
#' }
#'
#' Cached files are stored under:
#' \code{file.path(rappdirs::user_cache_dir("RHealth"), "medcode")}.
#'
#' @examples
#' \dontrun{
#' # Use default server
#' path1 <- download_medcode("ICD10")
#'
#' # Use a custom server
#' options(RHealth.medcode_base = "https://internal.example.com/medcode/")
#' path2 <- download_medcode("CPT")
#' }
#'
#' @seealso
#' \code{\link[fs]{path}}, \code{\link[fs]{dir_create}},
#' \code{\link[rappdirs]{user_cache_dir}},
#' \code{\link[httr]{GET}}, \code{\link[httr]{write_disk}}
#'
#' @keywords internal
#' @importFrom fs path dir_create file_exists
#' @importFrom rappdirs user_cache_dir
#' @importFrom httr GET write_disk
download_medcode <- function(name) {
  cache_dir <- fs::path(rappdirs::user_cache_dir("RHealth"), "medcode")
  fs::dir_create(cache_dir, recurse = TRUE)
  dest <- fs::path(cache_dir, paste0(name, ".csv"))
  if (!fs::file_exists(dest)) {
    url <- paste0(getOption("RHealth.medcode_base"), name, ".csv")
    httr::GET(url, httr::write_disk(dest, overwrite = TRUE))
  }
  dest
}
