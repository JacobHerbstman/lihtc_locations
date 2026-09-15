# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/within_city_discretion/code")
library(data.table)
source("../../../shared/code/save_data.R")
cities <- fread("city_coding.csv", colClasses = c(place_geoid = "character"))
models <- fread("../input/models.csv", colClasses = c(place_geoid = "character"))
models <- models[model == "joint" & adjustment == "housing_controls"]
stopifnot(!anyDuplicated(cities$place_geoid), !anyDuplicated(models[, .(place_geoid, sample, variable)]),
  setequal(cities$place_geoid, models$place_geoid))
x <- merge(models, cities, by = c("place_geoid", "city_name"), all.x = TRUE)
stopifnot(nrow(x) == nrow(models), nrow(x) == 48, !anyNA(x$pilot_category), all(x$comparison == "pooled"))
x[, `:=`(percent_change = 100 * (natural_rate_ratio - 1),
  percent_ci_low = 100 * (natural_ci_low - 1), percent_ci_high = 100 * (natural_ci_high - 1))]
setorder(x, place_geoid, sample, variable)
# No route averaging, composite score or correlation from uneven legal coverage.
SaveData(x, "../output/city_comparison.csv", "../report/city_comparison.txt", c("place_geoid", "sample", "variable"))
