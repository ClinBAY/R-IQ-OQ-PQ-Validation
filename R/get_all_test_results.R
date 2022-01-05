#' Generate all test results and return in named list
#' @param settings (list) IOP qual settings
#' @export
generateAllTestResults <- function(settings=IOPQUALR_SETTINGS) {
  list(
    basic = runBasicInstalledTest(),
    base_rec = testBaseAndRecommendedPackages(),
    custom_pkgs = testCustomInstalledPackages(),

    installed_pkg_versions =
      checkAllPackageRequirements(settings[["packages"]]),

    custom_operational =
      if(is.null(settings[["custom_operational_tests"]]))
        {NULL}
      else {
        runCustomTests(
          packages=settings[["custom_operational_tests"]],
          type="operational",
          tests_path=settings[["custom_tests_path"]]
        )
      },

    custom_performance =
      if(is.null(settings[["custom_performance_tests"]]))
        {NULL}
      else {
        runCustomTests(
          packages=settings[["custom_performance_tests"]],
          type="performance",
          tests_path=settings[["custom_tests_path"]]
        )
      }
  )
}
