# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/prepare_lihtc_property/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
  library(readxl)
})

validated_source <- fread("../input/lihtc_property_2024_files.csv")
if (nrow(validated_source) != 1) {
  stop("The validated source manifest must contain exactly one row.", call. = FALSE)
}

lihtc_property <- read_excel(
  "../temp/LIHTCPUB.xlsx",
  sheet = "Data",
  col_types = "text",
  na = "",
  trim_ws = FALSE,
  .name_repair = "minimal"
)
setDT(lihtc_property)

if (nrow(lihtc_property) != validated_source$project_rows) {
  stop("Workbook row count differs from the validated source manifest.", call. = FALSE)
}
if (ncol(lihtc_property) != validated_source$columns) {
  stop("Workbook column count differs from the validated source manifest.", call. = FALSE)
}
if (any(names(lihtc_property) == "") || anyDuplicated(names(lihtc_property))) {
  stop("Workbook column names must be nonempty and unique.", call. = FALSE)
}

write_parquet(
  lihtc_property,
  "../output/lihtc_property_2024_raw_text.parquet",
  compression = "zstd"
)

round_trip <- as.data.table(read_parquet("../output/lihtc_property_2024_raw_text.parquet"))
if (!identical(lihtc_property, round_trip)) {
  stop("Parquet round trip changed at least one name, type, value, or row order.", call. = FALSE)
}

cat(
  "Prepared ", format(nrow(lihtc_property), big.mark = ","), " rows and ",
  ncol(lihtc_property), " raw-text columns in Parquet.\n",
  sep = ""
)
