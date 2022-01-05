#' Test on non-base, non-recommended packages by their included tests
#' @param tests_to_run (list of lists with elements "pkg" and "types")
#' @export
testCustomInstalledPackages <- function(
      tests_to_run=CUSTOM_TESTS_TO_RUN(IOPQUALR_SETTINGS),
      output_directory=TESTS_OUTPUT_DIRECTORY,
      ...
) {
  print(output_directory)
  # Create data frame of input parameters:
  output <- plyr::ldply(
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
          {tools::testInstalledPackage(
            pkg = pkg,
            types = types,
            outDir = output_directory, 
            ...
          )
            }, error = function(e){1}
          )
        } %>%
      {dplyr::tibble(test_passed = !as.logical(.))}
  )
  #
  if (sum(dim(output)) == 0) {
    return(NULL)
  } else {
    return(output)
  }
}


#' @export

renameInstalledPackageVersions <- function(dat) {
  if (is.null(dat)) return(NULL)
  dat %>%
  dplyr::rename(
    `Requirement` = "requirement",
    `Installed` = is_installed,
    `Version` = installed_version,
    `Passed` = all_passed, 
  )
}

CUSTOM_TESTS_TO_RUN <- function(settings) {
  if (is.null(settings$packages)) return(NULL)
  #
  pkgs <- settings$packages %>% strsplit(" ") %>% as.data.frame %>% unname %>% .[1, ] %>% unlist %>% unique
  test_types <- settings$test_types
  test_list <- apply(unname(merge(pkgs, test_types, sort = T)), 1, function(test_comb) {
    list(pkg = test_comb[1], types = test_comb[2])
  })
  
  test_list
}
