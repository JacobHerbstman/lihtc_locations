# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/build_lihtc/code")
library(data.table)
x <- fread("../output/project_records.csv", na.strings = "")
p <- fread("../output/projects.csv", na.strings = "")
n <- fread("../output/sample_sizes.csv")
stats <- fread("../output/summary_statistics.csv")
counts <- data.table(
  measure = c("HUD new-construction records", "Missing HUD coordinates",
              "Main dataset: HUD project IDs", "Projects with a usable year",
              "Projects with total units", "Projects with a complete bedroom breakdown",
              "Projects with year, units, and bedroom breakdown"),
  count = c(nrow(x), sum(!x$hud_coordinates_present), nrow(p),
            n[sample == "Known pis_year", n], n[sample == "Known total_units", n],
            n[sample == "Known complete bedroom breakdown", n],
            n[sample == "Year, total units and complete bedroom breakdown", n])
)
lines <- c("\\begin{tabular}{lr}", "\\hline")
for (i in seq_len(nrow(counts))) {
  lines <- c(lines, paste0(counts$measure[i], " & ",
                          format(counts$count[i], big.mark = ","), " \\\\"))
}
lines <- c(lines, "\\hline", "\\end{tabular}", "\\par\\medskip",
           "\\begin{tabular}{lrrr}", "\\hline", "Characteristic & N & Mean & Median \\\\", "\\hline")
for (field in c("total_units", "low_income_units")) {
  value <- stats[variable == field]
  label <- if (field == "total_units") "Total project units" else "Low-income project units"
  lines <- c(lines, paste0(label, " & ", format(value$n, big.mark = ","), " & ",
                         sprintf("%.1f", value$mean), " & ", sprintf("%.0f", value$median), " \\\\"))
}
writeLines(c(lines, "\\hline", "\\end{tabular}"), "../output/summary.tex")
