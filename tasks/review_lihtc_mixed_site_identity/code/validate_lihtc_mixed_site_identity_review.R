# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/review_lihtc_mixed_site_identity/code")

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

reviews <- fread("mixed_site_identity_question_reviews.csv", na.strings = "")
partitions <- fread("mixed_site_identity_member_partitions.csv", na.strings = "")
questions <- as.data.table(read_parquet(
  "../input/lihtc_mixed_site_identity_questions.parquet"
))
members <- as.data.table(read_parquet(
  "../input/lihtc_mixed_site_identity_question_members.parquet"
))
pairs <- as.data.table(read_parquet(
  "../input/lihtc_mixed_site_identity_question_pairs.parquet"
))

if (nrow(reviews) != 87L ||
    nrow(partitions) != 195L ||
    nrow(questions) != 87L ||
    nrow(members) != 195L ||
    nrow(pairs) != 109L ||
    uniqueN(reviews$mixed_site_question_id) != nrow(reviews) ||
    uniqueN(questions$mixed_site_question_id) != nrow(questions) ||
    uniqueN(partitions$development_id) != nrow(partitions) ||
    uniqueN(members$development_id) != nrow(members) ||
    !setequal(
      reviews$mixed_site_question_id,
      questions$mixed_site_question_id
    ) ||
    !setequal(partitions$development_id, members$development_id)) {
  stop("The committed ledgers do not cover the prepared queue exactly.",
    call. = FALSE)
}

question_evidence <- questions[, .(
  mixed_site_question_id,
  candidate_signal_class,
  development_ids,
  development_names,
  development_anchor_hud_ids,
  first_pis_year_examples,
  episode_unit_max_examples,
  shared_site_key_examples
)]
question_evidence[reviews, `:=`(
  reviewed_candidate_signal_class = i.candidate_signal_class,
  reviewed_development_ids = i.development_ids,
  reviewed_development_names = i.development_names,
  reviewed_development_anchor_hud_ids = i.development_anchor_hud_ids,
  reviewed_first_pis_year_examples = i.first_pis_year_examples,
  reviewed_episode_unit_max_examples = i.episode_unit_max_examples,
  reviewed_shared_site_key_examples = i.shared_site_key_examples
), on = "mixed_site_question_id"]
if (question_evidence[
      candidate_signal_class != reviewed_candidate_signal_class |
        development_ids != reviewed_development_ids |
        development_names != reviewed_development_names |
        development_anchor_hud_ids !=
          reviewed_development_anchor_hud_ids |
        first_pis_year_examples != reviewed_first_pis_year_examples |
        episode_unit_max_examples != reviewed_episode_unit_max_examples |
        shared_site_key_examples != reviewed_shared_site_key_examples,
      .N
    ] > 0L) {
  stop("Prepared question evidence changed after review.", call. = FALSE)
}

member_evidence <- members[, .(
  mixed_site_question_id,
  development_id,
  development_name,
  development_anchor_hud_id,
  first_pis_year,
  last_pis_year,
  episode_unit_count_max,
  n_units_development,
  complete_site_key_examples
)]
member_evidence[partitions, `:=`(
  reviewed_question_id = i.mixed_site_question_id,
  reviewed_development_name = i.development_name,
  reviewed_development_anchor_hud_id = i.development_anchor_hud_id,
  reviewed_first_pis_year = i.first_pis_year,
  reviewed_last_pis_year = i.last_pis_year,
  reviewed_episode_unit_count_max = i.episode_unit_count_max,
  reviewed_n_units_development = i.n_units_development,
  reviewed_complete_site_key_examples = i.complete_site_key_examples
), on = "development_id"]
if (member_evidence[
      mixed_site_question_id != reviewed_question_id |
        development_name != reviewed_development_name |
        development_anchor_hud_id != reviewed_development_anchor_hud_id |
        complete_site_key_examples != reviewed_complete_site_key_examples |
        !fcoalesce(
          first_pis_year == reviewed_first_pis_year,
          is.na(first_pis_year) & is.na(reviewed_first_pis_year)
        ) |
        !fcoalesce(
          last_pis_year == reviewed_last_pis_year,
          is.na(last_pis_year) & is.na(reviewed_last_pis_year)
        ) |
        !fcoalesce(
          episode_unit_count_max == reviewed_episode_unit_count_max,
          is.na(episode_unit_count_max) &
            is.na(reviewed_episode_unit_count_max)
        ) |
        !fcoalesce(
          n_units_development == reviewed_n_units_development,
          is.na(n_units_development) & is.na(reviewed_n_units_development)
        ),
      .N
    ] > 0L) {
  stop("Prepared member evidence changed after review.", call. = FALSE)
}

