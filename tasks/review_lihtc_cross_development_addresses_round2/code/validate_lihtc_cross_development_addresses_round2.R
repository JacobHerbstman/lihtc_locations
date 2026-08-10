# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/review_lihtc_cross_development_addresses_round2/code")

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
  "cross_development_address_question_reviews_round2.csv",
  na.strings = ""
)
partitions <- fread(
  "cross_development_address_member_partitions_round2.csv",
  na.strings = ""
)
questions <- as.data.table(read_parquet(
  paste0(
    "../input/",
    "lihtc_cross_development_identity_questions_round2.parquet"
  )
))
members <- as.data.table(read_parquet(
  paste0(
    "../input/",
    "lihtc_cross_development_identity_question_members_round2.parquet"
  )
))

if (nrow(reviews) != 372L ||
    nrow(partitions) != 834L ||
    nrow(questions) != 372L ||
    nrow(members) != 834L ||
    uniqueN(reviews$identity_question_id) != nrow(reviews) ||
    uniqueN(questions$identity_question_id) != nrow(questions) ||
    uniqueN(partitions$development_id) != nrow(partitions) ||
    uniqueN(members$development_id) != nrow(members) ||
    !setequal(reviews$identity_question_id, questions$identity_question_id) ||
    !setequal(partitions$development_id, members$development_id)) {
  stop("The committed ledgers do not cover the prepared queue exactly.",
    call. = FALSE)
}

question_evidence <- questions[, .(
  identity_question_id,
  development_state,
  development_names,
  shared_address_examples,
  internal_evidence_pattern
)]
question_evidence[reviews, `:=`(
  reviewed_development_state = i.development_state,
  reviewed_development_names = i.development_names,
  reviewed_shared_address_examples = i.shared_address_examples,
  reviewed_internal_evidence_pattern = i.internal_evidence_pattern
), on = "identity_question_id"]
if (question_evidence[
      development_state != reviewed_development_state |
        development_names != reviewed_development_names |
        shared_address_examples != reviewed_shared_address_examples |
        internal_evidence_pattern != reviewed_internal_evidence_pattern,
      .N
    ] > 0L) {
  stop("Prepared question evidence changed after review.", call. = FALSE)
}

member_evidence <- members[, .(
  identity_question_id,
  development_id,
  development_name,
  first_pis_year,
  n_units_development
)]
member_evidence[partitions, `:=`(
  reviewed_identity_question_id = i.identity_question_id,
  reviewed_development_name = i.development_name,
  reviewed_first_pis_year = i.first_pis_year,
  reviewed_n_units_development = i.n_units_development
), on = "development_id"]
if (member_evidence[
      identity_question_id != reviewed_identity_question_id |
        development_name != reviewed_development_name |
        !fcoalesce(first_pis_year == reviewed_first_pis_year,
          is.na(first_pis_year) & is.na(reviewed_first_pis_year)) |
        !fcoalesce(n_units_development == reviewed_n_units_development,
          is.na(n_units_development) &
            is.na(reviewed_n_units_development)),
      .N
    ] > 0L) {
  stop("Prepared member evidence changed after review.", call. = FALSE)
}

required_review_fields <- c(
  "review_origin", "pass1_identity_decision", "pass1_reason_code",
  "pass1_notes", "pass1_reviewed_on", "pass2_identity_decision",
  "pass2_reason_code", "pass2_search_engine", "pass2_search_url",
  "pass2_source_title", "pass2_source_type", "pass2_source_url",
  "pass2_notes", "pass2_reviewed_on", "final_identity_decision",
  "final_reason_code", "address_overlap_class", "final_notes",
  "final_reviewed_on", "shared_geocoding_query_decision",
  "source_rows_changed"
)
required_partition_fields <- c(
  "identity_question_id", "development_id", "review_cluster_id",
  "development_anchor_hud_id", "adjudicated_development_id",
  "adjudicated_development_anchor_hud_id",
  "n_review_cluster_members", "review_cluster_question_count",
  "member_action", "shared_geocoding_query_decision",
  "source_rows_changed"
)
if (anyNA(reviews[, ..required_review_fields]) ||
    any(vapply(
      reviews[, ..required_review_fields],
      function(value) any(as.character(value) == ""),
      logical(1L)
    )) ||
    anyNA(partitions[, ..required_partition_fields]) ||
    any(vapply(
      partitions[, ..required_partition_fields],
      function(value) any(as.character(value) == ""),
      logical(1L)
    ))) {
  stop("A required review or partition field is empty.", call. = FALSE)
}

