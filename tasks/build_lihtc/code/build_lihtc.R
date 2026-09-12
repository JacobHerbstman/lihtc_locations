# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/build_lihtc/code")
# distance_diagnostic_meters <- 500
library(data.table)
source("../../shared/code/save_data.R")
if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  stopifnot(length(args) == 1L)
  distance_diagnostic_meters <- as.numeric(args[1])
}
stopifnot(is.finite(distance_diagnostic_meters), distance_diagnostic_meters > 0)

# 1. Join archived Census responses to HUD records, one row per HUD ID.
# The archive covers all previously queried addresses; it is not refreshed here.
x <- fread("../input/projects.csv", na.strings = "", colClasses = c(
  hud_id = "character", zip = "character", zip_raw = "character",
  state_project_id = "character"
))
g <- fread("../input/geocodes.csv", na.strings = "", colClasses = "character")
stopifnot(
  !anyDuplicated(x$hud_id), !anyDuplicated(g$hud_id),
  setequal(g$hud_id, x[address_queryable == TRUE, hud_id])
)
g[, `:=`(
  census_latitude = as.numeric(census_latitude),
  census_longitude = as.numeric(census_longitude)
)]
x <- merge(x, g, by = "hud_id", all.x = TRUE, sort = FALSE)
stopifnot(nrow(x) == 29453L, !anyDuplicated(x$hud_id))

# State FIPS follows R's alphabetical state.abb order, with DC appended.
state_codes <- data.table(
  state = c(state.abb, "DC"),
  expected_state = sprintf("%02d", c(
    1, 2, 4, 5, 6, 8, 9, 10, 12, 13, 15, 16, 17, 18, 19, 20, 21,
    22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37,
    38, 39, 40, 41, 42, 44, 45, 46, 47, 48, 49, 50, 51, 53, 54, 55, 56, 11
  ))
)
stopifnot(!anyDuplicated(state_codes$state))
x <- merge(x, state_codes, by = "state", all.x = TRUE, sort = FALSE)
x[, census_match := !is.na(match_status) & match_status == "Match"]
x[, state_agrees := census_match & !is.na(census_state) & census_state == expected_state]
x[, hud_census_distance_m := NA_real_]
x[census_match & hud_coordinates_present, hud_census_distance_m := {
  a <- sin((census_latitude - hud_latitude) * pi / 360)^2 +
    cos(hud_latitude * pi / 180) * cos(census_latitude * pi / 180) *
    sin((census_longitude - hud_longitude) * pi / 360)^2
  6371008.8 * 2 * asin(sqrt(pmin(1, pmax(0, a))))
}]

# 2. Use HUD coordinates first. An exact, same-state Census match can fill a gap.
x[, `:=`(
  longitude = fifelse(hud_coordinates_present, hud_longitude, NA_real_),
  latitude = fifelse(hud_coordinates_present, hud_latitude, NA_real_),
  location_source = fifelse(hud_coordinates_present, "HUD", "missing")
)]
# Keep non-exact fallback points provisionally for diagnostics.
# location_available below rejects them from the final sample.
x[!hud_coordinates_present & state_agrees == TRUE, `:=`(
  longitude = census_longitude, latitude = census_latitude,
  location_source = "Census ACS2025"
)]
x[, location_status := fcase(
  census_match & !state_agrees, "state_disagreement",
  state_agrees & !is.na(hud_census_distance_m) &
    hud_census_distance_m > distance_diagnostic_meters, "coordinate_disagreement",
  state_agrees & hud_coordinates_present, "census_hud_agree",
  state_agrees & match_type != "Exact", "inexact_census_match",
  state_agrees & match_type == "Exact", "census_exact_no_hud_comparison",
  hud_coordinates_present, "hud_only_unconfirmed",
  default = "no_location"
)]
x[, location_checked := location_status %in%
    c("census_hud_agree", "census_exact_no_hud_comparison")]
x[scattered_site == 1 & location_checked,
  location_status := "scattered_primary_point_only"]
x[, location_checked := location_checked & (is.na(scattered_site) | scattered_site != 1)]
x[, location_available := hud_coordinates_present |
    (state_agrees & !is.na(match_type) & match_type == "Exact")]

# 3. Select the earliest placed-in-service year within each address group.
# A singleton can be undated; a repeated address needs every year to be observed.
setorder(x, address_key, pis_year, hud_id, na.last = TRUE)
x[, `:=`(
  records_at_address = .N,
  first_year = if (all(is.na(pis_year))) NA_integer_ else min(pis_year, na.rm = TRUE)
), by = address_key]
x[, address_years_complete := all(!is.na(pis_year)), by = address_key]
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
x[, repeat_address_review := records_at_address > 1L]
x[, construction_review := !is.na(resyndicated) & resyndicated == 1]
x[, address_resolved := !grepl("^UNRESOLVED:", address_key)]

# 4. Define the dated sample using location and project-scope requirements.
# Hedonics, unresolved address text, and HUD–Census distances do not decide inclusion.
x[, record_confident := !is.na(pis_year) & location_available &
    !construction_review & (is.na(scattered_site) | scattered_site != 1)]
x[, `:=`(
  first_location_checked = any(first_record) & all(location_checked[first_record]),
  first_location_available = any(first_record) & all(location_available[first_record]),
  first_census_coordinates_agree = any(first_record) &
    uniqueN(paste(census_longitude[first_record], census_latitude[first_record])) == 1L,
  first_coordinates_agree = any(first_record) &
    uniqueN(paste(longitude[first_record], latitude[first_record])) == 1L,
  first_resyndicated = any(construction_review[first_record]),
  first_scattered = any(scattered_site[first_record] == 1, na.rm = TRUE)
), by = address_key]
x[, usable_location := keep_first %in% TRUE & first_location_available &
    first_coordinates_agree & !first_resyndicated & !first_scattered]
x[, confident_first := usable_location & !is.na(pis_year)]

# This historical comparison is diagnostic; it does not choose the current sample.
x[, corroborated_first := keep_first %in% TRUE & address_resolved & !is.na(pis_year) &
    first_location_checked & first_census_coordinates_agree &
    !first_resyndicated & !first_scattered]

# 5. Assign one primary reason per excluded record, in this explicit priority order.
x[, exclusion_reason := fcase(
  is.na(keep_first), "repeated_address_missing_year",
  !keep_first, selection_status,
  is.na(pis_year), "missing_year",
  first_resyndicated, "resyndication_flag",
  first_scattered, "scattered_site",
  !first_coordinates_agree, "tied_coordinates_disagree",
  !first_location_available & location_available, "other_tied_record_location_unavailable",
  !first_location_available, location_status,
  default = "retained"
)]
x[, review_needed := exclusion_reason != "retained"]
stopifnot(nrow(x) == 29453L, !anyDuplicated(x$hud_id))
stopifnot(x[keep_first %in% TRUE, all(!duplicated(address_key))])
stopifnot(all(x$confident_first == (x$exclusion_reason == "retained")))
setorder(x, hud_id)
SaveData(x, "../output/project_records.csv", "../report/project_records.txt", "hud_id")
