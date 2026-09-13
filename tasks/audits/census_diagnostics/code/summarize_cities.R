# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/census_diagnostics/code")
library(data.table)
source("../../../shared/code/save_data.R")
x <- fread("../output/city_tracts.csv", na.strings = "", colClasses = c(place_geoid = "character", tract_geoid = "character"))

# Latest-context comparisons and an interior-tract sensitivity; no weighted medians.
x <- rbind(x[, sample := "all_intersecting_tracts"], x[edge_tract == FALSE][, sample := "interior_tracts"])
x[, income_group := fifelse(is.na(income_quintile), "missing_income", paste0("quintile_", income_quintile))]
summary <- x[, .(tracts = .N, tracts_without_lihtc = sum(city_lihtc_projects == 0),
  lihtc_projects = sum(city_lihtc_projects), projects_known_units = sum(city_lihtc_projects_known_units),
  lihtc_units_known = sum(city_lihtc_units_known), tracts_known_housing = sum(!is.na(housing_units)),
  housing_units_known = sum(housing_units, na.rm = TRUE),
  projects_in_tracts_known_housing = sum(city_lihtc_projects[!is.na(housing_units)]),
  lihtc_units_in_tracts_known_housing = sum(city_lihtc_units_known[!is.na(housing_units)])),
  by = .(place_geoid, city_name, sample, income_group)]
summary[, projects_per_1000_current_housing := fifelse(housing_units_known > 0,
  1000 * projects_in_tracts_known_housing / housing_units_known, NA_real_)]
summary[, lihtc_units_per_1000_current_housing := fifelse(housing_units_known > 0,
  1000 * lihtc_units_in_tracts_known_housing / housing_units_known, NA_real_)]
setorder(summary, place_geoid, sample, income_group)
SaveData(summary, "../output/city_income_groups.csv", "../report/city_income_groups.txt",
         c("place_geoid", "sample", "income_group"))
