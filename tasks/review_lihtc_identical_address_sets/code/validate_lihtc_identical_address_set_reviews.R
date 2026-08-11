# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/review_lihtc_identical_address_sets/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
})

format_markdown_table <- function(table) {
  header <- paste0("| ", paste(names(table), collapse = " | "), " |")
  divider <- paste0(
    "| ", paste(rep("---", ncol(table)), collapse = " | "), " |"
  )
  rows <- apply(table, 1L, function(row) {
    paste0("| ", paste(row, collapse = " | "), " |")
  })
  c(header, divider, rows)
}

reviews <- fread(
  "lihtc_identical_address_set_reviews.csv",
  na.strings = ""
)
groups <- as.data.table(read_parquet(
  "../input/lihtc_identical_address_set_groups.parquet"
))
members <- as.data.table(read_parquet(
  "../input/lihtc_identical_address_set_members.parquet"
))

excluded_address_sets <- c("IAS0670", "IAS0687")
review_groups <- groups[
  group_review_status == "all_unresolved" &
    n_addresses >= 2L &
    !identical_address_set_id %chin% excluded_address_sets
]
review_members <- members[
  identical_address_set_id %chin% review_groups$identical_address_set_id
]

if (nrow(reviews) != 98L ||
    nrow(review_groups) != 98L ||
    nrow(review_members) != 199L ||
    uniqueN(reviews$review_question_id) != nrow(reviews) ||
    uniqueN(reviews$identical_address_set_id) != nrow(reviews) ||
    !setequal(
      reviews$identical_address_set_id,
      review_groups$identical_address_set_id
    ) ||
    any(reviews$identical_address_set_id %chin% excluded_address_sets)) {
  stop("The committed ledger does not cover the 98-group queue exactly.",
    call. = FALSE)
}

setorder(review_groups, identical_address_set_id)
review_groups[, expected_review_question_id := sprintf(
  "IASR_%03d",
  seq_len(.N)
)]
review_groups[reviews, reviewed_question_id := i.review_question_id,
  on = "identical_address_set_id"]
if (review_groups[
      expected_review_question_id != reviewed_question_id,
      .N
    ] > 0L) {
  stop("A review question ID no longer matches the frozen group order.",
    call. = FALSE)
}

required_fields <- c(
  "internal_identity_decision", "internal_reason_code", "internal_notes",
  "internal_reviewed_on", "external_identity_decision",
  "external_search_engine", "external_search_url", "external_source_title",
  "external_source_type", "external_source_url", "external_notes",
  "external_reviewed_on", "final_identity_decision", "final_reason_code",
  "address_set_assessment", "final_notes", "final_reviewed_on",
  "shared_geocoding_query_decision", "source_rows_changed"
)
if (anyNA(reviews[, ..required_fields]) ||
    any(vapply(
      reviews[, ..required_fields],
      function(value) any(as.character(value) == ""),
      logical(1L)
    ))) {
  stop("A required review field is empty.", call. = FALSE)
}

source_urls <- trimws(unlist(strsplit(
  reviews$external_source_url,
  "|",
  fixed = TRUE
)))
valid_decisions <- c("merge_all", "retain_each")
valid_address_assessments <- c(
  "consistent_with_identity_decision",
  "shared_campus_distinct_components",
  "copied_across_distinct_developments",
  "administrative_or_parcel_descriptions",
  "contains_unrelated_addresses"
)
if (!all(reviews$internal_identity_decision %chin% valid_decisions) ||
    !all(reviews$external_identity_decision %chin% valid_decisions) ||
    !all(reviews$final_identity_decision %chin% valid_decisions) ||
    !all(reviews$internal_identity_decision ==
      reviews$external_identity_decision) ||
    !all(reviews$external_identity_decision ==
      reviews$final_identity_decision) ||
    !all(reviews$address_set_assessment %chin%
      valid_address_assessments) ||
    !all(reviews$external_search_engine == "Google") ||
    !all(grepl(
      "^https://www[.]google[.]com/search[?]q=",
      reviews$external_search_url
    )) ||
    !all(grepl("^https://", source_urls)) ||
    any(grepl("google.com/search", source_urls, fixed = TRUE)) ||
    any(reviews$shared_geocoding_query_decision != "not_approved") ||
    any(reviews$source_rows_changed)) {
  stop("A review decision, source, or safety field is invalid.",
    call. = FALSE)
}

