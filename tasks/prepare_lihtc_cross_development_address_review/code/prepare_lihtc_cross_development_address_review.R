# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/prepare_lihtc_cross_development_address_review/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
})

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

pairs <- as.data.table(read_parquet(
  "../input/lihtc_cross_development_pairs.parquet"
))
development <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_name_adjudicated.parquet"
))
prior_review <- as.data.table(read_parquet(
  "../input/lihtc_name_variant_linkage_decisions_2024.parquet"
))

if (nrow(pairs) != 6688L ||
    uniqueN(pairs$shared_development_pair_id) != nrow(pairs) ||
    uniqueN(pairs, by = c(
      "development_id_1", "development_id_2"
    )) != nrow(pairs) ||
    nrow(development) != 54725L ||
    uniqueN(development$development_id) != nrow(development) ||
    nrow(prior_review) != 163L ||
    uniqueN(prior_review$candidate_group_id) != nrow(prior_review)) {
  stop("A review-preparation input contract changed.", call. = FALSE)
}

high_pairs <- pairs[pair_review_stratum == "identity_evidence_high"]
if (nrow(high_pairs) != 150L ||
    uniqueN(c(
      high_pairs$development_id_1,
      high_pairs$development_id_2
    )) != 279L) {
  stop("The high-identity-evidence review scope changed.", call. = FALSE)
}

review_development_ids <- sort(unique(c(
  high_pairs$development_id_1,
  high_pairs$development_id_2
)))
question_members <- data.table(
  development_id = review_development_ids,
  component_row = seq_along(review_development_ids)
)

parent <- seq_len(nrow(question_members))
find_root <- function(row_number) {
  while (parent[row_number] != row_number) {
    row_number <- parent[row_number]
  }
  row_number
}

high_pairs[, `:=`(
  member_row_1 = match(development_id_1, question_members$development_id),
  member_row_2 = match(development_id_2, question_members$development_id)
)]
if (anyNA(high_pairs[, .(member_row_1, member_row_2)])) {
  stop("A high-evidence edge contains an unknown development.",
    call. = FALSE)
}

for (edge_row in seq_len(nrow(high_pairs))) {
  root_1 <- find_root(high_pairs$member_row_1[edge_row])
  root_2 <- find_root(high_pairs$member_row_2[edge_row])
  if (root_1 != root_2) {
    parent[max(root_1, root_2)] <- min(root_1, root_2)
  }
}

question_members[, component_root := vapply(
  component_row,
  find_root,
  integer(1)
)]
high_pairs[, component_root := question_members$component_root[
  match(development_id_1, question_members$development_id)
]]
if (any(high_pairs$component_root != question_members$component_root[
      match(high_pairs$development_id_2, question_members$development_id)
    ])) {
  stop("A connected review question was assigned inconsistently.",
    call. = FALSE)
}

pair_member_evidence <- rbindlist(list(
  high_pairs[, .(
    development_id = development_id_1,
    hud_id_examples = hud_id_examples_1,
    state_id_examples = state_id_examples_1,
    primary_site_examples = primary_site_examples_1,
    allocation_year_examples = allocation_year_examples_1,
    placed_in_service_year_examples =
      placed_in_service_year_examples_1,
    episode_unit_examples = episode_unit_examples_1,
    n_all_development_addresses = n_all_development_addresses_1,
    complete_address_set_key = complete_address_set_key_1,
    complete_address_set_group_id = complete_address_set_group_id_1,
    n_developments_same_complete_address_set =
      n_developments_same_complete_address_set_1
  )],
  high_pairs[, .(
    development_id = development_id_2,
    hud_id_examples = hud_id_examples_2,
    state_id_examples = state_id_examples_2,
    primary_site_examples = primary_site_examples_2,
    allocation_year_examples = allocation_year_examples_2,
    placed_in_service_year_examples =
      placed_in_service_year_examples_2,
    episode_unit_examples = episode_unit_examples_2,
    n_all_development_addresses = n_all_development_addresses_2,
    complete_address_set_key = complete_address_set_key_2,
    complete_address_set_group_id = complete_address_set_group_id_2,
    n_developments_same_complete_address_set =
      n_developments_same_complete_address_set_2
  )]
), use.names = TRUE)
pair_member_evidence <- unique(pair_member_evidence)
if (uniqueN(pair_member_evidence$development_id) !=
      nrow(pair_member_evidence)) {
  stop("Pair evidence is inconsistent within a development.",
    call. = FALSE)
}
question_members[pair_member_evidence, `:=`(
  hud_id_examples = i.hud_id_examples,
  state_id_examples = i.state_id_examples,
  primary_site_examples = i.primary_site_examples,
  allocation_year_examples = i.allocation_year_examples,
  placed_in_service_year_examples =
    i.placed_in_service_year_examples,
  episode_unit_examples = i.episode_unit_examples,
  n_all_development_addresses = i.n_all_development_addresses,
  complete_address_set = vapply(
    strsplit(i.complete_address_set_key, "\u001F", fixed = TRUE),
    paste,
    character(1),
    collapse = " | "
  ),
  complete_address_set_group_id = i.complete_address_set_group_id,
  n_developments_same_complete_address_set =
    i.n_developments_same_complete_address_set
), on = "development_id"]
if (anyNA(question_members$hud_id_examples) ||
    anyNA(question_members$n_all_development_addresses)) {
  stop("A pair-member evidence join failed.", call. = FALSE)
}

