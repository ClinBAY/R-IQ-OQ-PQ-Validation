#' Interactive Helper to Write and Save an Yaml Input File
#' @export

inputHelper <- function() {
  settings <- loadInputFile()
  test_types_default <- c('examples', 'vignettes', 'tests')
  #
  split_packages <- function(x) { unlist(strsplit(gsub("\\s*", "", x), ",")) }
  #
  cat(paste0(rep("#", 22), collapse = ""), "IOPQUALR Helper", paste0(rep("#", 22), collapse = ""))
  cat("\n\nPlease answer carefully the next questions in order to setup your `input.yaml` file.\n")
  readline("Press RETURN to Start")
  #
  cat("\n\nType the Description text that will be shown on your report: ")
  description <- readline("ANSWER: ")
  #
  cat("\nWhat name should be used as the Report's author or Company: ")
  report_author <- readline("ANSWER: ")
  #
  cat("\nWhat R version is targetted for the test?")
  r_version <-  readline("ANSWER: ")
  #
  cat("\nWhat packages you want to test?")
  cat("\nSpecify multiple packages separating their names by a comma.")
  cat("\nThe packages version will be prompted shortly.")
  packages <-  readline("ANSWER: ")
  #
  packages <- split_packages(packages)
  n_pckgs <- length(split_packages(packages))
  if (n_pckgs > 0) {
    cat("\nEnter the version for each package to be tested.")
    for (i in seq(1, n_pckgs)) {
      ver <- readline(paste0(packages[i], ": "))
      if (nchar(ver) > 0) {
        packages[i] <-
          paste0(packages[i], sub("(\\$ver)", ver, " (== $ver)"))
      }
    }
  }
  #
  cat("\nWhere is your test directory?")
  readline("Press RETURN to select the folder.")
  custom_tests_path <- choose.dir()
  #
  cat("\nWhat packages to subject to a performance test?")
  cat("\nSpecify multiple packages separating their names by a comma.")
  custom_performance_tests <- split_packages(readline("ANSWER: "))
  #
  cat("\nWhat packages to subject to a operational test?")
  cat("\nSpecify multiple packages separating their names by a comma.")
  custom_operational_tests <- split_packages(readline("ANSWER: "))
  #
  cat("\nWhat tests to perform?\nOptions are: examples, vignettes and tests")
  cat("\nSpecify multiple packages separating their names by a comma.")
  test_types <- unique(split_packages(readline("ANSWER: ")))
  if (identical(test_types, character(0))) {
    test_types <- test_types_default
  } else {
    if (!all(test_types %in% test_types_default)) {
      stop("One or more types provided are not the types allowed (examples, vignettes and tests).")
    }
  }
  #
  cat("\nThe IOPQUALR Input File has been configured.")
  cat("\nWhere do you want to save the file?")
  readline("Press RETURN to select the folder and save it.")
  save_folder <- choose.dir()
  #
  cat("\nWhat name would you want to give to the file?")
  file_name <- readline("ANSWER: ")
  #
  settings$description <- list(description)
  settings$report_author <- report_author
  settings$r_version <- r_version
  settings$packages <- packages
  settings$custom_performance_tests <- custom_performance_tests
  settings$custom_operational_tests <- custom_operational_tests
  settings$test_types <- test_types
  settings$custom_tests_path <- custom_tests_path
  #
  yaml::write_yaml(settings, paste0(save_folder, "/", file_name, ".yaml"))
  #
  cat("\nFile `", paste0(file_name, ".yaml"), "` was saved sucessfully.", sep = "")
}
