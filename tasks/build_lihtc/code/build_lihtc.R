# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/build_lihtc/code")
library(data.table)
source("../../shared/code/save_data.R")

# 1. Read every prepared HUD new-construction record, preserving its own fields.
x <- fread("../input/projects.csv", na.strings = "", colClasses = c(
  hud_id = "character", zip = "character", zip_raw = "character",
  state_project_id = "character"
))
stopifnot(nrow(x) == 29453L, !anyNA(x$hud_id), !anyDuplicated(x$hud_id))

# 2. Flag shared addresses. No address grouping changes a record or its inclusion.
x[, records_at_address := .N, by = address_key]
x[, `:=`(repeated_address = records_at_address > 1L,
         address_resolved = !grepl("^UNRESOLVED:", address_key))]

# 3. The location sample requires only this HUD record's own coordinates.
# Dates, hedonics, shared addresses and scope flags do not select observations.
x[, `:=`(latitude = hud_latitude, longitude = hud_longitude,
         selected = hud_coordinates_present,
         exclusion_reason = fifelse(hud_coordinates_present, "retained", "missing_hud_coordinates"))]
stopifnot(all(x$selected == (x$exclusion_reason == "retained")))
setorder(x, hud_id)
SaveData(x, "../output/project_records.csv", "../report/project_records.txt", "hud_id")
