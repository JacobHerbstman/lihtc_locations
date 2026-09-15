# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/local_control/code")
library(data.table)
x <- fread("../output/locus_city_coverage.csv")
lines <- c("\\begin{center}\\begin{tabular}{lrr}\\hline",
  "City & Raw text chunks & Labeled zoning/buildings \\\\ \\hline")
for (i in seq_len(nrow(x))) {
  labeled <- if (is.na(x$source_zoning_building_chunks[i])) "---" else as.character(x$source_zoning_building_chunks[i])
  lines <- c(lines, sprintf("%s & %d & %s \\\\", x$city_name[i], x$raw_chunks[i], labeled))
}
lines <- c(lines, "\\hline\\end{tabular}\\end{center}",
  "Counts describe the saved public LOCUS text, not laws, approval routes or complete city codes. Zoning/building labels are source-model predictions and do not filter the extract. Missing city text does not mean zero discretion.\\par")
writeLines(lines, "../output/coverage.tex")
