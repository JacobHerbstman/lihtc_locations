# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/build_lihtc/code")
library(data.table)
x <- fread("../output/projects.csv",na.strings="",colClasses=c(hud_id="character",zip="character",state_project_id="character"))
x <- x[confident_first==TRUE]
stopifnot(!anyDuplicated(x$hud_id),!anyNA(x$pis_year),!anyNA(x$longitude),!anyNA(x$latitude))
fwrite(x,"../output/confident_projects.csv",na="")
