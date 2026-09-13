# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/assign_lihtc_tracts/code")
library(data.table)
source("../../shared/code/save_data.R")

# 1. Keep the original project fields. There must be exactly one demographic row per tract/release.
projects <- fread("../input/projects.csv", na.strings = "", colClasses = c(
  hud_id = "character", zip = "character", state_project_id = "character",
  hud_tract_1990 = "character", hud_tract_2000 = "character", hud_tract_2010 = "character", hud_tract_2020 = "character",
  hud_place_1990 = "character", hud_place_2000 = "character", hud_place_2010 = "character", hud_place_2020 = "character"))
demographics <- fread("../input/tract_demographics.csv", na.strings = "", colClasses = c(tract_geoid = "character", state_fips = "character"))
stopifnot(!anyDuplicated(projects$hud_id), !anyDuplicated(demographics[, .(period_end, tract_geoid)]))
links <- rbindlist(lapply(c(1980,1990,2000,2010,2020,2024), function(year)
  fread(paste0("../output/lihtc_tracts_", year, ".csv"), na.strings = "", colClasses = c(tract_geoid = "character", hud_tract_source = "character"))))
stopifnot(!anyDuplicated(links[, .(hud_id, boundary_year)]))

# 2. Baseline is the last observation ending strictly before placed-in-service.
# Missing fields within that observation do not trigger an older or future replacement.
periods <- sort(unique(demographics$period_end))
before <- findInterval(projects$pis_year - 1L, periods)
baseline_year <- rep(NA_integer_, nrow(projects))
valid <- !is.na(before) & before > 0L
baseline_year[valid] <- periods[before[valid]]
contexts <- rbind(projects[, .(hud_id, context = "latest", period_end = 2024L)],
                  projects[, .(hud_id, context = "baseline", period_end = baseline_year)])
contexts[, boundary_year := fcase(period_end <= 2000L, period_end, period_end < 2020L, 2010L,
                                 period_end < 2022L, 2020L, period_end >= 2022L, 2024L, default = NA_integer_)]
contexts <- merge(contexts, links[, .(hud_id, boundary_year, tract_geoid, assignment_method, hud_tract_disagrees)],
                  by = c("hud_id", "boundary_year"), all.x = TRUE, sort = FALSE)
stopifnot(nrow(contexts) == 2L * nrow(projects), !anyDuplicated(contexts[, .(hud_id, context)]))
demographics[, demographic_row_present := TRUE]
contexts <- merge(contexts, demographics, by = c("period_end", "tract_geoid", "boundary_year"),
                  all.x = TRUE, sort = FALSE)
stopifnot(nrow(contexts) == 2L * nrow(projects), !anyDuplicated(contexts[, .(hud_id, context)]))
contexts[, tract_match_status := fcase(is.na(period_end), "missing_project_year",
  is.na(tract_geoid), "unassigned_tract", is.na(demographic_row_present), "tract_absent_from_release",
  default = "matched")]
contexts[, demographic_row_present := NULL]

# 3. Two explicitly named blocks of context on one row per original HUD project.
x <- copy(projects)
for (context_name in c("latest", "baseline")) {
  block <- contexts[context == context_name]
  block[, context := NULL]
  fields <- setdiff(names(block), "hud_id")
  setnames(block, fields, paste0(context_name, "_", fields))
  x <- merge(x, block, by = "hud_id", all.x = TRUE, sort = FALSE)
  stopifnot(nrow(x) == nrow(projects), !anyDuplicated(x$hud_id))
}
places <- fread("../output/lihtc_places.csv", na.strings = "", colClasses = c(place_geoid = "character"))
stopifnot(!anyDuplicated(places$hud_id))
x <- merge(x, places, by = "hud_id", all.x = TRUE, sort = FALSE)
x[, baseline_age_years := pis_year - baseline_period_end]
stopifnot(setequal(x$hud_id, projects$hud_id), nrow(x) == nrow(projects),
          all(na.omit(x$baseline_age_years) > 0L))
setorder(x, hud_id)
SaveData(x, "../output/projects_with_tracts.csv", "../report/projects_with_tracts.txt", "hud_id")
