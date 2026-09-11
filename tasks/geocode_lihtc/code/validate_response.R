# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/geocode_lihtc/code")
# batch <- 1L
library(data.table)
if (!interactive()) {
  args <- commandArgs(trailingOnly=TRUE)
  stopifnot(length(args)==1L)
  batch <- as.integer(args[1])
}
stopifnot(batch %in% 1:3)
request <- fread(paste0("../temp/request_",batch,".csv"),header=FALSE,colClasses="character")
response <- fread(paste0("../temp/response_",batch,".csv"),header=FALSE,fill=TRUE,colClasses="character")
stopifnot(ncol(response)>=3L,nrow(response)==nrow(request),!anyDuplicated(response[[1]]),setequal(request[[1]],response[[1]]),all(response[[3]] %in% c("Match","No_Match","Tie")))

expected <- fread("../../../data_raw/census_geocoder/2026-09-11/sha256.txt",header=FALSE)
stopifnot(nrow(expected)==3L,setequal(expected$V2,paste0("response_",1:3,".csv")))
actual <- strsplit(system2("shasum",c("-a","256",paste0("../temp/response_",batch,".csv")),stdout=TRUE)," +")[[1]][1]
stopifnot(expected[V2==paste0("response_",batch,".csv"),V1]==actual)
