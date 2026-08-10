# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/audit_lihtc_cross_development_addresses_round2_adjudicated/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
  library(stringr)
})

first_text <- function(value) {
  value <- sort(unique(value[!is.na(value) & value != ""]))
  if (length(value) == 0L) NA_character_ else value[1L]
}

collapse_text <- function(value, maximum = 10L) {
  value <- sort(unique(as.character(value[!is.na(value) & value != ""])))
  if (length(value) == 0L) {
    return(NA_character_)
  }
  if (length(value) > maximum) {
    return(paste0(
      paste(value[seq_len(maximum)], collapse = " | "),
      " | ... (", length(value), " values)"
    ))
  }
  paste(value, collapse = " | ")
}

collapse_delimited <- function(value, delimiter = "|") {
  tokens <- unlist(strsplit(
    value[!is.na(value) & value != ""],
    delimiter,
    fixed = TRUE
  ))
  tokens <- sort(unique(trimws(tokens[tokens != ""])))
  if (length(tokens) == 0L) NA_character_ else
    paste(tokens, collapse = delimiter)
}

keys_overlap <- function(first_key, second_key, delimiter = "|") {
  if (is.na(first_key) || is.na(second_key)) {
    return(FALSE)
  }
  first_values <- strsplit(first_key, delimiter, fixed = TRUE)[[1L]]
  second_values <- strsplit(second_key, delimiter, fixed = TRUE)[[1L]]
  length(intersect(first_values, second_values)) > 0L
}

edit_similarity <- function(first_name, second_name) {
  if (is.na(first_name) || is.na(second_name)) {
    return(NA_real_)
  }
  1 - adist(first_name, second_name)[1L] /
    max(nchar(first_name), nchar(second_name))
}

token_jaccard <- function(first_name, second_name) {
  if (is.na(first_name) || is.na(second_name)) {
    return(NA_real_)
  }
  first_tokens <- unique(strsplit(first_name, " ", fixed = TRUE)[[1L]])
  second_tokens <- unique(strsplit(second_name, " ", fixed = TRUE)[[1L]])
  length(intersect(first_tokens, second_tokens)) /
    length(union(first_tokens, second_tokens))
}

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

prior_address_members <- as.data.table(read_parquet(
  paste0(
    "../input/",
    "lihtc_cross_development_address_members_adjudicated.parquet"
  )
))
prior_pairs <- as.data.table(read_parquet(
  "../input/lihtc_cross_development_pairs_adjudicated.parquet"
))
development <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_address_round2_adjudicated.parquet"
))
episode <- as.data.table(read_parquet(
  "../input/lihtc_project_episode_2024_address_round2_adjudicated.parquet"
))
site <- as.data.table(read_parquet(
  "../input/lihtc_development_site_2024_address_round2_adjudicated.parquet"
))
questions <- as.data.table(read_parquet(
  paste0(
    "../input/",
    "lihtc_cross_development_address_question_reviews_round2.parquet"
  )
))
partitions <- as.data.table(read_parquet(
  paste0(
    "../input/",
    "lihtc_cross_development_address_member_partitions_round2.parquet"
  )
))

if (nrow(prior_address_members) != 13414L ||
    uniqueN(prior_address_members, by = c(
      "address_identity_key", "development_id"
    )) != nrow(prior_address_members) ||
    nrow(prior_pairs) != 6483L ||
    uniqueN(prior_pairs$shared_development_pair_id) != nrow(prior_pairs) ||
    nrow(development) != 54344L ||
    uniqueN(development$development_id) != nrow(development) ||
    nrow(episode) != 55345L || uniqueN(episode$hud_id) != nrow(episode) ||
    nrow(site) != 134232L ||
    uniqueN(site$development_site_id) != nrow(site) ||
    uniqueN(site, by = c("development_id", "site_key")) != nrow(site) ||
    nrow(questions) != 372L ||
    uniqueN(questions$identity_question_id) != nrow(questions) ||
    nrow(partitions) != 834L ||
    uniqueN(partitions$development_id) != nrow(partitions)) {
  stop("A post-round-two audit input count or key changed.",
    call. = FALSE)
}
if (any(!episode$development_id %chin% development$development_id) ||
    any(!site$development_id %chin% development$development_id) ||
    any(questions$shared_geocoding_query_decision != "not_approved") ||
    any(partitions$shared_geocoding_query_decision != "not_approved") ||
    any(questions$source_rows_changed) ||
    any(partitions$source_rows_changed)) {
  stop("A foreign key or geocoding-safety contract failed.",
    call. = FALSE)
}

