#' Package Load Hook
#'
#' @description
#' Internal hook: when the RHealth package is loaded, ensure that
#' `options("RHealth.medcode_base")` is set to the default URL if
#' the user hasn’t already overridden it.
#'
#' @keywords internal
#' @noRd
.onLoad <- function(libname, pkgname) {
  if (is.null(getOption("RHealth.medcode_base"))) {
    options(
      RHealth.medcode_base =
        "https://storage.googleapis.com/pyhealth/resource/"
    )
  }
}
