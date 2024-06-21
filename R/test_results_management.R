#' Generate all test results and return in named list
#'
#' @param settings (list) IOP qual settings
#' @export
#' @examples
#' \dontrun{
#' settings_directory <- "path/to/settings"
#' settings_file <- "settings_file_name"
#' settings <- iop_load_input_file(file.path(settings_directory, settings_file))
#' results <- iop_gen_test_results(settings)
#' }
iop_gen_test_results <- function(settings) {
  assert_that(is.list(settings))

  assert_that(
    all(c(
      "packages", "custom_operational_tests", "custom_performance_tests",
      "custom_tests_path"
    ) %in% names(settings))
  )

  assert_that(
    is.null(settings[["packages"]]) || is.list(settings[["packages"]]) ||
      is.vector(settings[["packages"]]) || is.character(settings[["packages"]])
  )

  assert_that(
    is.null(settings[["custom_operational_tests"]]) ||
      is.list(settings[["custom_operational_tests"]]) ||
      is.character(settings[["custom_operational_tests"]])
  )

  assert_that(
    is.null(settings[["custom_performance_tests"]]) ||
      is.list(settings[["custom_performance_tests"]]) ||
      is.character(settings[["custom_performance_tests"]])
  )

  assert_that(
    is.null(settings[["custom_tests_path"]]) ||
      (is.character(settings[["custom_tests_path"]]) &&
         nzchar(settings[["custom_tests_path"]]))
  )

  list(
    basic = iop_run_basic_tests(),
    base_rec = iop_test_base_recomm(),
    custom_pkgs = iop_test_custom_pkgs(
      tests_to_run = iop_get_custom_tests(settings)
    ),
    installed_pkg_versions = iop_check_all_reqs(settings[["packages"]]),
    custom_operational = if (is.null(settings[["custom_operational_tests"]])) {
      NULL
    } else {
      iop_run_custom_tests(
        packages = settings[["custom_operational_tests"]],
        type = "operational",
        tests_path = settings[["custom_tests_path"]]
      )
    },
    custom_performance = if (is.null(settings[["custom_performance_tests"]])) {
      NULL
    } else {
      iop_run_custom_tests(
        packages = settings[["custom_performance_tests"]],
        type = "performance",
        tests_path = settings[["custom_tests_path"]]
      )
    }
  )
}

#' Summarize all the test results into one table
#' @param results (list of data frames) as created by `iop_gen_test_results()`
#' @export
iop_summarise_results <- function(results = iop_gen_test_results()) {
  # Test if results is a list
  assert_that(is.list(results))

  # Test if required elements exist in the results list
  required_elements <- c(
    "basic", "base_rec", "installed_pkg_versions",
    "custom_pkgs", "custom_operational",
    "custom_performance"
  )

  assert_that(all(required_elements %in% names(results)))

  is_data_frame_or_null <- function(x) {
        is.data.frame(x) || is.null(x)
    }
  
  assert_that(all(vapply(results, is_data_frame_or_null, logical(1))))

  d <- list(
    "Basic Tests" = results[["basic"]] %>%
      rename(!!!syms(c("Scope / Package" = "scope"))) %>%
      mutate(types = NA),
    "Base and Recommended Packages" = results[["base_rec"]] %>%
      rename(!!!syms(c("Scope / Package" = "scope"))),
    "Installed Package Versions" = {
      r <- results[["installed_pkg_versions"]]
      if (is.null(r)) {
        NULL
      } else {
        select(r, !!!syms(c(
          "Scope / Package" = "requirement",
          "test_passed" = "all_passed"
        )))
      }
    },
    "Installed Packages Operational" = {
      r <- results[["custom_pkgs"]]
      if (nrow(r) == 0) {
        NULL
      } else {
        filter(r, !!!sym("types") != "tests") %>%
          rename(!!!syms(c("Scope / Package" = "pkg")))
      }
    },
    "Installed Packages Performance" = {
      r <- results[["custom_pkgs"]]
      if (nrow(r) == 0) {
        NULL
      } else {
        filter(r, !!!sym("types") == "tests") %>%
          rename(!!!syms(c("Scope / Package" = "pkg")))
      }
    },
    "Custom Package Operational" = {
      r <- results[["custom_operational"]]
      if (is.null(r)) {
        NULL
      } else {
        group_by(r, !!!syms(c("Scope / Package" = "pkg"))) %>%
          summarise(test_passed = all(!(!!!sym("failed"))))
      }
    },
    "Custom Package Performance" = {
      r <- results[["custom_performance"]]
      if (is.null(r)) {
        NULL
      } else {
        group_by(r, !!!syms(c("Scope / Package" = "pkg"))) %>%
          summarise("test_passed" = all(!(!!!syms("failed"))))
      }
    }
  ) %>%
    ldply(.id = "Test Type", .fun = identity) %>%
    mutate(across("Test Type", as.character)) %>%
    rename(!!!syms(c("All Tests Passed" = "test_passed", "Types" = "types")))

  bind_rows(
    d,
    tibble(
      "Test Type" = "OVERALL RESULT",
      "Scope / Package" = NA,
      "All Tests Passed" = all(d[["All Tests Passed"]][-1]),
      Types = NA
    )
  ) %>%
    as_tibble()
}

