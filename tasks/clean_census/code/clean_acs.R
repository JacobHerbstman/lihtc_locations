# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/clean_census/code")
# year = 2024L
if (!interactive()) year <- as.integer(commandArgs(trailingOnly = TRUE)[[1L]])
library(data.table)
library(jsonlite)
source("../../shared/code/save_data.R")
stopifnot(year %in% 2010:2024)

# 1. Stack the 51 state responses without filtering on LIHTC presence.
folder <- paste0("../temp/acs5_", year)
dir.create(folder, showWarnings = FALSE)
untar(paste0("../input/acs5_", year, ".tar.gz"), exdir = folder)
files <- list.files(folder, pattern = "^state_[0-9]{2}[.]json$", full.names = TRUE)
stopifnot(length(files) == 51L)
tables <- lapply(files, function(file) {
  response <- fromJSON(file)
  x <- as.data.table(response[-1L, , drop = FALSE])
  setnames(x, response[1L, ])
  x
})
raw <- rbindlist(tables, use.names = TRUE)
x <- raw[, .(tract_geoid = paste0(state, county, tract), state_fips = state,
              tract_name = NAME, source = "acs5", period_start = year - 4L,
              period_end = year, geography_vintage = year,
              income_dollar_year = year, housing_dollar_year = year)]

# 2. Keep estimates and MOEs separate. Negative Census sentinels are not numbers.
variables <- fread("../input/acs_variables.csv")
if (year <= 2011L) {
  variables <- variables[!grepl("^B15003", census_code)]
  variables <- rbind(variables, data.table(
    variable = c("population_25_plus", "male_bachelors", "male_masters", "male_professional",
      "male_doctorate", "female_bachelors", "female_masters", "female_professional", "female_doctorate"),
    census_code = paste0("B15002_", c("001","015","016","017","018","032","033","034","035"))))
}
x[, census_sentinel_cells := 0L]
for (i in seq_len(nrow(variables))) {
  field <- variables$variable[[i]]
  code <- variables$census_code[[i]]
  for (suffix in c("E", "M")) {
    value <- suppressWarnings(as.numeric(raw[[paste0(code, suffix)]]))
    x[, census_sentinel_cells := census_sentinel_cells + as.integer(!is.na(value) & value < 0)]
    value[!is.finite(value) | value < 0] <- NA_real_
    set(x, j = paste0(field, if (suffix == "M") "_moe" else ""), value = value)
  }
  if (startsWith(field, "median_")) {
    set(x, j = paste0(field, "_raw"), value = raw[[paste0(code, "E")]])
    annotation <- raw[[paste0(code, "EA")]]
    set(x, j = paste0(field, "_annotation"), value = annotation)
    # A bound such as $250,000+ is retained in raw/annotation, not treated as an exact median.
    unusable <- !is.na(annotation) & nzchar(annotation)
    x[unusable, (field) := NA_real_]
    x[get(field) <= 0, (field) := NA_real_]
  }
}
degree_fields <- if (year <= 2011L) paste0(rep(c("male_", "female_"), each = 4L),
  rep(c("bachelors", "masters", "professional", "doctorate"), 2L)) else
  c("bachelors", "masters", "professional", "doctorate")
x[, college_graduates := rowSums(.SD), .SDcols = degree_fields]
# Census's approximation for a sum of disjoint categories; component MOEs remain available.
x[, college_graduates_moe := sqrt(rowSums(.SD^2)), .SDcols = paste0(degree_fields, "_moe")]
x[, `:=`(education_definition = "bachelors_degree_or_more", race_definition = "non_hispanic_race_alone",
         rent_universe = "renter_occupied_paying_cash_rent", home_value_universe = "owner_occupied")]

# 3. Native tract IDs and source year jointly identify observations.
stopifnot(all(grepl("^[0-9]{11}$", x$tract_geoid)), uniqueN(x$state_fips) == 51L)
setorder(x, tract_geoid)
SaveData(x, paste0("../output/acs_", year, ".csv"), paste0("../report/acs_", year, ".txt"), "tract_geoid")
