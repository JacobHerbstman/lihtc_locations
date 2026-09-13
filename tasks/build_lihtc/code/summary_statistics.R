# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/build_lihtc/code")
library(data.table)
source("../../shared/code/save_data.R")
x <- fread("../output/projects.csv", na.strings = "")
stopifnot(!anyDuplicated(x$hud_id))

# Give each project equal weight; each field uses its own nonmissing observations.
# Bedroom columns count units in that category, including valid partial breakdowns.
fields <- c("pis_year", "allocation_year", "total_units", "low_income_units",
            "bedrooms_0", "bedrooms_1", "bedrooms_2", "bedrooms_3", "bedrooms_4")
long <- melt(x, measure.vars = fields, id.vars = "hud_id", variable.name = "variable")
summary <- long[, {
  known <- as.numeric(value[!is.na(value)])
  .(n = length(known), missing = .N - length(known),
    mean = if (length(known)) mean(known) else NA_real_,
    sd = if (length(known) > 1L) sd(known) else NA_real_,
    min = if (length(known)) min(known) else NA_real_,
    p25 = if (length(known)) unname(quantile(known, .25)) else NA_real_,
    median = if (length(known)) median(known) else NA_real_,
    p75 = if (length(known)) unname(quantile(known, .75)) else NA_real_,
    max = if (length(known)) max(known) else NA_real_)
}, by = variable]
stopifnot(all(summary$n + summary$missing == nrow(x)))
SaveData(summary, "../output/summary_statistics.csv", "../report/summary_statistics.txt", "variable")
