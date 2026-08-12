# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/prepare_lihtc_tx_no_site_tdhca_source_review/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
  library(digest)
  library(readxl)
})

require_unique <- function(table, columns, label) {
  if (uniqueN(table, by = columns) != nrow(table)) {
    stop(label, " is not unique by ", paste(columns, collapse = ", "),
      call. = FALSE)
  }
}

normalize_key <- function(x) {
  gsub("[^A-Z0-9]", "", toupper(x))
}

questions <- as.data.table(read_parquet(
  "../input/lihtc_no_site_development_questions.parquet"
))
if (nrow(questions) != 797L) {
  stop("The final no-site question input changed.", call. = FALSE)
}
require_unique(questions, "no_site_review_question_id", "No-site questions")
require_unique(questions, "development_id", "No-site questions")

questions <- questions[development_state == "TX"]
if (nrow(questions) != 91L ||
    anyNA(questions$development_name) || any(questions$development_name == "") ||
    anyNA(questions$n_units_development)) {
  stop("The Texas no-site question universe changed.", call. = FALSE)
}
questions[, `:=`(
  normalized_development_name = normalize_key(development_name),
  normalized_development_city = normalize_key(development_city)
)]
if (any(nchar(questions$normalized_development_name) == 0L) ||
    uniqueN(questions$development_id) != 91L) {
  stop("Texas question normalization failed.", call. = FALSE)
}

manifest <- fread(
  "../input/tdhca_htc_property_inventory_2026-08-12_manifest.sha256",
  header = FALSE, col.names = c("source_sha256", "source_file")
)
if (nrow(manifest) != 1L ||
    manifest$source_file != "HTCPropertyInventory_0.xlsx" ||
    manifest$source_sha256 !=
      "3322cce8839d82de0d2e6373156149608aa3bb54d31c874f3faaf526549cdaaf" ||
    digest(file = "../input/HTCPropertyInventory_0.xlsx", algo = "sha256") !=
      manifest$source_sha256) {
  stop("The frozen TDHCA workbook does not match its expected manifest.",
    call. = FALSE)
}

source <- as.data.table(read_excel("../input/HTCPropertyInventory_0.xlsx"))
required_source_columns <- c(
  "TDHCA#", "Development Name", "Project Address", "Project City",
  "Zip Code", "Total Units", "Latitude", "Longitude"
)
if (nrow(source) != 3301L ||
    !setequal(required_source_columns,
      intersect(required_source_columns, names(source)))) {
  stop("The frozen TDHCA workbook schema or row count changed.", call. = FALSE)
}
source[, source_row_number := .I]
source[, `:=`(
  source_tdhca_number = as.character(`TDHCA#`),
  source_development_name = `Development Name`,
  source_project_address = `Project Address`,
  source_project_city = `Project City`,
  source_zip_code = as.character(`Zip Code`),
  source_total_units = as.integer(`Total Units`),
  source_latitude = as.numeric(Latitude),
  source_longitude = as.numeric(Longitude),
  normalized_source_name = normalize_key(`Development Name`),
  normalized_source_city = normalize_key(`Project City`),
  source_url = "https://www.tdhca.texas.gov/sites/default/files/multifamily/docs/HTCPropertyInventory_0.xlsx",
  source_sha256 = manifest$source_sha256
)]
if (anyNA(source$source_tdhca_number) ||
    any(source$source_tdhca_number == "") ||
    anyNA(source$source_development_name) ||
    any(nchar(source$normalized_source_name) == 0L) ||
    uniqueN(source$source_row_number) != nrow(source)) {
  stop("The TDHCA source identity contract failed.", call. = FALSE)
}

