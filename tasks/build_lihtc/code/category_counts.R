# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/build_lihtc/code")
library(data.table)
source("../../shared/code/save_data.R")
x <- fread("../output/projects.csv", na.strings = "")
stopifnot(!anyDuplicated(x$hud_id))

# Count each source category and missing values explicitly. Unknown is never "no".
fields <- c("credit_type", "target_family", "target_elderly", "target_disabled",
            "scattered_site", "resyndicated", "repeated_address")
x[, repeated_address := as.integer(repeated_address)]
long <- melt(x, id.vars = "hud_id", measure.vars = fields, variable.name = "variable")
counts <- long[, .(n = .N), by = .(variable, value)]
counts[, `:=`(total_n = sum(n), known_n = sum(n[!is.na(value)])), by = variable]
counts[, `:=`(percent_all = 100 * n / total_n,
             percent_known = fifelse(!is.na(value) & known_n > 0, 100 * n / known_n, NA_real_))]
counts[, category := fcase(
  is.na(value), "Missing",
  variable == "credit_type" & value == 1, "30 percent present value",
  variable == "credit_type" & value == 2, "70 percent present value",
  variable == "credit_type" & value == 3, "Both credit types",
  variable == "credit_type" & value == 4, "TCEP only",
  value == 1, "Yes",
  value %in% c(0, 2), "No"
)]
stopifnot(!anyNA(counts$category), all(counts$total_n == nrow(x)))
setorder(counts, variable, value, na.last = TRUE)
SaveData(counts, "../output/category_counts.csv", "../report/category_counts.txt", c("variable", "category"))
