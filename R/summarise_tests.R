#' Summarise all the test results into one table
#' @param test_results (list of data frames) as created by `generateAllTestResutls`
#' @export
summariseTestResults <- function(test_results=generateAllTestResults()) {
  test_results %$%
  {
    list(
      "Basic Tests" = basic %>%
        dplyr::rename("Scope / Package" = scope) %>%
        dplyr::mutate(types = NA),

      "Base and Recommended Packages" = base_rec %>%
        dplyr::rename("Scope / Package" = scope),

      "Installed Package Versions" = installed_pkg_versions %>%
        {
          if (is.null(.)) {NULL}
          else {
            test_results %$% installed_pkg_versions %>%
            dplyr::select("Scope / Package" = requirement, test_passed = all_passed)
          }
        },

      "Installed Packages Operational" = custom_pkgs %>%
        {
          if (is.null(.)) {NULL}
          else if(nrow(.) == 0) {NULL}
          else {
            test_results %$% custom_pkgs %>%
            dplyr::filter(types != "tests") %>%
            dplyr::rename("Scope / Package" = pkg)
          }
        },

      "Installed Packages Performance" = custom_pkgs %>%
        {
          if (is.null(.)) {NULL}
          else if(nrow(.) == 0) {NULL}
          else {
            test_results %$% custom_pkgs %>%
              dplyr::filter(types == "tests") %>%
              dplyr::rename("Scope / Package" = pkg)
          }
        },

      "Custom Package Operational" = custom_operational %>%
        {
          if (is.null(.)) {NULL}
          else if(nrow(.) == 0) {NULL}
          else {
            dplyr::group_by(., "Scope / Package" = pkg) %>%
            dplyr::summarise(test_passed = all(!failed))
          }
       },

      "Custom Package Performance" = custom_performance %>%
        {
          if (is.null(.)) {NULL}
          else if(nrow(.) == 0) {NULL}
          else {
            dplyr::group_by(., "Scope / Package" = pkg) %>%
            dplyr::summarise(test_passed = all(!failed))
          }
        }
    )
  } %>%
  plyr::ldply( .id = "Test Type", .fun = identity) %>%
  dplyr::mutate_at("Test Type", as.character) %>%
  dplyr::rename("All Tests Passed" = test_passed, "Types" = types) %>%
  {
    dplyr::bind_rows(
      .,
      dplyr::tibble(
        "Test Type" = "OVERALL RESULT",
        "Scope / Package" = NA,
        "All Tests Passed" = all(.[["All Tests Passed"]][-1]),
        Types = NA
      )
    )
  } %>%
  dplyr::as_tibble()
}