required_review_fields <- c(
  "candidate_signal_class", "development_ids", "development_names",
  "development_anchor_hud_ids", "first_pis_year_examples",
  "episode_unit_max_examples", "shared_site_key_examples", "review_origin",
  "first_read_reviewed_on", "outside_read_reviewed_on",
  "final_reviewed_on", "n_members", "first_read_n_clusters", "n_clusters",
  "n_physical_development_clusters", "n_nonphysical_umbrella_clusters",
  "first_read_identity_decision", "final_identity_decision",
  "first_read_reason_code", "final_reason_code",
  "outside_discovery_method", "outside_discovery_url",
  "outside_source_member_count", "outside_source_title",
  "outside_source_type", "outside_source_url", "outside_address_agreement",
  "outside_identity_assessment", "episode_to_property_bridge_status",
  "shared_geocoding_query_decision", "source_rows_changed"
)
required_partition_fields <- c(
  "mixed_site_question_id", "development_id", "development_name",
  "development_anchor_hud_id", "complete_site_key_examples",
  "review_cluster_id", "adjudicated_development_id",
  "adjudicated_development_anchor_hud_id", "n_review_cluster_members",
  "cluster_status", "member_action", "episode_to_property_bridge_status",
  "shared_geocoding_query_decision", "source_rows_changed"
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
  "first_read_reviewed_on", "outside_read_reviewed_on", "final_reviewed_on"
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
    !all(reviews$first_read_identity_decision %chin% c(
      "merge_all", "retain_each", "partition"
    )) ||
    !all(reviews$final_identity_decision %chin% c(
      "merge_all", "retain_each", "partition"
    )) ||
    !all(grepl("^https://", source_urls)) ||
    !all(grepl("^https://", discovery_urls)) ||
    any(grepl("google.com/search", source_urls, fixed = TRUE)) ||
    any(reviews$outside_source_member_count < 1L) ||
    any(reviews$outside_source_member_count > reviews$n_members) ||
    any(reviews$shared_geocoding_query_decision != "not_approved") ||
    any(partitions$shared_geocoding_query_decision != "not_approved") ||
    any(reviews$source_rows_changed) ||
    any(partitions$source_rows_changed)) {
  stop("A review evidence, decision, or safety field is invalid.",
    call. = FALSE)
}

if (reviews[final_identity_decision == "merge_all", .N] != 73L ||
    reviews[final_identity_decision == "partition", .N] != 7L ||
    reviews[final_identity_decision == "retain_each", .N] != 7L ||
    reviews[outside_discovery_method == "focused_web_search", .N] != 23L ||
    reviews[outside_discovery_method == "public_directory_sitemap", .N] !=
      64L ||
    reviews[n_nonphysical_umbrella_clusters == 1L, .N] != 1L ||
    reviews[
      n_nonphysical_umbrella_clusters == 1L,
      mixed_site_question_id
    ] != "MSIR_0076" ||
    reviews[
      episode_to_property_bridge_status == "required_unresolved",
      .N
    ] != 1L) {
  stop("The adjudication or outside-read coverage counts changed.",
    call. = FALSE)
}

