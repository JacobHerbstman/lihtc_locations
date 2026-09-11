# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/geocode_lihtc/code")
# batch <- 1L
library(data.table)
if (!interactive()) {
  args <- commandArgs(trailingOnly=TRUE)
  stopifnot(length(args)==1L)
  batch <- as.integer(args[1])
}
stopifnot(batch %in% 1:3)
x <- fread("../input/projects.csv",na.strings="",colClasses=c(hud_id="character",zip="character"))
x <- x[address_queryable==TRUE]
setorder(x,hud_id)
x[, batch_number := (.I-1L)%/%10000L+1L]
stopifnot(max(x$batch_number)<=3L)
y <- x[batch_number==batch,.(hud_id,street,city,state,zip)]
stopifnot(nrow(y)>0L,nrow(y)<=10000L,!anyDuplicated(y$hud_id))
fwrite(y,paste0("../temp/request_",batch,".csv"),col.names=FALSE,na="",quote=TRUE)
