# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/local_control/code")
library(data.table)
library(readxl)
source("../../../shared/code/save_data.R")

# 1. Identify each selected city's MSA from the fixed official principal-city list.
cities <- fread("../input/cities.csv", colClasses = "character")
p <- as.data.table(read_excel("../input/list2_2020.xls", skip = 2, col_types = "text"))
p <- p[grepl("^[0-9]{5}$", `CBSA Code`), .(
  place_geoid = paste0(`FIPS State Code`, `FIPS Place Code`), cbsa = `CBSA Code`,
  metro_name = `CBSA Title`, area_type = `Metropolitan/Micropolitan Statistical Area`)]
stopifnot(!anyDuplicated(p$place_geoid), !anyDuplicated(cities$place_geoid))
city_metro <- merge(cities, p, by = "place_geoid", all.x = TRUE)
stopifnot(nrow(city_metro) == nrow(cities), !anyNA(city_metro$cbsa),
  all(city_metro$area_type == "Metropolitan Statistical Area"), !anyDuplicated(city_metro$cbsa))

# 2. Read every government, preserving its Census identifier and primary county.
unzip("../input/govt_units_2022.ZIP", files = "Govt_Units_2022_Final.xlsx", exdir = "../temp")
g <- as.data.table(read_excel("../temp/Govt_Units_2022_Final.xlsx", sheet = "General Purpose"))
g <- g[, .(government_id = CENSUS_ID_PID6, government_name = UNIT_NAME,
  government_type = UNIT_TYPE, functionally_active = IS_ACTIVE,
  county_geoid = paste0(FIPS_STATE, FIPS_COUNTY),
  place_geoid = paste0(FIPS_STATE, FIPS_PLACE), source_population = POPULATION,
  source_population_year = POPULATION_YEAR)]
stopifnot(!anyNA(g$government_id), !anyDuplicated(g$government_id),
  all(g$functionally_active %chin% c("Y", "N")),
  all(g$government_type %chin% c("1 - COUNTY", "2 - MUNICIPAL", "3 - TOWNSHIP")))

# 3. Use Census's classified county, not a mailing ZIP or summed local populations.
# Cross-county governments receive one primary-county assignment; this is an inventory proxy.
counties <- as.data.table(read_excel("../input/list1_2020.xls", skip = 2, col_types = "text"))
counties <- counties[grepl("^[0-9]{5}$", `CBSA Code`), .(
  cbsa = `CBSA Code`, county_geoid = paste0(`FIPS State Code`, `FIPS County Code`))]
stopifnot(!anyDuplicated(counties$county_geoid))
counties <- counties[cbsa %chin% city_metro$cbsa]
g <- merge(g, counties, by = "county_geoid", all.x = TRUE)
g[, `:=`(in_selected_metro = !is.na(cbsa), government_year = 2022L,
  metro_boundary_vintage = "2020-03", metro_assignment = "Census primary county")]

# Each selected city's official principal-city MSA must agree with its primary county.
central <- g[government_type == "2 - MUNICIPAL" & place_geoid %chin% cities$place_geoid,
  .(place_geoid, government_cbsa = cbsa, central_city_population = source_population,
    population_year = source_population_year)]
stopifnot(nrow(central) == nrow(cities), !anyDuplicated(central$place_geoid),
  all(central$population_year == 2021L))
city_metro <- merge(city_metro, central, by = "place_geoid", all.x = TRUE)
stopifnot(all(city_metro$cbsa == city_metro$government_cbsa))

# Retain national rows so the selected-metro match coverage is inspectable.
setorder(g, government_id)
SaveData(g, "../output/governments.csv", "../report/governments.txt", "government_id")
