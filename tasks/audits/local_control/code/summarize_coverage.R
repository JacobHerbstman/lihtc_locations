# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/local_control/code")
library(data.table)
source("../../../shared/code/save_data.R")
# Base CSV parsing decodes doubled quotation marks in the original legal text.
x <- as.data.table(read.csv("../output/locus_city_text.csv", na.strings = "", fileEncoding = "UTF-8",
  colClasses = c(place_geoid = "character", county = "character")))
# The source has one empty content string and no null content values.
x[is.na(content), content := ""]
cities <- fread("../input/cities.csv", colClasses = "character")
z <- x[, .(raw_chunks = .N, text_characters = sum(nchar(content)),
  median_chunk_characters = as.numeric(median(nchar(content))), max_chunk_characters = max(nchar(content)),
  source_zoning_building_chunks = sum(source_topic %chin% c("Zoning", "Buildings")),
  source_process_chunks = sum(source_function == "Process"),
  source_process_without_topic = sum(source_function == "Process" & is.na(source_topic)),
  distinct_headers = uniqueN(header)), by = place_geoid]
z <- merge(cities, z, by = "place_geoid", all.x = TRUE)
z[, city_in_public_release := !is.na(raw_chunks)]
z[city_in_public_release == FALSE, raw_chunks := 0L]
z[, legal_coverage_status := fifelse(city_in_public_release,
  "city_text_present_completeness_not_established", "no_city_text_in_public_release")]
# Text presence and source labels establish neither full code coverage nor discretion.
setorder(z, city_name)
SaveData(z, "../output/locus_city_coverage.csv", "../report/locus_city_coverage.txt", "place_geoid")
