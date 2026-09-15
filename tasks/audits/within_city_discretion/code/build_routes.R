# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/within_city_discretion/code")
library(data.table)
source("../../../shared/code/save_data.R")
routes <- fread("route_coding.csv", colClasses = c(place_geoid = "character"), na.strings = "")
cities <- fread("city_coding.csv", colClasses = c(place_geoid = "character"))
selected <- fread("../input/cities.csv", colClasses = c(place_geoid = "character"))
evidence <- fread("../output/evidence.csv")
stopifnot(!anyDuplicated(routes$route_id), !anyDuplicated(cities$place_geoid),
  setequal(cities$place_geoid, selected$place_geoid), setequal(routes$place_geoid, cities$place_geoid),
  all(na.omit(routes$local_subjective_review) %in% 0:1),
  all(na.omit(routes$subjective_denial_code) %in% 0:1))
# Coding is a committed agent judgment. This script checks and joins it, not reclassifies law.
for (i in seq_len(nrow(routes))) {
  ids <- strsplit(routes$evidence_ids[i], ";", fixed = TRUE)[[1]]
  stopifnot(!anyDuplicated(ids), all(ids %in% evidence$evidence_id))
}
setnames(cities, c("trigger", "scope_limit"), c("city_trigger", "city_scope_limit"))
x <- merge(routes, cities, by = "place_geoid", all.x = TRUE)
stopifnot(nrow(x) == nrow(routes), !anyNA(x$city_name),
  all(is.na(x[route_id == "bos_article80", subjective_denial_code])),
  x[route_id == "la_siteplan", local_subjective_review] == 1,
  x[route_id == "la_siteplan", subjective_denial_code] == 0,
  x[route_id == "sea_affordable", local_subjective_review] == 0)
setorder(x, place_geoid, route_id)
SaveData(x, "../output/approval_routes.csv", "../report/approval_routes.txt", "route_id")