cluster_contract <- partitions[, .(
  observed_cluster_members = .N,
  observed_question_count = uniqueN(mixed_site_question_id),
  observed_status_count = uniqueN(cluster_status),
  cluster_status = first(cluster_status),
  adjudicated_development_id = first(adjudicated_development_id),
  adjudicated_development_anchor_hud_id =
    first(adjudicated_development_anchor_hud_id),
  expected_cluster_members = unique(n_review_cluster_members)
), by = review_cluster_id]
if (nrow(cluster_contract) != 105L ||
    cluster_contract[cluster_status == "final_physical_development", .N] !=
      104L ||
    cluster_contract[
      cluster_status ==
        "nonphysical_financing_umbrella_requires_bridge",
      .N
    ] != 1L ||
    cluster_contract[
      observed_question_count != 1L |
        observed_status_count != 1L |
        lengths(expected_cluster_members) != 1L |
        observed_cluster_members != unlist(expected_cluster_members),
      .N
    ] > 0L ||
    cluster_contract[
      cluster_status == "final_physical_development" &
        !adjudicated_development_id %chin% partitions$development_id,
      .N
    ] > 0L ||
    cluster_contract[
      cluster_status ==
        "nonphysical_financing_umbrella_requires_bridge" &
        (adjudicated_development_id !=
          "NOT_APPLICABLE_NONPHYSICAL_UMBRELLA" |
          adjudicated_development_anchor_hud_id != "NOT_APPLICABLE"),
      .N
    ] > 0L) {
  stop("A review cluster is inconsistent.", call. = FALSE)
}

