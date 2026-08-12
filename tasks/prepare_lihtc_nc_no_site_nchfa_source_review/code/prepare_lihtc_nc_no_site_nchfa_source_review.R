# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/prepare_lihtc_nc_no_site_nchfa_source_review/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
  library(digest)
  library(xml2)
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

questions <- questions[development_state == "NC"]
if (nrow(questions) != 55L ||
    anyNA(questions$development_name) || any(questions$development_name == "") ||
    anyNA(questions$development_city) || any(questions$development_city == "") ||
    anyNA(questions$n_units_development)) {
  stop("The North Carolina no-site question universe changed.", call. = FALSE)
}
questions[, `:=`(
  normalized_development_name = normalize_key(development_name),
  normalized_development_city = normalize_key(development_city)
)]
if (any(nchar(questions$normalized_development_name) == 0L) ||
    any(nchar(questions$normalized_development_city) == 0L)) {
  stop("North Carolina question normalization failed.", call. = FALSE)
}

manifest <- fread("../input/source_manifest.csv")
expected_source_files <- sprintf("awarded_projects_page_%s.html", 0:82)
expected_source_urls <- paste0(
  "https://housingbuildsnc.com/rental-housing-partners/",
  "rental-developers/find-awarded-projects?page=", 0:82
)
if (nrow(manifest) != 83L || !identical(manifest$source_page, 0:82) ||
    anyNA(manifest$source_file) || any(manifest$source_file == "") ||
    uniqueN(manifest$source_file) != 83L ||
    !identical(manifest$source_file, expected_source_files) ||
    anyNA(manifest$source_url) || any(manifest$source_url == "") ||
    uniqueN(manifest$source_url) != 83L ||
    !identical(manifest$source_url, expected_source_urls) ||
    anyNA(manifest$bytes) || any(manifest$bytes <= 0L) ||
    anyNA(manifest$source_sha256) ||
    any(!grepl("^[0-9a-f]{64}$", manifest$source_sha256))) {
  stop("The NCHFA source manifest changed.", call. = FALSE)
}
for (page in manifest$source_page) {
  path <- sprintf("../input/awarded_projects_page_%s.html", page)
  manifest_row <- manifest[source_page == page]
  if (nrow(manifest_row) != 1L ||
      basename(path) != manifest_row$source_file ||
      file.info(path)$size != manifest_row$bytes ||
      digest(file = path, algo = "sha256") != manifest_row$source_sha256) {
    stop("A frozen NCHFA source page does not match its manifest.", call. = FALSE)
  }
}

expected_source_headers <- c(
  "Project Name", "City", "County", "Total Units", "Type",
  "Target population", "Owner Name", "Contact", "Bond Deal", "Year"
)
source <- rbindlist(lapply(manifest$source_page, function(page) {
  document <- read_html(sprintf("../input/awarded_projects_page_%s.html", page))
  tables <- xml_find_all(document,
    "//table[contains(concat(' ', normalize-space(@class), ' '), ' views-table ')]")
  if (length(tables) != 1L) {
    stop("An NCHFA source page does not contain exactly one source table.",
      call. = FALSE)
  }
  headers <- trimws(xml_text(xml_find_all(tables[[1]], ".//thead/tr/th")))
  if (!identical(headers, expected_source_headers)) {
    stop("An NCHFA source page has unexpected ordered table headers.",
      call. = FALSE)
  }
  rows <- xml_find_all(tables[[1]], ".//tbody/tr")
  cells <- lapply(rows, function(row) trimws(xml_text(xml_find_all(row, ".//td"))))
  if (length(cells) == 0L || any(lengths(cells) != 10L)) {
    stop("An NCHFA source page has an unexpected table schema.", call. = FALSE)
  }
  data.table(
    source_page = page,
    source_row_number_page = seq_along(cells),
    source_development_name = vapply(cells, `[`, character(1), 1L),
    source_city = vapply(cells, `[`, character(1), 2L),
    source_county = vapply(cells, `[`, character(1), 3L),
    source_total_units = as.integer(vapply(cells, `[`, character(1), 4L)),
    source_property_type = vapply(cells, `[`, character(1), 5L),
    source_target_population = vapply(cells, `[`, character(1), 6L),
    source_owner_name = vapply(cells, `[`, character(1), 7L),
    source_bond_deal = vapply(cells, `[`, character(1), 9L),
    source_award_year = as.integer(vapply(cells, `[`, character(1), 10L))
  )
}), use.names = TRUE)
source[, `:=`(
  source_record_id = sprintf("nchfa_page_%03d_row_%02d", source_page,
    source_row_number_page),
  source_state = "NC",
  normalized_source_name = normalize_key(source_development_name),
  normalized_source_city = normalize_key(source_city),
  source_url = manifest$source_url[match(source_page, manifest$source_page)],
  source_sha256 = manifest$source_sha256[match(source_page, manifest$source_page)]
)]
if (nrow(source) != 1653L || anyNA(source$source_total_units) ||
    anyNA(source$source_award_year) || any(nchar(source$normalized_source_name) == 0L) ||
    any(nchar(source$normalized_source_city) == 0L)) {
  stop("The frozen NCHFA directory schema or row count changed.", call. = FALSE)
}
require_unique(source, "source_record_id", "NCHFA source records")