mapping <- partitions[, .(
  pre_round2_development_id = development_id,
  development_id = adjudicated_development_id,
  review_cluster_id,
  identity_question_id,
  member_action
)]
if (uniqueN(mapping$pre_round2_development_id) != nrow(mapping)) {
  stop("The round-two development mapping is not many-to-one.",
    call. = FALSE)
}

address_members <- copy(prior_address_members)
address_members[, pre_round2_development_id := development_id]
address_members[mapping, development_id := i.development_id,
  on = "pre_round2_development_id"]
if (any(!address_members$development_id %chin% development$development_id)) {
  stop("A mapped shared-address member lacks a final development.",
    call. = FALSE)
}

mapped_address_members <- address_members[, .(
  n_pre_round2_developments = uniqueN(pre_round2_development_id),
  pre_round2_development_ids = collapse_text(
    pre_round2_development_id
  ),
  published_street_examples = collapse_text(published_street_examples, 5L),
  published_city_examples = collapse_text(published_city_examples),
  published_state_examples = collapse_text(published_state_examples),
  published_zip_examples = collapse_text(published_zip_examples),
  normalized_street = first_text(normalized_street),
  normalized_city = first_text(normalized_city),
  normalized_state = first_text(normalized_state),
  normalized_zip_examples = collapse_text(normalized_zip_examples),
  n_normalized_zip_values = uniqueN(
    unlist(strsplit(
      normalized_zip_set_key[!is.na(normalized_zip_set_key)],
      "\u001F",
      fixed = TRUE
    ))
  ),
  coordinate_examples = collapse_text(coordinate_examples, 5L),
  n_coordinate_pairs = uniqueN(
    unlist(strsplit(
      coordinate_set_key[!is.na(coordinate_set_key)],
      "\u001F",
      fixed = TRUE
    ))
  ),
  any_address_form_problem = any(any_address_form_problem),
  any_source_problem = any(any_source_problem),
  any_coordinate_problem = any(any_coordinate_problem),
  all_queries_unapproved = all(all_queries_unapproved),
  all_query_ids_missing = all(all_query_ids_missing)
), by = .(address_identity_key, development_id)]

address_scope <- mapped_address_members[, .(
  n_developments = .N,
  n_pre_round2_developments = sum(n_pre_round2_developments)
), by = address_identity_key]
residual_keys <- address_scope[n_developments > 1L, address_identity_key]
residual_members <- mapped_address_members[
  address_identity_key %chin% residual_keys
]
if (any(!residual_members$all_queries_unapproved) ||
    any(!residual_members$all_query_ids_missing) ||
    uniqueN(residual_members, by = c(
      "address_identity_key", "development_id"
    )) != nrow(residual_members)) {
  stop("A residual shared address violates query safety or uniqueness.",
    call. = FALSE)
}

development_summary <- development[, .(
  development_id,
  development_name,
  development_name_key,
  development_state,
  development_city,
  n_project_episodes,
  first_pis_year,
  last_pis_year,
  episode_unit_count_max,
  n_units_development,
  n_development_sites,
  cross_address_round2_review_action,
  cross_address_round2_identity_question_ids
)]
episode_summary <- episode[, .(
  state_id_set_key = collapse_delimited(state_id[
    !is.na(state_id) & state_id != "" &
      !str_detect(state_id, "99-99|UNKNOWN|N/A|^9{6,}$")
  ]),
  primary_site_set_key = collapse_delimited(primary_site_key),
  hud_id_examples = collapse_text(hud_id, 5L),
  episode_unit_examples = collapse_text(episode_units, 5L)
), by = development_id]
development_summary[episode_summary, `:=`(
  state_id_set_key = i.state_id_set_key,
  primary_site_set_key = i.primary_site_set_key,
  hud_id_examples = i.hud_id_examples,
  episode_unit_examples = i.episode_unit_examples
), on = "development_id"]
if (anyNA(development_summary$hud_id_examples)) {
  stop("A final development lacks its project episodes.", call. = FALSE)
}

