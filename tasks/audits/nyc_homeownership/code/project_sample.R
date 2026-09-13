# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/nyc_homeownership/code")
library(data.table)
source("../../../shared/code/save_data.R")

# 1. Preserve every project inside the existing NYC place boundary.
p <- fread("../input/projects_with_tracts.csv", na.strings = "", colClasses = c(
  hud_id = "character", place_geoid = "character", baseline_tract_geoid = "character"))
x <- p[place_geoid == "3651000", .(hud_id, pis_year, total_units, longitude, latitude,
  baseline_tract_geoid, baseline_tract_match_status, baseline_period_start,
  baseline_period_end, baseline_boundary_year, baseline_age_years,
  baseline_homeowner_share, baseline_owner_occupied, baseline_occupied_units,
  baseline_housing_units)]
period <- fread("periods.csv")[specification == "main"]
stopifnot(nrow(period) == 1L, !anyDuplicated(x$hud_id))
x[, county_fips := substr(baseline_tract_geoid, 1L, 5L)]
x[, in_years := !is.na(pis_year) & pis_year >= period$first_year & pis_year <= period$last_year]
x[, era := fifelse(is.na(pis_year), NA_character_,
                   fifelse(pis_year <= period$cutoff_year, "through_2002", "after_2002"))]
x[, location_in_panel := in_years & baseline_tract_match_status == "matched" &
  county_fips %in% c("36005", "36047", "36061", "36081", "36085")]

# 2. Missing dates or characteristics affect this comparison, never the master file.
x[, sample_status := fcase(is.na(pis_year), "missing_project_year",
  pis_year %in% 2023:2024, "incomplete_HUD_cohort", !in_years, "outside_study_years",
  baseline_tract_match_status != "matched", "unmatched_prior_tract",
  !location_in_panel, "prior_tract_outside_five_counties",
  is.na(baseline_homeowner_share), "missing_prior_homeownership",
  is.na(baseline_housing_units) | baseline_housing_units <= 0, "missing_housing_exposure",
  default = "included")]
x[, analysis_included := sample_status == "included"]
stopifnot(all(na.omit(x$baseline_homeowner_share) >= 0),
          all(na.omit(x$baseline_homeowner_share) <= 1))
setorder(x, hud_id)
SaveData(x, "../output/project_sample.csv", "../report/project_sample.txt", "hud_id")