questions[, exact_question_name_count := .N, by = normalized_development_name]
source[, exact_source_name_count := .N, by = normalized_source_name]
exact_source_rows <- source[
  normalized_source_name %chin% questions$normalized_development_name &
    exact_source_name_count == 1L
]
exact_question_rows <- match(
  exact_source_rows$normalized_source_name,
  questions[exact_question_name_count == 1L, normalized_development_name]
)
if (anyNA(exact_question_rows) || anyDuplicated(exact_question_rows) ||
    anyDuplicated(exact_source_rows$source_record_id)) {
  stop("The exact screen is not one source record to one question.", call. = FALSE)
}
exact_candidates <- cbind(
  questions[exact_question_name_count == 1L][exact_question_rows, .(
    no_site_review_question_id, development_id, development_name,
    development_city, development_state, normalized_development_city,
    n_units_development
  )],
  exact_source_rows[, .(
    source_record_id, source_page, source_row_number_page,
    source_development_name, source_city, source_county, source_state,
    source_total_units, source_property_type, source_target_population,
    source_owner_name, source_bond_deal, source_award_year, source_url,
    source_sha256
  )]
)
exact_candidates[, `:=`(
  source_state_agrees = development_state == source_state,
  source_city_agrees = normalized_development_city == normalize_key(source_city),
  source_total_units_agree = n_units_development == source_total_units,
  screening_match_type = "exact_normalized_name_unique_on_both_sides",
  review_status = "not_adjudicated",
  geocoding_query_approval = "not_approved"
)]

fuzzy_candidates <- rbindlist(lapply(seq_len(nrow(questions)), function(i) {
  eligible_source <- source[
    source_state == questions$development_state[i] &
      normalized_source_city == questions$normalized_development_city[i] &
      source_total_units == questions$n_units_development[i] &
      normalized_source_name != questions$normalized_development_name[i]
  ]
  if (nrow(eligible_source) == 0L) return(NULL)
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
  if (nrow(eligible_source) == 0L) return(NULL)
  cbind(
    questions[rep(i, nrow(eligible_source)), .(
      no_site_review_question_id, development_id, development_name,
      development_city, development_state, normalized_development_city,
      n_units_development
    )],
    eligible_source[, .(
      source_record_id, source_page, source_row_number_page,
      source_development_name, source_city, source_county, source_state,
      source_total_units, source_property_type, source_target_population,
      source_owner_name, source_bond_deal, source_award_year, source_url,
      source_sha256, name_distance, name_max_length, name_distance_share
    )]
  )
}), fill = TRUE)
if (is.null(fuzzy_candidates) || ncol(fuzzy_candidates) == 0L) {
  fuzzy_candidates <- copy(exact_candidates[0])
}
if (nrow(fuzzy_candidates) > 0L) {
  fuzzy_candidates[, `:=`(
    source_state_agrees = TRUE,
    source_city_agrees = TRUE,
    source_total_units_agree = TRUE,
    screening_match_type = "fuzzy_name_with_exact_nc_city_and_units",
    review_status = "not_adjudicated",
    geocoding_query_approval = "not_approved"
  )]
}

setorder(exact_candidates, development_id, source_record_id)
if (nrow(fuzzy_candidates) > 0L) {
  setorder(fuzzy_candidates, development_id, source_record_id)
}
require_unique(exact_candidates,
  c("development_id", "source_record_id"), "Exact candidates")
if (nrow(fuzzy_candidates) > 0L) {
  require_unique(fuzzy_candidates,
    c("development_id", "source_record_id"), "Fuzzy candidates")
}

