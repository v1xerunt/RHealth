#' Package Load Hook
#'
#' @description
#' Internal hook: when the DeepRHealth package is loaded, ensure that
#' `options("DeepRHealth.medcode_base")` is set to the default URL if
#' the user hasn’t already overridden it.
#'
#' @keywords internal
#' @noRd
.onLoad <- function(libname, pkgname) {
  if (is.null(getOption("DeepRHealth.medcode_base"))) {
    options(
      DeepRHealth.medcode_base =
        "https://storage.googleapis.com/pyhealth/resource/"
    )
  }
}
