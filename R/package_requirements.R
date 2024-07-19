#' Rename columns in a data frame to more readable versions
#'
#' This function takes a data frame that contains package version information
#' and renames specific columns to more readable versions. It is typically used
#' to improve the readability of package dependency report outputs. If `dat` is
#' `NULL`, the function immediately returns `NULL`.
#'
#' @param d A data frame representing package version information with columns
#' possibly named "requirement", "is_installed", "installed_version", and
#' "all_passed". If `NULL` is passed, the function returns `NULL` without
#' performing any operations.
#'
#' @return A data frame with renamed columns, where "requirement" is renamed to
#' "Requirement", "is_installed" is renamed to "Installed", "installed_version"
#' is renamed to "Version", and "all_passed" is renamed to "Passed". If `dat`
#' is `NULL`, the function returns `NULL`.
#'
#' @export
#' @examples
#' \dontrun{
#' example_df <- data.frame(
#'   requirement = c("pkgA > 1.0.0", "pkgB > 2.0.0"),
#'   is_installed = c(TRUE, FALSE),
#'   installed_version = c("1.2.0", NA),
#'   all_passed = c(TRUE, NA)
#' )
#'
#' renamed_df <- iop_rename_pkg_versions(example_df)
#' }
#' # The renamed_df should have columns named "Requirement", "Installed",
#' # "Version", and "Passed", corresponding to the previous names.
iop_rename_pkg_versions <- function(d) {
  assert_that(
    is.null(d) || is.data.frame(d),
    msg = "The argument 'd' should be a data frame or NULL."
  )

  if (is.null(d)) {
    return(NULL)
  }

  colnames(d) <- str_replace_all(
    colnames(d), c(
      "requirement" = "Requirement",
      "is_installed" = "Installed",
      "installed_version" = "Version",
      "all_passed" = "Passed"
    )
  )

  required_cols <- c(
    "Requirement", "Installed", "Version",
    "Passed"
  )

  assert_that(
    all(required_cols %in% colnames(d)),
    msg = "The data frame 'd' must contain the required columns: 'requirement',
    'is_installed', 'installed_version', and 'all_passed'."
  )

  d
}

#' Check Package Installation and Version Requirements
#'
#' Ensures that all packages specified in the `pkg_reqs` parameter meet the
#' custom installation and version requirements. This function is intended to
#' be used similarly to how package requirements are specified in a
#' DESCRIPTION file.
#'
#' @param pkg_reqs A character vector with each element specifying a package
#' requirement in the format "package (version requirement)". For example,
#' "dplyr (>=1.0.1)" denotes that the `dplyr` package needs to be installed
#' and have a version of at least 1.0.1. The vector must have at least one
#' element.
#'
#' @return A `tibble` with one row per package requirement specified in
#' `pkg_reqs`. The `tibble` contains the following columns:
#'   - `requirement`: The package requirement as specified in `pkg_reqs`.
#'   - `is_installed`: Logical value indicating whether the package is
#'     installed.
#'   - `installed_version`: The installed version of the package or `NA` if
#'     the package is not installed or an error occurred while retrieving
#'     the version.
#'   - `all_passed`: Logical value indicating whether the installed version
#'     meets the specified requirement or `NA` if an error occurred during
#'     checking.
#'
#' @export
#' @examples
#' # Example package requirements, replace with actual package names
#' example_reqs <- c("dplyr (>=1.0.1)", "ggplot2 (>=3.3.3)")
#' iop_check_all_reqs(example_reqs)
iop_check_all_reqs <- function(pkg_reqs) {
  assert_that(!is.null(pkg_reqs), length(pkg_reqs) >= 1, is.character(pkg_reqs))

  if (is.null(pkg_reqs)) {
    return(NULL)
  }

  tibble("requirement" = pkg_reqs) %>%
    rowwise() %>%
    mutate(
      is_installed = iop_check_installed(!!!sym("requirement")),
      installed_version =
        tryCatch(
          error = function(e) {
            NA
          },
          expr = iop_get_pkg_name(!!!sym("requirement")) %>%
            packageVersion() %>%
            as.character()
        ),
      all_passed =
        tryCatch(
          error = function(e) {
            NA
          },
          iop_check_version(!!!sym("requirement"))
        )
    ) %>%
    ungroup()
}

#' Check whether a package has been installed
#' @param pkg_req (character length >= 1) package requirement strings
iop_check_installed <- function(pkg_req) {
  iop_get_pkg_name(pkg_req) %in% installed.packages()[, "Package", drop = TRUE]
}

#' Check that the package version meets the requirement
#' @param pkg_req (character length >= 1) package requirement strings
iop_check_version <- function(pkg_req) {
  match.fun(iop_get_comp_operator(pkg_req))(
    packageVersion(iop_get_pkg_name(pkg_req)),
    numeric_version(iop_get_pkg_version(pkg_req))
  )
}

#' Get the comparison operator from package requirement string (e.g. "==")
#' @param pkg_req (character length >= 1) package requirement strings
iop_get_comp_operator <- function(pkg_req) {
  str_extract(pkg_req, "(?<=\\(\\s{0,3})[^\\s]+(?=\\s+)")
}

#' Get the package version from package requirement string (e.g. "1.0-1")
#' @param pkg_req (character length >= 1) package requirement strings
iop_get_pkg_version <- function(pkg_req) {
  str_extract(pkg_req, "(?<=\\s)[^()]+(?=\\))")
}

#' Get the package name from package requirement string (e.g. "dplyr")
#' @param pkg_req (character length >= 1) package requirement strings
iop_get_pkg_name <- function(pkg_req) {
  str_extract(pkg_req, "^[^\\s(]+")
}

iop_get_custom_tests <- function(settings) {
  if (is.null(settings[["packages"]])) {
    return(NULL)
  }

  pkgs <- settings[["packages"]] %>%
    strsplit(" ") %>%
    as.data.frame() %>%
    unname() %>%
    head(1) %>%
    unlist() %>%
    unique()

  test_types <- settings[["test_types"]]

  apply(unname(merge(pkgs, test_types, sort = TRUE)), 1, function(test_comb) {
    list(pkg = test_comb[1], types = test_comb[2])
  })
}