exact_counts <- exact_candidates[, .(
  n_nchfa_exact_name_source_records = .N,
  n_nchfa_exact_name_city_agree_source_records = sum(source_city_agrees),
  n_nchfa_exact_name_city_unit_agree_source_records = sum(
    source_city_agrees & source_total_units_agree
  )
), by = no_site_review_question_id]
fuzzy_counts <- fuzzy_candidates[, .(
  n_nchfa_fuzzy_nc_city_unit_source_records = .N
), by = no_site_review_question_id]
questions[exact_counts, names(exact_counts)[-1L] := mget(paste0("i.",
  names(exact_counts)[-1L])), on = "no_site_review_question_id"]
questions[fuzzy_counts, n_nchfa_fuzzy_nc_city_unit_source_records :=
  i.n_nchfa_fuzzy_nc_city_unit_source_records, on = "no_site_review_question_id"]
for (column in grep("^n_nchfa_", names(questions), value = TRUE)) {
  set(questions, which(is.na(questions[[column]])), column, 0L)
}
questions[, `:=`(
  nchfa_source_screen_status =
    "screened_exact_unique_name_and_conservative_fuzzy_nc_city_units_only",
  review_status = "not_adjudicated",
  geocoding_query_approval = "not_approved"
)]
setorder(questions, development_id)

summary <- data.table(
  measure = c(
    "nc_no_site_questions", "nchfa_source_pages", "nchfa_source_records",
    "exact_name_source_records", "exact_name_developments",
    "exact_name_city_agree_source_records",
    "exact_name_city_unit_agree_source_records",
    "fuzzy_nc_city_unit_source_records", "fuzzy_nc_city_unit_developments"
  ),
  value = c(
    nrow(questions), nrow(manifest), nrow(source), nrow(exact_candidates),
    uniqueN(exact_candidates$development_id), sum(exact_candidates$source_city_agrees),
    sum(exact_candidates$source_city_agrees & exact_candidates$source_total_units_agree),
    nrow(fuzzy_candidates), uniqueN(fuzzy_candidates$development_id)
  )
)
expected <- c(
  nc_no_site_questions = 55L, nchfa_source_pages = 83L,
  nchfa_source_records = 1653L, exact_name_source_records = 2L,
  exact_name_developments = 2L,
  exact_name_city_agree_source_records = 1L,
  exact_name_city_unit_agree_source_records = 1L,
  fuzzy_nc_city_unit_source_records = 0L,
  fuzzy_nc_city_unit_developments = 0L
)
observed <- setNames(summary$value, summary$measure)
if (!identical(as.integer(observed[names(expected)]), as.integer(expected))) {
  stop("The NCHFA screening no longer reproduces frozen counts: ",
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

write_parquet(questions, "../output/lihtc_nc_no_site_nchfa_questions.parquet")
write_parquet(exact_candidates,
  "../output/lihtc_nc_no_site_nchfa_exact_source_candidates.parquet"
)
write_parquet(fuzzy_candidates,
  "../output/lihtc_nc_no_site_nchfa_fuzzy_source_candidates.parquet"
)
fwrite(summary, "../output/lihtc_nc_no_site_nchfa_screening_summary.csv")

questions_roundtrip <- as.data.table(read_parquet(
  "../output/lihtc_nc_no_site_nchfa_questions.parquet"
))
exact_roundtrip <- as.data.table(read_parquet(
  "../output/lihtc_nc_no_site_nchfa_exact_source_candidates.parquet"
))
fuzzy_roundtrip <- as.data.table(read_parquet(
  "../output/lihtc_nc_no_site_nchfa_fuzzy_source_candidates.parquet"
))
summary_roundtrip <- fread("../output/lihtc_nc_no_site_nchfa_screening_summary.csv")
if (nrow(questions_roundtrip) != 55L || nrow(exact_roundtrip) != 2L ||
    nrow(fuzzy_roundtrip) != 0L ||
    !identical(summary_roundtrip, summary) ||
    any(questions_roundtrip$review_status != "not_adjudicated") ||
    any(exact_roundtrip$review_status != "not_adjudicated") ||
    any(fuzzy_roundtrip$review_status != "not_adjudicated") ||
    any(questions_roundtrip$geocoding_query_approval != "not_approved") ||
    any(exact_roundtrip$geocoding_query_approval != "not_approved") ||
    any(fuzzy_roundtrip$geocoding_query_approval != "not_approved")) {
  stop("The NCHFA screening outputs failed their round-trip checks.",
    call. = FALSE)
}
