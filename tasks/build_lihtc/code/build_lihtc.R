# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/build_lihtc/code")
library(data.table)
source("../../shared/code/save_data.R")

# 1. Read all prepared HUD new-construction records, including missing locations.
x <- fread("../input/projects.csv", na.strings = "", colClasses = c(
  hud_id = "character", zip = "character", zip_raw = "character",
  state_project_id = "character"
))
stopifnot(nrow(x) == 29453L, !anyNA(x$hud_id), !anyDuplicated(x$hud_id))

# 2. Keep the existing first-address counting rule, before selecting coordinates.
# Repeated addresses need complete dates to establish which record came first.
# A singleton may be undated. Earliest-year ties use the smallest HUD ID.
setorder(x, address_key, pis_year, hud_id, na.last = TRUE)
x[, records_at_address := .N, by = address_key]
x[, address_years_complete := all(!is.na(pis_year)), by = address_key]
x[, first_year := if (all(is.na(pis_year))) NA_integer_ else min(pis_year, na.rm = TRUE),
  by = address_key]
x[, first_record := records_at_address == 1L |
    (address_years_complete & !is.na(pis_year) & pis_year == first_year)]
x[, representative_hud_id :=
    if (any(first_record)) min(hud_id[first_record]) else NA_character_,
  by = address_key]
x[, first_record_count := sum(first_record), by = address_key]
x[, keep_first := fifelse(is.na(representative_hud_id), NA, hud_id == representative_hud_id)]
x[, selection_status := fcase(
  records_at_address == 1L, "single_new_construction_record",
  !address_years_complete, "repeat_address_missing_year",
  !first_record, "later_new_construction_at_address",
  keep_first & first_record_count > 1L, "first_of_tied_records",
  keep_first, "earliest_at_repeated_address",
  default = "same_year_record_at_address"
)]

# 3. Use the representative's HUD coordinates. Other flags do not exclude it.
# A later geocoded record never replaces an earlier record without coordinates.
x[, `:=`(latitude = hud_latitude, longitude = hud_longitude,
         address_resolved = !grepl("^UNRESOLVED:", address_key))]
x[, tied_coordinates_disagree :=
    uniqueN(paste(hud_latitude[first_record & hud_coordinates_present],
                  hud_longitude[first_record & hud_coordinates_present])) > 1L,
  by = address_key]
x[, selected := keep_first %in% TRUE & hud_coordinates_present]
x[, exclusion_reason := fcase(
  is.na(keep_first), "repeated_address_missing_year",
  keep_first %in% FALSE, selection_status,
  !hud_coordinates_present, "missing_hud_coordinates",
  default = "retained"
)]
stopifnot(x[keep_first %in% TRUE, !anyDuplicated(address_key)],
          all(x$selected == (x$exclusion_reason == "retained")))
setorder(x, hud_id)
SaveData(x, "../output/project_records.csv", "../report/project_records.txt", "hud_id")
