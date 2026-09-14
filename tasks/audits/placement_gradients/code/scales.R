# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/placement_gradients/code")
library(data.table)
source("../../../shared/code/save_data.R")
x <- fread("../output/tract_years.csv", na.strings = "", colClasses = c(place_geoid = "character"))
# A fixed, within-city scale pools both eras, equally weighting eligible tract-years.
z <- melt(x[analysis_included == TRUE], id.vars = c("place_geoid", "city_name"),
  measure.vars = c("homeowner_share", "nh_black_share", "log_income"), variable.name = "variable")
s <- z[, .(mean = mean(value), sd = sd(value), tract_years = .N), by = .(place_geoid, city_name, variable)]
s[, natural_change := fifelse(variable == "log_income", log(1.1), .1)]
s[, sd_in_percent_units := fifelse(variable == "log_income", 100 * (exp(sd) - 1), 100 * sd)]
stopifnot(all(is.finite(s$sd)), all(s$sd > 0))
setorder(s, place_geoid, variable)
SaveData(s, "../output/scales.csv", "../report/scales.txt", c("place_geoid", "variable"))
