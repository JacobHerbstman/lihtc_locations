# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/census_diagnostics/code")
# place_geoid = "1714000"
# variable = "income"
if (!interactive()) {
  arguments <- commandArgs(trailingOnly = TRUE)
  place_geoid <- arguments[[1L]]
  variable <- arguments[[2L]]
}
library(data.table)
library(sf)
library(ggplot2)
stopifnot(variable %in% c("income", "race", "homeowners"))
cities <- fread("cities.csv", colClasses = "character")
stopifnot(place_geoid %in% cities$place_geoid)
city_id <- place_geoid
x <- fread("../output/city_tracts.csv", na.strings = "", colClasses = c(place_geoid = "character", tract_geoid = "character"))[place_geoid == city_id]
tracts <- st_read("../input/tracts_2024.gpkg", quiet = TRUE)
tracts <- tracts[match(x$tract_geoid, tracts$tract_geoid), ]
places <- st_read("../input/places_2024.gpkg", quiet = TRUE)
city <- places[places$place_geoid == city_id, ]
field <- switch(variable, income = "median_household_income_2024", race = "nh_black_share", homeowners = "homeowner_share")
tracts$value <- x[[field]]
tracts <- suppressWarnings(st_intersection(st_transform(tracts, 3857), st_transform(city, 3857)))
projects <- fread("../input/projects_with_tracts.csv", na.strings = "", colClasses = c(place_geoid = "character"))[place_geoid == city_id]
points <- st_as_sf(projects, coords = c("longitude", "latitude"), crs = 4326)
points <- st_transform(points, st_crs(tracts))
label <- switch(variable, income = "Median household income", race = "Non-Hispanic Black population", homeowners = "Owner-occupied share of occupied housing")
g <- ggplot(tracts) + geom_sf(aes(fill = value), color = "white", linewidth = .12) +
  geom_sf(data = points, shape = 21, size = 1.4, stroke = .3, fill = "#ffdf8d", color = "#151515") +
  scale_fill_viridis_c(option = "C", na.value = "#e5e5e5",
    labels = if (variable == "income") function(z) paste0("$", format(z, big.mark = ",", scientific = FALSE, trim = TRUE)) else function(z) paste0(round(100 * z), "%")) +
  labs(title = paste(cities$city_name[match(city_id, cities$place_geoid)], "·", label),
    subtitle = "2020–2024 ACS; points are HUD new-construction project records",
    fill = if (variable == "income") "2024 dollars" else "Percent",
    caption = sprintf("%s projects inside the 2024 city boundary. Gray: unavailable estimate.\nColors describe whole tracts, including tracts with no LIHTC; polygons are clipped only for display.\nThis is current neighborhood context, not neighborhood conditions when projects were built.", nrow(projects))) +
  coord_sf(datum = NA) + theme_void(base_size = 11) +
  theme(plot.title = element_text(face = "bold"), plot.caption = element_text(hjust = 0), legend.position = "right")
ggsave(paste0("../output/", city_id, "_", variable, ".png"), g, width = 9, height = 10, dpi = 150, bg = "white")
