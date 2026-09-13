# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/build_lihtc/code")
library(data.table)
source("../../shared/code/save_data.R")
x <- fread("../output/projects.csv", na.strings = "")

# 1. Each characteristic uses the observations where that characteristic is known.
fields <- c("pis_year", "allocation_year", "total_units", "low_income_units",
            "bedrooms_0", "bedrooms_1", "bedrooms_2", "bedrooms_3", "bedrooms_4",
            "credit_type", "target_family", "target_elderly", "target_disabled")
sizes <- data.table(
  sample = c("All project locations", paste("Known", fields)),
  n = c(nrow(x), vapply(x[, ..fields], function(z) sum(!is.na(z)), integer(1)))
)

# 2. Joint Ns illustrate adding controls; these masks never filter the master file.
# Actual regressions must report their own N for their actual outcome and controls.
sizes <- rbind(sizes, data.table(
  sample = c("Known complete bedroom breakdown", "Year and total units",
             "Year, total units and complete bedroom breakdown",
             "Year, total units, bedroom breakdown and all three targeting indicators"),
  n = c(sum(x$bedrooms_consistent),
        x[!is.na(pis_year) & !is.na(total_units), .N],
        x[!is.na(pis_year) & !is.na(total_units) & bedrooms_consistent, .N],
        x[!is.na(pis_year) & !is.na(total_units) & bedrooms_consistent &
          !is.na(target_family) & !is.na(target_elderly) & !is.na(target_disabled), .N])
))
sizes[, `:=`(missing_from_master = nrow(x) - n, available_pct = 100 * n / nrow(x))]
SaveData(sizes, "../output/sample_sizes.csv", "../report/sample_sizes.txt", "sample")
