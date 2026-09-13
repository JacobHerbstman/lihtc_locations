# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/build_lihtc/code")
library(data.table)
source("../../shared/code/save_data.R")

# Each row retains its own prepared HUD values. No address deduplication or consensus.
x <- fread("../output/project_records.csv", na.strings = "", colClasses = c(
  hud_id = "character", zip = "character", zip_raw = "character",
  state_project_id = "character",
  income_ceiling_raw = "character", lower_income_ceiling_raw = "character",
  lower_ceiling_units_raw = "character",
  hud_tract_1990 = "character", hud_tract_2000 = "character", hud_tract_2010 = "character", hud_tract_2020 = "character", hud_place_1990 = "character", hud_place_2000 = "character", hud_place_2010 = "character", hud_place_2020 = "character"
))
projects <- x[selected == TRUE, .(
  hud_id, project_name, state_project_id, street, city, state, zip,
  pis_year, allocation_year, total_units, low_income_units,
  bedrooms_0, bedrooms_1, bedrooms_2, bedrooms_3, bedrooms_4,
  credit_type, target_family, target_elderly, target_disabled,
  longitude, latitude, scattered_site, resyndicated,
  units_conflict, bedrooms_conflict, bedrooms_consistent,
  address_key, address_resolved, records_at_address, repeated_address,
  income_ceiling_raw, income_ceiling_type, lower_income_ceiling_raw, lower_income_ceiling,
  lower_ceiling_units_raw, lower_ceiling_units, lower_ceiling_units_conflict,
  lower_ceiling_indicator_conflict, low_income_share,
  hud_tract_1990, hud_tract_2000, hud_tract_2010, hud_tract_2020,
  hud_place_1990, hud_place_2000, hud_place_2010, hud_place_2020
)]
stopifnot(!anyNA(projects$hud_id), !anyDuplicated(projects$hud_id),
          !anyNA(projects$latitude), !anyNA(projects$longitude),
          setequal(projects$hud_id, x[hud_coordinates_present == TRUE, hud_id]))
SaveData(projects, "../output/projects.csv", "../report/projects.txt", "hud_id")
