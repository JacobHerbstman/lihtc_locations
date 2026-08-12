# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/audit_lihtc_no_site_source_review_progress/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
})

progress <- as.data.table(read_parquet(
  "../input/lihtc_no_site_development_questions.parquet"
))[, .(
  no_site_review_question_id, development_id, development_name,
  development_city, development_state, first_pis_year,
  n_units_development, li_units_development
)]
if (nrow(progress) != 797L || uniqueN(progress$development_id) != 797L ||
    uniqueN(progress$no_site_review_question_id) != 797L) {
  stop("The canonical no-site universe changed.", call. = FALSE)
}
progress[, `:=`(
  source_review_route = "no_state_source_task",
  source_review_stage = "not_started",
  source_candidate_count = 0L,
  second_read_disposition = NA_character_,
  source_access_status = "no_state_source_task",
  site_application_action = "not_applied",
  review_status = "not_adjudicated",
  geocoding_query_approval = "not_approved"
)]

pa <- as.data.table(read_parquet(
  "../input/lihtc_pa_no_site_phfa_questions.parquet"
))
pa_review <- as.data.table(read_parquet(
  "../input/lihtc_pa_no_site_numeric_candidate_second_read_validated.parquet"
))
tx <- as.data.table(read_parquet(
  "../input/lihtc_tx_no_site_tdhca_questions.parquet"
))
tx_review <- as.data.table(read_parquet(
  "../input/lihtc_tx_no_site_second_read_validated.parquet"
))
nc <- as.data.table(read_parquet(
  "../input/lihtc_nc_no_site_nchfa_questions.parquet"
))
ga <- as.data.table(read_parquet(
  "../input/lihtc_ga_no_site_dca_source_access_blocker.parquet"
))
me <- as.data.table(read_parquet(
  "../input/lihtc_me_no_site_mainehousing_questions.parquet"
))
indiana <- as.data.table(read_parquet(
  "../input/lihtc_in_no_site_ihcda_source_access_blocker.parquet"
))

if (nrow(pa) != 120L || nrow(pa_review) != 17L || nrow(tx) != 91L ||
    nrow(tx_review) != 14L || nrow(nc) != 55L || nrow(ga) != 41L ||
    nrow(me) != 41L || nrow(indiana) != 40L ||
    anyDuplicated(pa$development_id) || anyDuplicated(pa_review$development_id) ||
    anyDuplicated(tx$development_id) || anyDuplicated(tx_review$development_id) ||
    anyDuplicated(nc$development_id) || anyDuplicated(ga$development_id) ||
    anyDuplicated(me$development_id) || anyDuplicated(indiana$development_id)) {
  stop("A state no-site source-review universe changed.", call. = FALSE)
}

if (!fsetequal(pa[, .(no_site_review_question_id, development_id)],
      progress[development_state == "PA",
        .(no_site_review_question_id, development_id)]) ||
    !fsetequal(tx[, .(no_site_review_question_id, development_id)],
      progress[development_state == "TX",
        .(no_site_review_question_id, development_id)]) ||
    !fsetequal(nc[, .(no_site_review_question_id, development_id)],
      progress[development_state == "NC",
        .(no_site_review_question_id, development_id)]) ||
    !fsetequal(ga[, .(no_site_review_question_id, development_id)],
      progress[development_state == "GA",
        .(no_site_review_question_id, development_id)]) ||
    !fsetequal(me[, .(no_site_review_question_id, development_id)],
      progress[development_state == "ME",
        .(no_site_review_question_id, development_id)]) ||
    !fsetequal(indiana[, .(no_site_review_question_id, development_id)],
      progress[development_state == "IN",
        .(no_site_review_question_id, development_id)])) {
  stop("A state source screen does not equal its canonical state universe.",
    call. = FALSE)
}

screened_development_ids <- c(
  pa$development_id, tx$development_id, nc$development_id,
  ga$development_id, me$development_id, indiana$development_id
)
if (length(screened_development_ids) != 388L ||
    uniqueN(screened_development_ids) != 388L) {
  stop("The six state source-screen universes are not disjoint.",
    call. = FALSE)
}

pa_candidate_pairs <- pa[
  n_phfa_numeric_city_total_street_candidate_source_rows > 0L,
  .(no_site_review_question_id, development_id)
]
tx_candidate_pairs <- tx[
  n_tdhca_exact_name_city_unit_agree_source_rows +
    n_tdhca_fuzzy_city_unit_source_rows > 0L,
  .(no_site_review_question_id, development_id)
]
if (!fsetequal(pa_review[, .(no_site_review_question_id, development_id)],
      pa_candidate_pairs) ||
    !fsetequal(tx_review[, .(no_site_review_question_id, development_id)],
      tx_candidate_pairs)) {
  stop("A second-read ledger does not equal its screened candidate subset.",
    call. = FALSE)
}

if (any(pa$review_status != "not_adjudicated") ||
    any(pa$geocoding_query_approval != "not_approved") ||
    any(tx$review_status != "not_adjudicated") ||
    any(tx$geocoding_query_approval != "not_approved") ||
    any(nc$review_status != "not_adjudicated") ||
    any(nc$geocoding_query_approval != "not_approved") ||
    any(ga$review_status != "not_adjudicated") ||
    any(ga$geocoding_query_approval != "not_approved") ||
    any(me$review_status != "not_adjudicated") ||
    any(me$geocoding_query_approval != "not_approved") ||
    any(indiana$review_status != "not_adjudicated") ||
    any(indiana$geocoding_query_approval != "not_approved") ||
    any(pa_review$site_application_action != "not_applied") ||
    any(pa_review$candidate_acceptance_status != "not_accepted") ||
    any(pa_review$review_status != "not_adjudicated") ||
    any(pa_review$geocoding_query_approval != "not_approved") ||
    any(tx_review$site_application_action != "not_applied") ||
    any(tx_review$review_status != "not_adjudicated") ||
    any(tx_review$geocoding_query_approval != "not_approved")) {
  stop("A source screen or second read is applied, accepted, or approved.",
    call. = FALSE)
}

