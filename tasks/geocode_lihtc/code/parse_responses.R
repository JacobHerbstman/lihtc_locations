# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/geocode_lihtc/code")
library(data.table)
source("../../shared/code/save_data.R")
x <- rbindlist(list(
  fread("../input/response_1.csv",header=FALSE,fill=TRUE,colClasses="character"),
  fread("../input/response_2.csv",header=FALSE,fill=TRUE,colClasses="character"),
  fread("../input/response_3.csv",header=FALSE,fill=TRUE,colClasses="character")
),fill=TRUE)
stopifnot(ncol(x)==12L,!anyNA(x[[1]]),!anyDuplicated(x[[1]]))
setnames(x,c("hud_id","submitted_address","match_status","match_type","matched_address","coordinates","tigerline","side","census_state","census_county","census_tract","census_block"))
projects <- fread("../input/projects.csv",na.strings="",colClasses=c(hud_id="character",zip="character"))
expected <- projects[address_queryable==TRUE,.(hud_id,street,city,state,zip)]
stopifnot(setequal(expected$hud_id,x$hud_id))
expected <- expected[match(x$hud_id,hud_id)]
for (field in c("street","city","state","zip")) set(expected,which(is.na(expected[[field]])),field,"")
# Frozen responses must still correspond to these exact public address queries.
stopifnot(identical(trimws(x$submitted_address),trimws(paste(expected$street,expected$city,expected$state,expected$zip,sep=", "))))
parts <- tstrsplit(x$coordinates,",",fixed=TRUE)
x[,`:=`(census_longitude=suppressWarnings(as.numeric(parts[[1]])),census_latitude=suppressWarnings(as.numeric(parts[[2]])))]
stopifnot(x[match_status=="Match",all(!is.na(census_longitude) & !is.na(census_latitude) & grepl("^[0-9]{2}$",census_state))])
setorder(x,hud_id)
SaveData(x,"../output/geocodes.csv","../report/geocodes.txt","hud_id")
