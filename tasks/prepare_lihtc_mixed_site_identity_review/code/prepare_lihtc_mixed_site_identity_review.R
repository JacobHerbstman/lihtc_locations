# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/prepare_lihtc_mixed_site_identity_review/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
  library(stringr)
})

collapse_text <- function(value, maximum = 25L) {
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

collapse_key <- function(value) {
  value <- sort(unique(as.character(value[!is.na(value) & value != ""])))
  if (length(value) == 0L) NA_character_ else
    paste(value, collapse = "\u001F")
}

keys_overlap <- function(first_key, second_key, delimiter) {
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

development <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_single_address_adjudicated.parquet"
))
episode <- as.data.table(read_parquet(
  "../input/lihtc_project_episode_2024_single_address_adjudicated.parquet"
))
site <- as.data.table(read_parquet(
  "../input/lihtc_development_site_2024_single_address_adjudicated.parquet"
))
reopenings <- fread(
  "mixed_site_prior_decision_reopenings.csv",
  colClasses = "character"
)

if (nrow(development) != 54030L ||
    uniqueN(development$development_id) != nrow(development) ||
    nrow(episode) != 55345L || uniqueN(episode$hud_id) != nrow(episode) ||
    nrow(site) != 133324L ||
    uniqueN(site$development_site_id) != nrow(site) ||
    uniqueN(site, by = c("development_id", "site_key")) != nrow(site) ||
    any(!episode$development_id %chin% development$development_id) ||
    any(!site$development_id %chin% development$development_id)) {
  stop("A post-single-address input count or key changed.",
    call. = FALSE)
}
expected_reopening_columns <- c(
  "single_address_development_id",
  "multi_address_development_id",
  "reopen_reason_code",
  "reopen_evidence_titles",
  "reopen_evidence_urls",
  "reopen_evidence_accessed_on",
  "reopen_evidence_note"
)
if (!identical(names(reopenings), expected_reopening_columns) ||
    nrow(reopenings) != 1L ||
    uniqueN(reopenings, by = c(
      "single_address_development_id",
      "multi_address_development_id"
    )) != nrow(reopenings) ||
    anyNA(reopenings) ||
    any(reopenings == "") ||
    reopenings$reopen_evidence_accessed_on != "2026-08-11") {
  stop("The prior-decision reopening ledger is invalid.",
    call. = FALSE)
}

observed_site_counts <- site[, .(
  observed_development_sites = .N
), by = development_id]
development_site_counts <- development[, .(
  development_id,
  expected_development_sites = n_development_sites
)]
development_site_counts[observed_site_counts,
  observed_development_sites := i.observed_development_sites,
on = "development_id"]
development_site_counts[is.na(observed_development_sites),
  observed_development_sites := 0L]
if (anyNA(development_site_counts$expected_development_sites) ||
    any(
      development_site_counts$observed_development_sites !=
        development_site_counts$expected_development_sites
    )) {
  stop("A development site count is inconsistent.", call. = FALSE)
}

valid_states <- c(state.abb, "DC")
site_members <- development[, .(
  development_id,
  n_development_sites
)][site, on = "development_id", nomatch = 0L]
mixed_groups <- site_members[, .(
  n_developments = uniqueN(development_id),
  n_single_address_developments = uniqueN(
    development_id[n_development_sites == 1L]
  ),
  n_multi_address_developments = uniqueN(
    development_id[n_development_sites > 1L]
  ),
  all_members_in_scope = all(site_state %chin% valid_states)
), by = site_key][
  n_developments > 1L &
    n_single_address_developments > 0L &
    n_multi_address_developments > 0L &
    all_members_in_scope
]
mixed_members <- unique(site_members[
  mixed_groups,
  on = "site_key",
  nomatch = 0L,
  .(
    site_key,
    development_id,
    n_development_sites,
    site_street,
    site_city,
    site_state,
    site_zip,
    site_source
  )
])
mixed_pairs <- mixed_members[, {
  single_ids <- sort(unique(development_id[n_development_sites == 1L]))
  multi_ids <- sort(unique(development_id[n_development_sites > 1L]))
  CJ(
    single_address_development_id = single_ids,
    multi_address_development_id = multi_ids
  )
}, by = site_key]

