# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/prepare_lihtc_multisite/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
  library(readxl)
})

validated_source <- fread("../input/lihtc_property_2024_files.csv")
if (nrow(validated_source) != 1L) {
  stop("The validated source manifest must contain exactly one row.", call. = FALSE)
}
if (validated_source$archive_sha256 !=
    "e07acee706174b276f89596d614ac5699efa9848659e5834fdfb5198fa0a7288") {
  stop("The multi-address workbook is not from the pinned archive.", call. = FALSE)
}

lihtc_multisite <- read_excel(
  "../temp/LIHTCPUB_BIN.xlsx",
  sheet = "Data",
  col_types = "text",
  na = "",
  trim_ws = FALSE,
  .name_repair = "minimal"
)
setDT(lihtc_multisite)

expected_columns <- c(
  "hud_id", "project", "proj_st", "state_id",
  "bin", "bin_add", "bin_cty", "bin_zip"
)
if (!identical(names(lihtc_multisite), expected_columns)) {
  stop("The multi-address workbook columns or their order changed.", call. = FALSE)
}
if (nrow(lihtc_multisite) != 161715L) {
  stop("The multi-address workbook row count changed.", call. = FALSE)
}

write_parquet(
  lihtc_multisite,
  "../output/lihtc_multisite_2024_raw_text.parquet",
  compression = "zstd"
)

round_trip <- as.data.table(read_parquet(
  "../output/lihtc_multisite_2024_raw_text.parquet"
))
if (!identical(lihtc_multisite, round_trip)) {
  stop(
    "Parquet round trip changed a name, type, value, or row order.",
    call. = FALSE
  )
}

cat(
  "Prepared ", format(nrow(lihtc_multisite), big.mark = ","), " rows and ",
  ncol(lihtc_multisite), " raw-text columns in Parquet.\n",
  sep = ""
)
