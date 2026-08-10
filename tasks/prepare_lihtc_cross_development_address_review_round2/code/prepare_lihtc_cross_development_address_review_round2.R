# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/prepare_lihtc_cross_development_address_review_round2/code")

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
  "../input/lihtc_cross_development_pairs_adjudicated.parquet"
))
development <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_address_adjudicated.parquet"
))

if (nrow(pairs) != 6483L ||
    uniqueN(pairs$shared_development_pair_id) != nrow(pairs) ||
    uniqueN(pairs, by = c(
      "development_id_1", "development_id_2"
    )) != nrow(pairs) ||
    nrow(development) != 54612L ||
    uniqueN(development$development_id) != nrow(development)) {
  stop("A round-two review-preparation input changed.", call. = FALSE)
}

review_pairs <- pairs[pair_review_stratum %chin% c(
  "name_or_timing_review",
  "phase_or_component_review"
)]
if (nrow(review_pairs) != 587L ||
    review_pairs[prior_identity_review_status != "not_reviewed", .N] > 0L) {
  stop("The round-two pair scope changed.", call. = FALSE)
}

review_development_ids <- sort(unique(c(
  review_pairs$development_id_1,
  review_pairs$development_id_2
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

review_pairs[, `:=`(
  member_row_1 = match(development_id_1, question_members$development_id),
  member_row_2 = match(development_id_2, question_members$development_id)
)]
if (anyNA(review_pairs[, .(member_row_1, member_row_2)])) {
  stop("A round-two edge contains an unknown development.", call. = FALSE)
}
for (edge_row in seq_len(nrow(review_pairs))) {
  root_1 <- find_root(review_pairs$member_row_1[edge_row])
  root_2 <- find_root(review_pairs$member_row_2[edge_row])
  if (root_1 != root_2) {
    parent[max(root_1, root_2)] <- min(root_1, root_2)
  }
}
question_members[, component_root := vapply(
  component_row,
  find_root,
  integer(1L)
)]
review_pairs[, component_root := question_members$component_root[
  match(development_id_1, question_members$development_id)
]]
if (any(review_pairs$component_root != question_members$component_root[
      match(review_pairs$development_id_2, question_members$development_id)
    ])) {
  stop("A connected round-two question is inconsistent.", call. = FALSE)
}

question_members[development, `:=`(
  development_name = i.development_name,
  development_name_key = i.development_name_key,
  development_state = i.development_state,
  development_city = i.development_city,
  development_anchor_hud_id = i.development_anchor_hud_id,
  pre_cross_address_review_development_ids =
    i.pre_cross_address_review_development_ids,
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
  stop("A round-two development join failed.", call. = FALSE)
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
  "XDA2_%04d",
  seq_len(.N)
)]
question_members[component_order, identity_question_id :=
  i.identity_question_id, on = "component_root"]
review_pairs[component_order, identity_question_id :=
  i.identity_question_id, on = "component_root"]

pair_summary <- review_pairs[, .(
  n_pair_edges = .N,
  n_name_or_timing_edges = sum(
    pair_review_stratum == "name_or_timing_review"
  ),
  n_phase_or_component_edges = sum(
    pair_review_stratum == "phase_or_component_review"
  ),
  shared_development_pair_ids = collapse_text(
    shared_development_pair_id,
    25L
  ),
  n_shared_address_pair_rows = sum(n_shared_addresses),
  shared_address_examples = collapse_text(shared_address_examples, 10L),
  any_same_normalized_name = any(same_normalized_name),
  any_state_id_overlap = any(any_state_id_overlap),
  any_primary_site_overlap = any(any_primary_site_overlap),
  any_identical_complete_address_set = any(
    identical_complete_address_set
  ),
  maximum_name_edit_similarity = max(
    name_edit_similarity,
    na.rm = TRUE
  ),
  maximum_name_token_jaccard = max(
    name_token_jaccard,
    na.rm = TRUE
  ),
  minimum_first_pis_year_gap = as.numeric(suppressWarnings(
    min(first_pis_year_gap, na.rm = TRUE)
  )),
  any_equal_units_near_pis = any(equal_units_near_pis),
  any_phase_or_component_name_signal = any(
    phase_or_component_name_signal
  ),
  any_shared_address_problem = any(any_shared_address_problem),
  any_shared_source_problem = any(any_shared_source_problem),
  any_shared_zip_disagreement = any(
    any_shared_address_zip_disagreement
  )
), by = identity_question_id]
pair_summary[!is.finite(maximum_name_edit_similarity),
  maximum_name_edit_similarity := NA_real_]
pair_summary[!is.finite(maximum_name_token_jaccard),
  maximum_name_token_jaccard := NA_real_]
pair_summary[!is.finite(minimum_first_pis_year_gap),
  minimum_first_pis_year_gap := NA_real_]

questions <- question_members[, .(
  development_state = sort(unique(development_state))[1L],
  n_developments = .N,
  n_normalized_names = uniqueN(development_name_key),
  development_ids = collapse_text(development_id, 25L),
  development_names = collapse_text(development_name, 25L),
  development_cities = collapse_text(development_city),
  development_anchor_hud_ids = collapse_text(
    development_anchor_hud_id,
    25L
  ),
  first_pis_year_examples = collapse_text(first_pis_year),
  last_pis_year_examples = collapse_text(last_pis_year),
  episode_unit_max_examples = collapse_text(episode_unit_count_max),
  development_unit_examples = collapse_text(n_units_development),
  low_income_unit_examples = collapse_text(li_units_development),
  development_site_count_examples = collapse_text(n_development_sites)
), by = identity_question_id]
questions[pair_summary, `:=`(
  n_pair_edges = i.n_pair_edges,
  n_name_or_timing_edges = i.n_name_or_timing_edges,
  n_phase_or_component_edges = i.n_phase_or_component_edges,
  shared_development_pair_ids = i.shared_development_pair_ids,
  n_shared_address_pair_rows = i.n_shared_address_pair_rows,
  shared_address_examples = i.shared_address_examples,
  any_same_normalized_name = i.any_same_normalized_name,
  any_state_id_overlap = i.any_state_id_overlap,
  any_primary_site_overlap = i.any_primary_site_overlap,
  any_identical_complete_address_set =
    i.any_identical_complete_address_set,
  maximum_name_edit_similarity = i.maximum_name_edit_similarity,
  maximum_name_token_jaccard = i.maximum_name_token_jaccard,
  minimum_first_pis_year_gap = i.minimum_first_pis_year_gap,
  any_equal_units_near_pis = i.any_equal_units_near_pis,
  any_phase_or_component_name_signal =
    i.any_phase_or_component_name_signal,
  any_shared_address_problem = i.any_shared_address_problem,
  any_shared_source_problem = i.any_shared_source_problem,
  any_shared_zip_disagreement = i.any_shared_zip_disagreement
), on = "identity_question_id"]
questions[, internal_evidence_pattern := fcase(
  n_phase_or_component_edges == n_pair_edges,
  "phase_or_component_only",
  n_name_or_timing_edges == n_pair_edges & any_equal_units_near_pis,
  "name_or_timing_with_equal_units_near_pis",
  n_name_or_timing_edges == n_pair_edges,
  "name_similarity_only",
  default = "mixed_name_timing_and_phase_component"
)]
questions[, `:=`(
  review_scope = "new_two_pass_identity_review",
  pass1_identity_decision = "not_started",
  pass2_outside_evidence_status = "not_started",
  final_identity_decision = "unresolved",
  shared_geocoding_query_decision = "not_approved",
  source_rows_changed = FALSE
)]
setorder(
  questions,
  development_state,
  internal_evidence_pattern,
  development_names,
  identity_question_id
)
questions[, manual_review_order := seq_len(.N)]
setorder(questions, identity_question_id)
setorder(question_members, identity_question_id, development_id)

pattern_counts <- questions[, .(
  identity_questions = .N,
  development_members = sum(n_developments),
  pair_edges = sum(n_pair_edges)
), by = internal_evidence_pattern][order(internal_evidence_pattern)]
size_counts <- questions[, .(
  identity_questions = .N,
  pair_edges = sum(n_pair_edges)
), by = n_developments][order(n_developments)]
summary_lines <- c(
  "# LIHTC Cross-Development Address Review Round 2 Preparation",
  "",
  "## Scope",
  "",
  paste0("- Candidate pair edges: ", format(nrow(review_pairs), big.mark = ","), "."),
  paste0("- Connected identity questions: ", format(nrow(questions), big.mark = ","), "."),
  paste0("- Development members: ", format(nrow(question_members), big.mark = ","), "."),
  "- Previously reviewed retain-separate pairs included: 0.",
  "- Geocoding queries approved: 0.",
  "",
  "## Internal evidence patterns",
  "",
  format_markdown_table(pattern_counts),
  "",
  "## Connected-question size",
  "",
  format_markdown_table(size_counts),
  "",
  "## Interpretation",
  "",
  paste0(
    "These are the remaining close-name, timing, and explicit phase/component ",
    "questions. Each requires an independent internal read and outside-source ",
    "read before identity changes. This task makes no decision."
  ),
  ""
)

if (nrow(questions) != 372L ||
    nrow(question_members) != 834L ||
    uniqueN(questions$identity_question_id) != nrow(questions) ||
    uniqueN(question_members$development_id) != nrow(question_members) ||
    any(questions$final_identity_decision != "unresolved") ||
    any(questions$shared_geocoding_query_decision != "not_approved") ||
    any(questions$source_rows_changed)) {
  stop("The round-two preparation safety contract failed.", call. = FALSE)
}

setindexv(questions, NULL)
setindexv(question_members, NULL)
write_parquet(
  questions,
  "../output/lihtc_cross_development_identity_questions_round2.parquet",
  compression = "zstd"
)
write_parquet(
  question_members,
  paste0(
    "../output/",
    "lihtc_cross_development_identity_question_members_round2.parquet"
  ),
  compression = "zstd"
)
writeLines(summary_lines, "../output/audit_summary.md")

if (!identical(
  questions,
  as.data.table(read_parquet(
    "../output/lihtc_cross_development_identity_questions_round2.parquet"
  ))
) || !identical(
  question_members,
  as.data.table(read_parquet(paste0(
    "../output/",
    "lihtc_cross_development_identity_question_members_round2.parquet"
  )))
)) {
  stop("A round-two preparation Parquet changed on round trip.",
    call. = FALSE)
}

cat(
  "Prepared ",
  format(nrow(questions), big.mark = ","),
  " connected identity questions from ",
  format(nrow(review_pairs), big.mark = ","),
  " pair edges; no decision or query approved.\n",
  sep = ""
)
