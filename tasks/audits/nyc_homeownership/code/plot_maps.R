# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/nyc_homeownership/code")
library(data.table)
library(sf)
library(ggplot2)
period <- fread("periods.csv")[specification == "main"]
p <- fread("../output/project_sample.csv", na.strings = "")[in_years == TRUE]
labels <- c(paste0(period$first_year, "–", period$cutoff_year), paste0(period$cutoff_year + 1L, "–", period$last_year))
counts <- p[, .N, by = era]
p[, era := factor(era, levels = c("through_2002", "after_2002"), labels = labels)]
points <- st_as_sf(p, coords = c("longitude", "latitude"), crs = 4326)
points <- st_transform(points, 3857)
places <- st_read("../input/places_2024.gpkg", quiet = TRUE)
city <- st_transform(places[places$place_geoid == "3651000", ], 3857)
g <- ggplot() + geom_sf(data = city, fill = "#eeeeee", color = "#bbbbbb", linewidth = .15) +
  geom_sf(data = points, aes(fill = baseline_homeowner_share), shape = 21, size = 1.65, stroke = .2, color = "#333333") +
  facet_wrap(~era, nrow = 1) +
  scale_fill_viridis_c(option = "C", limits = c(0, 1), na.value = "white", labels = function(z) paste0(100 * z, "%")) +
  guides(fill = guide_colorbar(barwidth = grid::unit(7, "cm"), barheight = grid::unit(.35, "cm"))) +
  coord_sf(datum = NA) +
  labs(title = "New York placements colored by prior homeowner share",
    subtitle = paste0(counts[era == "through_2002", N], " projects through ", period$cutoff_year, "; ", counts[era == "after_2002", N], " projects afterward"),
    fill = "Homeowner share",
    caption = "Each point uses its own latest Census observation ending before placed-in-service; white points lack that estimate.\nThe gray outline shows the five boroughs. These maps show locations; the rate comparisons also include tracts with no placement.") +
  theme_void(base_size = 12) + theme(legend.position = "bottom", plot.title = element_text(face = "bold"), plot.caption = element_text(hjust = 0))
ggsave("../output/placement_maps.png", g, width = 12, height = 7.5, dpi = 170, bg = "white")
