library(testthat)
library(magrittr)
library(stringr)
library(gbRd)

context("iop_get_help_desc")

test_that("iop_get_help_desc returns help description for valid objects", {
  result <- iop_get_help_desc("lm")
  expect_true(is.character(result))
  expect_true(length(result) >= 1)
  expect_true(nchar(result) > 0)
})

test_that("iop_get_help_desc works with default argument", {
  result <- iop_get_help_desc()
  expect_true(is.character(result))
  expect_true(length(result) >= 1)
  expect_true(nchar(result) > 0)
  expect_true(grepl("invisibly", result))
})

test_that("iop_get_help_desc collapses and trims whitespace", {
  result <- iop_get_help_desc("data.frame")
  # Ensure that there are no excessive whitespace characters in the result
  expect_false(grepl("\\s{2,}", result))
  # Ensure that the result has no leading or trailing whitespace
  expect_equal(result, str_trim(result))
})

test_that("iop_get_help_desc throws an error for non-existing objects", {
  expect_error(iop_get_help_desc("non_existing_object"))
})
