# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/review_lihtc_wi_low_income_share/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
})

candidates <- as.data.table(read_parquet(
  "../input/lihtc_wi_low_income_share_candidates.parquet"
))
development <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_unit_scope_adjudicated.parquet"
))
reviews <- fread("wi_low_income_share_reviews.csv", na.strings = "")
reviews[, reviewed_on := as.IDate(reviewed_on)]
reviews[, `:=`(
  official_wheda_reviewed_on = as.IDate(official_wheda_reviewed_on),
  internal_identity_reviewed_on = as.IDate(internal_identity_reviewed_on)
)]

direct_matches <- candidates[
  candidate_evidence == "unique_name_year_total_match",
  .(
    development_id,
    wheda_project_id,
    wheda_low_income_units,
    wheda_total_units,
    wheda_name,
    wheda_address,
    wheda_placed_in_service,
    name_distance,
    candidate_evidence
  )
]
all_development_ids <- development[
  development_state == "WI" &
    !is.na(n_units_development) &
    !is.na(li_units_development) &
    li_units_development / n_units_development < 0.20,
  development_id
]

if (nrow(reviews) != 197L ||
    uniqueN(reviews$development_id) != nrow(reviews) ||
    uniqueN(direct_matches$development_id) != nrow(direct_matches) ||
    nrow(direct_matches) != 170L ||
    !setequal(reviews$development_id, all_development_ids) ||
    any(!reviews$review_action %chin% c(
      "propose_direct_wheda_low_income_value",
      "retain_hud_pending_scope_or_match_review"
    )) ||
    anyNA(reviews$reviewed_on) ||
    any(reviews$reviewed_on != as.IDate("2026-08-12")) ||
    anyNA(reviews[, .(
      official_wheda_reviewer,
      official_wheda_reviewed_on,
      internal_identity_reviewer,
      internal_identity_reviewed_on
    )]) ||
    any(reviews$official_wheda_reviewer ==
      reviews$internal_identity_reviewer) ||
    any(reviews$official_wheda_reviewed_on != as.IDate("2026-08-12")) ||
    any(reviews$internal_identity_reviewed_on != as.IDate("2026-08-12"))) {
  stop("The Wisconsin low-share review ledger is invalid.", call. = FALSE)
}

reviews[direct_matches, `:=`(
  observed_wheda_project_id = i.wheda_project_id,
  observed_wheda_low_income_units = i.wheda_low_income_units,
  observed_wheda_total_units = i.wheda_total_units,
  observed_wheda_name = i.wheda_name,
  observed_wheda_address = i.wheda_address,
  observed_wheda_placed_in_service = i.wheda_placed_in_service,
  observed_name_distance = i.name_distance,
  observed_candidate_evidence = i.candidate_evidence
), on = "development_id"]

direct_reviews <- reviews[
  review_action == "propose_direct_wheda_low_income_value"
]
pending_reviews <- reviews[
  review_action == "retain_hud_pending_scope_or_match_review"
]

if (nrow(direct_reviews) != 169L ||
    nrow(pending_reviews) != 28L ||
    anyNA(direct_reviews[, .(
      observed_wheda_project_id,
      observed_wheda_low_income_units,
      observed_wheda_total_units,
      observed_wheda_name,
      observed_wheda_address,
      observed_wheda_placed_in_service,
      observed_name_distance,
      observed_candidate_evidence
    )]) ||
    any(direct_reviews$wheda_project_id !=
      direct_reviews$observed_wheda_project_id) ||
    any(direct_reviews$proposed_low_income_units !=
      direct_reviews$observed_wheda_low_income_units) ||
    any(direct_reviews$proposed_low_income_units <= 0) ||
    any(direct_reviews$proposed_total_units !=
      direct_reviews$observed_wheda_total_units) ||
    any(direct_reviews$source_url !=
      "https://www.wheda.com/developers-and-property-managers/tax-credits/multifamily-data-library/monitored-htc-projects") ||
    any(direct_reviews$source_file !=
      "wheda_monitored_htc_projects.html") ||
    any(direct_reviews$source_sha256 !=
      "ba00414cf334e76c060d65ca8bcbda9ef6b2f50b260b3bdfca58af9bff2da25c") ||
    any(direct_reviews$official_wheda_record_confirmation !=
      "unique_name_year_total_match") ||
    any(!direct_reviews$internal_identity_address_confirmation %chin% c(
      "matched_development_has_exact_site_address",
      "matched_development_identity_previously_adjudicated_site_address_differs"
    )) ||
    any(pending_reviews$official_wheda_record_confirmation !=
      "wheda_snapshot_searched_no_safe_scope_match") ||
    any(pending_reviews$internal_identity_address_confirmation !=
      "internal_development_and_site_evidence_inspected_no_safe_scope_match") ||
    any(pending_reviews[, !is.na(c(
      wheda_project_id,
      proposed_total_units,
      proposed_low_income_units
    ))])) {
  stop("A Wisconsin review decision is not supported by the source evidence.",
    call. = FALSE)
}

reviews[, low_income_value_application_status := fifelse(
  review_action == "propose_direct_wheda_low_income_value",
  "reviewed_direct_wheda_value_not_applied",
  "unresolved_hud_value_retained"
)]
reviews[, c(
  "observed_wheda_project_id",
  "observed_wheda_low_income_units",
  "observed_wheda_total_units",
  "observed_wheda_name",
  "observed_wheda_address",
  "observed_wheda_placed_in_service",
  "observed_name_distance",
  "observed_candidate_evidence"
) := NULL]
setorder(reviews, development_id)

write_parquet(
  reviews,
  "../output/lihtc_wi_low_income_share_review.parquet",
  compression = "zstd"
)

round_trip_reviews <- as.data.table(read_parquet(
  "../output/lihtc_wi_low_income_share_review.parquet"
))
if (!isTRUE(all.equal(reviews, round_trip_reviews,
  check.attributes = FALSE))) {
  stop("The Wisconsin review Parquet changed on round trip.", call. = FALSE)
}

cat(
  "Recorded ", nrow(direct_reviews),
  " directly supported WHEDA low-income-value proposals and ",
  nrow(pending_reviews), " unresolved records. No value was applied.\n",
  sep = ""
)
