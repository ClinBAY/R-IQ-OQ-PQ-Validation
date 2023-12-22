#' Check if Output Directory Is Valid
#'
#' This function checks if the test output directory specified does not match
#' or is not a subdirectory of the input and settings directories.
#'
#' @param input_directory A string representing the path to the input directory.
#' @param settings_directory A string representing the path to the settings
#' directory.
#' @param test_outputs_directory A string representing the path to the directory
#' where test outputs are to be written.
#'
#' @return A logical value indicating whether the test output directory is
#' valid (`TRUE`) or not (`FALSE`).
#' If the test output directory does match any of the other directories, or if
#' it is a subdirectory of them,
#' then the function will return `FALSE`, otherwise it will return `TRUE`.
#'
#' @examples
#' \dontrun{
#' iop_check_output_dir(
#'   "/my/project/input", "/my/project/settings",
#'   "/my/project/test-outputs"
#' )
#' # Expected output: TRUE or FALSE depending on the context.
#' }
#' @export
iop_check_output_dir <- function(
    input_directory,
    settings_directory,
    test_outputs_directory) {
  !any(unlist(lapply(c(
    test_outputs_directory,
    paste0(test_outputs_directory, "/"),
    substr(test_outputs_directory, 1, nchar(test_outputs_directory) - 1)
  ), function(dir) {
    any(dir == c(settings_directory, input_directory))
  })))
}
