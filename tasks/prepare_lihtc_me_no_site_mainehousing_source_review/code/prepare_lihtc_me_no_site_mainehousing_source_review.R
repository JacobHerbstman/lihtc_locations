# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/prepare_lihtc_me_no_site_mainehousing_source_review/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
  library(digest)
  library(pdftools)
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

source_files <- c(
  "androscoggin.pdf", "aroostook.pdf", "cumberland.pdf", "franklin.pdf",
  "hancock.pdf", "kennebec.pdf", "knox.pdf", "lincoln.pdf", "oxford.pdf",
  "penobscot.pdf", "piscataquis.pdf", "sagadahoc.pdf", "somerset.pdf",
  "waldo.pdf", "washington.pdf", "york.pdf"
)

questions <- as.data.table(read_parquet(
  "../input/lihtc_no_site_development_questions.parquet"
))
if (nrow(questions) != 797L) {
  stop("The final no-site question input changed.", call. = FALSE)
}
require_unique(questions, "no_site_review_question_id", "No-site questions")
require_unique(questions, "development_id", "No-site questions")

questions <- questions[development_state == "ME"]
if (nrow(questions) != 41L ||
    anyNA(questions$development_name) || any(questions$development_name == "") ||
    anyNA(questions$development_city) || any(questions$development_city == "") ||
    anyNA(questions$n_units_development)) {
  stop("The Maine no-site question universe changed.", call. = FALSE)
}
questions[, `:=`(
  normalized_development_name = normalize_key(development_name),
  normalized_development_city = normalize_key(development_city)
)]
if (any(nchar(questions$normalized_development_name) == 0L) ||
    any(nchar(questions$normalized_development_city) == 0L)) {
  stop("Maine question normalization failed.", call. = FALSE)
}
questions[, exact_question_name_count := .N, by = normalized_development_name]

manifest <- fread("../input/source_manifest.csv")
expected_files <- c(source_files, "mainehousing_subsidized_housing.html")
if (nrow(manifest) != 17L || !setequal(manifest$source_file, expected_files) ||
    uniqueN(manifest$source_file) != 17L || anyNA(manifest$source_url) ||
    any(!grepl("^https://www[.]mainehousing[.]org/", manifest$source_url)) ||
    any(manifest$retrieved_on != "2026-08-12") || anyNA(manifest$bytes) ||
    any(manifest$bytes <= 0L) || anyNA(manifest$source_sha256) ||
    any(!grepl("^[0-9a-f]{64}$", manifest$source_sha256))) {
  stop("The MaineHousing source manifest changed.", call. = FALSE)
}
for (source_file in expected_files) {
  current_file <- source_file
  manifest_row <- manifest[source_file == current_file]
  source_path <- file.path("../input", source_file)
  if (nrow(manifest_row) != 1L || !file.exists(source_path) ||
      file.info(source_path)$size != manifest_row$bytes ||
      digest(file = source_path, algo = "sha256") != manifest_row$source_sha256) {
    stop("A frozen MaineHousing source does not match its manifest.",
      call. = FALSE)
  }
}
directory_html <- paste(readLines("../input/mainehousing_subsidized_housing.html",
  warn = FALSE), collapse = "\n")
for (source_file in source_files) {
  current_file <- source_file
  source_url_path <- sub("^https://www[.]mainehousing[.]org", "",
    manifest[source_file == current_file, source_url])
  if (length(source_url_path) != 1L ||
      !grepl(source_url_path, directory_html, fixed = TRUE)) {
    stop("A county-PDF URL is not linked by the frozen MaineHousing page.",
      call. = FALSE)
  }
}

source_lines <- rbindlist(lapply(source_files, function(source_file) {
  pages <- pdf_text(file.path("../input", source_file))
  rbindlist(lapply(seq_along(pages), function(page_number) {
    lines <- strsplit(pages[[page_number]], "\n", fixed = TRUE)[[1L]]
    data.table(
      source_file = source_file,
      source_page_number = page_number,
      source_line_number = seq_along(lines),
      source_line = lines,
      source_trimmed_line = trimws(lines)
    )
  }))
}), use.names = TRUE)
source_lines[, `:=`(
  source_property_name_field = trimws(substr(source_line, 1L, 50L)),
  normalized_source_line = normalize_key(source_trimmed_line)
)]
source_lines[, normalized_source_property_name := normalize_key(
  source_property_name_field
)]
source_lines[, exact_source_name_count := .N,
  by = normalized_source_property_name]