source_urls <- trimws(unlist(strsplit(
  reviews$pass2_source_url,
  "|",
  fixed = TRUE
)))
if (!all(reviews$review_origin == "new_two_pass_review") ||
    !all(reviews$pass1_identity_decision ==
      reviews$final_identity_decision) ||
    !all(reviews$pass2_identity_decision ==
      reviews$final_identity_decision) ||
    !all(reviews$pass2_reason_code == reviews$final_reason_code) ||
    !all(reviews$pass2_search_engine == "Google") ||
    !all(grepl(
      "^https://www[.]google[.]com/search[?]q=",
      reviews$pass2_search_url
    )) ||
    !all(grepl("^https://", source_urls)) ||
    any(grepl("google.com/search", source_urls, fixed = TRUE)) ||
    any(reviews$shared_geocoding_query_decision != "not_approved") ||
    any(partitions$shared_geocoding_query_decision != "not_approved") ||
    any(reviews$source_rows_changed) ||
    any(partitions$source_rows_changed)) {
  stop("A two-pass review or geocoding-safety field is invalid.",
    call. = FALSE)
}

date_fields <- c(
  "pass1_reviewed_on", "pass2_reviewed_on", "final_reviewed_on"
)
reviews[, (date_fields) := lapply(.SD, as.Date), .SDcols = date_fields]
if (anyNA(reviews[, ..date_fields]) ||
    reviews[final_identity_decision == "merge_all", .N] != 195L ||
    reviews[final_identity_decision == "retain_each", .N] != 155L ||
    reviews[final_identity_decision == "partition", .N] != 17L ||
    reviews[
      final_identity_decision == "cross_question_partition",
      .N
    ] != 5L) {
  stop("The question decisions or review dates changed.", call. = FALSE)
}

cluster_contract <- partitions[, .(
  observed_cluster_members = .N,
  observed_question_count = uniqueN(identity_question_id),
  observed_adjudicated_development_ids =
    uniqueN(adjudicated_development_id),
  observed_adjudicated_anchor_ids =
    uniqueN(adjudicated_development_anchor_hud_id),
  adjudicated_development_id = first(adjudicated_development_id),
  adjudicated_development_anchor_hud_id =
    first(adjudicated_development_anchor_hud_id),
  expected_cluster_members = unique(n_review_cluster_members),
  expected_question_count = unique(review_cluster_question_count)
), by = review_cluster_id]
if (nrow(cluster_contract) != 566L ||
    cluster_contract[
      observed_adjudicated_development_ids != 1L |
        observed_adjudicated_anchor_ids != 1L |
        lengths(expected_cluster_members) != 1L |
        lengths(expected_question_count) != 1L |
        observed_cluster_members != unlist(expected_cluster_members) |
        observed_question_count != unlist(expected_question_count),
      .N
    ] > 0L ||
    cluster_contract[
      !adjudicated_development_id %chin% partitions$development_id,
      .N
    ] > 0L) {
  stop("A physical-development review cluster is inconsistent.",
    call. = FALSE)
}

anchor_contract <- partitions[
  development_id == adjudicated_development_id,
  .(
    review_cluster_id,
    expected_anchor_hud_id = development_anchor_hud_id
  )
]
if (nrow(anchor_contract) != 566L ||
    uniqueN(anchor_contract$review_cluster_id) != nrow(anchor_contract)) {
  stop("A review cluster lacks exactly one anchor development.",
    call. = FALSE)
}
cluster_contract[anchor_contract, expected_anchor_hud_id :=
  i.expected_anchor_hud_id, on = "review_cluster_id"]
if (cluster_contract[
      adjudicated_development_anchor_hud_id != expected_anchor_hud_id,
      .N
    ] > 0L) {
  stop("A review-cluster HUD anchor is inconsistent.", call. = FALSE)
}

deterministic_anchors <- partitions[
  order(
    review_cluster_id,
    fifelse(is.na(first_pis_year), 9999L, first_pis_year),
    development_anchor_hud_id,
    development_id
  ),
  .(expected_development_id = first(development_id)),
  by = review_cluster_id
]
cluster_contract[deterministic_anchors, expected_development_id :=
  i.expected_development_id, on = "review_cluster_id"]
if (cluster_contract[
      adjudicated_development_id != expected_development_id,
      .N
    ] > 0L ||
    partitions[
      n_review_cluster_members > 1L &
        member_action != "merge_to_review_cluster",
      .N
    ] > 0L ||
    partitions[
      n_review_cluster_members == 1L &
        member_action != "retain_current_development",
      .N
    ] > 0L ||
    partitions[member_action == "merge_to_review_cluster", .N] != 489L ||
    partitions[member_action == "retain_current_development", .N] != 345L ||
    cluster_contract[observed_cluster_members > 1L, .N] != 221L) {
  stop("A member action or deterministic anchor changed.", call. = FALSE)
}

