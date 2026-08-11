# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/review_lihtc_single_address/code")

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
  "single_address_question_reviews.csv",
  na.strings = ""
)
partitions <- fread(
  "single_address_member_partitions.csv",
  na.strings = ""
)
questions <- as.data.table(read_parquet(
  "../input/lihtc_single_address_identity_questions.parquet"
))
members <- as.data.table(read_parquet(
  "../input/lihtc_single_address_identity_question_members.parquet"
))
pairs <- as.data.table(read_parquet(
  "../input/lihtc_single_address_identity_question_pairs.parquet"
))

if (nrow(reviews) != 1149L ||
    nrow(partitions) != 2463L ||
    nrow(questions) != 1149L ||
    nrow(members) != 2463L ||
    nrow(pairs) != 1618L ||
    uniqueN(reviews$single_address_question_id) != nrow(reviews) ||
    uniqueN(questions$single_address_question_id) != nrow(questions) ||
    uniqueN(partitions$development_id) != nrow(partitions) ||
    uniqueN(members$development_id) != nrow(members) ||
    !setequal(
      reviews$single_address_question_id,
      questions$single_address_question_id
    ) ||
    !setequal(partitions$development_id, members$development_id)) {
  stop("The committed ledgers do not cover the prepared queue exactly.",
    call. = FALSE)
}

question_evidence <- questions[, .(
  single_address_question_id,
  site_key,
  development_names,
  review_stratum
)]
question_evidence[reviews, `:=`(
  reviewed_site_key = i.site_key,
  reviewed_development_names = i.development_names,
  reviewed_review_stratum = i.review_stratum
), on = "single_address_question_id"]
if (question_evidence[
      site_key != reviewed_site_key |
        development_names != reviewed_development_names |
        review_stratum != reviewed_review_stratum,
      .N
    ] > 0L) {
  stop("Prepared question evidence changed after review.", call. = FALSE)
}

member_evidence <- members[, .(
  single_address_question_id,
  development_id,
  development_name,
  first_pis_year,
  n_units_development,
  development_anchor_hud_id
)]
member_evidence[partitions, `:=`(
  reviewed_question_id = i.single_address_question_id,
  reviewed_development_name = i.development_name,
  reviewed_first_pis_year = i.first_pis_year,
  reviewed_n_units_development = i.n_units_development,
  reviewed_development_anchor_hud_id = i.development_anchor_hud_id
), on = "development_id"]
if (member_evidence[
      single_address_question_id != reviewed_question_id |
        development_name != reviewed_development_name |
        development_anchor_hud_id !=
          reviewed_development_anchor_hud_id |
        !fcoalesce(
          first_pis_year == reviewed_first_pis_year,
          is.na(first_pis_year) & is.na(reviewed_first_pis_year)
        ) |
        !fcoalesce(
          n_units_development == reviewed_n_units_development,
          is.na(n_units_development) &
            is.na(reviewed_n_units_development)
        ),
      .N
    ] > 0L) {
  stop("Prepared member evidence changed after review.", call. = FALSE)
}

