#' Run all tests for base and recommended packages
#' @param tests_to_run (list of lists with "scope" and "type" elements)
#' @export
testBaseAndRecommendedPackages <- function(
      tests_to_run=list(
        list(scope = "base", types = "examples"),
        list(scope = "base", types = "vignettes"),
        list(scope = "base", types = "tests"),
        list(scope = "recommended", types = "examples"),
        list(scope = "recommended", types = "vignettes"),
        list(scope = "recommended", types = "tests")
      ),
      output_directory=TESTS_OUTPUT_DIRECTORY,
      ...
) {
  # Create data frame of input parameters:
  plyr::ldply(
    .data = tests_to_run,
    .fun = dplyr::as_tibble
  ) %>%
  # Run test on every row of input parameter:
  plyr::adply(
    .data = .,
    .margins = 1L,
    .fun = . %$% 
      {
        tryCatch(
          error = function(e) 1L,
          expr = tools::testInstalledPackages(
            scope = scope,
            types = types,
            outDir = output_directory,
            ...)
        )
      } %>% {dplyr::tibble(test_passed = !as.logical(.))}
  )
}