if (nrow(mixed_groups) != 813L ||
    sum(mixed_groups$n_single_address_developments) != 893L ||
    sum(mixed_groups$n_multi_address_developments) != 921L ||
    nrow(mixed_members) != 1814L ||
    uniqueN(mixed_members$development_id) != 1636L ||
    mixed_members[n_development_sites == 1L,
      uniqueN(development_id)] != 893L ||
    mixed_members[n_development_sites > 1L,
      uniqueN(development_id)] != 743L ||
    nrow(mixed_pairs) != 1014L ||
    uniqueN(mixed_pairs, by = c(
      "single_address_development_id",
      "multi_address_development_id"
    )) != nrow(mixed_pairs)) {
  stop("The mixed one-site/multi-site scope changed.", call. = FALSE)
}

episode_summary <- episode[, .(
  hud_ids = collapse_text(hud_id),
  project_name_examples = collapse_text(project),
  project_address_examples = collapse_text(proj_add),
  state_id_examples = collapse_text(state_id),
  matchable_state_id_set_key = collapse_key(state_id[
    !is.na(state_id) & state_id != "" &
      !str_detect(state_id, "99-99|UNKNOWN|N/A|^9{6,}$")
  ]),
  primary_site_examples = collapse_text(primary_site_key),
  primary_site_set_key = collapse_key(primary_site_key),
  allocation_year_examples = collapse_text(allocation_year),
  placed_in_service_year_examples = collapse_text(pis_year),
  episode_unit_examples = collapse_text(episode_units),
  episode_low_income_unit_examples = collapse_text(
    episode_low_income_units
  )
), by = development_id]
site_summary <- site[, .(
  complete_site_key_examples = collapse_text(site_key, 50L),
  complete_site_key_set = collapse_key(site_key),
  site_street_examples = collapse_text(site_street, 50L),
  site_city_examples = collapse_text(site_city),
  site_zip_examples = collapse_text(site_zip),
  site_source_examples = collapse_text(site_source),
  n_sites_requiring_review = sum(requires_site_review)
), by = development_id]
development_evidence <- development[, .(
  development_id,
  development_name,
  development_name_key,
  development_state,
  development_city,
  development_anchor_hud_id,
  n_project_episodes,
  first_pis_year,
  last_pis_year,
  episode_unit_count_max,
  n_units_development,
  li_units_development,
  unit_aggregation_status,
  n_development_sites,
  cross_address_identity_question_id,
  cross_address_review_decision,
  cross_address_round2_identity_question_ids,
  cross_address_round2_review_action,
  identical_address_set_review_question_ids,
  identical_address_set_review_action,
  single_address_review_question_ids,
  single_address_review_action
)]
development_evidence[episode_summary, `:=`(
  hud_ids = i.hud_ids,
  project_name_examples = i.project_name_examples,
  project_address_examples = i.project_address_examples,
  state_id_examples = i.state_id_examples,
  matchable_state_id_set_key = i.matchable_state_id_set_key,
  primary_site_examples = i.primary_site_examples,
  primary_site_set_key = i.primary_site_set_key,
  allocation_year_examples = i.allocation_year_examples,
  placed_in_service_year_examples =
    i.placed_in_service_year_examples,
  episode_unit_examples = i.episode_unit_examples,
  episode_low_income_unit_examples =
    i.episode_low_income_unit_examples
), on = "development_id"]
development_evidence[site_summary, `:=`(
  complete_site_key_examples = i.complete_site_key_examples,
  complete_site_key_set = i.complete_site_key_set,
  site_street_examples = i.site_street_examples,
  site_city_examples = i.site_city_examples,
  site_zip_examples = i.site_zip_examples,
  site_source_examples = i.site_source_examples,
  n_sites_requiring_review = i.n_sites_requiring_review
), on = "development_id"]
missing_development_evidence <- development_evidence[
  is.na(hud_ids) |
    (
      n_development_sites > 0L & (
        is.na(complete_site_key_set) |
          is.na(n_sites_requiring_review)
      )
    )
]
if (nrow(missing_development_evidence) > 0L) {
  stop(
    paste0(
      "A development evidence summary is incomplete: ",
      nrow(missing_development_evidence), " rows; hud=",
      sum(is.na(missing_development_evidence$hud_ids)),
      ", site_key=",
      sum(
        missing_development_evidence$n_development_sites > 0L &
          is.na(missing_development_evidence$complete_site_key_set)
      ),
      ", review_count=",
      sum(
        missing_development_evidence$n_development_sites > 0L &
          is.na(missing_development_evidence$n_sites_requiring_review)
      ),
      "."
    ),
    call. = FALSE
  )
}

