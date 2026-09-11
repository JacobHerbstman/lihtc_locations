# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/build_lihtc/code")
library(data.table)
x <- fread("../output/project_records.csv",na.strings="",colClasses=c(hud_id="character",zip="character",zip_raw="character",state_project_id="character"))
projects <- x[keep_first %in% TRUE,.(hud_id,project_name,state_project_id,street,city,state,zip,
  pis_year,allocation_year,total_units,low_income_units,bedrooms_0,bedrooms_1,bedrooms_2,bedrooms_3,bedrooms_4plus,
  credit_type,target_family,target_elderly,target_disabled,longitude,latitude,location_source,
  location_status,scattered_site,resyndicated,units_conflict,bedrooms_consistent,
  records_at_address,selection_status,repeat_address_review,construction_review,usable_location)]
stopifnot(!anyNA(projects$hud_id),!anyDuplicated(projects$hud_id))
fwrite(projects,"../output/projects.csv",na="")