residual_members[development_summary, `:=`(
  development_name = i.development_name,
  development_name_key = i.development_name_key,
  development_state = i.development_state,
  development_city = i.development_city,
  n_project_episodes = i.n_project_episodes,
  first_pis_year = i.first_pis_year,
  last_pis_year = i.last_pis_year,
  episode_unit_count_max = i.episode_unit_count_max,
  n_units_development = i.n_units_development,
  n_development_sites = i.n_development_sites,
  cross_address_round2_review_action =
    i.cross_address_round2_review_action,
  cross_address_round2_identity_question_ids =
    i.cross_address_round2_identity_question_ids
), on = "development_id"]
if (anyNA(residual_members$development_name)) {
  stop("A residual address member lacks development evidence.",
    call. = FALSE)
}

address_groups <- residual_members[, .(
  normalized_street = first_text(normalized_street),
  normalized_city = first_text(normalized_city),
  normalized_state = first_text(normalized_state),
  n_developments = .N,
  n_pre_round2_developments = sum(n_pre_round2_developments),
  n_development_names = uniqueN(development_name_key),
  development_id_examples = collapse_text(development_id, 5L),
  development_name_examples = collapse_text(development_name, 5L),
  n_normalized_zip_values = max(n_normalized_zip_values),
  normalized_zip_examples = collapse_text(normalized_zip_examples),
  n_coordinate_pairs = max(n_coordinate_pairs),
  coordinate_examples = collapse_text(coordinate_examples, 5L),
  any_address_form_problem = any(any_address_form_problem),
  any_source_problem = any(any_source_problem),
  any_coordinate_problem = any(any_coordinate_problem),
  all_queries_unapproved = all(all_queries_unapproved),
  all_query_ids_missing = all(all_query_ids_missing)
), by = address_identity_key]
setorder(
  address_groups,
  normalized_state,
  normalized_city,
  normalized_street,
  address_identity_key,
  na.last = TRUE
)
address_groups[, shared_address_round2_group_id := sprintf(
  "ASR2G_%05d",
  seq_len(.N)
)]
residual_members[address_groups, shared_address_round2_group_id :=
  i.shared_address_round2_group_id, on = "address_identity_key"]

pair_address_evidence <- residual_members[, {
  development_ids <- sort(unique(development_id))
  pair_matrix <- combn(development_ids, 2L)
  .(
    development_id_1 = pair_matrix[1L, ],
    development_id_2 = pair_matrix[2L, ]
  )
}, by = .(shared_address_round2_group_id, address_identity_key)]
pair_address_evidence[address_groups, `:=`(
  normalized_street = i.normalized_street,
  normalized_city = i.normalized_city,
  normalized_state = i.normalized_state,
  address_group_n_developments = i.n_developments,
  address_group_problem = i.any_address_form_problem,
  address_group_source_problem = i.any_source_problem,
  address_group_coordinate_problem = i.any_coordinate_problem
), on = c(
  "shared_address_round2_group_id",
  "address_identity_key"
)]

residual_pairs <- pair_address_evidence[, .(
  n_shared_addresses = .N,
  shared_address_examples = collapse_text(address_identity_key, 5L),
  shared_state = first_text(normalized_state),
  maximum_developments_at_one_address =
    max(address_group_n_developments),
  any_shared_address_problem = any(address_group_problem),
  any_shared_source_problem = any(address_group_source_problem),
  any_shared_coordinate_problem = any(address_group_coordinate_problem)
), by = .(development_id_1, development_id_2)]

prior_pair_mapping <- prior_pairs[, .(
  development_id_1,
  development_id_2,
  prior_identity_review_status,
  pair_review_stratum,
  shared_development_pair_id
)]
prior_pair_mapping[mapping, development_id_1 := i.development_id,
  on = c(development_id_1 = "pre_round2_development_id")]
