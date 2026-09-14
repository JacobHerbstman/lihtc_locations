# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/placement_gradients/code")
library(data.table)
source("../../../shared/code/save_data.R")

# 1. Join demographics to native city tracts using both the boundary year and code.
t <- fread("../output/city_tracts.csv", colClasses = c(place_geoid = "character", tract_geoid = "character"))
d <- fread("../input/tract_demographics.csv", na.strings = "", colClasses = c(tract_geoid = "character"),
  select = c("tract_geoid", "source", "period_start", "period_end", "boundary_year",
    "homeowner_share", "nh_black_share", "median_household_income_2024", "housing_units"))
stopifnot(!anyDuplicated(d[, .(period_end, tract_geoid)]),
  !anyDuplicated(t[, .(boundary_year, tract_geoid)]))
d <- merge(d, t[, .(tract_geoid, boundary_year, place_geoid, city_name, city_overlap_share, interior_tract)],
  by = c("tract_geoid", "boundary_year"), all.x = TRUE, sort = FALSE)
# The earlier NYC universe includes demographic rows even when the boundary snapshot lacks a polygon.
d[substr(tract_geoid, 1L, 5L) %in% c("36005", "36047", "36061", "36081", "36085"),
  `:=`(place_geoid = "3651000", city_name = "New York City")]
d <- d[!is.na(place_geoid)]
d[is.na(interior_tract), interior_tract := FALSE]
period <- fread("periods.csv")
observations <- sort(unique(d$period_end))
x <- rbindlist(lapply(period$first_year:period$last_year, function(year) {
  prior <- max(observations[observations < year])
  z <- copy(d[period_end == prior])
  z[, placement_year := year]
  z
}))
x[, `:=`(baseline_age_years = placement_year - period_end, era = "pooled")]

# 2. Count only projects whose HUD point is inside the city. Keep zero-project tracts.
p <- fread("../output/project_sample.csv", na.strings = "", colClasses = c(
  place_geoid = "character", baseline_tract_geoid = "character"))
counts <- p[location_in_panel == TRUE, .(new_projects = .N),
  by = .(place_geoid, placement_year = pis_year, tract_geoid = baseline_tract_geoid)]
stopifnot(!anyDuplicated(x[, .(place_geoid, placement_year, tract_geoid)]),
  nrow(counts[!x, on = .(place_geoid, placement_year, tract_geoid)]) == 0L)
x <- merge(x, counts, by = c("place_geoid", "placement_year", "tract_geoid"), all.x = TRUE, sort = FALSE)
x[is.na(new_projects), new_projects := 0L]
x[, homeowner_eligible := !is.na(homeowner_share) & !is.na(housing_units) & housing_units > 0]
x[, analysis_included := homeowner_eligible & !is.na(nh_black_share) &
  !is.na(median_household_income_2024) & median_household_income_2024 > 0]
x[, log_income := log(median_household_income_2024)]
stopifnot(sum(x$new_projects) == p[location_in_panel == TRUE, .N],
  x[analysis_included == TRUE, sum(new_projects)] == p[analysis_included == TRUE, .N],
  all(x$baseline_age_years > 0), all(na.omit(x$homeowner_share) %between% c(0, 1)),
  all(na.omit(x$nh_black_share) %between% c(0, 1)))
setorder(x, place_geoid, placement_year, tract_geoid)
SaveData(x, "../output/tract_years.csv", "../report/tract_years.txt",
  c("place_geoid", "placement_year", "tract_geoid"))
