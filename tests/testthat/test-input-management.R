library(testthat)
library(magrittr)
library(stringr)
library(gbRd)

context("iop_load_input_file")

test_that("iop_load_input_file loads a sample YAML file", {
  input_path <- system.file("extdata", "sample_input.yaml",
    package = "iopqualr"
  )

  # Test if the function successfully loads the file without errors
  expect_silent(iop_load_input_file(input_path))

  # Test if the function returns a list (typical structure of a loaded YAML)
  result <- iop_load_input_file(input_path)
  expect_true(is.list(result))

  # If there's known content in sample_input.yaml, you can test for specific
  # values expect_equal(result$some_key, "expected_value")
})
