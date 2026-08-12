# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/prepare_lihtc_pa_no_site_source_review/code")

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

normalize_name <- function(x) {
  gsub("[^A-Z0-9]", "", toupper(x))
}

county_files <- c(
  "dv_adams.pdf", "dv_allegheny.pdf", "dv_armstrong.pdf", "dv_beaver.pdf",
  "dv_bedford.pdf", "dv_berks.pdf", "dv_blair.pdf", "dv_bradford.pdf",
  "dv_bucks.pdf", "dv_butler.pdf", "dv_cambria.pdf", "dv_cameron.pdf",
  "dv_carbon.pdf", "dv_centre.pdf", "dv_chester.pdf", "dv_clarion.pdf",
  "dv_clearfield.pdf", "dv_clinton.pdf", "dv_columbia.pdf", "dv_crawford.pdf",
  "dv_cumberland.pdf", "dv_dauphin.pdf", "dv_delaware.pdf", "dv_elk.pdf",
  "dv_erie.pdf", "dv_fayette.pdf", "dv_forest.pdf", "dv_franklin.pdf",
  "dv_fulton.pdf", "dv_greene.pdf", "dv_huntingdon.pdf", "dv_indiana.pdf",
  "dv_jefferson.pdf", "dv_juniata.pdf", "dv_lackawanna.pdf", "dv_lancaster.pdf",
  "dv_lawrence.pdf", "dv_lebanon.pdf", "dv_lehigh.pdf", "dv_luzerne.pdf",
  "dv_lycoming.pdf", "dv_mcKean.pdf", "dv_mercer.pdf", "dv_mifflin.pdf",
  "dv_monroe.pdf", "dv_montgomery.pdf", "dv_montour.pdf", "dv_northumberland.pdf",
  "dv_perry.pdf", "dv_philadelphia.pdf", "dv_pike.pdf", "dv_potter.pdf",
  "dv_schuylkill.pdf", "dv_snyder.pdf", "dv_somerset.pdf", "dv_sullivan.pdf",
  "dv_susquehanna.pdf", "dv_tioga.pdf", "dv_union.pdf", "dv_venango.pdf",
  "dv_warren.pdf", "dv_washington.pdf", "dv_wayne.pdf", "dv_westmoreland.pdf",
  "dv_wyoming.pdf", "dv_york.pdf"
)

questions <- as.data.table(read_parquet(
  "../input/lihtc_no_site_development_questions.parquet"
))
if (nrow(questions) != 797L) {
  stop("The final no-site question input changed.", call. = FALSE)
}
require_unique(questions, "no_site_review_question_id", "No-site questions")
require_unique(questions, "development_id", "No-site questions")

questions <- questions[development_state == "PA"]
if (nrow(questions) != 120L ||
    anyNA(questions$development_name) || any(questions$development_name == "") ||
    anyNA(questions$development_city) || any(questions$development_city == "") ||
    anyNA(questions$n_units_development)) {
  stop("The Pennsylvania no-site question universe changed.", call. = FALSE)
}
questions[, normalized_development_name := normalize_name(development_name)]
if (any(nchar(questions$normalized_development_name) == 0L) ||
    uniqueN(questions$development_id) != 120L) {
  stop("Pennsylvania name normalization failed.", call. = FALSE)
}

observed_files <- list.files("../input", pattern = "^dv_.*[.]pdf$")
if (!setequal(observed_files, county_files) || length(observed_files) != 66L ||
    !file.exists("../input/phfa_renters.html")) {
  stop("The frozen PHFA snapshot files changed.", call. = FALSE)
}
manifest <- fread(
  "../input/phfa_rental_housing_inventory_2026-08-12_manifest.sha256",
  header = FALSE, col.names = c("source_sha256", "source_file")
)
expected_snapshot_files <- c(county_files, "phfa_renters.html")
if (nrow(manifest) != 67L || !setequal(manifest$source_file,
      expected_snapshot_files) || uniqueN(manifest$source_file) != 67L ||
    any(!grepl("^[0-9a-f]{64}$", manifest$source_sha256))) {
  stop("The PHFA snapshot manifest is not the expected 67-file inventory.",
    call. = FALSE)
}
observed_hashes <- vapply(expected_snapshot_files, function(source_file) {
  digest(file = file.path("../input", source_file), algo = "sha256")
}, character(1L))
if (!identical(unname(observed_hashes[manifest$source_file]),
      manifest$source_sha256)) {
  stop("A PHFA snapshot file does not match its frozen manifest hash.",
    call. = FALSE)
}