#' Run all tests for base and recommended packages
#' @param tests_to_run (list of lists with "scope" and "type" elements)
#' @param output_directory The file path where test results should be saved.
#'   By default the current working directory is used
#' @param ... The additional arguments that are passed on to the
#'   `tools::testInstalledPackages()` function. This allows for
#'   customizing the behavior of the test execution with extra
#'   arguments such as `filter`, `stopOnError`, and others that are
#' @export
iop_test_base_recomm <- function(
    tests_to_run = list(
      list(scope = "base", types = "examples"),
      list(scope = "base", types = "vignettes"),
      list(scope = "base", types = "tests"),
      list(scope = "recommended", types = "examples"),
      list(scope = "recommended", types = "vignettes"),
      list(scope = "recommended", types = "tests")
    ),
    output_directory = settings[["tests_output_dir"]],
    ...) {
  # Check if tests_to_run is a valid list of tests
  assert_that(is.list(tests_to_run), msg = "tests_to_run should be a list.")
  assert_that(
    all(sapply(tests_to_run, function(elem) {
      is.list(elem) && all(c("scope", "types") %in% names(elem))
    })),
    msg = "Each element of tests_to_run must be a list with \
  'scope' and 'types' elements."
  )

  assert_that(is.character(output_directory),
    msg = "output_directory should be a character string."
  )

  assert_that(dir.exists(output_directory),
    msg = "output_directory must be an existing directory."
  )

  # Check if 'scope' and 'type' are valid strings
  expected_scopes <- c("base", "recommended")
  expected_types <- c("examples", "vignettes", "tests")
  assert_that(all(sapply(tests_to_run, function(elem) {
    is.character(elem$scope) && elem$scope %in% expected_scopes
  })), msg = "Invalid 'scope' element in tests_to_run.")
  assert_that(all(sapply(tests_to_run, function(elem) {
    is.character(elem$types) && elem$types %in% expected_types
  })), msg = "Invalid 'type' element in tests_to_run.")

  # Placeholder for validating additional arguments
  # This assumes that `...` can be coerced to a list and that
  # testInstalledPackages can accept such a list
  assert_that(is.list(list(...)),
    msg = "Additional arguments should be valid for the
              testInstalledPackages function."
  )

  # The rest of the function body would go here...


  # Create data frame of input parameters:
  ldply(tests_to_run, as_tibble) %>%
    # Run test on every row of input parameter:
    adply(
      .margins = 1L,
      .fun = function(x) {
        r <- tryCatch(
          error = function(e) 1L,
          expr = testInstalledPackages(
            scope = x[["scope"]],
            types = x[["types"]],
            outDir = output_directory,
            ...
          )
        )
        tibble(test_passed = !as.logical(r))
      }
    )
}