question_members[development, `:=`(
  development_name = i.development_name,
  development_name_key = i.development_name_key,
  development_state = i.development_state,
  development_city = i.development_city,
  pre_name_review_development_ids = i.pre_name_review_development_ids,
  development_anchor_hud_id = i.development_anchor_hud_id,
  name_variant_candidate_group_id = i.name_variant_candidate_group_id,
  name_variant_review_decision = i.name_variant_review_decision,
  name_variant_review_reason_code = i.name_variant_review_reason_code,
  n_project_episodes = i.n_project_episodes,
  first_pis_year = i.first_pis_year,
  last_pis_year = i.last_pis_year,
  episode_unit_count_max = i.episode_unit_count_max,
  n_units_development = i.n_units_development,
  li_units_development = i.li_units_development,
  n_development_sites = i.n_development_sites
), on = "development_id"]
if (anyNA(question_members$development_name) ||
    anyNA(question_members$development_state)) {
  stop("A review-question development join failed.", call. = FALSE)
}

component_order <- question_members[, .(
  development_state = sort(unique(development_state))[1L],
  first_development_name = sort(development_name)[1L],
  first_development_id = sort(development_id)[1L]
), by = component_root]
setorder(
  component_order,
  development_state,
  first_development_name,
  first_development_id
)
component_order[, identity_question_id := sprintf(
  "XDAQ_%04d",
  seq_len(.N)
)]
question_members[component_order, identity_question_id :=
  i.identity_question_id, on = "component_root"]
high_pairs[component_order, identity_question_id :=
  i.identity_question_id, on = "component_root"]

pair_summary <- high_pairs[, .(
  n_pair_edges = .N,
  shared_development_pair_ids = collapse_text(
    shared_development_pair_id,
    20L
  ),
  n_shared_address_pair_rows = sum(n_shared_addresses),
  shared_address_examples = collapse_text(shared_address_examples, 10L),
  all_pair_names_same = all(same_normalized_name),
  any_state_id_overlap = any(any_state_id_overlap),
  all_pair_unit_max_equal = all(equal_nonmissing_unit_max),
  maximum_first_pis_year_gap = suppressWarnings(max(
    as.numeric(first_pis_year_gap),
    na.rm = TRUE
  )),
  any_primary_site_overlap = any(any_primary_site_overlap),
  all_pair_primary_sites_overlap = all(any_primary_site_overlap),
  any_identical_complete_address_set = any(
    identical_complete_address_set
  ),
  all_complete_address_sets_identical = all(
    identical_complete_address_set
  ),
  any_shared_address_problem = any(any_shared_address_problem),
  any_shared_source_problem = any(any_shared_source_problem),
  any_shared_zip_disagreement = any(
    any_shared_address_zip_disagreement
  )
), by = identity_question_id]
pair_summary[
  !is.finite(maximum_first_pis_year_gap),
  maximum_first_pis_year_gap := NA_real_
]

