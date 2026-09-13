# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/state_diagnostics/code")
library(data.table)
source("../../../shared/code/save_data.R")
x <- fread("../input/projects.csv", na.strings = "")
stopifnot(!anyDuplicated(x$hud_id))

# 1. Project sizes: each project with a reported total counts once.
size <- x[!is.na(total_units), .(total_units)]
size[, category := cut(total_units, breaks = c(0, 10, 20, 50, 99, 199, Inf),
                       labels = c("1–10", "11–20", "21–50", "51–99", "100–199", "200+"))]
stopifnot(!anyNA(size$category))
sizes <- size[, .(count = .N), by = category]
sizes[, category_order := as.integer(category)]
sizes[, category := as.character(category)]
sizes[, c("measure", "denominator", "projects_with_data") := list("Project size", nrow(size), nrow(size))]

# 2. Bedroom mix: each unit counts once, within complete consistent projects.
# These shares use a common set of projects; partial bedroom counts stay in the master.
complete <- x[bedrooms_consistent == TRUE]
bedrooms <- complete[, .(count = c(sum(bedrooms_0), sum(bedrooms_1), sum(bedrooms_2),
                                  sum(bedrooms_3), sum(bedrooms_4)))]
bedrooms[, category := c("Efficiency", "1 bedroom", "2 bedrooms", "3 bedrooms", "4 bedrooms")]
bedrooms[, category_order := 1:5]
bedrooms[, c("measure", "denominator", "projects_with_data") :=
           list("Bedroom mix", sum(complete$total_units), nrow(complete))]
stopifnot(sum(bedrooms$count) == sum(complete$total_units))

# 3. Save counts and their denominators, so the percentages can be reconstructed.
distribution <- rbindlist(list(sizes, bedrooms), use.names = TRUE)
distribution[, percent := 100 * count / denominator]
stopifnot(all(abs(distribution[, .(total = sum(percent)), by = measure]$total - 100) < 1e-8))
setorder(distribution, measure, category_order)
SaveData(distribution, "../output/characteristic_distributions.csv",
         "../report/characteristic_distributions.txt", c("measure", "category"))
