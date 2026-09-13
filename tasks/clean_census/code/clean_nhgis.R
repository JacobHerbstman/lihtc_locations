# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/clean_census/code")
library(data.table)
source("../../shared/code/save_data.R")

# 1. Extract the three national historical tables and their source codebooks.
unzip("../input/tables.zip", exdir = "../temp/nhgis")
files <- list.files("../temp/nhgis", pattern = "_tract[.]csv$", recursive = TRUE, full.names = TRUE)
stopifnot(length(files) == 3L)
historical <- vector("list", 3L)
for (i in seq_along(c(1980L, 1990L, 2000L))) {
  year <- c(1980L, 1990L, 2000L)[[i]]
  file <- files[grepl(paste0("_", year, "_tract[.]csv$"), files)]
  stopifnot(length(file) == 1L)
  raw <- fread(file, na.strings = "", colClasses = "character")
  stopifnot(all(nchar(raw$TRACTA) %in% c(4L, 6L)), !anyDuplicated(raw$GISJOIN))
  tract <- raw$TRACTA
  tract[nchar(tract) == 4L] <- paste0(tract[nchar(tract) == 4L], "00")
  x <- raw[, .(gisjoin = GISJOIN, state_fips = STATEA, tract_name = NA_character_)]
  x[, `:=`(tract_geoid = paste0(raw$STATEA, raw$COUNTYA, tract), source = "nhgis_decennial",
    period_start = year, period_end = year, geography_vintage = year,
    income_dollar_year = year - 1L, housing_dollar_year = year)]
  data_fields <- grep("^[A-Z0-9]{3}[0-9]{3}$", names(raw), value = TRUE)
  raw[, (data_fields) := lapply(.SD, as.numeric), .SDcols = data_fields]

  # 2. Source-specific definitions are visible here; sums require every component.
  if (year == 1980L) {
    x[, `:=`(population = raw$DGO001, housing_units = raw$DHP001,
      nh_white = raw$DFB001 - raw$DGD001, nh_black = raw$DFB002 - raw$DGD002,
      nh_asian = NA_real_, nh_asian_pacific_islander = NA_real_,
      hispanic = rowSums(raw[, paste0("DFN00", 2:6), with = FALSE]),
      owner_occupied = raw$DJG001, renter_occupied = raw$DJG002,
      poverty_universe = raw$DI8001 + raw$DI8002, poverty_count = raw$DI8002,
      population_25_plus = rowSums(raw[, paste0("DHM00", 1:5), with = FALSE]),
      college_graduates = raw$DHM005, median_household_income_raw = raw$DIE001,
      median_gross_rent_raw = raw$DFK001, median_home_value_raw = NA_real_,
      education_definition = "four_or_more_years_college", race_definition = "non_spanish_origin_race",
      income_suppressed = raw$SUPFLG08 == "1", rent_suppressed = raw$SUPFLG21 == "1")]
    # Suppression zeros are unavailable counts. NT97B owner count is derived from total minus renter.
    x[raw$SUPFLG08 == "1", c("owner_occupied", "renter_occupied") := NA_real_]
    x[raw$SUPFLG01 == "1", c("population_25_plus", "college_graduates", "poverty_universe", "poverty_count") := NA_real_]
  } else if (year == 1990L) {
    x[, `:=`(population = raw$E0H001, housing_units = raw$EXQ001,
      nh_white = raw$E1A001, nh_black = raw$E1A002, nh_asian = NA_real_,
      nh_asian_pacific_islander = raw$E1A004,
      hispanic = rowSums(raw[, sprintf("E1A%03d", 6:10), with = FALSE]),
      owner_occupied = raw$EZ2001, renter_occupied = raw$EZ2002,
      poverty_universe = rowSums(raw[, paste0("E1C00", 1:9), with = FALSE]),
      poverty_count = raw$E1C001 + raw$E1C002 + raw$E1C003,
      population_25_plus = rowSums(raw[, paste0("E3300", 1:7), with = FALSE]),
      college_graduates = raw$E33006 + raw$E33007,
      median_household_income_raw = raw$E4U001, median_gross_rent_raw = raw$EYU001,
      median_home_value_raw = raw$EZI001, education_definition = "bachelors_degree_or_more",
      race_definition = "non_hispanic_race_with_asian_pacific_combined", income_suppressed = FALSE, rent_suppressed = FALSE)]
  } else {
    x[, `:=`(population = rowSums(raw[, sprintf("GHJ%03d", 1:14), with = FALSE]),
      housing_units = raw$F84001, nh_white = raw$GHJ001, nh_black = raw$GHJ002,
      nh_asian = raw$GHJ004, nh_asian_pacific_islander = NA_real_,
      hispanic = rowSums(raw[, sprintf("GHJ%03d", 8:14), with = FALSE]),
      owner_occupied = raw$F9C001, renter_occupied = raw$F9C002,
      poverty_universe = raw$GN6001 + raw$GN6002, poverty_count = raw$GN6001,
      population_25_plus = rowSums(raw[, sprintf("GKT%03d", 1:32), with = FALSE]),
      college_graduates = rowSums(raw[, sprintf("GKT%03d", c(13:16,29:32)), with = FALSE]),
      median_household_income_raw = raw$GMY001, median_gross_rent_raw = raw$GBO001,
      median_home_value_raw = raw$GB7001, education_definition = "bachelors_degree_or_more",
      race_definition = "non_hispanic_race_alone", income_suppressed = FALSE, rent_suppressed = FALSE)]
  }
  x[, `:=`(occupied_units = owner_occupied + renter_occupied,
    rent_universe = "specified_renter_occupied_paying_cash_rent",
    home_value_universe = "specified_owner_occupied")]

  # 3. Keep raw medians, distinguish missing/suppressed and bounded values.
  # Historical dollar medians may be bounded; bounds are not point estimates.
  low <- switch(as.character(year), "1980" = c(2499,59,NA), "1990" = c(4999,99,14999), "2000" = c(2499,99,9999))
  high <- switch(as.character(year), "1980" = c(75001,501,NA), "1990" = c(150001,1001,500001), "2000" = c(200001,2001,1000001))
  for (j in seq_along(c("median_household_income", "median_gross_rent", "median_home_value"))) {
    field <- c("median_household_income", "median_gross_rent", "median_home_value")[[j]]
    value <- x[[paste0(field, "_raw")]]
    annotation <- rep(NA_character_, nrow(x))
    annotation[!is.na(value) & value <= 0] <- "zero_or_missing"
    annotation[!is.na(value) & !is.na(low[[j]]) & value == low[[j]]] <- "lower_bound"
    annotation[!is.na(value) & !is.na(high[[j]]) & value >= high[[j]]] <- "upper_bound"
    if (field == "median_household_income") annotation[x$income_suppressed] <- "suppressed"
    if (field == "median_gross_rent") annotation[x$rent_suppressed] <- "suppressed"
    value[!is.na(annotation)] <- NA_real_
    set(x, j = field, value = value)
    set(x, j = paste0(field, "_annotation"), value = annotation)
  }
  historical[[i]] <- x
}
x <- rbindlist(historical, use.names = TRUE, fill = TRUE)
# Territories in the extract remain in the raw file; the analytic geography is 50 states and DC.
x <- x[state_fips %in% c("01","02","04","05","06","08","09","10","11","12","13","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31","32","33","34","35","36","37","38","39","40","41","42","44","45","46","47","48","49","50","51","53","54","55","56")]
stopifnot(all(grepl("^[0-9]{11}$", x$tract_geoid)))
setorder(x, period_end, tract_geoid)
SaveData(x, "../output/historical_tracts.csv", "../report/historical_tracts.txt", c("period_end", "tract_geoid"))
