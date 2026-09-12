# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/build_lihtc/code")
library(data.table)
x <- fread("../output/project_records.csv",na.strings="")
p <- fread("../output/projects.csv",na.strings="")
counts <- data.table(
  measure=c("Original new-construction records","Selected first-address records","Later or same-year records not selected","Records with unresolved first selection","Retained using HUD coordinates by default","Former corroboration-rule sample","Retained with missing total units","Retained without consistent bedroom counts","Selected missing placed-in-service year"),
  count=c(nrow(x),nrow(p),sum(x$keep_first %in% FALSE),sum(is.na(x$keep_first)),
    sum(p$confident_first),sum(p$corroborated_first),p[confident_first & is.na(total_units),.N],
    p[confident_first & !bedrooms_consistent,.N],p[is.na(pis_year),.N]))
lines <- c("\\begin{tabular}{lr}","\\hline")
for (i in seq_len(nrow(counts))) lines <- c(lines,paste0(counts$measure[i]," & ",format(counts$count[i],big.mark=",")," \\\\"))
writeLines(c(lines,"\\hline","\\end{tabular}"),"../output/summary.tex")
