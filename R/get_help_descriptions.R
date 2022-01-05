#' Get help descriptions
#' @param object (character length 1) name of object for which to get help description
#' @export
getHelpDescription <- function(object="print") {
  help(object) %>%
  gbRd::Rd_help2txt(., ., keep_section = "\\description") %>%
  tail(-1L) %>%
  stringr::str_c(collapse = " ") %>%
  stringr::str_replace_all("\\s+", " ") %>%
  stringr::str_trim(.)
}