prior_pair_mapping[mapping, development_id_2 := i.development_id,
  on = c(development_id_2 = "pre_round2_development_id")]
prior_pair_mapping[, `:=`(
  ordered_development_id_1 = pmin(development_id_1, development_id_2),
  ordered_development_id_2 = pmax(development_id_1, development_id_2)
)]
prior_pair_mapping <- prior_pair_mapping[
  ordered_development_id_1 != ordered_development_id_2
]
pair_history <- prior_pair_mapping[, .(
  n_pre_round2_pair_records = .N,
  any_round1_reviewed_separate = any(
    prior_identity_review_status == "reviewed_retain_separate"
  ),
  prior_pair_strata = collapse_text(pair_review_stratum),
  pre_round2_pair_id_examples = collapse_text(
    shared_development_pair_id,
    5L
  )
), by = .(
  development_id_1 = ordered_development_id_1,
  development_id_2 = ordered_development_id_2
)]
residual_pairs[pair_history, `:=`(
  n_pre_round2_pair_records = i.n_pre_round2_pair_records,
  any_round1_reviewed_separate = i.any_round1_reviewed_separate,
  prior_pair_strata = i.prior_pair_strata,
  pre_round2_pair_id_examples = i.pre_round2_pair_id_examples
), on = c("development_id_1", "development_id_2")]
if (anyNA(residual_pairs$n_pre_round2_pair_records) ||
    !setequal(
      residual_pairs[, paste(development_id_1, development_id_2)],
      pair_history[, paste(development_id_1, development_id_2)]
    )) {
  stop("Mapped prior pairs and rebuilt residual pairs disagree.",
    call. = FALSE)
}

cluster_questions <- partitions[, .(
  round2_question_ids = collapse_delimited(identity_question_id),
  round2_review_cluster_id = first(review_cluster_id)
), by = .(development_id = adjudicated_development_id)]
if (uniqueN(cluster_questions$development_id) != nrow(cluster_questions)) {
  stop("A final reviewed development maps to multiple clusters.",
    call. = FALSE)
}
residual_pairs[cluster_questions, `:=`(
  round2_question_ids_1 = i.round2_question_ids,
  round2_review_cluster_id_1 = i.round2_review_cluster_id
), on = c("development_id_1" = "development_id")]
residual_pairs[cluster_questions, `:=`(
  round2_question_ids_2 = i.round2_question_ids,
  round2_review_cluster_id_2 = i.round2_review_cluster_id
), on = c("development_id_2" = "development_id")]
residual_pairs[, round2_reviewed_together := mapply(
  keys_overlap,
  round2_question_ids_1,
  round2_question_ids_2,
  MoreArgs = list(delimiter = "|")
)]

residual_pairs[development_summary, `:=`(
  development_name_1 = i.development_name,
  development_name_key_1 = i.development_name_key,
  development_city_1 = i.development_city,
  first_pis_year_1 = i.first_pis_year,
  episode_unit_count_max_1 = i.episode_unit_count_max,
  state_id_set_key_1 = i.state_id_set_key,
  primary_site_set_key_1 = i.primary_site_set_key,
  hud_id_examples_1 = i.hud_id_examples
), on = c("development_id_1" = "development_id")]
residual_pairs[development_summary, `:=`(
  development_name_2 = i.development_name,
  development_name_key_2 = i.development_name_key,
  development_city_2 = i.development_city,
  first_pis_year_2 = i.first_pis_year,
  episode_unit_count_max_2 = i.episode_unit_count_max,
  state_id_set_key_2 = i.state_id_set_key,
  primary_site_set_key_2 = i.primary_site_set_key,
  hud_id_examples_2 = i.hud_id_examples
), on = c("development_id_2" = "development_id")]
if (anyNA(residual_pairs[, .(
      development_name_1,
      development_name_2
    )])) {
  stop("A residual pair lacks final development evidence.",
    call. = FALSE)
}

