# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/build_lihtc/code")
library(data.table)
x <- fread("../output/project_records.csv", na.strings = "")
p <- fread("../output/projects.csv", na.strings = "")
n <- fread("../output/sample_sizes.csv")
counts <- data.table(
  measure = c("HUD new-construction records", "Source records with HUD coordinates",
              "First-address locations with HUD coordinates", "Locations with a usable year",
              "Locations with total units", "Locations with a complete bedroom breakdown",
              "Locations with year, units, and bedroom breakdown"),
  count = c(nrow(x), sum(x$hud_coordinates_present), nrow(p),
            n[sample == "Known pis_year", n], n[sample == "Known total_units", n],
            n[sample == "Known complete bedroom breakdown", n],
            n[sample == "Year, total units and complete bedroom breakdown", n])
)
lines <- c("\\begin{tabular}{lr}", "\\hline")
for (i in seq_len(nrow(counts))) {
  lines <- c(lines, paste0(counts$measure[i], " & ",
                          format(counts$count[i], big.mark = ","), " \\\\"))
}
writeLines(c(lines, "\\hline", "\\end{tabular}"), "../output/summary.tex")
