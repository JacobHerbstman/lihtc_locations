# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/review_lihtc_pa_no_site_source_review/code")

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

ledger <- fread("lihtc_pa_no_site_numeric_candidate_second_read_ledger.csv",
  na.strings = ""
)
if (nrow(ledger) != 17L) {
  stop("The second-read ledger must contain exactly 17 rows.", call. = FALSE)
}
require_unique(ledger, "development_id", "Second-read ledger")

expected_dispositions <- c(
  corroborated_candidate_address_not_applied_or_accepted = 3L,
  conflicting_or_incomplete_physical_site_scope = 6L,
  unresolved_no_qualifying_physical_site_corroboration = 8L
)
observed_dispositions <- ledger[, .N, by = review_disposition]
if (!setequal(observed_dispositions$review_disposition,
      names(expected_dispositions)) ||
    !identical(
      as.integer(observed_dispositions$N[match(
        names(expected_dispositions), observed_dispositions$review_disposition
      )]),
      as.integer(expected_dispositions)
    )) {
  stop("The prescribed 3/6/8 review dispositions changed.", call. = FALSE)
}

expected_disposition_ids <- list(
  corroborated_candidate_address_not_applied_or_accepted = c(
    "DEV_PAA20090100", "DEV_PAA20090110", "DEV_PAA20109146"
  ),
  conflicting_or_incomplete_physical_site_scope = c(
    "DEV_PAA00000165", "DEV_PAA00000175", "DEV_PAA00000207",
    "DEV_PAA00000262", "DEV_PAA19900320", "DEV_PAA20080105"
  ),
  unresolved_no_qualifying_physical_site_corroboration = c(
    "DEV_PAA00000059", "DEV_PAA00000150", "DEV_PAA19890665",
    "DEV_PAA19900315", "DEV_PAA19930135", "DEV_PAA19930180",
    "DEV_PAA20120020", "DEV_PAA20120070"
  )
)
for (disposition in names(expected_disposition_ids)) {
  if (!setequal(
      ledger[review_disposition == disposition, development_id],
      expected_disposition_ids[[disposition]]
    )) {
    stop("The prescribed development assignments changed for ", disposition,
      ".", call. = FALSE)
  }
}