deterministic_anchors <- partitions[
  cluster_status == "final_physical_development"
][
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
physical_clusters <- cluster_contract[
  cluster_status == "final_physical_development"
]
physical_clusters[deterministic_anchors, `:=`(
  expected_development_id = i.expected_development_id,
  expected_anchor_hud_id = i.expected_anchor_hud_id
), on = "review_cluster_id"]
if (physical_clusters[
      adjudicated_development_id != expected_development_id |
        adjudicated_development_anchor_hud_id != expected_anchor_hud_id,
      .N
    ] > 0L ||
    partitions[
      cluster_status == "final_physical_development" &
        n_review_cluster_members > 1L &
        member_action != "merge_to_review_cluster",
      .N
    ] > 0L ||
    partitions[
      cluster_status == "final_physical_development" &
        n_review_cluster_members == 1L &
        member_action != "retain_current_development",
      .N
    ] > 0L ||
    partitions[
      cluster_status ==
        "nonphysical_financing_umbrella_requires_bridge" &
        member_action != "retain_for_episode_to_property_bridge",
      .N
    ] > 0L ||
    partitions[member_action == "merge_to_review_cluster", .N] != 171L ||
    partitions[member_action == "retain_current_development", .N] != 23L ||
    partitions[
      member_action == "retain_for_episode_to_property_bridge",
      .N
    ] != 1L) {
  stop("A member action or deterministic anchor changed.", call. = FALSE)
}

hobbs_ciena <- partitions[mixed_site_question_id == "MSIR_0076"]
if (!setequal(
      hobbs_ciena[review_cluster_id == "MSIC_00091", development_id],
      c("DEV_NYC20090320", "DEV_NYC20110823")
    ) ||
    !identical(
      hobbs_ciena[review_cluster_id == "MSIC_00092", development_id],
      "DEV_NYC20110822"
    ) ||
    !identical(
      hobbs_ciena[review_cluster_id == "MSIC_00093", development_id],
      "DEV_NYC20110841"
    ) ||
    hobbs_ciena[
      development_id == "DEV_NYC20110841",
      cluster_status
    ] != "nonphysical_financing_umbrella_requires_bridge") {
  stop("The Hobbs/Ciena episode-to-property bridge case changed.",
    call. = FALSE)
}

question_contract <- partitions[, .(
  observed_members = .N,
  observed_clusters = uniqueN(review_cluster_id),
  observed_physical_clusters = uniqueN(
    review_cluster_id[cluster_status == "final_physical_development"]
  ),
  observed_nonphysical_clusters = uniqueN(
    review_cluster_id[cluster_status ==
      "nonphysical_financing_umbrella_requires_bridge"]
  )
), by = mixed_site_question_id]
question_contract[reviews, `:=`(
  expected_members = i.n_members,
  expected_clusters = i.n_clusters,
  expected_physical_clusters = i.n_physical_development_clusters,
  expected_nonphysical_clusters = i.n_nonphysical_umbrella_clusters,
  final_identity_decision = i.final_identity_decision
), on = "mixed_site_question_id"]
if (question_contract[
      observed_members != expected_members |
        observed_clusters != expected_clusters |
        observed_physical_clusters != expected_physical_clusters |
        observed_nonphysical_clusters != expected_nonphysical_clusters,
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
  c(
    "candidate_signal_class", "development_ids", "development_names",
    "development_anchor_hud_ids", "first_pis_year_examples",
    "episode_unit_max_examples", "shared_site_key_examples"
  )
)
question_output <- copy(questions)
question_output[reviews[, ..review_columns],
  (setdiff(review_columns, "mixed_site_question_id")) :=
    mget(paste0(
      "i.",
      setdiff(review_columns, "mixed_site_question_id")
    )),
  on = "mixed_site_question_id"]

partition_columns <- setdiff(
  names(partitions),
  c(
    "mixed_site_question_id", "development_id", "development_name",
    "development_anchor_hud_id", "first_pis_year", "last_pis_year",
    "episode_unit_count_max", "n_units_development",
    "complete_site_key_examples"
  )
)
member_output <- copy(members)
member_output[partitions[, c("development_id", partition_columns),
    with = FALSE],
  (partition_columns) := mget(paste0("i.", partition_columns)),
  on = "development_id"]

setorder(question_output, mixed_site_question_id)
setorder(member_output, mixed_site_question_id, review_cluster_id,
  development_id)
setindexv(question_output, NULL)
setindexv(member_output, NULL)

decision_counts <- question_output[, .(
  questions = .N,
  current_records = sum(n_members),
  review_clusters = sum(n_clusters),
  physical_developments = sum(n_physical_development_clusters)
), by = final_identity_decision][order(final_identity_decision)]
outside_counts <- question_output[, .(
  questions = .N,
  complete_member_coverage = sum(outside_source_member_count == n_members),
  partial_member_coverage = sum(outside_source_member_count < n_members)
), by = outside_discovery_method][order(outside_discovery_method)]
summary_lines <- c(
  "# LIHTC Mixed-Site Identity Review",
  "",
  "## Results",
  "",
  "- Mixed-site questions reviewed: 87.",
  "- Current development records reviewed: 195.",
  "- Review clusters after adjudication: 105.",
  "- Final physical-development clusters: 104.",
  "- Nonphysical umbrella clusters requiring a bridge: 1.",
  "- Multi-member physical clusters: 81, containing 171 current records.",
  "- Physical developments retained as singletons: 23.",
  "- Records held only for an episode-to-property bridge: 1.",
  "- Net reduction among records assigned to physical developments: 90.",
  "- Questions with at least one retained direct public source: 87.",
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
    "The committed member ledger is the operative reviewed partition. ",
    "Financing episodes and source-reported units remain unchanged. Hobbs ",
    "Court and Ciena are separate physical buildings; the 340-unit combined ",
    "record remains a nonphysical umbrella episode until a separate ",
    "episode-to-property bridge is adjudicated. No review cluster is approved ",
    "as a shared geocoding query."
  ),
  ""
)

write_parquet(
  question_output,
  "../output/lihtc_mixed_site_identity_question_reviews.parquet",
  compression = "zstd"
)
write_parquet(
  member_output,
  "../output/lihtc_mixed_site_identity_member_partitions.parquet",
  compression = "zstd"
)
writeLines(summary_lines, "../output/review_summary.md")

question_round_trip <- as.data.table(read_parquet(
  "../output/lihtc_mixed_site_identity_question_reviews.parquet"
))
member_round_trip <- as.data.table(read_parquet(
  "../output/lihtc_mixed_site_identity_member_partitions.parquet"
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
    "Validated 87 questions, 195 records, 104 physical developments, and",
    "one nonphysical umbrella bridge case; no query approved.\n"
  )
)
