# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/within_city_discretion/code")
library(data.table)
x <- fread("../output/city_comparison.csv")[sample == "all_city_tracts" & variable == "homeowner_share"]
labels <- c(compliance_route = "Ordinary compliance route", triggered_subjective_review = "Review when triggered",
  state_limited_review = "Local review / state limit", unresolved_2022 = "2022 coding unresolved")
lines <- c("\\begin{center}\\small\\begin{tabular}{llr}", "\\hline City & Pilot assessment & Homeowner gradient \\\\", "\\hline")
for (i in seq_len(nrow(x))) {
  lines <- c(lines, sprintf("%s & %s & %.1f\\%% \\\\", x$city_name[i], labels[x$pilot_category[i]], x$percent_change[i]))
}
lines <- c(lines, "\\hline\\end{tabular}\\end{center}",
  "\\noindent\\footnotesize Homeowner gradient: +10 percentage points in the existing joint model with housing controls. Legal categories describe routes, not a verified 2022 city index.\\normalsize")
writeLines(lines, "../output/summary.tex")
