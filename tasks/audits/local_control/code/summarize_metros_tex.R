# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/local_control/code")
library(data.table)
x <- fread("../output/metro_fragmentation.csv")
r <- fread("../output/metro_correlations.csv")
lines <- c("\\begin{center}\\small", "\\begin{tabular}{lrrr}",
  "\\hline City & Active governments & Per 100,000 & Central-city share \\\\", "\\hline")
for (i in seq_len(nrow(x))) {
  z <- x[i]
  lines <- c(lines, sprintf("%s & %d & %.2f & %.1f\\%% \\\\", z$city_name,
    z$general_purpose_governments, z$governments_per_100k, 100 * z$central_city_population_share))
}
lines <- c(lines, "\\hline\\end{tabular}\\end{center}",
  "\\begin{center}\\small\\begin{tabular}{lrrrr}",
  "\\hline Metro variable & Owner $r$ & Black $r$ & Income $r$ & Owner LOO range \\\\", "\\hline")
labels <- c(general_purpose_governments = "Active count", governments_per_100k = "Per 100,000", central_city_population_share = "Central-city share")
for (m in names(labels)) {
  a <- r[sample == "all_city_tracts" & measure == m & omitted_city == "none"]
  loo <- r[sample == "all_city_tracts" & measure == m & variable == "homeowner_share" & omitted_city != "none", pearson]
  lines <- c(lines, sprintf("%s & %.2f & %.2f & %.2f & %.2f to %.2f \\\\", labels[m],
    a[variable == "homeowner_share", pearson], a[variable == "nh_black_share", pearson],
    a[variable == "log_income", pearson], min(loo), max(loo)))
}
lines <- c(lines, "\\hline\\end{tabular}\\end{center}",
  "\\noindent\\footnotesize Pearson correlations use signed log-rate changes from the joint, housing-control models. Eight cities; each leave-one-city-out (LOO) comparison uses seven.\\normalsize")
writeLines(lines, "../output/metro_summary.tex")
