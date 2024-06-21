#' Load a YAML Test Input File
#'
#' This function reads a YAML file from the specified path and loads it into R.
#' The path provided should point to a YAML file. By default, the function looks
#' for a file named `sample_input.yaml` within the `extdata` directory of the
#' `iopqualr` package.
#'
#' @param input_file_path A string representing the full file path to the YAML
#'        input file. If not provided, the default sample input file from the
#'        package's `extdata` directory is used.
#' @param tests_output_dir A string representing the full path to the Youtput
#'        dir for tests execution
#' @return Returns a list structure containing the contents of the YAML file.
#' @export
#' @examples
#' \dontrun{
#' # Load the default sample input YAML file
#' data <- iop_load_input_file()
#'
#' # Specify a path to a custom YAML file
#' custom_path <- "/path/to/your/input.yaml"
#' data <- iop_load_input_file(custom_path, tests_output_path)
#' }
iop_load_input_file <- function(
    input_file_path =
      system.file("extdata", "sample_input.yaml", package = "iopqualr"),
    tests_output_dir = "/home/iopqualr/") {
  assert_that(is.character(input_file_path), length(input_file_path) == 1)
  input_data <- yaml.load_file(input = input_file_path)
  input_data$tests_output_dir <- tests_output_dir
  input_data
}


