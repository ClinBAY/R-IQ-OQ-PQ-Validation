#' Get help descriptions
#' @param object (character length 1) name of object for which to get help
#' description
#' @export
iop_get_help_desc <- function(object = "print") {
  assert_that(is.character(object))
  assert_that(length(object) == 1)
  assert_that(nchar(object) > 0)

  h <- help(object)
  gbRd::Rd_help2txt(h, h, keep_section = "\\description") %>%
    tail(-1L) %>%
    str_c(collapse = " ") %>%
    str_replace_all("\\s+", " ") %>%
    str_trim()
}
