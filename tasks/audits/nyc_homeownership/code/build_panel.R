# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/nyc_homeownership/code")
library(data.table)
source("../../../shared/code/save_data.R")

# 1. Each year's alternatives are every NYC tract in the latest prior observation.
d <- fread("../input/tract_demographics.csv", na.strings = "", colClasses = c(tract_geoid = "character"))
d <- d[substr(tract_geoid, 1L, 5L) %in% c("36005", "36047", "36061", "36081", "36085"),
  .(tract_geoid, source, period_start, period_end, boundary_year, homeowner_share,
    owner_occupied, occupied_units, housing_units)]
stopifnot(!anyDuplicated(d[, .(period_end, tract_geoid)]))
period <- fread("periods.csv")[specification == "main"]
observations <- sort(unique(d$period_end))
x <- rbindlist(lapply(period$first_year:period$last_year, function(year) {
  prior <- max(observations[observations < year])
  z <- copy(d[period_end == prior])
  z[, placement_year := year]
  z
}))
x[, `:=`(baseline_age_years = placement_year - period_end,
  county_fips = substr(tract_geoid, 1L, 5L),
  era = fifelse(placement_year <= period$cutoff_year, "through_2002", "after_2002"))]
x[, borough := c("Bronx", "Brooklyn", "Manhattan", "Queens", "Staten Island")[
  match(county_fips, c("36005", "36047", "36061", "36081", "36085"))]]

# 2. Count only the existing NYC HUD points; a missing outcome count is a zero.
p <- fread("../output/project_sample.csv", na.strings = "", colClasses = c(baseline_tract_geoid = "character"))
counts <- p[location_in_panel == TRUE, .(new_projects = .N,
  projects_known_units = sum(!is.na(total_units)), new_units_known = sum(total_units, na.rm = TRUE)),
  by = .(placement_year = pis_year, tract_geoid = baseline_tract_geoid)]
stopifnot(!anyDuplicated(x[, .(placement_year, tract_geoid)]),
          nrow(counts[!x, on = .(placement_year, tract_geoid)]) == 0L)
x <- merge(x, counts, by = c("placement_year", "tract_geoid"), all.x = TRUE, sort = FALSE)
for (field in c("new_projects", "projects_known_units", "new_units_known")) x[is.na(get(field)), (field) := 0L]
x[, analysis_included := !is.na(homeowner_share) & !is.na(housing_units) & housing_units > 0]
x[, homeowner_bin := fifelse(analysis_included, pmin(9L, as.integer(floor(10 * homeowner_share))), NA_integer_)]
stopifnot(sum(x$new_projects) == p[location_in_panel == TRUE, .N],
          x[analysis_included == TRUE, sum(new_projects)] == p[analysis_included == TRUE, .N],
          all(x$baseline_age_years > 0), !anyDuplicated(x[, .(placement_year, tract_geoid)]))
setorder(x, placement_year, tract_geoid)
SaveData(x, "../output/tract_years.csv", "../report/tract_years.txt", c("placement_year", "tract_geoid"))