question_contract <- partitions[, .(
  observed_members = .N,
  observed_clusters = uniqueN(review_cluster_id),
  observed_cross_question_clusters = uniqueN(
    review_cluster_id[review_cluster_question_count > 1L]
  )
), by = identity_question_id]
question_contract[reviews, `:=`(
  expected_members = i.n_members,
  expected_clusters = i.n_clusters,
  expected_cross_question_clusters = i.n_cross_question_clusters,
  final_identity_decision = i.final_identity_decision
), on = "identity_question_id"]
if (question_contract[
      observed_members != expected_members |
        observed_clusters != expected_clusters |
        observed_cross_question_clusters !=
          expected_cross_question_clusters,
      .N
    ] > 0L ||
    question_contract[
      final_identity_decision == "merge_all" &
        observed_clusters != 1L,
      .N
    ] > 0L ||
    question_contract[
      final_identity_decision == "retain_each" &
        observed_clusters != observed_members,
      .N
    ] > 0L ||
    cluster_contract[observed_question_count > 1L, .N] != 9L ||
    uniqueN(partitions[
      review_cluster_question_count > 1L,
      .(question_set = paste(
        sort(unique(identity_question_id)),
        collapse = "|"
      )),
      by = review_cluster_id
    ]$question_set) != 6L) {
  stop("A question-level partition contract changed.", call. = FALSE)
}

review_columns <- setdiff(
  names(reviews),
  c(
    "development_state", "development_names", "shared_address_examples",
    "internal_evidence_pattern"
  )
)
question_output <- copy(questions)
question_output[reviews[, ..review_columns],
  (setdiff(review_columns, "identity_question_id")) :=
    mget(paste0("i.", setdiff(review_columns, "identity_question_id"))),
  on = "identity_question_id"]

partition_columns <- setdiff(
  names(partitions),
  c(
    "identity_question_id", "development_id", "development_name",
    "first_pis_year", "n_units_development"
  )
)
member_output <- copy(members)
member_output[partitions[, c("development_id", partition_columns),
    with = FALSE],
  (partition_columns) := mget(paste0("i.", partition_columns)),
  on = "development_id"]
setorder(question_output, identity_question_id)
setorder(member_output, identity_question_id, review_cluster_id, development_id)
setindexv(question_output, NULL)
setindexv(member_output, NULL)

decision_counts <- question_output[, .(
  questions = .N,
  members = sum(n_members),
  within_question_clusters = sum(n_clusters)
), by = final_identity_decision][order(final_identity_decision)]
cluster_counts <- member_output[, .(
  physical_development_clusters = uniqueN(review_cluster_id),
  members = .N
), by = member_action][order(member_action)]
summary_lines <- c(
  "# LIHTC Cross-Development Address Review, Round 2",
  "",
  "## Results",
  "",
  "- Connected identity questions reviewed: 372.",
  "- Current physical-development records reviewed: 834.",
  "- Explicit physical-development clusters after review: 566.",
  "- Multi-member clusters to merge: 221, containing 489 records.",
  "- Records retained as their own development: 345.",
  "- Cross-question clusters: 9, spanning 6 question sets.",
  "- Shared geocoding queries approved: 0.",
  "- Source rows changed: 0.",
  "",
  "## Question decisions",
  "",
  format_markdown_table(decision_counts),
  "",
  "## Member actions",
  "",
  format_markdown_table(cluster_counts),
  "",
  "## Interpretation",
  "",
  paste0(
    "The committed member partition, rather than the question label alone, ",
    "defines physical-development identity. This allows duplicate reporting ",
    "within a phase to merge while distinct phases at the same address remain ",
    "separate. Every HUD row remains a project episode, every source address ",
    "remains evidence, and no address has been approved for geocoding."
  ),
  ""
)

write_parquet(
  question_output,
  "../output/lihtc_cross_development_address_question_reviews_round2.parquet",
  compression = "zstd"
)
write_parquet(
  member_output,
  "../output/lihtc_cross_development_address_member_partitions_round2.parquet",
  compression = "zstd"
)
writeLines(summary_lines, "../output/review_summary.md")

question_round_trip <- as.data.table(read_parquet(
  paste0(
    "../output/",
    "lihtc_cross_development_address_question_reviews_round2.parquet"
  )
))
member_round_trip <- as.data.table(read_parquet(
  paste0(
    "../output/",
    "lihtc_cross_development_address_member_partitions_round2.parquet"
  )
))
question_comparison <- all.equal(question_output, question_round_trip)
member_comparison <- all.equal(member_output, member_round_trip)
if (!isTRUE(question_comparison) || !isTRUE(member_comparison)) {
  stop(
    paste(
      "A validated review output changed on Parquet round trip:",
      paste(question_comparison, collapse = "; "),
      paste(member_comparison, collapse = "; ")
    ),
    call. = FALSE
  )
}

cat(
  "Validated 372 questions, 834 members, and 566 explicit physical-development clusters; no query approved.\n"
)
