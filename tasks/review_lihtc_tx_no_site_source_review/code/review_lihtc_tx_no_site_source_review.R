# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/review_lihtc_tx_no_site_source_review/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
  library(digest)
})

require_unique <- function(table, columns, label) {
  if (uniqueN(table, by = columns) != nrow(table)) {
    stop(label, " is not unique by ", paste(columns, collapse = ", "),
      call. = FALSE)
  }
}

ledger <- fread("lihtc_tx_no_site_second_read_ledger.csv", na.strings = "")
for (column in names(ledger)) {
  if (is.character(ledger[[column]])) {
    set(ledger, j = column, value = trimws(ledger[[column]]))
    set(ledger, i = which(ledger[[column]] == ""), j = column, value = NA_character_)
  }
}
if (nrow(ledger) != 14L) {
  stop("The Texas second-read ledger must contain exactly 14 rows.", call. = FALSE)
}
require_unique(ledger, "development_id", "Texas second-read ledger")

expected_dispositions <- c(
  address_correlated_candidate_not_applied = 6L,
  conflicting_or_incomplete_physical_site_scope = 6L,
  unresolved_no_qualifying_physical_site_corroboration = 2L
)
observed_dispositions <- ledger[, .N, by = review_disposition]
if (!setequal(observed_dispositions$review_disposition,
      names(expected_dispositions)) ||
    !identical(as.integer(observed_dispositions$N[match(
      names(expected_dispositions), observed_dispositions$review_disposition
    )]), as.integer(expected_dispositions))) {
  stop("The prescribed 6/6/2 review dispositions changed.", call. = FALSE)
}

if (any(!ledger$second_read_provenance %chin% c(
      "frozen_source", "executed_search_no_qualifying_physical_site_corroboration"
    )) ||
    anyNA(ledger$source_locator) || anyNA(ledger$source_statement) ||
    anyNA(ledger$executed_search_url) || anyNA(ledger$executed_search_note) ||
    anyNA(ledger$executed_search_on) ||
    any(!grepl("^https://", ledger$source_locator)) ||
    any(!grepl("^https://", ledger$executed_search_url)) ||
    any(ledger$second_read_provenance == "frozen_source" &
      (is.na(ledger$second_read_source_file) |
        is.na(ledger$second_read_source_url) |
        is.na(ledger$second_read_source_retrieved_on))) ||
    any(ledger$second_read_provenance ==
      "executed_search_no_qualifying_physical_site_corroboration" &
      (!is.na(ledger$second_read_source_file) |
        !is.na(ledger$second_read_source_url) |
        !is.na(ledger$second_read_source_retrieved_on))) ||
    any(ledger$second_read_provenance ==
      "executed_search_no_qualifying_physical_site_corroboration" &
      ledger$source_locator != ledger$executed_search_url) ||
    any(!ledger$site_application_action %chin% "not_applied") ||
    any(!ledger$review_status %chin% "not_adjudicated") ||
    any(!ledger$geocoding_query_approval %chin% "not_approved")) {
  stop("The ledger has incomplete provenance or attempted an application.",
    call. = FALSE)
}

manifest <- fread("../input/tx_no_site_second_reads_2026-08-12_manifest.csv")
expected_raw_files <- c(
  "constitution_court_municipal.html", "floral_gardens_manager.html",
  "guadalupe_crossing_tx_puc.html", "heights_corral_tamuk.pdf",
  "heights_corral_tdhca_2008_log.pdf", "hillsboro_tdhca_2000_log.pdf",
  "hillsboro_tdhca_board_2018.pdf", "justice_park_houston_2012.pdf",
  "justice_park_houston_2024.pdf", "maeghan_pointe_tejas.html",
  "park_ridge_txhf.html", "san_antonio_2020_council.html",
  "sunrise_terrace_manager.html", "tierra_pointe_merced.html"
)
if (nrow(manifest) != 14L || !setequal(manifest$file, expected_raw_files) ||
    uniqueN(manifest$file) != 14L || any(!grepl("^[0-9a-f]{64}$", manifest$sha256)) ||
    anyNA(manifest$url) || anyNA(manifest$retrieved_on)) {
  stop("The Texas second-read manifest does not cover its frozen source bytes.",
    call. = FALSE)
}
observed_hashes <- vapply(expected_raw_files, function(source_file) {
  digest(file = file.path("../input", source_file), algo = "sha256")
}, character(1L))
if (!identical(unname(observed_hashes[manifest$file]), manifest$sha256)) {
  stop("A Texas second-read source file does not match its frozen manifest hash.",
    call. = FALSE)
}

evidence <- fread("lihtc_tx_no_site_second_read_evidence.csv")
if (nrow(evidence) != 13L ||
    anyNA(evidence[, .(development_id, source_file, source_url, retrieved_on,
      source_sha256, source_type, source_claim)]) ||
    any(evidence$source_claim == "")) {
  stop("The source-specific evidence child ledger changed or is incomplete.",
    call. = FALSE)
}
require_unique(evidence, c("development_id", "source_file"),
  "Source-specific evidence child ledger")
if (any(!evidence$development_id %chin% ledger$development_id) ||
    any(!evidence$source_file %chin% manifest$file)) {
  stop("The evidence child ledger contains an unknown development or source.",
    call. = FALSE)
}

