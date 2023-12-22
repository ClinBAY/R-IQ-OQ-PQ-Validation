library(testthat)
library(xtable)

context("Testing iop_print_xtable")

test_that("iop_print_xtable returns NULL for NULL input", {
  output <- iop_print_xtable(NULL, "A caption")
  expect_null(output)
})

test_that("iop_print_xtable works with HTML output", {
  # Mockup of dependent functions
  mock_iop_color_logical <- function(x) {
    return(x)
  }
  mock_iop_custom_sanitize <- function(x) {
    return(x)
  }
  mock_is_html_output <- function() {
    return(TRUE)
  }

  # Test code
  data_example <- data.frame(a = TRUE, b = FALSE)
  xtable_obj <- xtable(data_example)

  with_mock(
    `iop_color_logical` = mock_iop_color_logical,
    `iop_custom_sanitize` = mock_iop_custom_sanitize,
    `is_html_output` = mock_is_html_output,
    {
      output <- iop_print_xtable(data_example, "Test caption for HTML")
      expect_output(print(output), "html")
    }
  )
})

test_that("iop_print_xtable works with LaTeX output", {
  # Mockup of dependent functions
  mock_iop_color_logical <- function(x) {
    return(x)
  }
  mock_iop_custom_sanitize <- function(x) {
    return(x)
  }
  mock_is_html_output <- function() {
    return(FALSE)
  }

  # Test code
  data_example <- data.frame(a = TRUE, b = FALSE)
  xtable_obj <- xtable(data_example)

  with_mock(
    `iop_color_logical` = mock_iop_color_logical,
    `iop_custom_sanitize` = mock_iop_custom_sanitize,
    `is_html_output` = mock_is_html_output,
    {
      output <- iop_print_xtable(data_example, "Test caption for LaTeX")
      expect_output(print(output), "latex")
    }
  )
})

context("Testing iop_color_logical")

test_that("iop_color_logical colors logical values correctly", {
  df <- data.frame(a = c(TRUE, FALSE), b = c(1, 2), c = c(TRUE, FALSE))
  colored <- iop_color_logical(df)
  expect_equal(
    colored$a[2],
    "\\textcolor{red!100}{FALSE}"
  )
  # Non-logical values should remain unchanged
  expect_equal(colored$b, df$b)
})

test_that("iop_color_logical handles NULL input correctly", {
  expect_null(iop_color_logical(NULL))
})

test_that("iop_custom_sanitize leaves custom colored FALSE unchanged", {
  expect_equal(
    iop_custom_sanitize("\\textcolor{red!100}{FALSE}"),
    "\\textcolor{red!100}{FALSE}"
  )
})

context("Testing iop_custom_sanitize")

test_that("iop_custom_sanitize sanitizes input without custom FALSE", {
  expect_equal(
    iop_custom_sanitize("some text"),
    sanitize("some text")
  )
})

context("Testing iop_custom_add_row")

test_that("iop_custom_add_row returns the correct list", {
  result <- iop_custom_add_row()
  expected <- list(
    pos = list(0),
    command = paste0(
      "\\hline \n",
      "\\endhead \n",
      "\\hline \n",
      "{\\footnotesize Continued on next page} \n",
      "\\endfoot \n",
      "\\endlastfoot \n"
    )
  )
  expect_equal(result, expected)
})