mixed_pairs[development_evidence, `:=`(
  development_name_single = i.development_name,
  development_name_key_single = i.development_name_key,
  development_city_single = i.development_city,
  hud_ids_single = i.hud_ids,
  matchable_state_id_set_key_single =
    i.matchable_state_id_set_key,
  primary_site_set_key_single = i.primary_site_set_key,
  first_pis_year_single = i.first_pis_year,
  episode_unit_count_max_single = i.episode_unit_count_max,
  round1_question_ids_single =
    i.cross_address_identity_question_id,
  round2_question_ids_single =
    i.cross_address_round2_identity_question_ids,
  identical_set_question_ids_single =
    i.identical_address_set_review_question_ids,
  single_address_question_ids_single =
    i.single_address_review_question_ids
), on = c(single_address_development_id = "development_id")]
mixed_pairs[development_evidence, `:=`(
  development_name_multi = i.development_name,
  development_name_key_multi = i.development_name_key,
  development_city_multi = i.development_city,
  hud_ids_multi = i.hud_ids,
  matchable_state_id_set_key_multi = i.matchable_state_id_set_key,
  primary_site_set_key_multi = i.primary_site_set_key,
  first_pis_year_multi = i.first_pis_year,
  episode_unit_count_max_multi = i.episode_unit_count_max,
  round1_question_ids_multi =
    i.cross_address_identity_question_id,
  round2_question_ids_multi =
    i.cross_address_round2_identity_question_ids,
  identical_set_question_ids_multi =
    i.identical_address_set_review_question_ids,
  single_address_question_ids_multi =
    i.single_address_review_question_ids
), on = c(multi_address_development_id = "development_id")]
if (anyNA(mixed_pairs[, .(
      development_name_single,
      development_name_multi,
      hud_ids_single,
      hud_ids_multi
    )])) {
  stop("A mixed-site pair evidence join failed.", call. = FALSE)
}

