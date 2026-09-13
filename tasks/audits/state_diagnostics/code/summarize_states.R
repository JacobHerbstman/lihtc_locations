# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/state_diagnostics/code")
library(data.table)
library(readxl)
source("../../../shared/code/save_data.R")

# 1. Read the source denominator, all new-construction records, and selected locations.
hud <- as.data.table(read_excel("../input/LIHTCPUB.xlsx", sheet = "Data", col_types = "text"))
x <- fread("../input/project_records.csv", na.strings = "", colClasses = c(hud_id = "character"))
p <- fread("../input/projects.csv", na.strings = "", colClasses = c(hud_id = "character"))
stopifnot(!anyDuplicated(hud$hud_id), !anyDuplicated(x$hud_id), !anyDuplicated(p$hud_id),
          all(x$hud_id %in% hud$hud_id), setequal(p$hud_id, x[selected == TRUE, hud_id]))
hud <- hud[proj_st %in% c(state.abb, "DC")]
hud[, year := fcase(yr_pis %in% as.character(1987:2024), yr_pis,
                    yr_pis %in% as.character(2025:2027), "after_2024", default = "unknown")]
x[, year := hud$year[match(hud_id, hud$hud_id)]]
p[, year := hud$year[match(hud_id, hud$hud_id)]]

# 2. Show source coverage and the counting alternative using the same HUD-coordinate rule.
coverage <- hud[, .(hud_records = .N, type_unknown = sum(is.na(type))), by = .(state = proj_st, year)]
records <- x[, .(
  new_records = .N, new_units = sum(total_units, na.rm = TRUE),
  new_units_known = sum(!is.na(total_units)),
  hud_coordinate_records = sum(hud_coordinates_present),
  hud_coordinate_units = sum(total_units[hud_coordinates_present], na.rm = TRUE),
  hud_coordinate_units_known = sum(hud_coordinates_present & !is.na(total_units)),
  first_records = sum(keep_first %in% TRUE),
  drop_uncertain_order = sum(is.na(keep_first)),
  drop_later = sum(selection_status == "later_new_construction_at_address"),
  drop_same_year = sum(selection_status == "same_year_record_at_address"),
  drop_no_hud = sum(keep_first %in% TRUE & !hud_coordinates_present)
), by = .(state, year)]

# 3. Marginal and joint availability counts describe the master file, not extra filters.
selected <- p[, .(
  selected_records = .N, selected_units = sum(total_units, na.rm = TRUE),
  year_known = sum(!is.na(pis_year)), units_known = sum(!is.na(total_units)),
  low_income_units_known = sum(!is.na(low_income_units)),
  bedrooms_known = sum(bedrooms_consistent),
  family_known = sum(!is.na(target_family)), elderly_known = sum(!is.na(target_elderly)),
  disabled_known = sum(!is.na(target_disabled)),
  year_units_known = sum(!is.na(pis_year) & !is.na(total_units)),
  year_units_bedrooms_known = sum(!is.na(pis_year) & !is.na(total_units) & bedrooms_consistent),
  all_controls_known = sum(!is.na(pis_year) & !is.na(total_units) & bedrooms_consistent &
                          !is.na(target_family) & !is.na(target_elderly) & !is.na(target_disabled)),
  unresolved_addresses = sum(!address_resolved),
  scattered_records = sum(scattered_site == 1, na.rm = TRUE),
  resyndicated_records = sum(resyndicated == 1, na.rm = TRUE),
  tied_records = sum(first_record_count > 1L),
  tied_coordinate_disagreements = sum(tied_coordinates_disagree)
), by = .(state, year)]
stopifnot(!anyDuplicated(coverage[, .(state, year)]),
          !anyDuplicated(records[, .(state, year)]), !anyDuplicated(selected[, .(state, year)]))

# 4. Complete the 51-state grid, retaining unknown and after-release dates separately.
out <- CJ(state = c(state.abb, "DC"), year = c(as.character(1987:2024), "after_2024", "unknown"))
out <- merge(out, coverage, by = c("state", "year"), all.x = TRUE)
out <- merge(out, records, by = c("state", "year"), all.x = TRUE)
out <- merge(out, selected, by = c("state", "year"), all.x = TRUE)
for (field in setdiff(names(out), c("state", "year"))) {
  set(out, which(is.na(out[[field]])), field, 0)
}
stopifnot(nrow(out) == 51L * 40L, sum(out$new_records) == nrow(x),
          sum(out$selected_records) == nrow(p),
          all(out$new_records == out$selected_records + out$drop_uncertain_order +
              out$drop_later + out$drop_same_year + out$drop_no_hud),
          all(out$selected_records <= out$hud_coordinate_records),
          all(out$all_controls_known <= out$year_units_bedrooms_known))
SaveData(out, "../output/state_year_counts.csv", "../report/state_year_counts.txt", c("state", "year"))