#' Custom operation and performance tests
#' @param packages (character length >= 1)
#' @param type (character length 1) either "operational" or "performance",
#' the test "type"
#' @param tests_path (character length 1) the location of the tests
#' @export
iop_run_custom_tests <- function(packages = NULL, type = NULL,
                                 tests_path = NULL) {
  assert_that(!is.null(packages), length(packages) >= 1, is.character(packages))

  assert_that(
    !is.null(type),
    length(type) == 1,
    is.character(type),
    type %in% c("operational", "performance")
  )

  assert_that(
    !is.null(tests_path),
    length(tests_path) == 1,
    is.character(tests_path)
  )

  if (any(vapply(list(packages, type, tests_path), is.null, TRUE))) {
    return(NULL)
  }

  ldply(
    setNames(as.list(packages), packages),
    .id = "pkg",
    .fun = function(x) {
      test_dir(path = file.path(tests_path, x, type)) %>%
        as_tibble() %>%
        mutate("type" = type)
    }
  ) %>%
    as_tibble() %>%
    select(!!!sym("pkg"), !!!sym("type"), everything())
}

#' Run basic installed test
#' @param scope (character length 1) which tests to run, should be one of
#' "basic"" "devel", "both", "internet"
#' @export
iop_run_basic_tests <- function(scope = "both") {
  assert_that(scope %in% c("basic", "devel", "both", "internet"),
    msg = "Scope must be one of 'basic', 'devel', 'both', or 'internet'."
  )
  # Check that the tests have been installed.
  passed <- {
    if (!dir.exists(file.path(R.home(), "tests"))) {
      NA
    } else {
      !(testInstalledBasic(scope = scope) %>% as.logical())
    }
  }

  tibble("scope" = scope, "test_passed" = passed)
}

#' Test non-base, non-recommended packages using their included tests
#'
#' This function takes a list of non-base, non-recommended R packages and
#' runs the tests included with each package. It is used to ensure that
#' custom-installed packages are working as expected. The results of the tests
#' are output to a specified directory.
#'
#' @param tests_to_run A list of lists containing the packages to be tested
#' and the types of tests to be run. Each sublist should have elements "pkg"
#' (a character string specifying the name of the package to be tested)
#' and "types" (a character vector specifying which types of tests to run).
#' @param output_directory A character string specifying the directory where
#' test results will be saved. If not provided, defaults to the current
#' working directory
#' @param ... Additional arguments passed to `tools::testInstalledPackage`.
#'
#' @return A `data.frame` that summarizes the test results for each package.
#' Each row in the data frame will have the package name, the types of tests
#' that were run, and a logical indicator of whether the tests passed.
#' Returns `NULL` if no tests are run.
#'
#' @export
#' @examples
#' \dontrun{
#' # Assuming you have a customized list of tests in the format required:
#' tests_list <- list(
#'   list(pkg = "ggplot2", types = c("tests")),
#'   list(pkg = "dplyr", types = c("tests", "vignettes"))
#' )
#' result <- iop_test_custom_pkgs(tests_to_run = tests_list, out_dir)
#'
#' # To use the default settings for tests to run and output directory:
#' settings_directory <- "path/to/settings"
#' settings_file <- "settings_file_name"
#' output_directory <- "path/to/out/folder"
#' settings <- iop_load_input_file(
#'   file.path(settings_directory, settings_file),
#'   out_path
#' )
#' tests_list <- iop_get_custom_tests(settings)
#' result <- iop_test_custom_pkgs(
#'   tests_to_run = tests_list,
#'   output_directory = output_dir
#' )
#' }
iop_test_custom_pkgs <- function(
    tests_to_run,
    output_directory = settings[["tests_output_dir"]],
    ...) {
  # Assert that tests_to_run is a list and not empty
  assert_that(is.list(tests_to_run), length(tests_to_run) > 0)

  # Assert that every element of tests_to_run has both "pkg" and "types" parts
  assert_that(all(sapply(tests_to_run, function(x) {
    "pkg" %in% names(x) &&
      "types" %in% names(x)
  })))

  # Assert that output_directory is a non-empty character string
  assert_that(is.character(output_directory), length(output_directory) > 0)

  # Create data frame of input parameters:
  output <- ldply(tests_to_run, as_tibble) %>%
    # Run test on every row of input parameter:
    adply(
      .margins = 1L,
      .fun = function(x) {
        r <- tryCatch(error = function(e) {
          1
        }, {
          testInstalledPackage(
            pkg = x[["pkg"]], types = x[["types"]], outDir = output_directory,
            ...
          )
        })
        tibble(test_passed = !as.logical(r))
      }
    )

  if (sum(dim(output)) == 0) {
    return(NULL)
  } else {
    return(output)
  }
}
