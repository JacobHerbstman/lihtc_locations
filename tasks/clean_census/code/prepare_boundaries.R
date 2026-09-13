# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/clean_census/code")
# kind = "tracts"
# year = 2024L
if (!interactive()) {
  arguments <- commandArgs(trailingOnly = TRUE)
  kind <- arguments[[1L]]
  year <- as.integer(arguments[[2L]])
}
library(sf)
stopifnot(kind %in% c("tracts", "places"), year %in% c(1980,1990,2000,2010,2020,2024))

# 1. Read the NHGIS-delivered national shapefile, preserving its native identifiers.
folder <- paste0("../temp/", kind, "_", year)
dir.create(folder, recursive = TRUE, showWarnings = FALSE)
archive <- paste0("../input/", kind, "_", year, ".zip")
members <- unzip(archive, list = TRUE)$Name
inner <- members[grepl("[.]zip$", members)]
stopifnot(length(inner) == 1L)
unzip(archive, files = inner, exdir = folder)
inner <- normalizePath(file.path(folder, inner))
shapefile <- unzip(inner, list = TRUE)$Name
shapefile <- shapefile[grepl("[.]shp$", shapefile)]
stopifnot(length(shapefile) == 1L)
x <- st_read(paste0("/vsizip/", inner, "/", shapefile), quiet = TRUE)

# 2. NHGIS GISJOIN matches its tables. Census GEOIDs remain character identifiers.
stopifnot("GISJOIN" %in% names(x), !anyDuplicated(x$GISJOIN))
if (kind == "tracts") {
  if ("GEOID" %in% names(x)) {
    x$tract_geoid <- as.character(x$GEOID)
  } else if ("GEOID20" %in% names(x)) {
    x$tract_geoid <- as.character(x$GEOID20)
  } else if ("GEOID10" %in% names(x)) {
    x$tract_geoid <- as.character(x$GEOID10)
  } else {
    # Historical GISJOIN inserts a zero after the two-digit state and three-digit county.
    tract <- substring(x$GISJOIN, 9L)
    stopifnot(all(nchar(tract) %in% c(4L, 6L)))
    tract[nchar(tract) == 4L] <- paste0(tract[nchar(tract) == 4L], "00")
    x$tract_geoid <- paste0(substr(x$GISJOIN, 2L, 3L), substr(x$GISJOIN, 5L, 7L), tract)
  }
  x$state_fips <- substr(x$tract_geoid, 1L, 2L)
  x <- x[, c("GISJOIN", "tract_geoid", "state_fips")]
  key <- x$tract_geoid
} else {
  stopifnot("GEOID" %in% names(x), "NAME" %in% names(x))
  x$place_geoid <- as.character(x$GEOID)
  x$place_name <- x$NAME
  x$state_fips <- substr(x$place_geoid, 1L, 2L)
  x <- x[, c("GISJOIN", "place_geoid", "place_name", "state_fips")]
  key <- x$place_geoid
}
states <- c("01","02","04","05","06","08","09","10","11","12","13","15",
  "16","17","18","19","20","21","22","23","24","25","26","27","28","29",
  "30","31","32","33","34","35","36","37","38","39","40","41","42","44",
  "45","46","47","48","49","50","51","53","54","55","56")
x <- x[x$state_fips %in% states, ]
stopifnot(!anyNA(key), !anyDuplicated(key))
x$geography_vintage <- year
x <- st_transform(x, 4326)
invalid <- !st_is_valid(x)
x[invalid, ] <- st_make_valid(x[invalid, ])
x <- x[order(x$GISJOIN), ]

# 3. One native geography per file. No crosswalk or population interpolation.
destination <- paste0("../output/", kind, "_", year, ".gpkg")
st_write(x, destination, layer = kind, delete_dsn = TRUE, quiet = TRUE)
writeLines(c(paste("Features:", nrow(x)), "CRS: EPSG 4326",
  "Key: native Census GEOID, complete and unique", paste("Repaired invalid geometries:", sum(invalid)),
  paste("Source ZIP MD5:", tools::md5sum(archive))), paste0("../report/", kind, "_", year, ".txt"))
