# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/build_lihtc/code")
library(data.table)
x <- fread("../output/project_records.csv",na.strings="")
counts <- data.table(
  measure=c("Original new-construction records","Selected first-address records","Later or identical records not selected","Records with unresolved first selection","Selected with checked, unflagged locations","Selected with only unconfirmed HUD coordinates","Selected with no location","Selected missing placed-in-service year","Selected with positive total units","Selected with consistent bedroom totals"),
  count=c(nrow(x),sum(x$keep_first %in% TRUE),sum(x$keep_first %in% FALSE),sum(is.na(x$keep_first)),
    sum(x$usable_location),x[keep_first %in% TRUE & location_status=="hud_only_unconfirmed",.N],
    x[keep_first %in% TRUE & location_status=="no_location",.N],x[keep_first %in% TRUE & is.na(pis_year),.N],
    x[keep_first %in% TRUE & !is.na(total_units) & total_units>0,.N],x[keep_first %in% TRUE & bedrooms_consistent==TRUE,.N]))
lines <- c("\\begin{tabular}{lr}","\\hline")
for (i in seq_len(nrow(counts))) lines <- c(lines,paste0(counts$measure[i]," & ",format(counts$count[i],big.mark=",")," \\\\"))
writeLines(c(lines,"\\hline","\\end{tabular}"),"../output/summary.tex")
