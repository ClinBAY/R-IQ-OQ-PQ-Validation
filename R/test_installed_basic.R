#' Run basic installed test
#' @param scope (character length 1) which tests to run
#' @export
runBasicInstalledTest <- function(scope="both") {
  # Check that the tests have been installed.
  {
    if (!dir.exists(file.path(R.home(), "tests"))) {
      NA
    } else {
      tools::testInstalledBasic(scope = scope) %>%
      {!as.logical(.)}
    }
  } %>%
    {dplyr::tibble(scope = scope, test_passed = .)}
}