exact_source_rows <- source[
  normalized_source_name %chin% questions$normalized_development_name
]
exact_question_rows <- match(
  exact_source_rows$normalized_source_name,
  questions$normalized_development_name
)
if (anyNA(exact_question_rows) ||
    anyDuplicated(exact_question_rows) ||
    anyDuplicated(exact_source_rows$source_row_number)) {
  stop("The exact screen is not one source row to one question.", call. = FALSE)
}
exact_candidates <- cbind(
  questions[exact_question_rows, .(
    no_site_review_question_id, development_id, development_name,
    development_city, normalized_development_city, n_units_development
  )],
  exact_source_rows[, .(
    source_row_number, source_tdhca_number, source_development_name,
    source_project_address, source_project_city, source_zip_code,
    source_total_units, source_latitude, source_longitude, source_url,
    source_sha256
  )]
)
exact_candidates[, `:=`(
  source_city_agrees = normalized_development_city ==
    normalize_key(source_project_city) & nchar(normalized_development_city) > 0L,
  source_total_units_agree = n_units_development == source_total_units,
  screening_match_type = "exact_normalized_name",
  review_status = "not_adjudicated",
  geocoding_query_approval = "not_approved"
)]

fuzzy_candidates <- rbindlist(lapply(seq_len(nrow(questions)), function(i) {
  eligible_source <- source[
    normalized_source_city == questions$normalized_development_city[i] &
      nchar(normalized_source_city) > 0L &
      source_total_units == questions$n_units_development[i] &
      normalized_source_name != questions$normalized_development_name[i]
  ]
  if (nrow(eligible_source) == 0L) {
    return(NULL)
  }
  eligible_source[, `:=`(
    name_distance = as.integer(adist(
      questions$normalized_development_name[i], normalized_source_name
    )),
    name_max_length = pmax(
      nchar(questions$normalized_development_name[i]),
      nchar(normalized_source_name)
    )
  )]
  eligible_source[, name_distance_share := name_distance / name_max_length]
  eligible_source <- eligible_source[name_distance_share <= 0.25]
  if (nrow(eligible_source) == 0L) {
    return(NULL)
  }
  cbind(
    questions[rep(i, nrow(eligible_source)), .(
      no_site_review_question_id, development_id, development_name,
      development_city, normalized_development_city, n_units_development
    )],
    eligible_source[, .(
      source_row_number, source_tdhca_number, source_development_name,
      source_project_address, source_project_city, source_zip_code,
      source_total_units, source_latitude, source_longitude, source_url,
      source_sha256, name_distance, name_max_length, name_distance_share
    )]
  )
}), fill = TRUE)
if (is.null(fuzzy_candidates)) {
  fuzzy_candidates <- data.table()
}
if (nrow(fuzzy_candidates) > 0L) {
  fuzzy_candidates[, `:=`(
    source_city_agrees = TRUE,
    source_total_units_agree = TRUE,
    screening_match_type = "fuzzy_name_with_exact_city_and_units",
    review_status = "not_adjudicated",
    geocoding_query_approval = "not_approved"
  )]
}

setorder(exact_candidates, development_id, source_row_number)
setorder(fuzzy_candidates, development_id, source_row_number)
require_unique(exact_candidates,
  c("development_id", "source_row_number"), "Exact candidates")
require_unique(fuzzy_candidates,
  c("development_id", "source_row_number"), "Fuzzy candidates")

exact_counts <- exact_candidates[, .(
  n_tdhca_exact_name_source_rows = .N,
  n_tdhca_exact_name_city_agree_source_rows = sum(source_city_agrees),
  n_tdhca_exact_name_city_unit_agree_source_rows = sum(
    source_city_agrees & source_total_units_agree
  )
), by = no_site_review_question_id]
fuzzy_counts <- fuzzy_candidates[, .(
  n_tdhca_fuzzy_city_unit_source_rows = .N
), by = no_site_review_question_id]
questions[exact_counts, names(exact_counts)[-1L] := mget(paste0("i.",
  names(exact_counts)[-1L])), on = "no_site_review_question_id"]
questions[fuzzy_counts, n_tdhca_fuzzy_city_unit_source_rows :=
  i.n_tdhca_fuzzy_city_unit_source_rows, on = "no_site_review_question_id"]
