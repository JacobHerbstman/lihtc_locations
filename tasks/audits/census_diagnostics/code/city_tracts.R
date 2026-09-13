# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/census_diagnostics/code")
library(data.table)
library(sf)
source("../../../shared/code/save_data.R")

# 1. The city list is the only city-specific input. National sources are unchanged.
cities <- fread("cities.csv", colClasses = "character")
tracts <- st_read("../input/tracts_2024.gpkg", quiet = TRUE)
places <- st_read("../input/places_2024.gpkg", quiet = TRUE)
stopifnot(!anyDuplicated(cities$place_geoid), all(cities$place_geoid %in% places$place_geoid))
places <- places[match(cities$place_geoid, places$place_geoid), ]
output <- vector("list", nrow(cities))
for (i in seq_len(nrow(cities))) {
  city <- places[i, ]
  candidates <- tracts[tracts$state_fips == city$state_fips, ]
  candidates <- candidates[lengths(st_intersects(candidates, city)) > 0L, ]
  # Equal-area projection is used for areas, including when the city list expands.
  candidates <- st_transform(candidates, 6933)
  city <- st_transform(city, 6933)
  overlap <- suppressWarnings(st_intersection(candidates[, "tract_geoid"], city[, "place_geoid"]))
  overlap$overlap_area <- as.numeric(st_area(overlap))
  x <- as.data.table(st_drop_geometry(overlap))[, .(overlap_area = sum(overlap_area)), by = .(place_geoid, tract_geoid)]
  x <- x[overlap_area > 0]
  x[, tract_area := as.numeric(st_area(candidates))[match(tract_geoid, candidates$tract_geoid)]]
  x[, city_overlap_share := pmin(1, overlap_area / tract_area)]
  x[, `:=`(edge_tract = city_overlap_share < 1 - 1e-6,
           city_name = cities$city_name[[i]], place_vintage = 2024L)]
  output[[i]] <- x
}
x <- rbindlist(output)

# 2. Use whole-tract ACS characteristics; do not area-weight medians or counts.
demographics <- fread("../input/tract_lihtc_counts.csv", na.strings = "", colClasses = c(tract_geoid = "character", state_fips = "character"))
demographics <- demographics[period_end == 2024L]
stopifnot(!anyDuplicated(demographics$tract_geoid))
x <- merge(x, demographics, by = "tract_geoid", all.x = TRUE, sort = FALSE)
projects <- fread("../input/projects_with_tracts.csv", na.strings = "", colClasses = c(place_geoid = "character", latest_tract_geoid = "character"))
counts <- projects[latest_tract_match_status == "matched" & !is.na(place_geoid), .(
  city_lihtc_projects = .N, city_lihtc_projects_known_units = sum(!is.na(total_units)),
  city_lihtc_units_known = sum(total_units, na.rm = TRUE)), by = .(place_geoid, tract_geoid = latest_tract_geoid)]
x <- merge(x, counts, by = c("place_geoid", "tract_geoid"), all.x = TRUE, sort = FALSE)
for (field in c("city_lihtc_projects", "city_lihtc_projects_known_units", "city_lihtc_units_known")) x[is.na(get(field)), (field) := 0]

# Equal-sized groups of tracts, with tied income values kept in the same group.
x[, income_quintile := {
  value <- median_household_income_2024
  breaks <- quantile(value, seq(0, 1, .2), na.rm = TRUE, type = 1)
  stopifnot(!anyDuplicated(breaks))
  as.integer(cut(value, breaks, include.lowest = TRUE, labels = FALSE))
}, by = place_geoid]
setorder(x, place_geoid, tract_geoid)
SaveData(x, "../output/city_tracts.csv", "../report/city_tracts.txt", c("place_geoid", "tract_geoid"))
