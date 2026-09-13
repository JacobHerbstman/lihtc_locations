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

# 2. Compute first-address selection here only, as a sensitivity comparison.
# Use the earliest year before checking coordinates; ties use the smallest HUD ID.
# Repeated addresses with any missing date have unresolved ordering in this comparison.
# Each representative retains its own hedonics, so only the counting rule differs.
x[, address_years_complete := all(!is.na(pis_year)), by = address_key]
x[, first_year := if (all(is.na(pis_year))) NA_integer_ else min(pis_year, na.rm = TRUE),
  by = address_key]
x[, first_record := records_at_address == 1L |
    (address_years_complete & !is.na(pis_year) & pis_year == first_year)]
x[, first_hud_id := if (any(first_record)) min(hud_id[first_record]) else NA_character_,
  by = address_key]
x[, comparison_first := !is.na(first_hud_id) & hud_id == first_hud_id]
x[, comparison_reason := fcase(
  is.na(first_hud_id), "uncertain_order",
  !first_record, "later_record",
  !comparison_first, "same_year_tie",
  default = "first_record"
)]
stopifnot(x[comparison_first == TRUE, !anyDuplicated(address_key)])

coverage <- hud[, .(hud_records = .N, type_unknown = sum(is.na(type))), by = .(state = proj_st, year)]
records <- x[, .(
  new_records = .N, new_units = sum(total_units, na.rm = TRUE),
  new_units_known = sum(!is.na(total_units)),
  hud_coordinate_records = sum(hud_coordinates_present),
  drop_no_hud = sum(!hud_coordinates_present),
  first_address_records = sum(comparison_first & hud_coordinates_present),
  first_address_units = sum(total_units[comparison_first & hud_coordinates_present], na.rm = TRUE),
  first_address_units_known = sum(comparison_first & hud_coordinates_present & !is.na(total_units)),
  first_omitted_uncertain_order = sum(hud_coordinates_present & comparison_reason == "uncertain_order"),
  first_omitted_later = sum(hud_coordinates_present & comparison_reason == "later_record"),
  first_omitted_same_year = sum(hud_coordinates_present & comparison_reason == "same_year_tie")
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
  repeated_address_records = sum(repeated_address)
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
          all(out$new_records == out$selected_records + out$drop_no_hud),
          all(out$selected_records == out$hud_coordinate_records),
          all(out$selected_records == out$first_address_records + out$first_omitted_uncertain_order +
              out$first_omitted_later + out$first_omitted_same_year),
          all(out$all_controls_known <= out$year_units_bedrooms_known))
SaveData(out, "../output/state_year_counts.csv", "../report/state_year_counts.txt", c("state", "year"))
