# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/build_lihtc/code")
library(data.table)
x <- fread("../output/project_records.csv",na.strings="",colClasses=c(hud_id="character",zip="character",zip_raw="character",state_project_id="character"))
review <- x[review_needed==TRUE,.(hud_id,project_name,address_key,street,city,state,pis_year,total_units,
  keep_first,selection_status,records_at_address,resyndicated,scattered_site,construction_review,
  location_status,matched_address,hud_latitude,hud_longitude,census_latitude,census_longitude,hud_census_distance_m)]
fwrite(review,"../output/review.csv",na="")