mixed_pairs[, `:=`(
  same_normalized_name =
    !is.na(development_name_key_single) &
      development_name_key_single == development_name_key_multi,
  name_edit_similarity = mapply(
    edit_similarity,
    development_name_key_single,
    development_name_key_multi
  ),
  name_token_jaccard = mapply(
    token_jaccard,
    development_name_key_single,
    development_name_key_multi
  ),
  any_state_id_overlap = mapply(
    keys_overlap,
    matchable_state_id_set_key_single,
    matchable_state_id_set_key_multi,
    MoreArgs = list(delimiter = "\u001F")
  ),
  any_primary_site_overlap = mapply(
    keys_overlap,
    primary_site_set_key_single,
    primary_site_set_key_multi,
    MoreArgs = list(delimiter = "\u001F")
  ),
  equal_nonmissing_unit_max =
    !is.na(episode_unit_count_max_single) &
      episode_unit_count_max_single == episode_unit_count_max_multi,
  first_pis_year_gap = abs(
    first_pis_year_single - first_pis_year_multi
  ),
  round1_reviewed_together = mapply(
    keys_overlap,
    round1_question_ids_single,
    round1_question_ids_multi,
    MoreArgs = list(delimiter = "|")
  ),
  round2_reviewed_together = mapply(
    keys_overlap,
    round2_question_ids_single,
    round2_question_ids_multi,
    MoreArgs = list(delimiter = "|")
  ),
  identical_set_reviewed_together = mapply(
    keys_overlap,
    identical_set_question_ids_single,
    identical_set_question_ids_multi,
    MoreArgs = list(delimiter = "|")
  ),
  single_address_reviewed_together = mapply(
    keys_overlap,
    single_address_question_ids_single,
    single_address_question_ids_multi,
    MoreArgs = list(delimiter = "|")
  )
)]
mixed_pairs[, `:=`(
  high_name_similarity =
    (!is.na(name_edit_similarity) & name_edit_similarity >= 0.90) |
      (!is.na(name_token_jaccard) & name_token_jaccard >= 0.80),
  equal_units_near_pis =
    equal_nonmissing_unit_max &
      !is.na(first_pis_year_gap) & first_pis_year_gap <= 2L,
  prior_reviewed_distinct =
    round1_reviewed_together |
      round2_reviewed_together |
      identical_set_reviewed_together |
      single_address_reviewed_together
)]
mixed_pairs[, strong_candidate :=
  !prior_reviewed_distinct & (
    same_normalized_name |
      any_state_id_overlap |
      (high_name_similarity & equal_units_near_pis)
  )]
mixed_pairs[, moderate_candidate :=
  !prior_reviewed_distinct &
    !strong_candidate & (
      high_name_similarity |
        (
          equal_units_near_pis &
            pmin(
              episode_unit_count_max_single,
              episode_unit_count_max_multi
            ) > 2L
        )
    )]
mixed_pairs[, tiny_equal_unit_count_excluded :=
  !prior_reviewed_distinct &
    !strong_candidate &
    equal_units_near_pis &
    pmin(
      episode_unit_count_max_single,
      episode_unit_count_max_multi
    ) <= 2L]
mixed_pairs[, `:=`(
  prior_decision_reopened = FALSE,
  reopen_reason_code = NA_character_,
  reopen_evidence_titles = NA_character_,
  reopen_evidence_urls = NA_character_,
  reopen_evidence_accessed_on = NA_character_,
  reopen_evidence_note = NA_character_
)]
mixed_pairs[reopenings, `:=`(
  prior_decision_reopened = TRUE,
  reopen_reason_code = i.reopen_reason_code,
  reopen_evidence_titles = i.reopen_evidence_titles,
  reopen_evidence_urls = i.reopen_evidence_urls,
  reopen_evidence_accessed_on = i.reopen_evidence_accessed_on,
  reopen_evidence_note = i.reopen_evidence_note
), on = c(
  "single_address_development_id",
  "multi_address_development_id"
)]

if (mixed_pairs[round1_reviewed_together == TRUE, .N] != 7L ||
    mixed_pairs[round2_reviewed_together == TRUE, .N] != 72L ||
    mixed_pairs[identical_set_reviewed_together == TRUE, .N] != 0L ||
    mixed_pairs[single_address_reviewed_together == TRUE, .N] != 0L ||
    mixed_pairs[prior_reviewed_distinct == TRUE, .N] != 79L ||
    mixed_pairs[prior_decision_reopened == TRUE, .N] != 1L ||
    mixed_pairs[prior_decision_reopened == TRUE &
      prior_reviewed_distinct == FALSE, .N] != 0L ||
    mixed_pairs[prior_reviewed_distinct == TRUE &
      prior_decision_reopened == FALSE, .N] != 78L ||
    mixed_pairs[prior_reviewed_distinct == TRUE &
      (strong_candidate | moderate_candidate), .N] != 0L ||
    mixed_pairs[strong_candidate == TRUE, .N] != 2L ||
    mixed_pairs[moderate_candidate == TRUE, .N] != 91L ||
    mixed_pairs[tiny_equal_unit_count_excluded == TRUE, .N] != 4L) {
  stop("A mixed-site candidate or prior-constraint count changed.",
    call. = FALSE)
}

