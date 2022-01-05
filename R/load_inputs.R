#' Load a YAML test input file
#' @param input_file_path (character length 1) full file path to input file
#' @export
loadInputFile <- function(input_file_path =  system.file("extdata", "sample_input.yaml", package = "iopqualr")) {
  yaml_content <- yaml::yaml.load_file(input = input_file_path)
  yaml_content
}
