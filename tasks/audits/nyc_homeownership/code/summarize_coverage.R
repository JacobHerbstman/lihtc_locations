# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/nyc_homeownership/code")
library(data.table)
source("../../../shared/code/save_data.R")
p <- fread("../output/project_sample.csv", na.strings = "")
x <- fread("../output/tract_years.csv", na.strings = "")
periods <- fread("periods.csv")
out <- list()
for (i in seq_len(nrow(periods))) {
  s <- periods[i]
  for (era_name in c("through_2002", "after_2002")) {
    a <- p[in_years == TRUE & pis_year >= s$first_year & pis_year <= s$last_year & era == era_name]
    b <- x[placement_year >= s$first_year & placement_year <= s$last_year & era == era_name]
    eligible <- b[analysis_included == TRUE]
    out[[length(out) + 1L]] <- data.table(specification = s$specification, era = era_name,
      years = uniqueN(b$placement_year), projects = nrow(a),
      projects_with_prior_tract = sum(a$location_in_panel), projects_in_analysis = sum(a$analysis_included),
      projects_missing_homeowners = sum(a$sample_status == "missing_prior_homeownership"),
      projects_known_units = a[analysis_included == TRUE, sum(!is.na(total_units))],
      units_known = a[analysis_included == TRUE, sum(total_units, na.rm = TRUE)],
      tract_years = nrow(b), tract_years_in_analysis = nrow(eligible),
      zero_project_tract_years = eligible[new_projects == 0, .N],
      housing_unit_years = sum(eligible$housing_units),
      mean_prior_age_at_projects = a[analysis_included == TRUE, mean(baseline_age_years)],
      max_prior_age_at_projects = a[analysis_included == TRUE, max(baseline_age_years)],
      project_mean_homeowner_pct = a[analysis_included == TRUE, 100 * mean(baseline_homeowner_share)],
      housing_weighted_homeowner_pct = 100 * weighted.mean(eligible$homeowner_share, eligible$housing_units),
      projects_per_10000_housing_years = 10000 * sum(eligible$new_projects) / sum(eligible$housing_units))
  }
}
coverage <- rbindlist(out)
SaveData(coverage, "../output/coverage.csv", "../report/coverage.txt", c("specification", "era"))