source_lines <- rbindlist(lapply(county_files, function(source_file) {
  pages <- pdf_text(file.path("../input", source_file))
  lines <- unlist(strsplit(pages, "\n", fixed = TRUE), use.names = FALSE)
  data.table(
    source_file = source_file,
    source_url = paste0(
      "https://www.phfa.org/forms/multifamily_inventory/", source_file
    ),
    source_sha256 = digest(
      file = file.path("../input", source_file), algo = "sha256"
    ),
    source_line_number = seq_along(lines),
    source_line = lines,
    source_left_field = trimws(substr(lines, 1L, 75L))
  )
}), use.names = TRUE)

source_lines[, source_property_name_key := normalize_name(source_left_field)]
development_name_keys <- questions$normalized_development_name
property_hits <- source_lines[
  source_property_name_key %chin% development_name_keys &
    nchar(source_property_name_key) > 0L
]

candidates <- rbindlist(lapply(seq_len(nrow(property_hits)), function(i) {
  hit <- property_hits[i]
  question <- questions[
    questions$normalized_development_name == hit$source_property_name_key
  ]
  following <- source_lines[
    source_file == hit$source_file &
      source_line_number > hit$source_line_number &
      source_line_number <= hit$source_line_number + 8L,
    source_left_field
  ]
  locality <- following[
    grepl(", *PA +[0-9]{5}", following, ignore.case = TRUE)
  ][1L]
  non_locality <- following[
    nzchar(following) & !grepl(", *PA +[0-9]{5}", following,
      ignore.case = TRUE)
  ]
  address <- non_locality[1L]
  preceding <- source_lines[
    source_file == hit$source_file &
      source_line_number >= pmax(1L, hit$source_line_number - 8L) &
      source_line_number < hit$source_line_number,
    source_line
  ]
  distribution <- trimws(substr(preceding, 145L, nchar(preceding)))
  distribution <- distribution[grepl("^[0-9]+ +[0-9]+", distribution)]
  distribution <- tail(distribution, 1L)
  total_units <- suppressWarnings(as.integer(sub("^([0-9]+).*", "\\1", distribution)))

  question[, .(
    no_site_review_question_id,
    development_id,
    development_name,
    development_city,
    n_units_development,
    source_file = hit$source_file,
    source_url = hit$source_url,
    source_sha256 = hit$source_sha256,
    source_line_number = hit$source_line_number,
    source_property_name = hit$source_left_field,
    source_address = address,
    source_locality = locality,
    source_total_units = total_units,
    source_distribution_line = distribution,
    source_city_agrees = grepl(
      paste0("^", normalize_name(development_city)),
      normalize_name(locality)
    ),
    source_total_units_agree = !is.na(total_units) &
      total_units == n_units_development,
    source_street_candidate = grepl("^[0-9]+", address),
    review_status = "not_adjudicated",
    geocoding_query_approval = "not_approved"
  )]
}), fill = TRUE)

setorder(candidates, development_id, source_file, source_line_number)
require_unique(candidates,
  c("development_id", "source_file", "source_line_number"),
  "Exact PHFA source candidates"
)

candidate_counts <- candidates[, .(
  n_phfa_exact_name_source_rows = .N,
  n_phfa_exact_name_source_files = uniqueN(source_file),
  n_phfa_exact_name_city_agree_source_rows = sum(source_city_agrees),
  n_phfa_exact_name_city_total_agree_source_rows = sum(
    source_city_agrees & source_total_units_agree
  ),
  n_phfa_numeric_city_total_street_candidate_source_rows = sum(
    source_city_agrees & source_total_units_agree & source_street_candidate
  )
), by = no_site_review_question_id]

