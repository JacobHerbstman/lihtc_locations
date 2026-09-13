# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/census_diagnostics/code")
# grouping = "state"
if (!interactive()) grouping <- commandArgs(trailingOnly = TRUE)[[1L]]
library(data.table)
source("../../../shared/code/save_data.R")
stopifnot(grouping %in% c("state", "cohort", "vintage"))

# Each report retains its full denominator; Census availability never selects HUD rows.
projects <- fread("../input/projects_with_tracts.csv", na.strings = "")
if (grouping == "vintage") {
  x <- fread("../input/tract_lihtc_counts.csv", na.strings = "")
  output <- x[, .(tracts = .N, states = uniqueN(state_fips),
    income_observed = sum(!is.na(median_household_income_2024)),
    rent_observed = sum(!is.na(median_gross_rent_2024)),
    home_value_observed = sum(!is.na(median_home_value_2024)),
    homeowner_share_observed = sum(!is.na(homeowner_share)),
    race_observed = sum(!is.na(nh_black_share)), college_observed = sum(!is.na(college_share)),
    income_moe_observed = sum(!is.na(median_household_income_2024_moe)),
    new_lihtc_projects = sum(new_lihtc_projects, na.rm = TRUE),
    tracts_zero_new_lihtc = sum(new_lihtc_projects == 0, na.rm = TRUE)), by = .(source, period_end)]
  output[period_end == 2024L, c("new_lihtc_projects", "tracts_zero_new_lihtc") := NA_integer_]
  keys <- c("source", "period_end")
} else {
  projects[, cohort := fifelse(is.na(pis_year), "unknown", as.character(pis_year))]
  keys <- if (grouping == "state") "state" else c("state", "cohort")
  output <- projects[, .(projects = .N, known_pis_year = sum(!is.na(pis_year)),
    latest_tract_matched = sum(latest_tract_match_status == "matched"),
    baseline_tract_matched = sum(baseline_tract_match_status == "matched"),
    latest_income_observed = sum(!is.na(latest_median_household_income_2024)),
    baseline_income_observed = sum(!is.na(baseline_median_household_income_2024)),
    latest_homeowner_observed = sum(!is.na(latest_homeowner_share)),
    baseline_homeowner_observed = sum(!is.na(baseline_homeowner_share)),
    latest_tract_absent_from_release = sum(latest_tract_match_status == "tract_absent_from_release"),
    baseline_tract_absent_from_release = sum(baseline_tract_match_status == "tract_absent_from_release")), by = keys]
}
setorderv(output, keys)
SaveData(output, paste0("../output/coverage_by_", grouping, ".csv"),
         paste0("../report/coverage_by_", grouping, ".txt"), keys)