residual_pairs[, `:=`(
  same_normalized_name =
    !is.na(development_name_key_1) &
      development_name_key_1 == development_name_key_2,
  name_edit_similarity = mapply(
    edit_similarity,
    development_name_key_1,
    development_name_key_2
  ),
  name_token_jaccard = mapply(
    token_jaccard,
    development_name_key_1,
    development_name_key_2
  ),
  any_state_id_overlap = mapply(
    keys_overlap,
    state_id_set_key_1,
    state_id_set_key_2,
    MoreArgs = list(delimiter = "|")
  ),
  any_primary_site_overlap = mapply(
    keys_overlap,
    primary_site_set_key_1,
    primary_site_set_key_2,
    MoreArgs = list(delimiter = "|")
  ),
  equal_nonmissing_unit_max =
    !is.na(episode_unit_count_max_1) &
      episode_unit_count_max_1 == episode_unit_count_max_2,
  first_pis_year_gap = abs(first_pis_year_1 - first_pis_year_2)
)]
component_name_pattern <- paste0(
  "\\b(PHASE|PROJECT|SITE|LOT|BUILDING|BLDG)[[:space:]]+",
  "[A-Z0-9IVX-]+"
)
residual_pairs[, phase_or_component_name_signal :=
  str_detect(development_name_key_1, component_name_pattern) |
    str_detect(development_name_key_2, component_name_pattern)]
residual_pairs[, `:=`(
  high_name_similarity =
    (!is.na(name_edit_similarity) & name_edit_similarity >= 0.90) |
      (!is.na(name_token_jaccard) & name_token_jaccard >= 0.80),
  equal_units_near_pis =
    equal_nonmissing_unit_max &
      !is.na(first_pis_year_gap) & first_pis_year_gap <= 2L
)]
residual_pairs[, fresh_identity_signal := fcase(
  same_normalized_name | any_state_id_overlap,
  "identity_evidence_high",
  phase_or_component_name_signal &
    (high_name_similarity | equal_units_near_pis),
  "phase_or_component",
  high_name_similarity | equal_units_near_pis,
  "name_or_timing",
  any_primary_site_overlap,
  "shared_primary_address",
  default = "none"
)]
residual_pairs[, pair_audit_class := fcase(
  round2_reviewed_together,
  "round2_reviewed_distinct",
  any_round1_reviewed_separate,
  "round1_reviewed_distinct",
  str_detect(prior_pair_strata, "identical_complete_set_different_names"),
  "unresolved_identical_complete_address_set",
  str_detect(prior_pair_strata, "shared_primary_address"),
  "unresolved_shared_primary_address",
  default = "unresolved_shared_secondary_address"
)]
residual_pairs[, `:=`(
  development_identity_decision = fifelse(
    round2_reviewed_together | any_round1_reviewed_separate,
    "retain_separate",
    "unresolved"
  ),
  outside_evidence_status = fcase(
    round2_reviewed_together,
    "completed_round2_two_read_review",
    any_round1_reviewed_separate,
    "completed_round1_two_pass_review",
    default = "not_started"
  ),
  shared_geocoding_query_decision = "not_approved",
  source_rows_changed = FALSE
)]
setorder(
  residual_pairs,
  pair_audit_class,
  shared_state,
  development_name_1,
  development_name_2,
  development_id_1,
  development_id_2,
  na.last = TRUE
)
residual_pairs[, manual_review_order := seq_len(.N)]
residual_pairs[, residual_shared_development_pair_id := sprintf(
  "ASR2P_%05d",
  seq_len(.N)
)]

