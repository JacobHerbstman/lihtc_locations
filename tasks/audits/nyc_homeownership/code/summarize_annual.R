# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/nyc_homeownership/code")
library(data.table)
source("../../../shared/code/save_data.R")
x <- fread("../output/tract_years.csv", na.strings = "")
annual <- x[analysis_included == TRUE, .(period_end = unique(period_end),
  boundary_year = unique(boundary_year), projects = sum(new_projects), tract_years = .N,
  housing_units = sum(housing_units),
  project_mean_homeowner_pct = if (sum(new_projects) > 0) 100 * weighted.mean(homeowner_share, new_projects) else NA_real_,
  housing_weighted_homeowner_pct = 100 * weighted.mean(homeowner_share, housing_units)), by = placement_year]
annual[, location_gap_pp := project_mean_homeowner_pct - housing_weighted_homeowner_pct]
SaveData(annual, "../output/annual_summary.csv", "../report/annual_summary.txt", "placement_year")
