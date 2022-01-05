#' Check that all custom package installation and version requirements are met
#' @param pkg_reqs (character length >= 1) package requirements of same format
#'  as used in the DESCRIPTION DCF files (e.g. "dplyr (>=1.0.1)")
#' @export
checkAllPackageRequirements <- function(pkg_reqs) {
  if (is.null(pkg_reqs)) return(NULL)
  dplyr::tibble(requirement = pkg_reqs) %>%
  dplyr::rowwise() %>%
  dplyr::mutate(
    is_installed = checkPackageInstalled(requirement),
    installed_version =
      tryCatch(
        error = function(e) {NA},
        expr = getPkgName(requirement) %>%
          packageVersion %>%
          as.character
      ),
    all_passed =
      tryCatch(
        error = function(e) {NA},
        checkPackageVersion(requirement)
      )
  ) %>%
  dplyr::ungroup()
}


#' Check whether a package has been installed
#' @param pkg_req (character length >= 1) package requirement strings
checkPackageInstalled <- function(pkg_req) {
  getPkgName(pkg_req) %in% installed.packages()[,"Package", drop=TRUE]
}


#' Check that the package version meets the requirement
#' @param pkg_req (character length >= 1) package requirement strings
checkPackageVersion <- function(pkg_req) {
  match.fun(getPkgComparisonOperator(pkg_req))(
    packageVersion(getPkgName(pkg_req)),
    numeric_version(getPkgVersion(pkg_req))
  )
}


#' Get the comparison operator from package requirement string (e.g. "==")
#' @param pkg_req (character length >= 1) package requirement strings
getPkgComparisonOperator <- function(pkg_req) {
  stringr::str_extract(pkg_req, "(?<=\\(\\s{0,3})[^\\s]+(?=\\s+)")
}


#' Get the package version from package requirement string (e.g. "1.0-1")
#' @param pkg_req (character length >= 1) package requirement strings
getPkgVersion <- function(pkg_req) {
  stringr::str_extract(pkg_req, "(?<=\\s)[^()]+(?=\\))")
}


#' Get the package name from package requirement string (e.g. "dplyr")
#' @param pkg_req (character length >= 1) package requirement strings
getPkgName <- function(pkg_req) {
  stringr::str_extract(pkg_req, "^[^\\s(]+")
}
