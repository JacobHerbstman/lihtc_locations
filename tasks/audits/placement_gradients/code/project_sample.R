# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/placement_gradients/code")
library(data.table)
source("../../../shared/code/save_data.R")
cities <- fread("cities.csv", colClasses = "character")
period <- fread("periods.csv")
p <- fread("../input/projects_with_tracts.csv", na.strings = "", colClasses = c(
  hud_id = "character", place_geoid = "character", baseline_tract_geoid = "character"))
x <- p[place_geoid %in% cities$place_geoid, .(hud_id, place_geoid, pis_year, total_units,
  baseline_tract_geoid, baseline_tract_match_status, baseline_period_end, baseline_boundary_year,
  baseline_age_years, baseline_homeowner_share, baseline_nh_black_share,
  baseline_median_household_income_2024, baseline_housing_units)]
x[, city_name := cities$city_name[match(place_geoid, cities$place_geoid)]]
t <- fread("../output/city_tracts.csv", colClasses = c(place_geoid = "character", tract_geoid = "character"))
x <- merge(x, t[, .(place_geoid, baseline_tract_geoid = tract_geoid,
  baseline_boundary_year = boundary_year, city_overlap_share, interior_tract)],
  by = c("place_geoid", "baseline_boundary_year", "baseline_tract_geoid"), all.x = TRUE, sort = FALSE)
stopifnot(nrow(period) == 1L, !anyDuplicated(x$hud_id), nrow(x) == p[place_geoid %in% cities$place_geoid, .N])
x[, in_years := !is.na(pis_year) & pis_year >= period$first_year & pis_year <= period$last_year]
x[, era := fifelse(in_years, "pooled", NA_character_)]
x[, location_in_panel := in_years & baseline_tract_match_status == "matched" & !is.na(city_overlap_share)]
x[, sample_status := fcase(is.na(pis_year), "missing_project_year",
  pis_year %in% 2023:2024, "incomplete_HUD_cohort", !in_years, "outside_study_years",
  baseline_tract_match_status != "matched", "unmatched_prior_tract",
  is.na(city_overlap_share), "prior_tract_outside_city_selection",
  is.na(baseline_housing_units) | baseline_housing_units <= 0, "missing_housing_exposure",
  is.na(baseline_homeowner_share), "missing_homeowner_share",
  is.na(baseline_nh_black_share), "missing_black_share",
  is.na(baseline_median_household_income_2024) | baseline_median_household_income_2024 <= 0, "missing_income",
  default = "included")]
x[, analysis_included := sample_status == "included"]
setorder(x, place_geoid, hud_id)
SaveData(x, "../output/project_sample.csv", "../report/project_sample.txt", "hud_id")