component_members <- data.table(
  development_id = sort(unique(c(
    mixed_pairs$single_address_development_id,
    mixed_pairs$multi_address_development_id
  )))
)
component_members[, member_row := .I]
parent <- seq_len(nrow(component_members))
find_root <- function(row_number) {
  while (parent[row_number] != row_number) {
    row_number <- parent[row_number]
  }
  row_number
}
mixed_pairs[, `:=`(
  single_member_row = match(
    single_address_development_id,
    component_members$development_id
  ),
  multi_member_row = match(
    multi_address_development_id,
    component_members$development_id
  )
)]
for (edge_row in seq_len(nrow(mixed_pairs))) {
  single_root <- find_root(mixed_pairs$single_member_row[edge_row])
  multi_root <- find_root(mixed_pairs$multi_member_row[edge_row])
  if (single_root != multi_root) {
    parent[max(single_root, multi_root)] <- min(single_root, multi_root)
  }
}
component_members[, component_root := vapply(
  member_row,
  find_root,
  integer(1L)
)]
mixed_pairs[, component_root := component_members$component_root[
  match(single_address_development_id, component_members$development_id)
]]
if (any(mixed_pairs$component_root != component_members$component_root[
      match(
        mixed_pairs$multi_address_development_id,
        component_members$development_id
      )
    ])) {
  stop("A mixed-site connected component is inconsistent.",
    call. = FALSE)
}

candidate_components <- mixed_pairs[, .(
  contains_candidate = any(
    strong_candidate |
      moderate_candidate |
      prior_decision_reopened
  )
), by = component_root][contains_candidate == TRUE]
review_pairs <- mixed_pairs[candidate_components,
  on = "component_root",
  nomatch = 0L
]
review_members <- component_members[candidate_components,
  on = "component_root",
  nomatch = 0L
]
review_members[development_evidence, `:=`(
  development_name = i.development_name,
  development_name_key = i.development_name_key,
  development_state = i.development_state,
  development_city = i.development_city,
  development_anchor_hud_id = i.development_anchor_hud_id,
  n_project_episodes = i.n_project_episodes,
  first_pis_year = i.first_pis_year,
  last_pis_year = i.last_pis_year,
  episode_unit_count_max = i.episode_unit_count_max,
  n_units_development = i.n_units_development,
  li_units_development = i.li_units_development,
  unit_aggregation_status = i.unit_aggregation_status,
  n_development_sites = i.n_development_sites,
  hud_ids = i.hud_ids,
  project_name_examples = i.project_name_examples,
  project_address_examples = i.project_address_examples,
  state_id_examples = i.state_id_examples,
  primary_site_examples = i.primary_site_examples,
  allocation_year_examples = i.allocation_year_examples,
  placed_in_service_year_examples =
    i.placed_in_service_year_examples,
  episode_unit_examples = i.episode_unit_examples,
  episode_low_income_unit_examples =
    i.episode_low_income_unit_examples,
  complete_site_key_examples = i.complete_site_key_examples,
  site_street_examples = i.site_street_examples,
  site_city_examples = i.site_city_examples,
  site_zip_examples = i.site_zip_examples,
  site_source_examples = i.site_source_examples,
  n_sites_requiring_review = i.n_sites_requiring_review,
  prior_round1_question_ids =
    i.cross_address_identity_question_id,
  prior_round1_decisions = i.cross_address_review_decision,
  prior_round2_question_ids =
    i.cross_address_round2_identity_question_ids,
  prior_round2_actions = i.cross_address_round2_review_action,
  prior_identical_set_question_ids =
    i.identical_address_set_review_question_ids,
  prior_identical_set_actions =
    i.identical_address_set_review_action,
  prior_single_address_question_ids =
    i.single_address_review_question_ids,
  prior_single_address_actions = i.single_address_review_action
), on = "development_id"]

