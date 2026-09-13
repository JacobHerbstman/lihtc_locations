# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/assign_lihtc_tracts/code")
library(data.table)
library(sf)
source("../../shared/code/save_data.R")

# Official 2024 place polygons define city membership for every project nationally.
projects <- fread("../input/projects.csv", na.strings = "", colClasses = c(hud_id = "character"))
places <- st_read("../input/places_2024.gpkg", quiet = TRUE)
stopifnot(!anyDuplicated(places$place_geoid))
points <- st_as_sf(projects[, .(hud_id, longitude, latitude)], coords = c("longitude", "latitude"), crs = 4326)
matches <- st_intersects(points, places, model = "closed")
x <- projects[, .(hud_id, place_vintage = 2024L)]
x[, `:=`(place_candidates = lengths(matches), place_geoid = NA_character_, place_name = NA_character_)]
single <- which(lengths(matches) == 1L)
x[single, `:=`(place_geoid = places$place_geoid[unlist(matches[single])],
               place_name = places$place_name[unlist(matches[single])])]
x[, place_status := fcase(place_candidates == 1L, "assigned", place_candidates == 0L,
                          "outside_census_places", default = "multiple_place_matches")]
SaveData(x, "../output/lihtc_places.csv", "../report/lihtc_places.txt", "hud_id")