questions <- question_members[, .(
  development_state = sort(unique(development_state))[1L],
  n_developments = .N,
  n_normalized_names = uniqueN(development_name_key),
  development_ids = collapse_text(development_id, 20L),
  development_names = collapse_text(development_name, 20L),
  development_cities = collapse_text(development_city),
  development_anchor_hud_ids = collapse_text(
    development_anchor_hud_id,
    20L
  ),
  hud_id_examples = collapse_text(hud_id_examples, 20L),
  state_id_examples = collapse_text(state_id_examples, 20L),
  primary_site_examples = collapse_text(primary_site_examples, 10L),
  complete_address_set_examples = collapse_text(
    complete_address_set,
    10L
  ),
  pre_name_review_development_ids = collapse_text(
    pre_name_review_development_ids,
    20L
  ),
  first_pis_year_examples = collapse_text(first_pis_year),
  last_pis_year_examples = collapse_text(last_pis_year),
  episode_unit_max_examples = collapse_text(episode_unit_count_max),
  development_unit_examples = collapse_text(n_units_development),
  low_income_unit_examples = collapse_text(li_units_development),
  development_site_count_examples = collapse_text(n_development_sites),
  all_members_previously_retained = all(
    name_variant_review_decision == "retain_separate"
  ),
  n_prior_name_review_groups = uniqueN(
    name_variant_candidate_group_id[
      !is.na(name_variant_candidate_group_id)
    ]
  ),
  prior_name_review_group_ids = collapse_text(
    name_variant_candidate_group_id
  ),
  prior_name_review_reason_codes = collapse_text(
    name_variant_review_reason_code
  )
), by = identity_question_id]
questions[pair_summary, `:=`(
  n_pair_edges = i.n_pair_edges,
  shared_development_pair_ids = i.shared_development_pair_ids,
  n_shared_address_pair_rows = i.n_shared_address_pair_rows,
  shared_address_examples = i.shared_address_examples,
  all_pair_names_same = i.all_pair_names_same,
  any_state_id_overlap = i.any_state_id_overlap,
  all_pair_unit_max_equal = i.all_pair_unit_max_equal,
  maximum_first_pis_year_gap = i.maximum_first_pis_year_gap,
  any_primary_site_overlap = i.any_primary_site_overlap,
  all_pair_primary_sites_overlap = i.all_pair_primary_sites_overlap,
  any_identical_complete_address_set =
    i.any_identical_complete_address_set,
  all_complete_address_sets_identical =
    i.all_complete_address_sets_identical,
  any_shared_address_problem = i.any_shared_address_problem,
  any_shared_source_problem = i.any_shared_source_problem,
  any_shared_zip_disagreement = i.any_shared_zip_disagreement
), on = "identity_question_id"]

questions[, internal_evidence_pattern := fcase(
  all_members_previously_retained,
  "carried_forward_previous_retain_separate",
  all_pair_names_same & all_pair_unit_max_equal &
    maximum_first_pis_year_gap <= 1,
  "same_name_same_timing_units",
  all_pair_names_same & all_pair_unit_max_equal &
    maximum_first_pis_year_gap > 1,
  "same_name_same_units_later_episode",
  all_pair_names_same,
  "same_name_changed_units_or_timing",
  any_state_id_overlap & all_pair_unit_max_equal &
    maximum_first_pis_year_gap <= 1,
  "state_id_name_variant_same_timing_units",
  any_state_id_overlap,
  "state_id_other",
  default = "other_high_identity_evidence"
)]
questions[, review_scope := fifelse(
  all_members_previously_retained,
  "carry_forward_completed_review",
  "new_two_pass_review_required"
)]

prior_review_source <- prior_review[
  final_decision == "retain_separate",
  .(
    prior_name_review_group_id = candidate_group_id,
    inherited_identity_decision = final_decision,
    inherited_identity_reason_code = final_reason_code,
    inherited_internal_notes = pass1_notes,
    inherited_outside_source_title = pass2_source_1_title,
    inherited_outside_source_type = pass2_source_1_type,
    inherited_outside_source_url = pass2_source_1_url,
    inherited_outside_notes = pass2_notes,
    inherited_final_notes = final_notes,
    inherited_reviewed_on = final_reviewed_on
  )
]
questions[, prior_name_review_group_id := fifelse(
  all_members_previously_retained & n_prior_name_review_groups == 1L,
  prior_name_review_group_ids,
  NA_character_
)]
questions[prior_review_source, `:=`(
  inherited_identity_decision = i.inherited_identity_decision,
  inherited_identity_reason_code = i.inherited_identity_reason_code,
  inherited_internal_notes = i.inherited_internal_notes,
  inherited_outside_source_title = i.inherited_outside_source_title,
  inherited_outside_source_type = i.inherited_outside_source_type,
  inherited_outside_source_url = i.inherited_outside_source_url,
  inherited_outside_notes = i.inherited_outside_notes,
  inherited_final_notes = i.inherited_final_notes,
  inherited_reviewed_on = i.inherited_reviewed_on
), on = "prior_name_review_group_id"]
questions[, `:=`(
  new_identity_decision = "unresolved",
  shared_geocoding_query_decision = "unresolved",
  source_rows_changed = FALSE
)]