pair_counts <- residual_pairs[, .(
  development_pairs = .N,
  shared_addresses = sum(n_shared_addresses),
  address_problem_pairs = sum(any_shared_address_problem),
  source_problem_pairs = sum(any_shared_source_problem),
  coordinate_problem_pairs = sum(any_shared_coordinate_problem)
), by = pair_audit_class][order(pair_audit_class)]
fresh_signal_counts <- residual_pairs[
  development_identity_decision == "unresolved",
  .(development_pairs = .N),
  by = fresh_identity_signal
][order(fresh_identity_signal)]
address_groups[pair_address_evidence[
  residual_pairs[, .(
    development_id_1,
    development_id_2,
    pair_audit_class
  )],
  pair_audit_class := i.pair_audit_class,
  on = c("development_id_1", "development_id_2")
][, .(
  n_pairs = .N,
  n_round2_reviewed_distinct_pairs = sum(
    pair_audit_class == "round2_reviewed_distinct"
  ),
  n_round1_reviewed_distinct_pairs = sum(
    pair_audit_class == "round1_reviewed_distinct"
  ),
  n_unresolved_pairs = sum(str_starts(pair_audit_class, "unresolved_"))
), by = shared_address_round2_group_id], `:=`(
  n_pairs = i.n_pairs,
  n_round2_reviewed_distinct_pairs =
    i.n_round2_reviewed_distinct_pairs,
  n_round1_reviewed_distinct_pairs =
    i.n_round1_reviewed_distinct_pairs,
  n_unresolved_pairs = i.n_unresolved_pairs
), on = "shared_address_round2_group_id"]
address_groups[, `:=`(
  group_identity_status = fcase(
    n_unresolved_pairs == 0L,
    "all_pairs_reviewed_distinct",
    n_round2_reviewed_distinct_pairs +
      n_round1_reviewed_distinct_pairs > 0L,
    "mixed_reviewed_and_unresolved",
    default = "unresolved"
  ),
  shared_geocoding_query_decision = "not_approved",
  source_rows_changed = FALSE
)]
group_status_counts <- address_groups[, .(
  address_groups = .N,
  address_problem_groups = sum(any_address_form_problem),
  source_problem_groups = sum(any_source_problem),
  coordinate_problem_groups = sum(any_coordinate_problem)
), by = group_identity_status][order(group_identity_status)]

candidate_edges <- prior_pairs[
  pair_review_stratum %chin% c(
    "name_or_timing_review",
    "phase_or_component_review"
  ),
  .(
    shared_development_pair_id,
    pre_round2_development_id_1 = development_id_1,
    pre_round2_development_id_2 = development_id_2,
    pair_review_stratum,
    development_name_1,
    development_name_2
  )
]
if (sum(questions$n_pair_edges) != 587L ||
    nrow(candidate_edges) != 587L ||
    uniqueN(candidate_edges$shared_development_pair_id) != 587L) {
  stop("The prepared round-two candidate-edge set changed.",
    call. = FALSE)
}
candidate_edges[mapping, `:=`(
  development_id_1 = i.development_id,
  identity_question_id_1 = i.identity_question_id,
  review_cluster_id_1 = i.review_cluster_id
), on = c(
  pre_round2_development_id_1 = "pre_round2_development_id"
)]
candidate_edges[mapping, `:=`(
  development_id_2 = i.development_id,
  identity_question_id_2 = i.identity_question_id,
  review_cluster_id_2 = i.review_cluster_id
), on = c(
  pre_round2_development_id_2 = "pre_round2_development_id"
)]
if (anyNA(candidate_edges[, .(
      development_id_1,
      development_id_2,
      identity_question_id_1,
      identity_question_id_2
    )]) ||
    any(candidate_edges$identity_question_id_1 !=
      candidate_edges$identity_question_id_2)) {
  stop("A candidate edge is missing or crosses its prepared question.",
    call. = FALSE)
}
candidate_edges[, edge_disposition := fifelse(
  development_id_1 == development_id_2,
  "merged_same_physical_development",
  "reviewed_distinct_physical_developments"
)]
candidate_edges[, shared_geocoding_query_decision := "not_approved"]
candidate_edge_counts <- candidate_edges[, .N, by = edge_disposition][
  order(edge_disposition)
]

if (any(!address_groups$all_queries_unapproved) ||
    any(!address_groups$all_query_ids_missing) ||
    any(address_groups$shared_geocoding_query_decision != "not_approved") ||
    any(residual_pairs$shared_geocoding_query_decision != "not_approved") ||
    any(address_groups$source_rows_changed) ||
    any(residual_pairs$source_rows_changed) ||
    nrow(address_groups) != 5255L ||
    nrow(residual_members) != 12695L ||
    nrow(residual_pairs) != 5987L ||
    candidate_edges[
      edge_disposition == "merged_same_physical_development",
      .N
    ] != 359L ||
    candidate_edges[
      edge_disposition == "reviewed_distinct_physical_developments",
      .N
    ] != 228L ||
    candidate_edges[!edge_disposition %chin% c(
      "merged_same_physical_development",
      "reviewed_distinct_physical_developments"
    ), .N] > 0L) {
  stop("A residual identity or query decision is invalid.",
    call. = FALSE)
}

