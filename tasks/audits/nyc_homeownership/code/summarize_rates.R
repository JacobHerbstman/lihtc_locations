# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/nyc_homeownership/code")
library(data.table)
source("../../../shared/code/save_data.R")
x <- fread("../output/tract_years.csv", na.strings = "", colClasses = c(tract_geoid = "character"))
periods <- fread("periods.csv")
out <- list()
for (i in seq_len(nrow(periods))) {
  s <- periods[i]
  z <- x[analysis_included == TRUE & placement_year >= s$first_year & placement_year <= s$last_year]
  rates <- z[, .(tract_years = .N, tract_codes = uniqueN(tract_geoid),
    zero_project_tract_years = sum(new_projects == 0), housing_unit_years = sum(housing_units),
    projects = sum(new_projects), projects_known_units = sum(projects_known_units),
    units_known = sum(new_units_known)), by = .(era, homeowner_bin)]
  rates[, `:=`(specification = s$specification, bin_lower_pct = 10 * homeowner_bin,
    bin_upper_pct = 10 * (homeowner_bin + 1L),
    projects_per_10000_housing_years = 10000 * projects / housing_unit_years,
    known_units_per_10000_housing_years = 10000 * units_known / housing_unit_years)]
  out[[i]] <- rates
}
rates <- rbindlist(out)
setorder(rates, specification, era, homeowner_bin)
SaveData(rates, "../output/binned_rates.csv", "../report/binned_rates.txt", c("specification", "era", "homeowner_bin"))
