# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/build_lihtc/code")
library(data.table)
source("../../shared/code/save_data.R")

# Each row retains its own prepared HUD values. No address deduplication or consensus.
x <- fread("../output/project_records.csv", na.strings = "", colClasses = c(
  hud_id = "character", zip = "character", zip_raw = "character",
  state_project_id = "character"
))
projects <- x[selected == TRUE, .(
  hud_id, project_name, state_project_id, street, city, state, zip,
  pis_year, allocation_year, total_units, low_income_units,
  bedrooms_0, bedrooms_1, bedrooms_2, bedrooms_3, bedrooms_4,
  credit_type, target_family, target_elderly, target_disabled,
  longitude, latitude, scattered_site, resyndicated,
  units_conflict, bedrooms_conflict, bedrooms_consistent,
  address_key, address_resolved, records_at_address, repeated_address
)]
stopifnot(!anyNA(projects$hud_id), !anyDuplicated(projects$hud_id),
          !anyNA(projects$latitude), !anyNA(projects$longitude),
          setequal(projects$hud_id, x[hud_coordinates_present == TRUE, hud_id]))
SaveData(projects, "../output/projects.csv", "../report/projects.txt", "hud_id")