question_members[questions, `:=`(
  review_scope = i.review_scope,
  internal_evidence_pattern = i.internal_evidence_pattern,
  inherited_identity_decision = i.inherited_identity_decision,
  new_identity_decision = i.new_identity_decision,
  shared_geocoding_query_decision =
    i.shared_geocoding_query_decision
), on = "identity_question_id"]

setorder(questions, identity_question_id)
setorder(question_members, identity_question_id, development_id)

pattern_counts <- questions[, .(
  identity_questions = .N,
  development_members = sum(n_developments),
  pair_edges = sum(n_pair_edges)
), by = .(review_scope, internal_evidence_pattern)][
  order(review_scope, -identity_questions, internal_evidence_pattern)
]

summary_lines <- c(
  "# LIHTC Cross-Development Identity Review Preparation",
  "",
  "## Scope",
  "",
  paste0("- High-identity-evidence development pairs: ", nrow(high_pairs), "."),
  paste0("- Connected identity questions: ", nrow(questions), "."),
  paste0("- Development members: ", nrow(question_members), "."),
  paste0("- Questions carrying forward a completed `retain_separate` decision: ", questions[review_scope == "carry_forward_completed_review", .N], "."),
  paste0("- New questions requiring two-pass review: ", questions[review_scope == "new_two_pass_review_required", .N], "."),
  "",
  "## Internal evidence patterns",
  "",
  "Patterns organize the review queue. They do not merge a development, change an address, or approve a geocoding query.",
  "",
  format_markdown_table(pattern_counts),
  "",
  "## Safety contract",
  "",
  "- Prior completed decisions and outside-source URLs are carried forward rather than repeated.",
  "- Every new identity decision remains `unresolved`.",
  "- Every shared geocoding-query decision remains `unresolved`.",
  "- No source row is changed.",
  ""
)

if (nrow(questions) != 137L ||
    nrow(question_members) != 279L ||
    questions[review_scope == "carry_forward_completed_review", .N] != 8L ||
    questions[review_scope == "new_two_pass_review_required", .N] != 129L ||
    sum(questions$n_pair_edges) != 150L ||
    questions[internal_evidence_pattern ==
      "same_name_same_timing_units", .N] != 53L ||
    questions[internal_evidence_pattern ==
      "state_id_name_variant_same_timing_units", .N] != 12L ||
    questions[internal_evidence_pattern ==
      "same_name_same_units_later_episode", .N] != 18L ||
    questions[internal_evidence_pattern ==
      "same_name_changed_units_or_timing", .N] != 31L ||
    questions[internal_evidence_pattern == "state_id_other", .N] != 15L ||
    any(questions$new_identity_decision != "unresolved") ||
    any(questions$shared_geocoding_query_decision != "unresolved") ||
    any(questions$source_rows_changed) ||
    questions[review_scope == "carry_forward_completed_review" &
      (is.na(inherited_identity_decision) |
        is.na(inherited_outside_source_url)), .N] > 0L ||
    questions[review_scope == "new_two_pass_review_required" &
      !is.na(inherited_identity_decision), .N] > 0L) {
  stop("The identity-review preparation contract failed.", call. = FALSE)
}

setindexv(questions, NULL)
setindexv(question_members, NULL)
write_parquet(
  questions,
  "../output/lihtc_cross_development_identity_questions.parquet",
  compression = "zstd"
)
write_parquet(
  question_members,
  paste0(
    "../output/",
    "lihtc_cross_development_identity_question_members.parquet"
  ),
  compression = "zstd"
)
writeLines(summary_lines, "../output/audit_summary.md")

if (nrow(as.data.table(read_parquet(
      "../output/lihtc_cross_development_identity_questions.parquet"
    ))) != nrow(questions) ||
    nrow(as.data.table(read_parquet(paste0(
      "../output/",
      "lihtc_cross_development_identity_question_members.parquet"
    )))) != nrow(question_members)) {
  stop("An identity-review preparation output failed its round trip.",
    call. = FALSE)
}

cat(
  "Prepared ",
  nrow(questions),
  " connected identity questions; ",
  questions[review_scope == "new_two_pass_review_required", .N],
  " require new two-pass review.\n",
  sep = ""
)
