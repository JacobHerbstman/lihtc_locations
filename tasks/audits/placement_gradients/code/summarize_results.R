# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/placement_gradients/code")
library(data.table)
c <- fread("../output/coverage.csv")
m <- fread("../output/models.csv")[sample == "all_city_tracts" & model == "separate"]
lines <- c("\\begin{center}\\begin{tabular}{llrr}\\hline",
  "City & Measure & Through 2002 & After 2002 \\\\ \\hline")
for (city in unique(c$city_name)) {
  z <- c[city_name == city]
  lines <- c(lines, sprintf("%s & Common-sample projects & %d & %d \\\\", city,
    z[era == "through_2002", common_projects], z[era == "after_2002", common_projects]))
  for (v in c("homeowner_share", "nh_black_share", "log_income")) {
    label <- c(homeowner_share = "Homeowner share", nh_black_share = "Black share", log_income = "Income")[[v]]
    z <- m[city_name == city & variable == v]
    lines <- c(lines, sprintf(" & %s: rate ratio per SD & %.3f & %.3f \\\\", label,
      z[comparison == "through_2002", rate_ratio], z[comparison == "after_2002", rate_ratio]))
  }
}
lines <- c(lines, "\\hline\\end{tabular}\\end{center}",
  "One standard deviation is calculated across common-sample tract-years within each city, pooling both periods. These separate regressions use the same observations, year effects and baseline housing exposure. A ratio of 0.50 means half as many placements; 2.00 means twice as many.\\par")
writeLines(lines, "../output/summary.tex")