component_order <- review_members[, .(
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
component_order[, mixed_site_question_id := sprintf(
  "MSIR_%04d",
  seq_len(.N)
)]
review_members[component_order, mixed_site_question_id :=
  i.mixed_site_question_id, on = "component_root"]
review_pairs[component_order, mixed_site_question_id :=
  i.mixed_site_question_id, on = "component_root"]

shared_key_memberships <- rbindlist(list(
  review_pairs[, .(
    mixed_site_question_id,
    development_id = single_address_development_id,
    site_key
  )],
  review_pairs[, .(
    mixed_site_question_id,
    development_id = multi_address_development_id,
    site_key
  )]
))[, .(
  n_shared_site_keys_in_question = uniqueN(site_key),
  shared_site_key_examples = collapse_text(site_key, 50L)
), by = .(mixed_site_question_id, development_id)]
review_members[shared_key_memberships, `:=`(
  n_shared_site_keys_in_question =
    i.n_shared_site_keys_in_question,
  shared_site_key_examples = i.shared_site_key_examples
), on = c("mixed_site_question_id", "development_id")]
candidate_development_ids <- unique(c(
  review_pairs[
    strong_candidate | moderate_candidate | prior_decision_reopened,
    single_address_development_id
  ],
  review_pairs[
    strong_candidate | moderate_candidate | prior_decision_reopened,
    multi_address_development_id
  ]
))
review_members[, `:=`(
  is_candidate_endpoint = development_id %chin% candidate_development_ids,
  question_member_role = fifelse(
    n_development_sites == 1L,
    "one_site_development",
    "multi_site_development"
  ),
  current_identity_decision = "unresolved",
  outside_evidence_status = "not_started",
  shared_geocoding_query_decision = "not_approved",
  source_rows_changed = FALSE
)]

review_pairs[, pair_review_stratum := fcase(
  prior_decision_reopened,
  "prior_decision_reopened",
  prior_reviewed_distinct,
  "prior_reviewed_distinct_constraint",
  strong_candidate,
  "strong_identity_evidence",
  moderate_candidate,
  "moderate_identity_evidence",
  default = "component_context_only"
)]
review_pairs[, `:=`(
  requires_new_identity_review =
    !prior_reviewed_distinct | prior_decision_reopened,
  current_identity_decision = fifelse(
    prior_reviewed_distinct & !prior_decision_reopened,
    "retain_separate",
    "unresolved"
  ),
  outside_evidence_status = fcase(
    prior_decision_reopened,
    "official_evidence_frozen_reconsideration_pending",
    round2_reviewed_together,
    "completed_round2_two_read_review",
    round1_reviewed_together,
    "completed_round1_two_pass_review",
    default = "not_started"
  ),
  shared_geocoding_query_decision = "not_approved",
  source_rows_changed = FALSE
)]
setorder(
  review_pairs,
  mixed_site_question_id,
  single_address_development_id,
  multi_address_development_id
)
review_pairs[, mixed_site_pair_id := sprintf(
  "MSIP_%04d",
  seq_len(.N)
)]

pair_summary <- review_pairs[, .(
  n_cross_type_pairs = .N,
  n_candidate_pairs = sum(
    strong_candidate |
      moderate_candidate |
      prior_decision_reopened
  ),
  n_strong_candidate_pairs = sum(strong_candidate),
  n_moderate_candidate_pairs = sum(moderate_candidate),
  n_reopened_prior_decision_pairs = sum(prior_decision_reopened),
  n_prior_reviewed_distinct_pairs = sum(prior_reviewed_distinct),
  n_context_only_pairs = sum(
    !strong_candidate &
      !moderate_candidate &
      !prior_reviewed_distinct
  ),
  n_shared_site_keys = uniqueN(site_key),
  shared_site_key_examples = collapse_text(site_key, 50L),
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
  reopen_reason_codes = collapse_text(reopen_reason_code),
  reopen_evidence_titles = collapse_text(reopen_evidence_titles),
  reopen_evidence_urls = collapse_text(reopen_evidence_urls),
  reopen_evidence_accessed_on = collapse_text(
    reopen_evidence_accessed_on
  )
), by = mixed_site_question_id]
pair_summary[!is.finite(maximum_name_edit_similarity),
  maximum_name_edit_similarity := NA_real_]
pair_summary[!is.finite(maximum_name_token_jaccard),
  maximum_name_token_jaccard := NA_real_]
pair_summary[!is.finite(minimum_first_pis_year_gap),
  minimum_first_pis_year_gap := NA_real_]

questions <- review_members[, .(
  development_state = sort(unique(development_state))[1L],
  n_developments = .N,
  n_candidate_endpoint_developments = sum(is_candidate_endpoint),
  n_component_context_developments = sum(!is_candidate_endpoint),
  n_single_address_developments = sum(n_development_sites == 1L),
  n_multi_address_developments = sum(n_development_sites > 1L),
  development_ids = collapse_text(development_id, 50L),
  development_names = collapse_text(development_name, 50L),
  development_cities = collapse_text(development_city),
  development_anchor_hud_ids = collapse_text(
    development_anchor_hud_id,
    50L
  ),
  first_pis_year_examples = collapse_text(first_pis_year),
  episode_unit_max_examples = collapse_text(episode_unit_count_max),
  development_site_count_examples = collapse_text(n_development_sites)
), by = mixed_site_question_id]
questions[pair_summary, `:=`(
  n_cross_type_pairs = i.n_cross_type_pairs,
  n_candidate_pairs = i.n_candidate_pairs,
  n_strong_candidate_pairs = i.n_strong_candidate_pairs,
  n_moderate_candidate_pairs = i.n_moderate_candidate_pairs,
  n_reopened_prior_decision_pairs =
    i.n_reopened_prior_decision_pairs,
  n_prior_reviewed_distinct_pairs =
    i.n_prior_reviewed_distinct_pairs,
  n_context_only_pairs = i.n_context_only_pairs,
  n_shared_site_keys = i.n_shared_site_keys,
  shared_site_key_examples = i.shared_site_key_examples,
  maximum_name_edit_similarity = i.maximum_name_edit_similarity,
  maximum_name_token_jaccard = i.maximum_name_token_jaccard,
  minimum_first_pis_year_gap = i.minimum_first_pis_year_gap,
  reopen_reason_codes = i.reopen_reason_codes,
  reopen_evidence_titles = i.reopen_evidence_titles,
  reopen_evidence_urls = i.reopen_evidence_urls,
  reopen_evidence_accessed_on = i.reopen_evidence_accessed_on
), on = "mixed_site_question_id"]
questions[, `:=`(
  candidate_signal_class = fcase(
    n_reopened_prior_decision_pairs > 0L,
    "prior_decision_reopened",
    n_strong_candidate_pairs > 0L,
    "strong_identity_evidence",
    default =
    "moderate_identity_evidence"
  ),
  review_priority = fcase(
    n_reopened_prior_decision_pairs > 0L,
    1L,
    n_strong_candidate_pairs > 0L,
    2L,
    default = 3L
  ),
  review_scope = "two_read_mixed_site_identity_partition",
  current_identity_decision = "unresolved",
  outside_evidence_status = "not_started",
  shared_geocoding_query_decision = "not_approved",
  source_rows_changed = FALSE
)]
setorder(
  questions,
  review_priority,
  development_state,
  development_names,
  mixed_site_question_id
)
questions[, manual_review_order := seq_len(.N)]
setorder(questions, mixed_site_question_id)
setorder(review_members, mixed_site_question_id, development_id)
setorder(review_pairs, mixed_site_question_id, mixed_site_pair_id)

if (nrow(questions) != 87L ||
    uniqueN(questions$mixed_site_question_id) != nrow(questions) ||
    questions[candidate_signal_class ==
      "strong_identity_evidence", .N] != 2L ||
    questions[candidate_signal_class ==
      "moderate_identity_evidence", .N] != 84L ||
    questions[candidate_signal_class ==
      "prior_decision_reopened", .N] != 1L ||
    nrow(review_members) != 195L ||
    uniqueN(review_members$development_id) != nrow(review_members) ||
    review_members[is_candidate_endpoint == TRUE, .N] != 181L ||
    review_members[is_candidate_endpoint == FALSE, .N] != 14L ||
    review_members[question_member_role ==
      "one_site_development", .N] != 102L ||
    review_members[question_member_role ==
      "multi_site_development", .N] != 93L ||
    nrow(review_pairs) != 109L ||
    review_pairs[strong_candidate == TRUE, .N] != 2L ||
    review_pairs[moderate_candidate == TRUE, .N] != 91L ||
    review_pairs[prior_decision_reopened == TRUE, .N] != 1L ||
    review_pairs[prior_reviewed_distinct == TRUE, .N] != 2L ||
    review_pairs[pair_review_stratum ==
      "component_context_only", .N] != 14L ||
    uniqueN(review_pairs$site_key) != 90L ||
    max(questions$n_developments) != 4L ||
    max(questions$n_cross_type_pairs) != 4L ||
    max(questions$n_shared_site_keys) != 2L ||
    any(questions$n_candidate_pairs == 0L) ||
    anyNA(review_members$n_shared_site_keys_in_question) ||
    any(questions$shared_geocoding_query_decision != "not_approved") ||
    any(review_members$shared_geocoding_query_decision != "not_approved") ||
    any(review_pairs$shared_geocoding_query_decision != "not_approved") ||
    any(questions$source_rows_changed) ||
    any(review_members$source_rows_changed) ||
    any(review_pairs$source_rows_changed)) {
  stop("A prepared mixed-site review contract failed.", call. = FALSE)
}

review_members[, c(
  "member_row",
  "component_root"
) := NULL]
review_pairs[, c(
  "component_root",
  "single_member_row",
  "multi_member_row"
) := NULL]
setcolorder(questions, c(
  "mixed_site_question_id",
  "manual_review_order",
  "review_priority",
  "candidate_signal_class",
  setdiff(names(questions), c(
    "mixed_site_question_id",
    "manual_review_order",
    "review_priority",
    "candidate_signal_class"
  ))
))
setcolorder(review_members, c(
  "mixed_site_question_id",
  "development_id",
  "question_member_role",
  "is_candidate_endpoint",
  setdiff(names(review_members), c(
    "mixed_site_question_id",
    "development_id",
    "question_member_role",
    "is_candidate_endpoint"
  ))
))
setcolorder(review_pairs, c(
  "mixed_site_question_id",
  "mixed_site_pair_id",
  "site_key",
  "single_address_development_id",
  "multi_address_development_id",
  "pair_review_stratum",
  setdiff(names(review_pairs), c(
    "mixed_site_question_id",
    "mixed_site_pair_id",
    "site_key",
    "single_address_development_id",
    "multi_address_development_id",
    "pair_review_stratum"
  ))
))

write_parquet(
  questions,
  "../output/lihtc_mixed_site_identity_questions.parquet",
  compression = "zstd"
)
write_parquet(
  review_members,
  "../output/lihtc_mixed_site_identity_question_members.parquet",
  compression = "zstd"
)
write_parquet(
  review_pairs,
  "../output/lihtc_mixed_site_identity_question_pairs.parquet",
  compression = "zstd"
)

if (!isTRUE(all.equal(
      questions,
      as.data.table(read_parquet(
        "../output/lihtc_mixed_site_identity_questions.parquet"
      ))
    )) || !isTRUE(all.equal(
      review_members,
      as.data.table(read_parquet(
        "../output/lihtc_mixed_site_identity_question_members.parquet"
      ))
    )) || !isTRUE(all.equal(
      review_pairs,
      as.data.table(read_parquet(
        "../output/lihtc_mixed_site_identity_question_pairs.parquet"
      ))
    ))) {
  stop("A mixed-site review output changed on Parquet round trip.",
    call. = FALSE)
}

cat(
  "Prepared 87 mixed-site identity questions with 195 developments and ",
  "94 candidate pairs; retained 78 prior-distinct constraints, reopened ",
  "one with frozen official evidence, and approved no query.\n",
  sep = ""
)
