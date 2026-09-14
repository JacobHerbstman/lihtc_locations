# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/placement_gradients/code")
library(data.table)
library(sf)
source("../../../shared/code/save_data.R")

# 1. Retain the earlier NYC audit's five-county universe. Chicago uses city overlaps.
cities <- fread("cities.csv", colClasses = "character")
places <- st_read("../input/places_2024.gpkg", quiet = TRUE)
stopifnot(!anyDuplicated(cities$place_geoid), all(cities$place_geoid %in% places$place_geoid))
places <- places[match(cities$place_geoid, places$place_geoid), ]
out <- list()
for (year in c(1980, 1990, 2000, 2010, 2020)) {
  tracts <- st_read(paste0("../input/tracts_", year, ".gpkg"),
    query = "SELECT * FROM tracts WHERE state_fips IN ('17', '36')", quiet = TRUE)
  for (i in seq_len(nrow(cities))) {
    city <- places[i, ]
    candidates <- tracts[tracts$state_fips == city$state_fips, ]
    if (city$place_geoid == "3651000") {
      candidates <- candidates[substr(candidates$tract_geoid, 1L, 5L) %in%
        c("36005", "36047", "36061", "36081", "36085"), ]
    } else {
      candidates <- candidates[lengths(st_intersects(candidates, city)) > 0L, ]
    }
    candidates <- st_transform(candidates, 6933)
    city <- st_transform(city, 6933)
    overlap <- suppressWarnings(st_intersection(candidates[, "tract_geoid"], city[, "place_geoid"]))
    overlap$overlap_area <- as.numeric(st_area(overlap))
    z <- as.data.table(st_drop_geometry(overlap))[, .(overlap_area = sum(overlap_area)),
      by = .(place_geoid, tract_geoid)]
    z <- merge(data.table(tract_geoid = candidates$tract_geoid), z, by = "tract_geoid", all.x = TRUE)
    z[is.na(overlap_area), overlap_area := 0]
    z[, place_geoid := cities$place_geoid[[i]]]
    if (city$place_geoid != "3651000") z <- z[overlap_area > 0]
    z[, tract_area := as.numeric(st_area(candidates))[match(tract_geoid, candidates$tract_geoid)]]
    z[, `:=`(city_overlap_share = pmin(1, overlap_area / tract_area),
      boundary_year = year, city_name = cities$city_name[[i]], place_vintage = 2024L)]
    out[[length(out) + 1L]] <- z
  }
}

# 2. Keep whole-tract characteristics; the 99%-inside check excludes boundary tracts.
x <- rbindlist(out)
x[, interior_tract := city_overlap_share >= .99]
stopifnot(!anyDuplicated(x[, .(place_geoid, boundary_year, tract_geoid)]))
setorder(x, place_geoid, boundary_year, tract_geoid)
SaveData(x, "../output/city_tracts.csv", "../report/city_tracts.txt",
  c("place_geoid", "boundary_year", "tract_geoid"))