evidence_manifest <- merge(
  evidence,
  manifest[, .(source_file = file, manifest_url = url,
    manifest_retrieved_on = retrieved_on, manifest_sha256 = sha256,
    manifest_source_type = source_type)],
  by = "source_file", all.x = TRUE, sort = FALSE
)
if (nrow(evidence_manifest) != 13L ||
    anyNA(evidence_manifest$manifest_sha256) ||
    any(evidence_manifest$source_url != evidence_manifest$manifest_url) ||
    any(evidence_manifest$retrieved_on !=
      evidence_manifest$manifest_retrieved_on) ||
    any(evidence_manifest$source_sha256 != evidence_manifest$manifest_sha256) ||
    any(evidence_manifest$source_type !=
      evidence_manifest$manifest_source_type)) {
  stop("Evidence files, URLs, dates, hashes, or types do not match the manifest.",
    call. = FALSE)
}

frozen_evidence <- ledger[second_read_provenance == "frozen_source"]
matched_evidence <- merge(
  frozen_evidence,
  evidence_manifest[, .(development_id,
    second_read_source_file = source_file,
    child_source_url = source_url,
    child_retrieved_on = retrieved_on,
    child_source_sha256 = source_sha256,
    child_source_type = source_type,
    child_source_claim = source_claim)],
  by = c("development_id", "second_read_source_file"),
  all.x = TRUE, sort = FALSE
)
if (nrow(matched_evidence) != nrow(frozen_evidence) ||
    anyNA(matched_evidence$child_source_sha256) ||
    any(matched_evidence$second_read_source_url !=
      matched_evidence$child_source_url) ||
    any(matched_evidence$second_read_source_retrieved_on !=
      matched_evidence$child_retrieved_on) ||
    any(matched_evidence$source_locator != matched_evidence$child_source_url)) {
  stop("Primary source fields do not exactly join to the evidence child ledger.",
    call. = FALSE)
}
evidence_counts <- evidence[, .N, by = development_id]
if (evidence_counts[development_id == "DEV_TXA20130855", N] != 2L ||
    any(evidence_counts[development_id != "DEV_TXA20130855", N] != 1L) ||
    !setequal(evidence_counts$development_id, frozen_evidence$development_id) ||
    any(ledger[second_read_provenance ==
      "executed_search_no_qualifying_physical_site_corroboration",
      development_id] %chin% evidence$development_id) ||
    !setequal(
      evidence[development_id == "DEV_TXA20130855", source_file],
      c("justice_park_houston_2012.pdf", "justice_park_houston_2024.pdf")
    )) {
  stop("The one-to-many Justice Park evidence binding changed.", call. = FALSE)
}
if (any(matched_evidence$child_source_type %chin% c("state-board", "state-program") &
      matched_evidence$independent_address_corroboration) ||
    any(ledger$review_disposition == "address_correlated_candidate_not_applied" &
      ledger$site_application_action != "not_applied")) {
  stop("Same-agency evidence was treated as independent or a candidate was applied.",
    call. = FALSE)
}

exact_candidates <- as.data.table(read_parquet(
  "../input/lihtc_tx_no_site_tdhca_exact_source_candidates.parquet"
))
fuzzy_candidates <- as.data.table(read_parquet(
  "../input/lihtc_tx_no_site_tdhca_fuzzy_source_candidates.parquet"
))
candidates <- rbindlist(list(exact_candidates, fuzzy_candidates), fill = TRUE)
candidates <- candidates[development_id %chin% ledger$development_id]
if (nrow(candidates) != 14L || uniqueN(candidates$development_id) != 14L ||
    !setequal(candidates$development_id, ledger$development_id)) {
  stop("The review ledger does not equal the prescribed TDHCA candidate set.",
    call. = FALSE)
}

validated <- merge(
  ledger,
  candidates[, .(development_id, no_site_review_question_id,
    candidate_development_name = development_name,
    candidate_development_city = development_city,
    candidate_n_units_development = n_units_development,
    candidate_screening_match_type = screening_match_type,
    candidate_tdhca_address = source_project_address,
    source_tdhca_number, source_development_name, source_project_city,
    source_total_units, source_url = source_url, source_sha256 = source_sha256)],
  by = "development_id", all = TRUE, sort = FALSE
)
validated <- merge(
  validated,
  evidence[, .(
    n_bound_evidence_sources = .N,
    bound_evidence_source_files = paste(sort(source_file), collapse = "|")
  ), by = development_id],
  by = "development_id", all.x = TRUE, sort = FALSE
)
validated[is.na(n_bound_evidence_sources), n_bound_evidence_sources := 0L]
if (nrow(validated) != 14L ||
    any(validated$development_name != validated$candidate_development_name) ||
    any(validated$development_city != validated$candidate_development_city) ||
    any(validated$n_units_development != validated$candidate_n_units_development) ||
    any(validated$screening_match_type != validated$candidate_screening_match_type) ||
    any(validated$tdhca_candidate_address != validated$candidate_tdhca_address) ||
    validated[development_id == "DEV_TXA20130855",
      n_bound_evidence_sources] != 2L ||
    any(validated[second_read_provenance == "frozen_source" &
      development_id != "DEV_TXA20130855", n_bound_evidence_sources] != 1L) ||
    any(validated[second_read_provenance != "frozen_source",
      n_bound_evidence_sources] != 0L)) {
  stop("The ledger did not preserve the exact TDHCA candidate fields.", call. = FALSE)
}
setorder(validated, development_id)
write_parquet(validated,
  "../output/lihtc_tx_no_site_second_read_validated.parquet")

roundtrip <- as.data.table(read_parquet(
  "../output/lihtc_tx_no_site_second_read_validated.parquet"
))
if (nrow(roundtrip) != 14L ||
    any(roundtrip$site_application_action != "not_applied") ||
    any(roundtrip$review_status != "not_adjudicated") ||
    any(roundtrip$geocoding_query_approval != "not_approved")) {
  stop("The validated Texas ledger failed its round-trip checks.", call. = FALSE)
}