date_fields <- c(
  "internal_reviewed_on", "external_reviewed_on", "final_reviewed_on"
)
reviews[, (date_fields) := lapply(.SD, as.Date), .SDcols = date_fields]
if (anyNA(reviews[, ..date_fields]) ||
    reviews[final_identity_decision == "merge_all", .N] != 85L ||
    reviews[final_identity_decision == "retain_each", .N] != 13L) {
  stop("The decision counts or review dates changed.", call. = FALSE)
}

review_groups[reviews, `:=`(
  review_question_id = i.review_question_id,
  internal_identity_decision = i.internal_identity_decision,
  internal_reason_code = i.internal_reason_code,
  internal_notes = i.internal_notes,
  internal_reviewed_on = i.internal_reviewed_on,
  external_identity_decision = i.external_identity_decision,
  external_search_engine = i.external_search_engine,
  external_search_url = i.external_search_url,
  external_source_title = i.external_source_title,
  external_source_type = i.external_source_type,
  external_source_url = i.external_source_url,
  external_notes = i.external_notes,
  external_reviewed_on = i.external_reviewed_on,
  final_identity_decision = i.final_identity_decision,
  final_reason_code = i.final_reason_code,
  address_set_assessment = i.address_set_assessment,
  final_notes = i.final_notes,
  final_reviewed_on = i.final_reviewed_on,
  shared_geocoding_query_decision =
    i.shared_geocoding_query_decision,
  source_rows_changed = i.source_rows_changed
), on = "identical_address_set_id"]

member_mapping <- review_members[
  review_groups[, .(
    identical_address_set_id,
    review_question_id,
    final_identity_decision,
    final_reason_code,
    address_set_assessment,
    shared_geocoding_query_decision,
    source_rows_changed
  )],
  on = "identical_address_set_id"
]
member_mapping[, sort_first_pis_year := fifelse(
  is.na(first_pis_year),
  9999L,
  first_pis_year
)]
setorder(
  member_mapping,
  review_question_id,
  sort_first_pis_year,
  development_id
)
member_mapping[, proposed_physical_development_id := fifelse(
  final_identity_decision == "merge_all",
  first(development_id),
  development_id
), by = review_question_id]
member_mapping[, review_cluster_id := fifelse(
  final_identity_decision == "merge_all",
  paste0(review_question_id, "_MERGED"),
  paste0(review_question_id, "_", development_id)
)]
member_mapping[, member_action := fifelse(
  final_identity_decision == "merge_all",
  "merge_to_proposed_physical_development",
  "retain_current_development"
)]
member_mapping[, n_review_cluster_members := .N, by = review_cluster_id]
member_mapping[, sort_first_pis_year := NULL]

if (nrow(member_mapping) != 199L ||
    uniqueN(member_mapping$development_id) != nrow(member_mapping) ||
    uniqueN(member_mapping$review_cluster_id) != 112L ||
    member_mapping[
      member_action == "merge_to_proposed_physical_development",
      .N
    ] != 172L ||
    member_mapping[
      member_action == "retain_current_development",
      .N
    ] != 27L ||
    member_mapping[
      n_review_cluster_members > 1L &
        member_action != "merge_to_proposed_physical_development",
      .N
    ] > 0L ||
    member_mapping[
      n_review_cluster_members == 1L &
        member_action != "retain_current_development",
      .N
    ] > 0L) {
  stop("The proposed member mapping is inconsistent.", call. = FALSE)
}

write_parquet(
  review_groups[, -c(
    "expected_review_question_id",
    "reviewed_question_id"
  )],
  "../output/lihtc_identical_address_set_reviews.parquet"
)
write_parquet(
  member_mapping,
  "../output/lihtc_identical_address_set_proposed_member_mapping.parquet"
)

decision_summary <- reviews[, .(groups = .N), by = final_identity_decision]
setorder(decision_summary, final_identity_decision)
address_summary <- reviews[, .(groups = .N), by = address_set_assessment]
setorder(address_summary, -groups, address_set_assessment)

writeLines(c(
  "# Identical Address-Set Review Summary",
  "",
  "The two-read ledger covers all 98 retained groups and 199 development records. The known Massachusetts eight-address and Baltimore 53-address portfolio cross-listings are excluded. No source row was changed and no address was approved for geocoding.",
  "",
  "## Proposed identity decisions",
  "",
  format_markdown_table(decision_summary),
  "",
  "The proposed member mapping contains 112 physical-development clusters: 85 merged clusters and 27 development records retained individually across 13 groups.",
  "",
  "## Address-set assessments",
  "",
  format_markdown_table(address_summary),
  "",
  "Identity decisions do not validate every address. Copied, administrative, and contaminated sets remain blocked for later site-level repair. Conflicting unit counts remain attached to their original project episodes and are not aggregated."
), "../output/review_summary.md")