count_columns <- grep("^n_tdhca_", names(questions), value = TRUE)
for (column in count_columns) {
  set(questions, which(is.na(questions[[column]])), column, 0L)
}
questions[, `:=`(
  tdhca_source_screen_status = "screened_exact_and_conservative_fuzzy_only",
  review_status = "not_adjudicated",
  geocoding_query_approval = "not_approved"
)]
setorder(questions, development_id)

summary <- data.table(
  measure = c(
    "tx_no_site_questions", "tdhca_source_rows", "exact_name_source_rows",
    "exact_name_developments", "exact_name_city_agree_source_rows",
    "exact_name_city_unit_agree_source_rows", "fuzzy_city_unit_source_rows",
    "fuzzy_city_unit_developments"
  ),
  value = c(
    nrow(questions), nrow(source), nrow(exact_candidates),
    uniqueN(exact_candidates$development_id), sum(exact_candidates$source_city_agrees),
    sum(exact_candidates$source_city_agrees &
      exact_candidates$source_total_units_agree),
    nrow(fuzzy_candidates), uniqueN(fuzzy_candidates$development_id)
  )
)
expected <- c(
  tx_no_site_questions = 91L, tdhca_source_rows = 3301L,
  exact_name_source_rows = 16L, exact_name_developments = 16L,
  exact_name_city_agree_source_rows = 12L,
  exact_name_city_unit_agree_source_rows = 12L,
  fuzzy_city_unit_source_rows = 2L, fuzzy_city_unit_developments = 2L
)
observed <- setNames(summary$value, summary$measure)
if (!identical(as.integer(observed[names(expected)]), as.integer(expected))) {
  stop("The TDHCA screening no longer reproduces frozen counts: ",
    paste(names(expected), observed[names(expected)], expected,
      sep = "=", collapse = "; "), call. = FALSE)
}
if (any(questions$review_status != "not_adjudicated") ||
    any(questions$geocoding_query_approval != "not_approved") ||
    any(exact_candidates$review_status != "not_adjudicated") ||
    any(exact_candidates$geocoding_query_approval != "not_approved") ||
    any(fuzzy_candidates$review_status != "not_adjudicated") ||
    any(fuzzy_candidates$geocoding_query_approval != "not_approved")) {
  stop("The preparation-only decision status failed.", call. = FALSE)
}

write_parquet(questions, "../output/lihtc_tx_no_site_tdhca_questions.parquet")
write_parquet(exact_candidates,
  "../output/lihtc_tx_no_site_tdhca_exact_source_candidates.parquet"
)
write_parquet(fuzzy_candidates,
  "../output/lihtc_tx_no_site_tdhca_fuzzy_source_candidates.parquet"
)
fwrite(summary, "../output/lihtc_tx_no_site_tdhca_screening_summary.csv")

questions_roundtrip <- as.data.table(read_parquet(
  "../output/lihtc_tx_no_site_tdhca_questions.parquet"
))
exact_roundtrip <- as.data.table(read_parquet(
  "../output/lihtc_tx_no_site_tdhca_exact_source_candidates.parquet"
))
fuzzy_roundtrip <- as.data.table(read_parquet(
  "../output/lihtc_tx_no_site_tdhca_fuzzy_source_candidates.parquet"
))
summary_roundtrip <- fread("../output/lihtc_tx_no_site_tdhca_screening_summary.csv")
if (nrow(questions_roundtrip) != 91L || nrow(exact_roundtrip) != 16L ||
    nrow(fuzzy_roundtrip) != 2L || !identical(summary_roundtrip, summary) ||
    any(questions_roundtrip$review_status != "not_adjudicated") ||
    any(exact_roundtrip$review_status != "not_adjudicated") ||
    any(fuzzy_roundtrip$review_status != "not_adjudicated") ||
    any(questions_roundtrip$geocoding_query_approval != "not_approved") ||
    any(exact_roundtrip$geocoding_query_approval != "not_approved") ||
    any(fuzzy_roundtrip$geocoding_query_approval != "not_approved")) {
  stop("The TDHCA screening outputs failed their round-trip checks.",
    call. = FALSE)
}