setorder(
  residual_members,
  shared_address_round2_group_id,
  development_id
)
setorder(address_groups, shared_address_round2_group_id)
setorder(candidate_edges, shared_development_pair_id)
setindexv(residual_members, NULL)
setindexv(address_groups, NULL)
setindexv(residual_pairs, NULL)
setindexv(candidate_edges, NULL)

summary_lines <- c(
  "# LIHTC Cross-Development Address Audit After Round 2",
  "",
  "## Identity-review disposition",
  "",
  "The 587 prepared candidate edges are all resolved by the committed member partition:",
  "",
  format_markdown_table(candidate_edge_counts),
  "",
  "## Residual shared-address scope",
  "",
  paste0(
    "- Residual shared address keys: ",
    format(nrow(address_groups), big.mark = ","),
    "."
  ),
  paste0(
    "- Residual address/development members: ",
    format(nrow(residual_members), big.mark = ","),
    "."
  ),
  paste0(
    "- Residual development pairs sharing at least one address: ",
    format(nrow(residual_pairs), big.mark = ","),
    "."
  ),
  "- Shared geocoding queries approved: 0.",
  "- Source rows changed: 0.",
  "",
  "## Residual pair classes",
  "",
  format_markdown_table(pair_counts),
  "",
  "## Fresh signals within the unresolved strata",
  "",
  format_markdown_table(fresh_signal_counts),
  "",
  "## Residual address-group status",
  "",
  format_markdown_table(group_status_counts),
  "",
  "## Interpretation",
  "",
  paste0(
    "Round two resolves every name/timing and phase/component edge that it ",
    "was designed to review. Remaining shared-address pairs are either ",
    "explicitly reviewed distinct developments or lower-priority overlaps ",
    "outside that queue. They remain blocked from geocoding. Compound ",
    "addresses, ranges, cross-listed sites, and malformed source addresses ",
    "must be handled before any coordinate-query pilot."
  ),
  ""
)

write_parquet(
  residual_members,
  "../output/lihtc_cross_development_address_members_round2_adjudicated.parquet",
  compression = "zstd"
)
write_parquet(
  address_groups,
  "../output/lihtc_cross_development_address_groups_round2_adjudicated.parquet",
  compression = "zstd"
)
write_parquet(
  residual_pairs,
  "../output/lihtc_cross_development_pairs_round2_adjudicated.parquet",
  compression = "zstd"
)
write_parquet(
  candidate_edges,
  "../output/lihtc_round2_candidate_edge_dispositions.parquet",
  compression = "zstd"
)
writeLines(summary_lines, "../output/audit_summary.md")

if (!isTRUE(all.equal(
  residual_members,
  as.data.table(read_parquet(
    paste0(
      "../output/",
      "lihtc_cross_development_address_members_round2_adjudicated.parquet"
    )
  ))
)) || !isTRUE(all.equal(
  address_groups,
  as.data.table(read_parquet(
    paste0(
      "../output/",
      "lihtc_cross_development_address_groups_round2_adjudicated.parquet"
    )
  ))
)) || !isTRUE(all.equal(
  residual_pairs,
  as.data.table(read_parquet(
    paste0(
      "../output/",
      "lihtc_cross_development_pairs_round2_adjudicated.parquet"
    )
  ))
)) || !isTRUE(all.equal(
  candidate_edges,
  as.data.table(read_parquet(
    "../output/lihtc_round2_candidate_edge_dispositions.parquet"
  ))
))) {
  stop("A post-round-two audit Parquet changed on round trip.",
    call. = FALSE)
}

cat(
  "Audited all 587 candidate edges and ",
  format(nrow(residual_pairs), big.mark = ","),
  " residual shared-address development pairs; no query approved.\n",
  sep = ""
)
