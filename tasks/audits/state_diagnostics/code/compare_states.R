# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/state_diagnostics/code")
library(data.table)
source("../../../shared/code/save_data.R")
x <- fread("../output/state_year_counts.csv")
stopifnot(!anyDuplicated(x[, .(state, year)]))

# 1. Aggregate counts before forming percentages; never average state-year rates.
counts <- setdiff(names(x), c("state", "year"))
s <- x[, lapply(.SD, sum), by = state, .SDcols = counts]
s[, state_name := c(state.name, "District of Columbia")[match(state, c(state.abb, "DC"))]]
s[, `:=`(
  type_missing_pct = 100 * type_unknown / hud_records,
  coordinates_missing_pct = 100 * (new_records - hud_coordinate_records) / new_records,
  first_address_reduction_pct = 100 * (hud_coordinate_records - selected_records) / hud_coordinate_records,
  year_missing_pct = 100 * (selected_records - year_known) / selected_records,
  units_missing_pct = 100 * (selected_records - units_known) / selected_records,
  bedrooms_missing_pct = 100 * (selected_records - bedrooms_known) / selected_records,
  all_controls_missing_pct = 100 * (selected_records - all_controls_known) / selected_records
)]

# 2. Separate losses related to cohort composition from extra state differences.
# These are diagnostics, not weights or corrections for selection bias.
national <- x[, .(new_records = sum(new_records), located = sum(hud_coordinate_records),
                  selected = sum(selected_records), controls = sum(all_controls_known)), by = year]
national[, `:=`(location_rate = fifelse(new_records > 0, located / new_records, 0),
               controls_rate = fifelse(selected > 0, controls / selected, 0))]
stopifnot(!anyDuplicated(national$year))
x[national, on = "year", `:=`(expected_locations = new_records * i.location_rate,
                             expected_controls = selected_records * i.controls_rate)]
expected <- x[, .(expected_locations = sum(expected_locations),
                  expected_controls = sum(expected_controls)), by = state]
stopifnot(!anyDuplicated(expected$state))
s <- merge(s, expected, by = "state", all.x = TRUE)
s[, `:=`(excess_coordinate_loss_pp = 100 * (expected_locations - hud_coordinate_records) / new_records,
         excess_controls_loss_pp = 100 * (expected_controls - all_controls_known) / selected_records)]
stopifnot(nrow(s) == 51L, !anyDuplicated(s$state))
SaveData(s[order(state)], "../output/state_summary.csv", "../report/state_summary.txt", "state")