#' Interactive Helper to Write and Save an Yaml Input File
#'
#' This function provides an interactive session to the user for setting up
#'   a YAML input file required by the IOPQUALR package. It guides the user
#'   through a series of questions to capture necessary information, such as
#'   description, author, R version, targeted packages, and test directories.
#'   The collected data is then saved into a YAML file at a chosen location.
#'
#' @details
#' The function is interactive and requires the user to input answers to
#'  prompted questions in the console.
#'  The user is guided to provide the following information:
#'
#' - A descriptive text for the report.
#' - The name of the report's author or the responsible company.
#' - The targeted version of R for the tests.
#' - A list of packages to be tested, along with their specific versions.
#' - The path to a custom test directory.
#' - Lists of packages for performance and operational tests.
#' - A selection of test types to perform (examples, vignettes, tests).
#'
#' After gathering all the inputs, the function will ask the user for a
#' directory and file name to save the generated YAML file, which contains
#' all the configured settings.
#'
#' @return
#' Invisibly returns `NULL`. A YAML file with the collected settings is
#'  created and saved in the specified location.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Run the function to start the interactive input helper
#' iop_input_helper()
#' }
iop_input_helper <- function() {
  settings <- iop_load_input_file()
  test_types_default <- c("examples", "vignettes", "tests")

  split_packages <- function(x) {
    unlist(strsplit(gsub("\\s*", "", x), ","))
  }

  header_line <- paste0(rep("#", 22), collapse = "")
  cat(header_line, "IOPQUALR Helper", header_line, "\n\n")
  cat(
    "Hello! This package is intended for created report on a performance",
    "of an R environment (testing the installed packages: their performance,",
    "versionizing, status of installation, custom tests passings, etc.)",
    "Please answer carefully the next questions in order to setup your ",
    "`input.yaml` file.\n"
  )
  readline("Press ENTER to Start")

  cat("\n\nType the Description text that will be shown on your report: ")
  description <- readline("ANSWER: ")

  cat("\nWhat name should be used as the Report's author or Company: ")
  report_author <- readline("ANSWER: ")

  cat(
    "\nWhat R version is targeted for the test?",
    "\n(To check your current R version, enter the following command",
    "into your R console:",
    "\nR.Version()",
    "\nThis will display info about the version of R you have installed,",
    "\nincluding the version number.)\n"
  )
  cat(
    "In case multiple R versions are installed, you can find available R",
    "\nversions in RStudio:\n"
  )
  cat(
    "1. Open RStudio and go to ‘Tools’ > ‘Global Options’ > ‘R Version’.\n"
  )
  cat(
    "2. You’ll see a list of installed R versions and can select the one you",
    "wish to use.\n\n"
  )
  r_version <- readline("ANSWER: ")
  cat(
    "\nWhat packages you want to test? You can find the list of installed",
    "packages and select which ones you want to test with installed.packages()",
    "command."
  )
  cat("\nSpecify multiple packages separating their names by a comma.")
  cat("\nThe packages version will be prompted shortly.")
  packages <- readline("ANSWER: ")
  packages <- split_packages(packages)
  n_pckgs <- length(packages)
  if (n_pckgs > 0) {
    cat(
      "\nEnter the version for each package to be tested. You can check which",
      "\npackages versions are used currently with installed.packages() command"
    )
    for (i in seq_len(n_pckgs)) {
      ver <- readline(paste0(packages[i], ": "))
      if (nchar(ver) > 0) {
        packages[i] <- paste0(packages[i], " (== ", ver, ")")
      }
    }
  }

  cat("\nWhere is your custom tests directory?")
  cat("\n(This is the main folder where you organize performance and")
  cat("operational test folders for each package.)")
  readline("Press ENTER to select the folder.")

  if (.Platform$OS.type == "windows") {
    custom_tests_path <- choose.dir()
  } else {
    custom_tests_path <- tcltk::tk_choose.dir()
  }

  cat("\nWhat packages to subject to a performance test?")
  cat("\n(Performance tests measure the efficiency of the package.)")
  cat("\nSpecify multiple packages separating their names by a comma.")
  cat("\nIn case explanations here are not sufficient, refer to the 'Custom")
  cat("    Performance and Operational Tests Documentation' section for")
  cat("    detailed explanations on writing and organizing your tests.")
  performance_input <- readline("ANSWER: ")
  custom_performance_tests <- split_packages(performance_input)

  cat("\nWhat packages to subject to an operational test?")
  cat("\n(Operational tests check if the package functions as expected.)")
  cat("\nSpecify multiple packages separating their names by a comma.")
  cat("\nIn case explanations here are not sufficient, refer to the 'Custom")
  cat("    Performance and Operational Tests Documentation' section for")
  cat("    detailed explanations on writing and organizing your tests.")
  operational_input <- readline("ANSWER: ")
  custom_operational_tests <- split_packages(operational_input)

  cat(
    "\nWhat basic tests (included to the installed packages; no need to",
    "write them manually like with operational/performance tests) to perform?",
    "\nOptions are: examples, vignettes, and tests"
  )
  cat("\n(Examples: Code snippets demonstrating functionality.)")
  cat("\n(Vignettes: Detailed documents and tutorials.)")
  cat("\n(Tests: Unit tests checking the package's correctness.)")
  cat("\nSpecify multiple test types separating their names by a comma.")
  test_types <- unique(split_packages(readline("ANSWER: ")))
  if (identical(test_types, character(0))) {
    test_types <- test_types_default
  } else if (!all(test_types %in% test_types_default)) {
    stop(
      "One or more types provided are not the types allowed ",
      "(examples, vignettes, and tests)."
    )
  }

  cat("\nThe IOPQUALR Input File has been configured.")
  cat("\nWhere do you want to save the file?")
  readline("Press ENTER to select the folder and save it.")

  if (.Platform$OS.type == "windows") {
    save_folder <- choose.dir()
  } else {
    save_folder <- tcltk::tk_choose.dir()
  }

  cat("\nWhat name do you want to give to the file? Format is 'filename.yaml'")
  file_name <- readline("ANSWER: ")

  settings$description <- list(description)
  settings$report_author <- report_author
  settings$r_version <- r_version
  settings$packages <- packages
  settings$custom_performance_tests <- custom_performance_tests
  settings$custom_operational_tests <- custom_operational_tests
  settings$test_types <- test_types
  settings$custom_tests_path <- custom_tests_path
  settings$tests_output_dir <- save_folder

  write_yaml(settings, file.path(save_folder, file_name))

  cat("\nFile `", file_name, ".yaml` was saved sucessfully.", sep = "")
}
