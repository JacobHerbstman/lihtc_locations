# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/local_control/code")
library(data.table)
library(readxl)
source("../../../shared/code/save_data.R")
g <- fread("../output/governments.csv", colClasses = c(government_id = "character", county_geoid = "character", place_geoid = "character", cbsa = "character"))
cities <- fread("../input/cities.csv", colClasses = "character")
stopifnot(!anyDuplicated(g$government_id), !anyDuplicated(cities$place_geoid))

# Metro population sums disjoint counties, including counties with no county government.
counties <- as.data.table(read_excel("../input/list1_2020.xls", skip = 2, col_types = "text"))
counties <- counties[grepl("^[0-9]{5}$", `CBSA Code`), .(
  cbsa = `CBSA Code`, metro_name = `CBSA Title`, county_geoid = paste0(`FIPS State Code`, `FIPS County Code`))]
counties <- counties[cbsa %chin% g[!is.na(cbsa), unique(cbsa)]]
pop <- fread("../input/co-est2021-alldata.csv", colClasses = c(STATE = "character", COUNTY = "character"))
pop <- pop[SUMLEV == 50L, .(county_geoid = paste0(STATE, COUNTY), population = POPESTIMATE2021)]
stopifnot(!anyDuplicated(counties$county_geoid), !anyDuplicated(pop$county_geoid))
counties <- merge(counties, pop, by = "county_geoid", all.x = TRUE)
stopifnot(!anyNA(counties$population), all(counties$population > 0))
totals <- counties[, .(metro_population = sum(population), metro_counties = .N), by = .(cbsa, metro_name)]

# The main count excludes functionally dormant units; preserve the Census-inclusive count too.
counts <- g[in_selected_metro == TRUE, .(
  active_county_governments = sum(government_type == "1 - COUNTY" & functionally_active == "Y"),
  active_municipal_governments = sum(government_type == "2 - MUNICIPAL" & functionally_active == "Y"),
  active_township_governments = sum(government_type == "3 - TOWNSHIP" & functionally_active == "Y"),
  general_purpose_governments = sum(functionally_active == "Y"),
  census_inclusive_governments = .N, dormant_governments = sum(functionally_active == "N")), by = cbsa]
central <- g[government_type == "2 - MUNICIPAL" & place_geoid %chin% cities$place_geoid,
  .(place_geoid, cbsa, central_city_population = source_population, population_year = source_population_year)]
stopifnot(!anyDuplicated(central$place_geoid), !anyDuplicated(central$cbsa), all(central$population_year == 2021L))
x <- merge(cities, central, by = "place_geoid", all.x = TRUE)
x <- merge(x, totals, by = "cbsa", all.x = TRUE)
x <- merge(x, counts, by = "cbsa", all.x = TRUE)
stopifnot(nrow(x) == nrow(cities), !anyNA(x), all(x$central_city_population < x$metro_population))
x[, `:=`(governments_per_100k = 100000 * general_purpose_governments / metro_population,
  central_city_population_share = central_city_population / metro_population,
  government_year = 2022L, metro_boundary_vintage = "2020-03",
  population_vintage = 2021L, metro_assignment = "Census primary county")]
setorder(x, city_name)
SaveData(x, "../output/metro_fragmentation.csv", "../report/metro_fragmentation.txt", "place_geoid")
