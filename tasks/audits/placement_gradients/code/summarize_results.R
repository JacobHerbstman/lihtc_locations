# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/placement_gradients/code")
library(data.table)
c <- fread("../output/coverage.csv")
m <- fread("../output/models.csv")[sample == "all_city_tracts" & model == "separate"]
lines <- c("\\begin{center}\\begin{tabular}{lrrrr}\\hline",
  "City & Projects & Homeowner & Black share & Income \\\\ \\hline")
for (city in unique(c$city_name)) {
  z <- m[city_name == city & comparison == "pooled"]
  lines <- c(lines, sprintf("%s & %d & %.3f & %.3f & %.3f \\\\", city,
    c[city_name == city, common_projects], z[variable == "homeowner_share", rate_ratio],
    z[variable == "nh_black_share", rate_ratio], z[variable == "log_income", rate_ratio]))
}
lines <- c(lines, "\\hline\\end{tabular}\\end{center}",
  "The full study period is pooled separately within each city. Rate ratios describe one standard deviation higher characteristic. These separate regressions use the same observations, year effects and baseline housing exposure. A ratio of 0.50 means half as many placements; 2.00 means twice as many.\\par")
writeLines(lines, "../output/summary.tex")
