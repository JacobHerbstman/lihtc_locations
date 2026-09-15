# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/local_control/code")
library(data.table)
source("../../../shared/code/save_data.R")
x <- fread("../output/metro_comparison.csv", colClasses = c(place_geoid = "character", cbsa = "character"))
out <- list()
for (s in c("all_city_tracts", "interior_tracts")) {
  for (v in c("homeowner_share", "nh_black_share", "log_income")) {
    z <- x[sample == s & variable == v]
    stopifnot(!anyDuplicated(z$place_geoid), !anyDuplicated(z$cbsa))
    for (measure in c("general_purpose_governments", "governments_per_100k", "central_city_population_share")) {
      for (omit in c("none", z$city_name)) {
        d <- if (omit == "none") z else z[city_name != omit]
        stopifnot(!anyNA(d[[measure]]), !anyNA(d$natural_log_rate_change))
        out[[length(out) + 1L]] <- data.table(sample = s, variable = v, measure, omitted_city = omit,
          n_cities = nrow(d), pearson = cor(d[[measure]], d$natural_log_rate_change),
          spearman = cor(d[[measure]], d$natural_log_rate_change, method = "spearman"))
      }
    }
  }
}
r <- rbindlist(out)
SaveData(r, "../output/metro_correlations.csv", "../report/metro_correlations.txt",
  c("sample", "variable", "measure", "omitted_city"))
