# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/assign_lihtc_tracts/code")
library(data.table)
source("../../shared/code/save_data.R")

# 1. Start with every Census tract observation, including those with no LIHTC.
x <- fread("../input/tract_demographics.csv", na.strings = "", colClasses = c(tract_geoid = "character", state_fips = "character"))
projects <- fread("../output/projects_with_tracts.csv", na.strings = "", colClasses = c(
  baseline_tract_geoid = "character", latest_tract_geoid = "character"))
stopifnot(!anyDuplicated(x[, .(period_end, tract_geoid)]), !anyDuplicated(projects$hud_id))

# 2. New siting after each observation and through the next observation's end year.
# E.g. 2000 Census describes the baseline for projects placed in service in 2001–2010.
periods <- sort(unique(x$period_end))
x[, siting_window_start := pmax(1987L, period_end + 1L)]
x[, siting_window_end := c(periods[-1L], NA_integer_)[match(period_end, periods)]]
counts <- projects[baseline_tract_match_status == "matched", .(
  new_lihtc_projects = .N, new_lihtc_projects_known_units = sum(!is.na(total_units)),
  new_lihtc_units_known = sum(total_units, na.rm = TRUE)),
  by = .(period_end = baseline_period_end, tract_geoid = baseline_tract_geoid)]
x <- merge(x, counts, by = c("period_end", "tract_geoid"), all.x = TRUE, sort = FALSE)
for (field in c("new_lihtc_projects", "new_lihtc_projects_known_units", "new_lihtc_units_known")) {
  x[is.na(get(field)) & !is.na(siting_window_end), (field) := 0]
}
x[, new_lihtc_units_per_1000_housing := fifelse(housing_units > 0,
    1000 * new_lihtc_units_known / housing_units, NA_real_)]

# 3. The latest geography also provides a cross-section of every retained HUD record.
latest <- projects[latest_tract_match_status == "matched", .(
  lihtc_projects_all_years = .N, lihtc_projects_known_units = sum(!is.na(total_units)),
  lihtc_units_known = sum(total_units, na.rm = TRUE), lihtc_projects_missing_pis_year = sum(is.na(pis_year))),
  by = .(tract_geoid = latest_tract_geoid)]
latest[, period_end := 2024L]
x <- merge(x, latest, by = c("period_end", "tract_geoid"), all.x = TRUE, sort = FALSE)
for (field in c("lihtc_projects_all_years", "lihtc_projects_known_units", "lihtc_units_known", "lihtc_projects_missing_pis_year")) {
  x[period_end == 2024L & is.na(get(field)), (field) := 0]
}
stopifnot(sum(x$new_lihtc_projects, na.rm = TRUE) == projects[baseline_tract_match_status == "matched", .N],
          sum(x$lihtc_projects_all_years, na.rm = TRUE) == projects[latest_tract_match_status == "matched", .N])
setorder(x, period_end, tract_geoid)
SaveData(x, "../output/tract_lihtc_counts.csv", "../report/tract_lihtc_counts.txt", c("period_end", "tract_geoid"))
