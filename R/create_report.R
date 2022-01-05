#  Folder validator
is_output_dir_valid <- function(input_directory,
                                settings_directory,
                                test_outputs_directory) {
  !any(unlist(lapply(c(
    test_outputs_directory,
    paste0(test_outputs_directory, '/'),
    substr(test_outputs_directory, 1, nchar(test_outputs_directory) - 1)
  ), function(dir) {
    any(dir == c(settings_directory, input_directory))
  })))
}


#' Create IOP Qualification report (PDF)
#' @param settings_file Name of the settings file (*.yaml) used to generate the
#' report. [type:character]
#' @param settings_directory Full path to the directory where the settings file
#' is stored. [type:character]
#' @param input_directory Full path to the directory where Rmd file is
#' stored. [type:character]
#' @param tests_output_directory Full path to the directory where test outputs
#' should be stored (WARNING: any existing files will be deleted). [type:character]
#' @param html_report Logical flag to enable html report generation. [type:boolean]
#' @export
createReport <- function(input_directory,
                         settings_directory,
                         test_outputs_directory,
                         settings_file, html_report=FALSE) {
  # Check pdfcrop, and subsequently tinytex, is installed:

  if ((system('pdfcrop --version') != 0) & (!html_report)) {
    stop("The application `pdfcrop` couldn't not be found in your system, which
         may mean tinytex is missing or misconfigured. Please run
         iopqualr:::help_tex() to perform an automatic repair attempt.\n
         Alternatively, you can generate a HTML report by adding
         `html_report=TRUE` to the `createReport()` function.")
  }
  #
  if (!is_output_dir_valid(input_directory, settings_directory,
                           test_outputs_directory)){
    stop("The `test_outputs_directory` must point to a folder different of both
    `input_directory` and `settings_directory`. Please create an exclusive
         folder to the output.")

  }
  # Check that Rmd file and inputs file exist:
  if (!file.exists(file.path(settings_directory, settings_file))) {
    if (settings_directory == dirname(settings_file)){
      settings_file = basename(settings_file)
    } else {
      stop("Settings file cannot be found")
    }
  }
  if (!file.exists(file.path(input_directory, "report.Rmd"))) {
    stop("Base report Rmd file cannot be found")
  }
  assign(
    x = "TESTS_OUTPUT_DIRECTORY",
    value = test_outputs_directory,
    envir = globalenv()
  )
  # Creating the outputs directory for the `tools` tests, if it does not exist:
  if (!dir.exists(TESTS_OUTPUT_DIRECTORY)) {
    dir.create(TESTS_OUTPUT_DIRECTORY)
  }

  # WARNING: any files found in the TESTS_OUTPUT_DIRECTORY will be deleted
  # Delete (any) files in the tests output directory:
  list.files(TESTS_OUTPUT_DIRECTORY, full.names = TRUE) %>%
  file.remove

  assign(x = "TESTS_PATH",
         value = input_directory,
         envir = globalenv())

  assign(x = "IOPQUALR_SETTINGS",
         value = loadInputFile(file.path(settings_directory, settings_file)),
         envir = globalenv())

  output_format_selected = ifelse(html_report, "html_document", "pdf_document")
  output_file_selected = ifelse(html_report, "report.html", "report.pdf")

  rmarkdown::render(
    input = file.path(input_directory, "report.Rmd"),
    output_format = output_format_selected,
    output_dir = input_directory,
    output_file = output_file_selected,
    clean = TRUE
  )
}


#' Custom print function for xtable objects in report
printXtable <- function(x, caption, ...) {
  if (is.null(x)) return(NULL)
  x %>% colorLogical %>% xtable::xtable(caption = caption) %>%
    xtable::print.xtable(hline.after = (-1):nrow(x),
                         type = ifelse(knitr::is_html_output(), "html", "latex"),
                         sanitize.text.function = customSanitize, ...)
}


#' Color false logical values as 'red'
#' @param dat (data frame)
colorLogical <- function(dat) {
  if (is.null(dat)) return(NULL)
  dat %>% dplyr::mutate_if(is.logical,
                           . %>% {ifelse(., ., stringr::str_c(
                             "\\textcolor{red!100}{", ., "}"))} )
}


#' Sanitize function which does not sanitize custom coloring of logical values
#' @param char (character length 1) character string to "sanitize"
customSanitize <- function(char, type="latex") { char %>% {
  ifelse(stringr::str_detect(., "\\\\textcolor.*FALSE"), .,
         xtable::sanitize(., type = type) ) }
}

help_tex <-function(){
  install.packages("tinytex")
  library(tinytex)
  tinytex::tlmgr_install('pdfcrop')
}

#' Add statement to final row of multi-page table
customAddToRow <- function() {
  list(pos = list(0), command = paste0(
    "\\hline \n",
    "\\endhead \n",
    "\\hline \n",
    "{\\footnotesize Continued on next page} \n",
    "\\endfoot \n",
    "\\endlastfoot \n"
    )
  )
}
