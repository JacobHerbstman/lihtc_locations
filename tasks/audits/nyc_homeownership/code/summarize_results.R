# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/nyc_homeownership/code")
library(data.table)
c <- fread("../output/coverage.csv")[specification == "main"]
m <- fread("../output/models.csv")
lines <- c("\\begin{center}\\begin{tabular}{lrr}\\hline",
  " & 1987--2002 & 2003--2022 \\\\ \\hline")
for (field in c("projects", "projects_in_analysis", "project_mean_homeowner_pct", "housing_weighted_homeowner_pct")) {
  label <- c(projects = "Dated project records", projects_in_analysis = "Projects with usable prior context",
    project_mean_homeowner_pct = "Prior homeowner share at projects (percent)",
    housing_weighted_homeowner_pct = "Prior homeowner share across housing (percent)")[[field]]
  value <- c[[field]][match(c("through_2002", "after_2002"), c$era)]
  lines <- c(lines, sprintf("%s & %.1f & %.1f \\\\", label, value[[1L]], value[[2L]]))
}
lines <- c(lines, "\\hline\\end{tabular}\\end{center}",
  "\\begin{center}\\begin{tabular}{llrrr}\\hline",
  "Sample & Adjustment & Early ratio & Later ratio & Ratio of ratios \\\\ \\hline")
for (s in c("main", "same_2000")) for (a in c("year", "borough_year")) {
  z <- m[specification == s & adjustment == a]
  values <- z$rate_ratio[match(c("through_2002", "after_2002", "later_minus_earlier"), z$comparison)]
  lines <- c(lines, sprintf("%s & %s & %.3f & %.3f & %.3f \\\\",
    if (s == "main") "Full periods" else "Same 2000 Census", if (a == "year") "Year" else "Borough/year",
    values[[1L]], values[[2L]], values[[3L]]))
}
lines <- c(lines, "\\hline\\end{tabular}\\end{center}",
  "Ratios describe the association with ten percentage points higher prior homeownership, at the same baseline housing exposure. A ratio below one means fewer placements. The ratio of ratios is below one when the later association is more negative. Confidence intervals and sample counts are in the audit report.\\par")
writeLines(lines, "../output/summary.tex")
