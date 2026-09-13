# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/census_diagnostics/code")
library(data.table)
states <- fread("../output/coverage_by_state.csv")
vintages <- fread("../output/coverage_by_vintage.csv", na.strings = "")
cities <- fread("../output/city_tracts.csv", na.strings = "")
projects <- fread("../input/projects_with_tracts.csv", na.strings = "")
setorder(vintages, period_end)
n <- nrow(projects)
lines <- c(sprintf("The Census extension preserves all %s HUD project IDs. Of these, %s have a latest ACS tract match and %s have a matched observation ending before placed-in-service. The latter denominator includes %s projects with known placed-in-service years.\\par",
  format(n, big.mark = ","), format(sum(states$latest_tract_matched), big.mark = ","),
  format(sum(states$baseline_tract_matched), big.mark = ","), format(sum(states$known_pis_year), big.mark = ",")),
  "\\begin{center}\\begin{tabular}{rrrrr}\\hline",
  "Observation & Tracts & Income observed & Rent observed & Homeowner share \\\\ \\hline")
for (i in seq_len(nrow(vintages))) lines <- c(lines, sprintf("%d & %s & %s & %s & %s \\\\",
  vintages$period_end[[i]], format(vintages$tracts[[i]], big.mark = ","),
  format(vintages$income_observed[[i]], big.mark = ","), format(vintages$rent_observed[[i]], big.mark = ","),
  format(vintages$homeowner_share_observed[[i]], big.mark = ",")))
lines <- c(lines, "\\hline\\end{tabular}\\end{center}")
city <- cities[, .(tracts = .N, zero = sum(city_lihtc_projects == 0), count = sum(city_lihtc_projects)), by = city_name]
for (i in seq_len(nrow(city))) lines <- c(lines, sprintf("%s has %d intersecting tracts, of which %d have no matched LIHTC point inside the city; %d project records are counted in these tracts.\\par", city$city_name[[i]], city$tracts[[i]], city$zero[[i]], city$count[[i]]))
writeLines(lines, "../output/summary.tex")