text_columns <- c(
  "second_read_evidence_statement", "second_read_evidence_locator",
  "reviewed_on", "review_reason"
)
if (any(vapply(ledger[, ..text_columns], function(column) {
      anyNA(column) || any(trimws(column) == "")
    }, logical(1L))) ||
    any(!grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", ledger$reviewed_on)) ||
    any(ledger$reviewed_on != "2026-08-12") ||
    any(!ledger$second_read_provenance %chin% c(
      "frozen_source",
      "executed_search_no_qualifying_physical_site_corroboration"
    ))) {
  stop("The second-read ledger has incomplete evidence text or review dates.",
    call. = FALSE)
}

frozen_rows <- ledger[second_read_provenance == "frozen_source"]
search_rows <- ledger[
  second_read_provenance ==
    "executed_search_no_qualifying_physical_site_corroboration"
]
if (nrow(frozen_rows) != 11L || nrow(search_rows) != 6L ||
    anyNA(frozen_rows$second_read_source_file) ||
    anyNA(frozen_rows$second_read_source_url) ||
    anyNA(frozen_rows$second_read_source_sha256) ||
    any(!grepl("^https://", frozen_rows$second_read_source_url)) ||
    any(!grepl("^[0-9a-f]{64}$", frozen_rows$second_read_source_sha256)) ||
    any(!is.na(frozen_rows$executed_search_url)) ||
    any(!is.na(frozen_rows$executed_search_notes)) ||
    any(!is.na(search_rows$second_read_source_file)) ||
    any(!is.na(search_rows$second_read_source_url)) ||
    any(!is.na(search_rows$second_read_source_sha256)) ||
    anyNA(search_rows$executed_search_url) ||
    any(!grepl("^https://", search_rows$executed_search_url)) ||
    anyNA(search_rows$executed_search_notes) ||
    any(trimws(search_rows$executed_search_notes) == "") ||
    any(search_rows$review_disposition !=
      "unresolved_no_qualifying_physical_site_corroboration")) {
  stop("Frozen-source or executed-search provenance is incomplete.",
    call. = FALSE)
}

manifest <- fread(
  "../input/pa_no_site_second_reads_2026-08-12_source_manifest.csv"
)
byte_manifest <- fread(
  "../input/pa_no_site_second_reads_2026-08-12_manifest.sha256",
  header = FALSE, col.names = c("sha256", "source_file")
)
if (digest(
      file = "../input/pa_no_site_second_reads_2026-08-12_source_manifest.csv",
      algo = "sha256"
    ) != "9ebb455aa4633016e5469d30193a75bd653287212277dbf88dd82cec9ff7ff24" ||
    digest(
      file = "../input/pa_no_site_second_reads_2026-08-12_manifest.sha256",
      algo = "sha256"
    ) != "22b237ed8779beac72d8c76c21cd6abd1c82136be7bb113f64e852fb94b3dbcf") {
  stop("A source-manifest byte snapshot changed.", call. = FALSE)
}
expected_raw_files <- c(
  "chambersburg_townhomes.html", "community_ventures_projects.html",
  "fayette_housing_needs.pdf", "hill_com_fire_publicsource.html",
  "negley_neighbors_hunt.html", "pha_family_developments.html",
  "phfa_newport_2006.pdf", "philadelphia_inventory_2019.pdf",
  "surrey_hill.html", "towns_governors_contact.html"
)
if (nrow(manifest) != 10L || nrow(byte_manifest) != 10L ||
    !setequal(manifest$source_file, expected_raw_files) ||
    !setequal(byte_manifest$source_file, expected_raw_files) ||
    uniqueN(manifest$source_file) != 10L ||
    uniqueN(byte_manifest$source_file) != 10L ||
    any(!grepl("^https://", manifest$original_url)) ||
    any(as.character(manifest$retrieved_on) != "2026-08-12") ||
    any(!grepl("^[0-9a-f]{64}$", manifest$sha256)) ||
    any(!grepl("^[0-9a-f]{64}$", byte_manifest$sha256))) {
  stop("The structured or byte source manifest changed.", call. = FALSE)
}
require_unique(manifest, "source_file", "Structured source manifest")
require_unique(byte_manifest, "source_file", "Byte source manifest")

manifest_comparison <- merge(
  manifest,
  byte_manifest,
  by = "source_file", all = TRUE, sort = FALSE,
  suffixes = c("_structured", "_byte")
)
if (nrow(manifest_comparison) != 10L ||
    anyNA(manifest_comparison$sha256_structured) ||
    anyNA(manifest_comparison$sha256_byte) ||
    any(manifest_comparison$sha256_structured !=
      manifest_comparison$sha256_byte)) {
  stop("The structured and byte source manifests disagree.", call. = FALSE)
}

observed_hashes <- vapply(expected_raw_files, function(source_file) {
  digest(file = file.path("../input", source_file), algo = "sha256")
}, character(1L))
if (!identical(unname(observed_hashes[manifest$source_file]),
      manifest$sha256)) {
  stop("A second-read source file does not match its frozen manifest hash.",
    call. = FALSE)
}

frozen_source_validation <- merge(
  frozen_rows,
  manifest,
  by.x = c(
    "second_read_source_file", "second_read_source_url",
    "second_read_source_sha256"
  ),
  by.y = c("source_file", "original_url", "sha256"),
  all.x = TRUE, sort = FALSE
)
if (nrow(frozen_source_validation) != nrow(frozen_rows) ||
    anyNA(frozen_source_validation$retrieved_on)) {
  stop("A frozen ledger row does not join exactly to file, URL, and SHA-256.",
    call. = FALSE)
}

candidates <- as.data.table(read_parquet(
  "../input/lihtc_pa_no_site_phfa_exact_source_candidates.parquet"
))
candidates <- candidates[
  source_city_agrees & source_total_units_agree & source_street_candidate
]
if (nrow(candidates) != 17L || uniqueN(candidates$development_id) != 17L) {
  stop("The PHFA numeric candidate universe changed.", call. = FALSE)
}
require_unique(candidates, "development_id", "PHFA numeric candidates")
if (!setequal(ledger$development_id, candidates$development_id)) {
  stop("The review ledger and PHFA numeric candidate universe disagree.",
    call. = FALSE)
}
setorder(candidates, development_id)
candidate_signature_rows <- do.call(paste, c(
  candidates[, .(
    development_id, development_name, development_city,
    n_units_development, source_address, source_locality,
    source_total_units, source_file, source_sha256
  )],
  sep = "|"
))
candidate_signature <- digest(
  paste(candidate_signature_rows, collapse = "\n"),
  algo = "sha256", serialize = FALSE
)
if (candidate_signature !=
    "1e4b7f6019a704db27b513d25959cbb390bda725c92e00315805698db2dcec8e") {
  stop("The exact 17-row PHFA candidate fields changed.", call. = FALSE)
}

validated <- merge(
  ledger,
  candidates[, .(
    development_id,
    no_site_review_question_id,
    development_name,
    development_city,
    n_units_development,
    phfa_candidate_address = source_address,
    phfa_candidate_locality = source_locality,
    phfa_candidate_total_units = source_total_units,
    phfa_source_file = source_file,
    phfa_source_url = source_url,
    phfa_source_sha256 = source_sha256
  )],
  by = "development_id", all = TRUE, sort = FALSE
)
if (nrow(validated) != 17L || anyNA(validated$review_disposition) ||
    anyNA(validated$phfa_candidate_address) ||
    anyNA(validated$phfa_source_sha256)) {
  stop("The validated review ledger did not preserve all candidate fields.",
    call. = FALSE)
}
validated[, `:=`(
  site_application_action = "not_applied",
  candidate_acceptance_status = "not_accepted",
  review_status = "not_adjudicated",
  geocoding_query_approval = "not_approved"
)]
setorder(validated, development_id)
if (any(validated$site_application_action != "not_applied") ||
    any(validated$candidate_acceptance_status != "not_accepted") ||
    any(validated$review_status != "not_adjudicated") ||
    any(validated$geocoding_query_approval != "not_approved")) {
  stop("The review task attempted to apply or approve a candidate.", call. = FALSE)
}

write_parquet(validated,
  "../output/lihtc_pa_no_site_numeric_candidate_second_read_validated.parquet"
)

validated_roundtrip <- as.data.table(read_parquet(
  "../output/lihtc_pa_no_site_numeric_candidate_second_read_validated.parquet"
))
if (nrow(validated_roundtrip) != 17L ||
    !identical(validated_roundtrip$development_id, validated$development_id) ||
    any(validated_roundtrip$site_application_action != "not_applied") ||
    any(validated_roundtrip$candidate_acceptance_status != "not_accepted") ||
    any(validated_roundtrip$review_status != "not_adjudicated") ||
    any(validated_roundtrip$geocoding_query_approval != "not_approved")) {
  stop("The validated second-read output failed its round-trip checks.",
    call. = FALSE)
}