questions[candidate_counts,
  c("n_phfa_exact_name_source_rows", "n_phfa_exact_name_source_files",
    "n_phfa_exact_name_city_agree_source_rows",
    "n_phfa_exact_name_city_total_agree_source_rows",
    "n_phfa_numeric_city_total_street_candidate_source_rows") := .(
      i.n_phfa_exact_name_source_rows,
      i.n_phfa_exact_name_source_files,
      i.n_phfa_exact_name_city_agree_source_rows,
      i.n_phfa_exact_name_city_total_agree_source_rows,
      i.n_phfa_numeric_city_total_street_candidate_source_rows
    ),
  on = "no_site_review_question_id"
]
count_columns <- grep("^n_phfa_", names(questions), value = TRUE)
for (column in count_columns) {
  set(questions, which(is.na(questions[[column]])), column, 0L)
}
questions[, `:=`(
  phfa_source_screen_status = "screened_exact_normalized_name_only",
  review_status = "not_adjudicated",
  geocoding_query_approval = "not_approved"
)]
setorder(questions, development_id)

summary <- data.table(
  measure = c(
    "pa_no_site_questions",
    "exact_name_source_rows",
    "exact_name_developments",
    "exact_name_city_agree_developments",
    "exact_name_city_total_agree_developments",
    "numeric_city_total_street_candidate_developments"
  ),
  value = c(
    nrow(questions),
    nrow(candidates),
    uniqueN(candidates$development_id),
    uniqueN(candidates$development_id[candidates$source_city_agrees]),
    uniqueN(candidates$development_id[
      candidates$source_city_agrees & candidates$source_total_units_agree
    ]),
    uniqueN(candidates$development_id[
      candidates$source_city_agrees & candidates$source_total_units_agree &
        candidates$source_street_candidate
    ])
  )
)

expected <- c(
  pa_no_site_questions = 120L,
  exact_name_source_rows = 44L,
  exact_name_developments = 43L,
  exact_name_city_agree_developments = 41L,
  exact_name_city_total_agree_developments = 32L,
  numeric_city_total_street_candidate_developments = 17L
)
observed <- setNames(summary$value, summary$measure)
if (!identical(as.integer(observed[names(expected)]), as.integer(expected))) {
  stop(
    "The exact PHFA parser no longer reproduces the frozen screening counts: ",
    paste(names(expected), observed[names(expected)], expected,
      sep = "=", collapse = "; "),
    call. = FALSE
  )
}

if (any(questions$review_status != "not_adjudicated") ||
    any(questions$geocoding_query_approval != "not_approved") ||
    any(candidates$review_status != "not_adjudicated") ||
    any(candidates$geocoding_query_approval != "not_approved")) {
  stop("The preparation-only decision status failed.", call. = FALSE)
}

write_parquet(questions, "../output/lihtc_pa_no_site_phfa_questions.parquet")
write_parquet(candidates,
  "../output/lihtc_pa_no_site_phfa_exact_source_candidates.parquet"
)
fwrite(summary, "../output/lihtc_pa_no_site_phfa_screening_summary.csv")

questions_roundtrip <- as.data.table(read_parquet(
  "../output/lihtc_pa_no_site_phfa_questions.parquet"
))
candidates_roundtrip <- as.data.table(read_parquet(
  "../output/lihtc_pa_no_site_phfa_exact_source_candidates.parquet"
))
summary_roundtrip <- fread("../output/lihtc_pa_no_site_phfa_screening_summary.csv")
if (nrow(questions_roundtrip) != 120L || nrow(candidates_roundtrip) != 44L ||
    !identical(summary_roundtrip, summary) ||
    any(questions_roundtrip$review_status != "not_adjudicated") ||
    any(candidates_roundtrip$review_status != "not_adjudicated")) {
  stop("The PHFA screening outputs failed their round-trip checks.", call. = FALSE)
}
