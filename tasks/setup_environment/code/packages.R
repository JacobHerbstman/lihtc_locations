# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/setup_environment/code")

options(repos = c(CRAN = "https://cloud.r-project.org"))

cran_packages <- c(
  "arrow",
  "dplyr",
  "fixest",
  "ggplot2",
  "readr",
  "sf",
  "stringr",
  "tibble",
  "tidycensus",
  "tidyr",
  "tigris"
)

for (package in cran_packages) {
  if (!requireNamespace(package, quietly = TRUE)) {
    install.packages(package)
  }

  if (!requireNamespace(package, quietly = TRUE)) {
    stop("R package is unavailable after installation: ", package, call. = FALSE)
  }
}

package_versions <- data.frame(
  package = cran_packages,
  version = vapply(
    cran_packages,
    function(package) as.character(packageVersion(package)),
    character(1)
  )
)

write.table(
  package_versions,
  "../output/R_packages.txt",
  sep = "\t",
  row.names = FALSE,
  quote = FALSE
)
