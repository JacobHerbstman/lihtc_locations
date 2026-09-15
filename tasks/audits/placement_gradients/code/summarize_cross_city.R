# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/placement_gradients/code")
library(data.table)
m <- fread("../output/models.csv")
m <- m[sample == "all_city_tracts" & model == "joint" & adjustment == "housing_controls"]
city_order <- m[variable == "homeowner_share"][order(natural_rate_ratio), city_name]
lines <- c("\\begin{center}\\small\\begin{tabular}{lrrrr}\\hline",
  "City & Projects & Homeowner & Black share & Income \\\\ \\hline")
for (city in city_order) {
  z <- m[city_name == city]
  lines <- c(lines, sprintf("%s & %d & %+.1f\\%% & %+.1f\\%% & %+.1f\\%% \\\\", city,
    unique(z$projects), 100 * (z[variable == "homeowner_share", natural_rate_ratio] - 1),
    100 * (z[variable == "nh_black_share", natural_rate_ratio] - 1),
    100 * (z[variable == "log_income", natural_rate_ratio] - 1)))
}
lines <- c(lines, "\\hline\\end{tabular}\\end{center}",
  "Percent changes in the placement rate for ten percentage points higher homeowner or non-Hispanic Black share, or 10\\% higher real median household income. All three enter jointly with prior vacancy, log housing density, year effects and baseline housing-unit exposure. Different increments across columns: compare cities within columns; use standardized estimates to compare characteristics.\\par")
writeLines(lines, "../output/cross_city.tex")
