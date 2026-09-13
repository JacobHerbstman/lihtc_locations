# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/setup_environment/code")
options(repos=c(CRAN="https://cloud.r-project.org"))
packages <- c("data.table","readxl","ggplot2","sf","jsonlite","curl","sandwich")
for (package in packages) {
  if (!requireNamespace(package,quietly=TRUE)) install.packages(package)
}
versions <- data.frame(package=packages,version=vapply(packages,function(p) as.character(packageVersion(p)),character(1)))
write.table(versions,"../output/packages.txt",sep="\t",quote=FALSE,row.names=FALSE)
