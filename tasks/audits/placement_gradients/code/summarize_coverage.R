# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/placement_gradients/code")
library(data.table)
source("../../../shared/code/save_data.R")
x <- fread("../output/tract_years.csv", na.strings = "", colClasses = c(place_geoid = "character"))
p <- fread("../output/project_sample.csv", na.strings = "", colClasses = c(place_geoid = "character"))
c <- x[, .(tract_years = .N, homeowner_tract_years = sum(homeowner_eligible),
  common_tract_years = sum(analysis_included),
  common_zero_project_tract_years = sum(analysis_included & new_projects == 0),
  matched_projects = sum(new_projects), homeowner_projects = sum(new_projects[homeowner_eligible]),
  common_projects = sum(new_projects[analysis_included]),
  projects_missing_homeownership = sum(new_projects[is.na(homeowner_share)]),
  projects_missing_black_share = sum(new_projects[is.na(nh_black_share)]),
  projects_missing_income = sum(new_projects[is.na(log_income)]),
  interior_common_projects = sum(new_projects[analysis_included & interior_tract]),
  housing_unit_years = sum(housing_units[analysis_included]),
  controls_tract_years = sum(controls_included),
  controls_zero_project_tract_years = sum(controls_included & new_projects == 0),
  controls_projects = sum(new_projects[controls_included]),
  controls_housing_unit_years = sum(housing_units[controls_included]),
  missing_vacancy_tract_years = sum(analysis_included & is.na(vacancy_share)),
  missing_density_tract_years = sum(analysis_included & is.na(log_housing_density)),
  controls_interior_projects = sum(new_projects[controls_included & interior_tract]),
  mean_baseline_age_at_projects = weighted.mean(baseline_age_years[analysis_included], new_projects[analysis_included])),
  by = .(place_geoid, city_name, era)]
dated <- p[in_years == TRUE, .(dated_projects = .N), by = .(place_geoid, era)]
c <- merge(c, dated, by = c("place_geoid", "era"), all.x = TRUE, sort = FALSE)
stopifnot(all(c$common_projects <= c$homeowner_projects), all(c$matched_projects <= c$dated_projects),
  all(c$controls_projects <= c$common_projects), all(c$controls_tract_years <= c$common_tract_years))
setorder(c, place_geoid, era)
SaveData(c, "../output/coverage.csv", "../report/coverage.txt", c("place_geoid", "era"))
