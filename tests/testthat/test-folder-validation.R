library(testthat)

context("iop_check_output_dir")

test_that("output directory is not the same as input or settings directory", {
  expect_true(iop_check_output_dir("input/dir", "settings/dir", "output/dir"))
})

test_that("output directory is the same as input directory", {
  expect_false(iop_check_output_dir("input/dir", "settings/dir", "input/dir"))
})

test_that("output directory with slash is the same as input directory", {
  expect_false(iop_check_output_dir("input/dir", "settings/dir", "input/dir/"))
})

test_that("output directory is the same as settings directory", {
  expect_false(
    iop_check_output_dir("input/dir", "settings/dir", "settings/dir")
  )
})

test_that("output directory with slash is the same as settings directory", {
  expect_false(
    iop_check_output_dir("input/dir", "settings/dir", "settings/dir/")
  )
})

test_that("output directory is an empty string", {
  expect_true(iop_check_output_dir("input/dir", "settings/dir", ""))
})

test_that("input or settings directory is an empty string", {
  expect_true(iop_check_output_dir("", "settings/dir", "output/dir"))
  expect_true(iop_check_output_dir("input/dir", "", "output/dir"))
})
