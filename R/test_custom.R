#' Custom operation and performance tests
#' @param packages (character length >= 1)
#' @param type (character length 1) either "operational" or "performance", the
#'   test "type"
#' @param tests_path (character length 1) the location of the tests
#' @export
runCustomTests <- function(packages=NULL, type=NULL, tests_path=NULL) {
  if (any(sapply(list(packages, type, tests_path), is.null))) return(NULL)
  packages %>%
  {setNames(as.list(.), .)} %>%
  print %>%
  plyr::ldply(
    .id = "pkg",
    .fun = . %>% 
      {testthat::test_dir(path = print(file.path(tests_path, ., type)))} %>%
      dplyr::as_tibble() %>%
      dplyr::mutate(type = type)
  ) %>%
  dplyr::as_tibble() %>%
  dplyr::select(pkg, type, dplyr::everything())
}
