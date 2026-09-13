# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/clean_census/code")
library(data.table)
source("../../shared/code/save_data.R")

# 1. Native tract observations: three decennial snapshots and fifteen ACS releases.
historical <- fread("../output/historical_tracts.csv", na.strings = "", colClasses = c(tract_geoid = "character", state_fips = "character"))
acs <- lapply(2010:2024, function(year) fread(paste0("../output/acs_", year, ".csv"),
  na.strings = "", colClasses = c(tract_geoid = "character", state_fips = "character")))
x <- rbindlist(c(list(historical), acs), use.names = TRUE, fill = TRUE)
stopifnot(!anyDuplicated(x[, .(source, period_end, tract_geoid)]))

# 2. Use the appropriate population for each share. Conflicting counts are flagged,
# and only the affected share is blanked. Original counts and their MOEs remain.
numerators <- c("nh_white", "nh_black", "nh_asian", "nh_asian_pacific_islander", "hispanic",
                "owner_occupied", "poverty_count", "college_graduates")
denominators <- c(rep("population", 5L), "occupied_units", "poverty_universe", "population_25_plus")
shares <- c("nh_white_share", "nh_black_share", "nh_asian_share", "nh_asian_pacific_islander_share",
            "hispanic_share", "homeowner_share", "poverty_share", "college_share")
x[, share_conflict_count := 0L]
for (i in seq_along(shares)) {
  numerator <- x[[numerators[[i]]]]
  denominator <- x[[denominators[[i]]]]
  conflict <- !is.na(numerator) & !is.na(denominator) & (numerator < 0 | numerator > denominator)
  value <- numerator / denominator
  value[!is.finite(value) | denominator <= 0 | conflict] <- NA_real_
  set(x, j = shares[[i]], value = value)
  x[, share_conflict_count := share_conflict_count + as.integer(conflict)]
}
x[, vacant_units := housing_units - occupied_units]
x[, vacancy_share := fifelse(housing_units > 0 & vacant_units >= 0 & vacant_units <= housing_units,
                              vacant_units / housing_units, NA_real_)]

# 3. Convert income from its reference year and housing dollars from their own year.
# ACS five-year dollar estimates are already in the last survey year's dollars.
prices <- fread("../output/price_index.csv")
stopifnot(!anyDuplicated(prices$dollar_year))
x[, income_factor_to_2024 := prices$factor_to_2024[match(income_dollar_year, prices$dollar_year)]]
x[, housing_factor_to_2024 := prices$factor_to_2024[match(housing_dollar_year, prices$dollar_year)]]
stopifnot(!anyNA(x$income_factor_to_2024), !anyNA(x$housing_factor_to_2024))
for (field in c("median_household_income", "median_gross_rent", "median_home_value")) {
  factor <- if (field == "median_household_income") x$income_factor_to_2024 else x$housing_factor_to_2024
  set(x, j = paste0(field, "_2024"), value = x[[field]] * factor)
  set(x, j = paste0(field, "_2024_moe"), value = x[[paste0(field, "_moe")]] * factor)
}
x[, `:=`(real_dollar_year = 2024L, price_index_geography = "United States",
         price_index_series = "Census continuous historical income series, 2025 release")]

# Boundary snapshots used for lookup are recorded separately from the data release.
# Every resulting tract ID must still match the actual demographic release at the join.
x[, boundary_year := fcase(period_end <= 2000L, period_end, period_end < 2020L, 2010L,
                           period_end < 2022L, 2020L, default = 2024L)]
setorder(x, period_end, tract_geoid)
SaveData(x, "../output/tract_demographics.csv", "../report/tract_demographics.txt",
         c("source", "period_end", "tract_geoid"))
