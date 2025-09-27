.medcode_gdrive_links <- c(
  "ATC" = "1LOAf-AheiZ28vkTcAn6K2X89-jpxU-ok",
  "CCSCM" = "1FpsaT1EPaeJ2vw9WxCi0fTt3kr1jjmyi",
  "CCSPROC" = "1dd6MNzENb9utr_F-YPwoNFV6wheHwBi8",
  "DDI" = "15DKDEcENncyeAVieHV_kP8iCZl8hMpRP",
  "ICD9CM_to_CCSCM" = "1Yruhix5yEH15C898p0VL_40G9K0dn-cR",
  "ICD9CM" = "1UMF66hl5vxZ9SXIAJLCSC8ugxeYwkFV9",
  "ICD9PROC_to_CCSPROC" = "16oFsOpgmtlDmMHAr5pW6KUCks1-ir5k6",
  "ICD9PROC" = "1Sez38YseXaifokM2frRvZ8chNI8NhvB0",
  "ICD10CM_to_CCSCM" = "1utcHE81_mbjqDuEbPvZ9uto9f_yGqr9n",
  "ICD10CM" = "1Oe9A6x58O2ZaXhtfqnK5vqjbXMVIAH0W",
  "ICD10PROC_to_CCSPROC" = "1gG44ALc8DVGT6Yg9HRUlwgLv9iuJ-6Ql",
  "ICD10PROC" = "1ThPq6D16QXnK21fV_kl5JqD5A-rDVHQQ",
  "NDC_to_ATC" = "11IQSkVaGjTc6kZ0XFUd_FgQa3uRrvihP",
  "NDC" = "11mCQ3AJTkZvkC0WWfxLhaxU5Mg-a3S9L",
  "ICD10CM_to_ICD9CM" = "1Ioo_Aq-sXmiO8FKmsupE8EidiWpm8Q_6",
  "ICD9CM_to_ICD10CM" = "1_EUiJ8AINq4ktZcbuVGoxXDj8Ddy8QrQ",
  "ICD10PCS_to_ICD9PCS" = "1ZQOw2ww73uqJBGHNfJDRpYVzHAXeXWz7",
  "ICD9PCS_to_ICD10PCS" = "1pYsgXndNTaRvWieEBw4FQu8AvM25-Qh2",
  "ICD10CMPCS_to_ICD9CM" = "12GlFYTmdxOVGjxSLQKR-qMv9q4rOka8e"
)

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
#' @concept MedCode
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
    if (name %in% names(.medcode_gdrive_links)) {
      file_id <- .medcode_gdrive_links[[name]]
      url <- paste0("https://drive.google.com/uc?export=download&id=", file_id)
    } else {
      stop(paste("Medical code", name, "is not supported."))
    }
    httr::GET(url, httr::write_disk(dest, overwrite = TRUE))
  }
  dest
}
