# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/build_lihtc/code")
library(data.table)
source("../../shared/code/save_data.R")

# 1. Keep the selected address representatives, including undated singletons.
x <- fread("../output/project_records.csv", na.strings = "", colClasses = c(
  hud_id = "character", zip = "character", zip_raw = "character",
  state_project_id = "character"
))
projects <- x[keep_first %in% TRUE, .(
  hud_id, project_name, state_project_id, street, city, state, zip,
  pis_year, allocation_year, total_units, low_income_units,
  bedrooms_0, bedrooms_1, bedrooms_2, bedrooms_3, bedrooms_4,
  credit_type, target_family, target_elderly, target_disabled,
  longitude, latitude, location_source, location_status, location_available,
  address_resolved, scattered_site, resyndicated, units_conflict, bedrooms_consistent,
  records_at_address, first_record_count, selection_status, repeat_address_review,
  construction_review, usable_location, confident_first, corroborated_first,
  exclusion_reason
)]
projects[, `:=`(source_hud_ids = hud_id, tied_characteristics_disagree = FALSE)]

# 2. For earliest-year ties, use consensus values rather than prefer one source row.
# The smallest HUD ID labels the group; all tied IDs remain available for tracing.
fields <- c(
  "project_name", "state_project_id", "allocation_year", "total_units", "low_income_units",
  "bedrooms_0", "bedrooms_1", "bedrooms_2", "bedrooms_3", "bedrooms_4", "credit_type",
  "target_family", "target_elderly", "target_disabled", "longitude", "latitude",
  "scattered_site", "resyndicated"
)
for (id in projects[first_record_count > 1L, hud_id]) {
  first <- x[first_record & representative_hud_id == id]
  row <- which(projects$hud_id == id)
  projects[row, source_hud_ids := paste(sort(first$hud_id), collapse = ";")]
  projects[row, units_conflict := any(first$units_conflict)]
  for (field in fields) {
    values <- unique(first[[field]][!is.na(first[[field]])])
    if (length(values) == 1L) set(projects, i = row, j = field, value = values[1])
    if (length(values) != 1L) set(projects, i = row, j = field, value = NA)
    if (length(values) > 1L) projects[row, tied_characteristics_disagree := TRUE]
  }
}

# 3. Blank inconsistent hedonics without dropping the project or imputing counts.
projects[, units_conflict := units_conflict |
    (!is.na(total_units) & !is.na(low_income_units) & low_income_units > total_units)]
projects[units_conflict == TRUE, low_income_units := NA_real_]
bedrooms <- c("bedrooms_0", "bedrooms_1", "bedrooms_2", "bedrooms_3", "bedrooms_4")
projects[, bedrooms_consistent := !is.na(total_units) & rowSums(is.na(.SD)) == 0 &
    rowSums(.SD) == total_units & rowSums(.SD < 0) == 0 &
    rowSums(.SD != floor(as.matrix(.SD))) == 0,
  .SDcols = bedrooms]
projects[bedrooms_consistent == FALSE, (bedrooms) := NA_real_]

stopifnot(!anyNA(projects$hud_id), !anyDuplicated(projects$hud_id))
SaveData(projects, "../output/projects.csv", "../report/projects.txt", "hud_id")