source_lines[, source_url := manifest$source_url[
  match(source_file, manifest$source_file)
]]
source_lines[, source_sha256 := manifest$source_sha256[
  match(source_file, manifest$source_file)
]]

property_hits <- source_lines[
  normalized_source_property_name %chin% questions$normalized_development_name &
    nchar(normalized_source_property_name) > 0L &
    exact_source_name_count == 1L
]

exact_candidates <- rbindlist(lapply(seq_len(nrow(property_hits)), function(i) {
  hit <- property_hits[i]
  question <- questions[
    normalized_development_name == hit$normalized_source_property_name &
      exact_question_name_count == 1L
  ]
  if (nrow(question) != 1L) {
    stop("The exact MaineHousing screen is not one source line to one question.",
      call. = FALSE)
  }
  page_lines <- source_lines[
    source_file == hit$source_file & source_page_number == hit$source_page_number
  ]
  prior <- page_lines[
    source_line_number < hit$source_line_number &
      source_line_number >= pmax(1L, hit$source_line_number - 80L)
  ]
  city_lines <- prior[
    normalized_source_line == question$normalized_development_city
  ]
  source_city <- if (nrow(city_lines) == 0L) NA_character_ else
    city_lines$source_trimmed_line[nrow(city_lines)]
  following <- page_lines[
    source_line_number > hit$source_line_number &
      source_line_number <= hit$source_line_number + 2L,
    trimws(substr(source_line, 1L, 50L))
  ]
  source_address <- following[nzchar(following)][1L]
  source_total_units <- suppressWarnings(as.integer(sub(
    ".*?([0-9]+) +units.*", "\\1", hit$source_trimmed_line,
    ignore.case = TRUE
  )))
  if (!grepl("[0-9]+ +units", hit$source_trimmed_line, ignore.case = TRUE)) {
    source_total_units <- NA_integer_
  }
  question[, .(
    no_site_review_question_id, development_id, development_name,
    development_city, development_state, n_units_development,
    source_file = hit$source_file,
    source_page_number = hit$source_page_number,
    source_line_number = hit$source_line_number,
    source_url = hit$source_url,
    source_sha256 = hit$source_sha256,
    source_property_name = hit$source_property_name_field,
    source_city = source_city,
    source_address = source_address,
    source_total_units = source_total_units,
    source_city_agrees = !is.na(source_city) &
      normalize_key(source_city) == normalized_development_city,
    source_total_units_agree = !is.na(source_total_units) &
      source_total_units == n_units_development,
    source_street_candidate = !is.na(source_address) &
      grepl("^[0-9]+", source_address),
    screening_match_type = "exact_normalized_name",
    review_status = "not_adjudicated",
    geocoding_query_approval = "not_approved"
  )]
}), fill = TRUE)
setorder(exact_candidates, development_id, source_file, source_page_number,
  source_line_number)
require_unique(exact_candidates,
  c("development_id", "source_file", "source_page_number", "source_line_number"),
  "Exact MaineHousing candidates"
)

fuzzy_candidates <- copy(exact_candidates[0])

