# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/fetch_hud_income_limits/code")
library(curl)
library(readxl)

# Official April 22, 2024 revision. Preserve the downloaded workbook unchanged.
response <- curl_fetch_disk(
  "https://www.huduser.gov/portal/datasets/mtsp/mtsp24/MTSP-Data-FY24.xlsx",
  "../temp/MTSP-Data-FY24.xlsx", new_handle(timeout = 120))
if (response$status_code != 200L) stop(sprintf(
  "HUD returned HTTP %d; its automated-download challenge currently prevents acquisition. No source was published.",
  response$status_code))
sheets <- excel_sheets("../temp/MTSP-Data-FY24.xlsx")
stopifnot(length(sheets) > 0L)
rows <- vapply(sheets, function(sheet) nrow(read_excel("../temp/MTSP-Data-FY24.xlsx", sheet = sheet)), integer(1))
stopifnot(any(rows > 0L))
dir.create("../../../data_raw/hud_income_limits/2024", recursive = TRUE, showWarnings = FALSE)
file <- "../../../data_raw/hud_income_limits/2024/MTSP-Data-FY24.xlsx"
stopifnot(file.rename("../temp/MTSP-Data-FY24.xlsx", file))
writeLines(c(paste("Source workbook MD5:", tools::md5sum(file)), paste(sheets, rows, sep = ": ")), "../report/source_workbook.txt")
