# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/assign_lihtc_tracts/code")
# year = 2024L
if (!interactive()) year <- as.integer(commandArgs(trailingOnly = TRUE)[[1L]])
library(data.table)
library(sf)
source("../../shared/code/save_data.R")
stopifnot(year %in% c(1980,1990,2000,2010,2020,2024))

# 1. Assign the same HUD coordinate to both tracts and cities. Source tract IDs
# remain comparison fields; a valid ID alone need not describe the recorded point.
projects <- fread("../input/projects.csv", na.strings = "", colClasses = "character")
tracts <- st_read(paste0("../input/tracts_", year, ".gpkg"), quiet = TRUE)
stopifnot(!anyDuplicated(projects$hud_id), !anyDuplicated(tracts$tract_geoid))
field <- paste0("hud_tract_", if (year == 2024L) 2020L else year)
source_id <- if (year == 1980L) rep(NA_character_, nrow(projects)) else projects[[field]]
x <- projects[, .(hud_id, state, boundary_year = year)]
x[, `:=`(hud_tract_source = source_id, tract_geoid = NA_character_,
          assignment_method = "unassigned", point_candidates = NA_integer_)]
x[, hud_tract_in_boundary_file := !is.na(hud_tract_source) &
    grepl("^[0-9]{11}$", hud_tract_source) & hud_tract_source %in% tracts$tract_geoid]

# 2. Point-in-polygon assigns a geography; it does not replace or verify coordinates.
# No nearest-tract substitution, source-ID fallback or arbitrary boundary tie breaking.
points <- st_as_sf(data.frame(longitude = as.numeric(projects$longitude),
  latitude = as.numeric(projects$latitude)), coords = c("longitude", "latitude"), crs = 4326)
matches <- st_intersects(points, tracts, model = "closed")
x[, point_candidates := lengths(matches)]
single <- which(lengths(matches) == 1L)
x[single, `:=`(tract_geoid = tracts$tract_geoid[unlist(matches[single])],
               assignment_method = "hud_point_in_tract")]
x[point_candidates == 0L, assignment_method := "no_polygon_match"]
x[point_candidates > 1L, assignment_method := "multiple_polygon_matches"]
x[, hud_tract_disagrees := fifelse(hud_tract_in_boundary_file & !is.na(tract_geoid),
                                  hud_tract_source != tract_geoid, NA)]
x[, assigned_state_fips := substr(tract_geoid, 1L, 2L)]
stopifnot(nrow(x) == nrow(projects), setequal(x$hud_id, projects$hud_id),
          all(na.omit(x$tract_geoid) %in% tracts$tract_geoid))
setorder(x, hud_id)
SaveData(x, paste0("../output/lihtc_tracts_", year, ".csv"),
         paste0("../report/lihtc_tracts_", year, ".txt"), "hud_id")