candidate_counts <- exact_candidates[, .(
  n_mainehousing_exact_name_source_rows = .N,
  n_mainehousing_exact_name_city_agree_source_rows = sum(source_city_agrees),
  n_mainehousing_exact_name_city_total_agree_source_rows = sum(
    source_city_agrees & source_total_units_agree
  ),
  n_mainehousing_numeric_city_total_street_candidate_source_rows = sum(
    source_city_agrees & source_total_units_agree & source_street_candidate
  )
), by = no_site_review_question_id]
questions[candidate_counts,
  c("n_mainehousing_exact_name_source_rows",
    "n_mainehousing_exact_name_city_agree_source_rows",
    "n_mainehousing_exact_name_city_total_agree_source_rows",
    "n_mainehousing_numeric_city_total_street_candidate_source_rows") := .(
      i.n_mainehousing_exact_name_source_rows,
      i.n_mainehousing_exact_name_city_agree_source_rows,
      i.n_mainehousing_exact_name_city_total_agree_source_rows,
      i.n_mainehousing_numeric_city_total_street_candidate_source_rows
    ), on = "no_site_review_question_id"
]
for (column in grep("^n_mainehousing_", names(questions), value = TRUE)) {
  set(questions, which(is.na(questions[[column]])), column, 0L)
}
questions[, `:=`(
  mainehousing_source_screen_status = "screened_exact_normalized_name_only",
  fuzzy_screen_status = "not_run_no_structured_statewide_property_table",
  review_status = "not_adjudicated",
  geocoding_query_approval = "not_approved"
)]
setorder(questions, development_id)

summary <- data.table(
  measure = c(
    "me_no_site_questions", "exact_name_source_rows", "exact_name_developments",
    "exact_name_city_agree_developments", "exact_name_city_total_agree_developments",
    "numeric_city_total_street_candidate_developments", "fuzzy_candidate_rows"
  ),
  value = c(
    nrow(questions), nrow(exact_candidates), uniqueN(exact_candidates$development_id),
    uniqueN(exact_candidates$development_id[exact_candidates$source_city_agrees]),
    uniqueN(exact_candidates$development_id[
      exact_candidates$source_city_agrees & exact_candidates$source_total_units_agree
    ]),
    uniqueN(exact_candidates$development_id[
      exact_candidates$source_city_agrees & exact_candidates$source_total_units_agree &
        exact_candidates$source_street_candidate
    ]),
    nrow(fuzzy_candidates)
  )
)
if (summary[measure == "me_no_site_questions", value] != 41L ||
    !isTRUE(all.equal(summary$value, c(41, 22, 22, 16, 14, 12, 0))) ||
    any(questions$review_status != "not_adjudicated") ||
    any(questions$geocoding_query_approval != "not_approved") ||
    any(exact_candidates$review_status != "not_adjudicated") ||
    any(exact_candidates$geocoding_query_approval != "not_approved")) {
  stop("MaineHousing screening status validation failed: ",
    paste(summary$value, collapse = ","), call. = FALSE)
}

write_parquet(questions, "../output/lihtc_me_no_site_mainehousing_questions.parquet")
write_parquet(exact_candidates,
  "../output/lihtc_me_no_site_mainehousing_exact_source_candidates.parquet")
write_parquet(fuzzy_candidates,
  "../output/lihtc_me_no_site_mainehousing_fuzzy_source_candidates.parquet")
fwrite(summary, "../output/lihtc_me_no_site_mainehousing_screening_summary.csv")

questions_check <- as.data.table(read_parquet(
  "../output/lihtc_me_no_site_mainehousing_questions.parquet"
))
exact_check <- as.data.table(read_parquet(
  "../output/lihtc_me_no_site_mainehousing_exact_source_candidates.parquet"
))
fuzzy_check <- as.data.table(read_parquet(
  "../output/lihtc_me_no_site_mainehousing_fuzzy_source_candidates.parquet"
))
summary_check <- fread("../output/lihtc_me_no_site_mainehousing_screening_summary.csv")
if (nrow(questions_check) != 41L || nrow(exact_check) != 22L ||
    nrow(fuzzy_check) != 0L ||
    !isTRUE(all.equal(summary_check$measure, summary$measure)) ||
    !isTRUE(all.equal(summary_check$value, summary$value)) ||
    any(questions_check$review_status != "not_adjudicated") ||
    any(questions_check$geocoding_query_approval != "not_approved") ||
    any(exact_check$review_status != "not_adjudicated") ||
    any(exact_check$geocoding_query_approval != "not_approved") ||
    any(fuzzy_check$review_status != "not_adjudicated") ||
    any(fuzzy_check$geocoding_query_approval != "not_approved")) {
  stop("MaineHousing screening output roundtrip validation failed.",
    call. = FALSE)
}