progress[development_id %chin% pa$development_id, `:=`(
  source_review_route = "pennsylvania_phfa",
  source_review_stage = "official_first_source_screen_only",
  source_candidate_count = pa$n_phfa_numeric_city_total_street_candidate_source_rows[
    match(development_id, pa$development_id)
  ],
  source_access_status = "official_bulk_source_screened"
)]
progress[development_id %chin% pa_review$development_id, `:=`(
  source_review_stage = "candidate_second_read_complete_not_adjudicated",
  second_read_disposition = pa_review$review_disposition[
    match(development_id, pa_review$development_id)
  ],
  source_access_status = "second_read_recorded_candidate_not_accepted"
)]

progress[development_id %chin% tx$development_id, `:=`(
  source_review_route = "texas_tdhca",
  source_review_stage = "official_first_source_screen_only",
  source_candidate_count =
    tx$n_tdhca_exact_name_city_unit_agree_source_rows[
      match(development_id, tx$development_id)
    ] + tx$n_tdhca_fuzzy_city_unit_source_rows[
      match(development_id, tx$development_id)
    ],
  source_access_status = "official_bulk_source_screened"
)]
progress[development_id %chin% tx_review$development_id, `:=`(
  source_review_stage = "candidate_second_read_complete_not_adjudicated",
  second_read_disposition = tx_review$review_disposition[
    match(development_id, tx_review$development_id)
  ],
  source_access_status = "second_read_recorded_candidate_not_accepted"
)]

progress[development_id %chin% nc$development_id, `:=`(
  source_review_route = "north_carolina_nchfa",
  source_review_stage = "official_identity_screen_no_address_source",
  source_candidate_count = nc$n_nchfa_exact_name_source_records[
    match(development_id, nc$development_id)
  ],
  source_access_status = "official_directory_screened_no_street_field"
)]
progress[development_id %chin% ga$development_id, `:=`(
  source_review_route = "georgia_dca",
  source_review_stage = "official_source_access_blocked",
  source_access_status = ga$source_access_status[
    match(development_id, ga$development_id)
  ]
)]
progress[development_id %chin% me$development_id, `:=`(
  source_review_route = "maine_mainehousing",
  source_review_stage = "official_first_source_screen_only",
  source_candidate_count =
    me$n_mainehousing_numeric_city_total_street_candidate_source_rows[
      match(development_id, me$development_id)
    ],
  source_access_status = "official_subsidized_directory_screened"
)]
progress[development_id %chin% indiana$development_id, `:=`(
  source_review_route = "indiana_ihcda",
  source_review_stage = "official_source_access_blocked",
  source_access_status = indiana$source_access_status[
    match(development_id, indiana$development_id)
  ]
)]

progress[, progress_category := fifelse(
  source_review_stage == "candidate_second_read_complete_not_adjudicated",
  paste(source_review_route, second_read_disposition, sep = "__"),
  paste(source_review_route, source_review_stage, sep = "__")
)]
counts <- progress[, .N, by = progress_category][order(progress_category)]
expected_counts <- c(
  "georgia_dca__official_source_access_blocked" = 41L,
  "indiana_ihcda__official_source_access_blocked" = 40L,
  "maine_mainehousing__official_first_source_screen_only" = 41L,
  "no_state_source_task__not_started" = 409L,
  "north_carolina_nchfa__official_identity_screen_no_address_source" = 55L,
  "pennsylvania_phfa__conflicting_or_incomplete_physical_site_scope" = 6L,
  "pennsylvania_phfa__corroborated_candidate_address_not_applied_or_accepted" = 3L,
  "pennsylvania_phfa__official_first_source_screen_only" = 103L,
  "pennsylvania_phfa__unresolved_no_qualifying_physical_site_corroboration" = 8L,
  "texas_tdhca__address_correlated_candidate_not_applied" = 6L,
  "texas_tdhca__conflicting_or_incomplete_physical_site_scope" = 6L,
  "texas_tdhca__official_first_source_screen_only" = 77L,
  "texas_tdhca__unresolved_no_qualifying_physical_site_corroboration" = 2L
)
observed_counts <- setNames(counts$N, counts$progress_category)
if (!setequal(names(observed_counts), names(expected_counts)) ||
    !identical(as.integer(observed_counts[names(expected_counts)]),
      as.integer(expected_counts)) ||
    sum(counts$N) != 797L ||
    any(progress$site_application_action != "not_applied") ||
    any(progress$review_status != "not_adjudicated") ||
    any(progress$geocoding_query_approval != "not_approved")) {
  stop("The no-site source-review progress partition changed.", call. = FALSE)
}

setorder(progress, development_id)
write_parquet(progress,
  "../output/lihtc_no_site_source_review_progress.parquet")
fwrite(counts, "../output/lihtc_no_site_source_review_progress_counts.csv")

progress_roundtrip <- as.data.table(read_parquet(
  "../output/lihtc_no_site_source_review_progress.parquet"
))
counts_roundtrip <- fread(
  "../output/lihtc_no_site_source_review_progress_counts.csv"
)
if (!identical(progress_roundtrip, progress) ||
    !identical(counts_roundtrip, counts)) {
  stop("The no-site source-review progress outputs failed round-trip checks.",
    call. = FALSE)
}