required_review_fields <- c(
  "site_key", "development_names", "review_stratum", "review_origin",
  "pass1_reviewed_on", "pass2_reviewed_on", "final_reviewed_on",
  "outside_discovery_method", "outside_discovery_url",
  "shared_geocoding_query_decision", "source_rows_changed", "n_members",
  "pass1_n_clusters", "n_clusters", "pass1_identity_decision",
  "final_identity_decision", "outside_source_member_count",
  "outside_source_title", "outside_source_type", "outside_source_url",
  "outside_address_agreement", "pass1_reason_code",
  "outside_identity_assessment", "final_reason_code"
)
required_partition_fields <- c(
  "single_address_question_id", "development_id", "development_name",
  "review_cluster_id", "development_anchor_hud_id",
  "adjudicated_development_id",
  "adjudicated_development_anchor_hud_id", "n_review_cluster_members",
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

date_fields <- c(
  "pass1_reviewed_on", "pass2_reviewed_on", "final_reviewed_on"
)
reviews[, (date_fields) := lapply(.SD, as.Date), .SDcols = date_fields]
source_urls <- trimws(unlist(strsplit(
  reviews$outside_source_url,
  "|",
  fixed = TRUE
)))
discovery_urls <- trimws(unlist(strsplit(
  reviews$outside_discovery_url,
  "|",
  fixed = TRUE
)))
if (anyNA(reviews[, ..date_fields]) ||
    !all(reviews$review_origin == "new_two_read_review") ||
    !all(reviews$outside_discovery_method %chin% c(
      "focused_web_search", "public_directory_sitemap"
    )) ||
    !all(reviews$pass1_identity_decision %chin% c(
      "merge_all", "retain_each", "partition"
    )) ||
    !all(reviews$final_identity_decision %chin% c(
      "merge_all", "retain_each", "partition"
    )) ||
    !all(reviews$outside_identity_assessment %chin% c(
      "supports_merge_all", "supports_retain_each",
      "corroborates_all_listed_members_and_address",
      "corroborates_part_of_listed_members_and_address"
    )) ||
    !all(grepl("^https://", source_urls)) ||
    !all(grepl("^https://", discovery_urls)) ||
    any(grepl("google.com/search", source_urls, fixed = TRUE)) ||
    any(reviews$shared_geocoding_query_decision != "not_approved") ||
    any(partitions$shared_geocoding_query_decision != "not_approved") ||
    any(reviews$source_rows_changed) ||
    any(partitions$source_rows_changed)) {
  stop("A review evidence, decision, or safety field is invalid.",
    call. = FALSE)
}

if (reviews[final_identity_decision == "merge_all", .N] != 203L ||
    reviews[final_identity_decision == "partition", .N] != 10L ||
    reviews[final_identity_decision == "retain_each", .N] != 936L ||
    reviews[outside_discovery_method == "focused_web_search", .N] != 32L ||
    reviews[
      outside_discovery_method == "public_directory_sitemap",
      .N
    ] != 1117L ||
    reviews[outside_source_member_count == n_members, .N] != 1040L ||
    reviews[outside_source_member_count < n_members, .N] != 109L ||
    reviews[
      outside_source_member_count < 1L |
        outside_source_member_count > n_members,
      .N
    ] > 0L) {
  stop("The adjudication or outside-read coverage counts changed.",
    call. = FALSE)
}

cluster_contract <- partitions[, .(
  observed_cluster_members = .N,
  observed_question_count = uniqueN(single_address_question_id),
  observed_adjudicated_development_ids =
    uniqueN(adjudicated_development_id),
  observed_adjudicated_anchor_ids =
    uniqueN(adjudicated_development_anchor_hud_id),
  adjudicated_development_id = first(adjudicated_development_id),
  adjudicated_development_anchor_hud_id =
    first(adjudicated_development_anchor_hud_id),
  expected_cluster_members = unique(n_review_cluster_members)
), by = review_cluster_id]
if (nrow(cluster_contract) != 2236L ||
    cluster_contract[
      observed_question_count != 1L |
        observed_adjudicated_development_ids != 1L |
        observed_adjudicated_anchor_ids != 1L |
        lengths(expected_cluster_members) != 1L |
        observed_cluster_members != unlist(expected_cluster_members),
      .N
    ] > 0L ||
    cluster_contract[
      !adjudicated_development_id %chin% partitions$development_id,
      .N
    ] > 0L) {
  stop("A physical-development review cluster is inconsistent.",
    call. = FALSE)
}

deterministic_anchors <- partitions[
  order(
    review_cluster_id,
    fifelse(is.na(first_pis_year), 9999L, first_pis_year),
    development_anchor_hud_id,
    development_id
  ),
  .(
    expected_development_id = first(development_id),
    expected_anchor_hud_id = first(development_anchor_hud_id)
  ),
  by = review_cluster_id
]
cluster_contract[deterministic_anchors, `:=`(
  expected_development_id = i.expected_development_id,
  expected_anchor_hud_id = i.expected_anchor_hud_id
), on = "review_cluster_id"]
if (cluster_contract[
      adjudicated_development_id != expected_development_id |
        adjudicated_development_anchor_hud_id != expected_anchor_hud_id,
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
    partitions[member_action == "merge_to_review_cluster", .N] != 442L ||
    partitions[member_action == "retain_current_development", .N] !=
      2021L ||
    cluster_contract[observed_cluster_members > 1L, .N] != 215L) {
  stop("A member action or deterministic anchor changed.", call. = FALSE)
}

question_contract <- partitions[, .(
  observed_members = .N,
  observed_clusters = uniqueN(review_cluster_id)
), by = single_address_question_id]
question_contract[reviews, `:=`(
  expected_members = i.n_members,
  expected_clusters = i.n_clusters,
  final_identity_decision = i.final_identity_decision
), on = "single_address_question_id"]
if (question_contract[
      observed_members != expected_members |
        observed_clusters != expected_clusters,
      .N
    ] > 0L ||
    question_contract[
      final_identity_decision == "merge_all" & observed_clusters != 1L,
      .N
    ] > 0L ||
    question_contract[
      final_identity_decision == "retain_each" &
        observed_clusters != observed_members,
      .N
    ] > 0L ||
    question_contract[
      final_identity_decision == "partition" &
        (observed_clusters == 1L | observed_clusters == observed_members),
      .N
    ] > 0L) {
  stop("A question-level partition contract changed.", call. = FALSE)
}

review_columns <- setdiff(
  names(reviews),
  c("site_key", "development_names", "review_stratum")
)
question_output <- copy(questions)
question_output[reviews[, ..review_columns],
  (setdiff(review_columns, "single_address_question_id")) :=
    mget(paste0(
      "i.",
      setdiff(review_columns, "single_address_question_id")
    )),
  on = "single_address_question_id"]

partition_columns <- setdiff(
  names(partitions),
  c(
    "single_address_question_id", "development_id", "development_name",
    "first_pis_year", "n_units_development", "development_anchor_hud_id"
  )
)
member_output <- copy(members)
member_output[partitions[, c("development_id", partition_columns),
    with = FALSE],
  (partition_columns) := mget(paste0("i.", partition_columns)),
  on = "development_id"]

setorder(question_output, single_address_question_id)
setorder(member_output, single_address_question_id, review_cluster_id,
  development_id)
setindexv(question_output, NULL)
setindexv(member_output, NULL)

decision_counts <- question_output[, .(
  questions = .N,
  current_records = sum(n_members),
  reviewed_clusters = sum(n_clusters)
), by = final_identity_decision][order(final_identity_decision)]
outside_counts <- question_output[, .(
  questions = .N,
  complete_member_coverage = sum(outside_source_member_count == n_members),
  partial_member_coverage = sum(outside_source_member_count < n_members)
), by = outside_discovery_method][order(outside_discovery_method)]
summary_lines <- c(
  "# LIHTC Single-Address Identity Review",
  "",
  "## Results",
  "",
  "- Shared-address questions reviewed: 1,149.",
  "- Current development records reviewed: 2,463.",
  "- Physical-development clusters after review: 2,236.",
  "- Multi-member clusters: 215, containing 442 current records.",
  "- Records retained as singleton developments: 2,021.",
  "- Net reduction if the partition is applied: 227 developments.",
  "- Questions with at least one retained direct public source: 1,149.",
  "- Shared geocoding queries approved: 0.",
  "- Source rows changed: 0.",
  "",
  "## Question decisions",
  "",
  format_markdown_table(decision_counts),
  "",
  "## Outside-read coverage",
  "",
  format_markdown_table(outside_counts),
  "",
  "## Interpretation",
  "",
  paste0(
    "The committed member ledger is the operative physical-development ",
    "partition. Distinct phases and buildings remain separate unless a ",
    "duplicate component or one documented physical development was found. ",
    "All HUD episodes and source addresses remain available, and public ",
    "housing directories are treated as corroborating rather than ",
    "independent evidence. No address is approved for geocoding."
  ),
  ""
)

write_parquet(
  question_output,
  "../output/lihtc_single_address_question_reviews.parquet",
  compression = "zstd"
)
write_parquet(
  member_output,
  "../output/lihtc_single_address_member_partitions.parquet",
  compression = "zstd"
)
writeLines(summary_lines, "../output/review_summary.md")

question_round_trip <- as.data.table(read_parquet(
  "../output/lihtc_single_address_question_reviews.parquet"
))
member_round_trip <- as.data.table(read_parquet(
  "../output/lihtc_single_address_member_partitions.parquet"
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
  paste(
    "Validated 1,149 questions, 2,463 records, and 2,236 explicit",
    "physical-development clusters; no query approved.\n"
  )
)
