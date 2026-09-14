# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/placement_gradients/code")
library(data.table)
m <- fread("../output/models.csv")[sample == "all_city_tracts" & model == "joint"]
c <- fread("../output/coverage.csv")
lines <- c("\\begin{center}\\begin{tabular}{llrr}\\hline",
  "City & Characteristic & Before controls & Add vacancy/density \\\\ \\hline")
for (city in unique(c$city_name)) {
  for (v in c("homeowner_share", "nh_black_share", "log_income")) {
    label <- c(homeowner_share = "Homeowner share", nh_black_share = "Black share", log_income = "Income")[[v]]
    z <- m[city_name == city & variable == v]
    lines <- c(lines, sprintf("%s & %s & %.3f & %.3f \\\\", city, label,
      z[adjustment == "same_sample", rate_ratio], z[adjustment == "housing_controls", rate_ratio]))
  }
}
lines <- c(lines, "\\hline\\end{tabular}\\end{center}",
  "All three characteristics enter jointly in both columns. Estimates use the same observations, city-specific year effects, baseline housing exposure, and original within-city standardization. Ratios describe one standard deviation higher characteristic.\\par")
for (city in unique(c$city_name)) {
  z <- c[city_name == city]
  lines <- c(lines, sprintf("%s retains %d projects and %d eligible tract-years with the added controls; %d projects and %d tract-years are excluded relative to the original pooled sample.\\par",
    city, z$controls_projects, z$controls_tract_years, z$common_projects - z$controls_projects,
    z$common_tract_years - z$controls_tract_years))
}
writeLines(lines, "../output/housing_controls.tex")
