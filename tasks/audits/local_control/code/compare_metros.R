# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/local_control/code")
library(data.table)
source("../../../shared/code/save_data.R")
metros <- fread("../output/metro_fragmentation.csv", colClasses = c(place_geoid = "character", cbsa = "character"))
models <- fread("../input/models.csv", colClasses = c(place_geoid = "character"))
models <- models[model == "joint" & adjustment == "housing_controls"]
stopifnot(!anyDuplicated(metros$place_geoid), !anyDuplicated(metros$cbsa),
  !anyDuplicated(models[, .(place_geoid, sample, variable)]))
x <- merge(models, metros, by = c("place_geoid", "city_name"), all.x = TRUE)
stopifnot(nrow(x) == nrow(models), !anyNA(x$cbsa), all(x$comparison == "pooled"))
x[, `:=`(natural_log_rate_change = log(natural_rate_ratio),
  natural_log_ci_low = log(natural_ci_low), natural_log_ci_high = log(natural_ci_high))]
setorder(x, place_geoid, sample, variable)
SaveData(x, "../output/metro_comparison.csv", "../report/metro_comparison.txt", c("place_geoid", "sample", "variable"))
