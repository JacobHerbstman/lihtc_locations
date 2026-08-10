# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/audit_lihtc_cross_development_addresses_adjudicated/code")

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

collapse_key <- function(value) {
  value <- sort(unique(as.character(value[!is.na(value) & value != ""])))
  if (length(value) == 0L) NA_character_ else
    paste(value, collapse = "\u001F")
}

keys_overlap <- function(first_key, second_key) {
  if (is.na(first_key) || is.na(second_key)) {
    return(FALSE)
  }
  first_values <- strsplit(first_key, "\u001F", fixed = TRUE)[[1L]]
  second_values <- strsplit(second_key, "\u001F", fixed = TRUE)[[1L]]
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

site_evidence <- as.data.table(read_parquet(
  "../input/lihtc_site_geocoding_readiness.parquet"
))
development <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_address_adjudicated.parquet"
))
episode <- as.data.table(read_parquet(
  "../input/lihtc_project_episode_2024_address_adjudicated.parquet"
))
site <- as.data.table(read_parquet(
  "../input/lihtc_development_site_2024_address_adjudicated.parquet"
))
review_members <- as.data.table(read_parquet(
  paste0(
    "../input/",
    "lihtc_cross_development_address_member_decisions.parquet"
  )
))

if (nrow(site_evidence) != 134823L ||
    uniqueN(site_evidence$development_site_id) != nrow(site_evidence) ||
    nrow(development) != 54612L ||
    uniqueN(development$development_id) != nrow(development) ||
    nrow(episode) != 55345L || uniqueN(episode$hud_id) != nrow(episode) ||
    nrow(site) != 134646L ||
    uniqueN(site$development_site_id) != nrow(site) ||
    uniqueN(site, by = c("development_id", "site_key")) != nrow(site) ||
    nrow(review_members) != 279L ||
    uniqueN(review_members$development_id) != nrow(review_members)) {
  stop("An adjudicated audit input count or key changed.", call. = FALSE)
}
if (any(site_evidence$submission_approval != "not_approved") ||
    any(review_members$shared_geocoding_query_decision != "not_approved") ||
    any(!site$development_id %chin% development$development_id) ||
    any(!episode$development_id %chin% development$development_id)) {
  stop("An input foreign key or geocoding safety contract failed.",
    call. = FALSE)
}

development_mapping <- review_members[, .(
  pre_cross_address_review_development_id = development_id,
  development_id = adjudicated_development_id
)]
site_evidence[, pre_cross_address_review_development_id := development_id]
site_evidence[development_mapping, development_id := i.development_id,
  on = "pre_cross_address_review_development_id"]

site_index <- unique(site_evidence[, .(
  development_id,
  site_key,
  address_identity_key,
  geographic_scope
)])
if (uniqueN(site_index, by = c("development_id", "site_key")) !=
      nrow(site_index) ||
    uniqueN(site_index, by = c(
      "development_id", "address_identity_key"
    )) != nrow(site_index) ||
    nrow(site_index) != nrow(site)) {
  stop("Mapped readiness evidence does not collapse to the applied sites.",
    call. = FALSE)
}
site_index[site[, .(
  development_id,
  site_key,
  development_site_id
)], development_site_id := i.development_site_id,
on = c("development_id", "site_key")]
if (anyNA(site_index$development_site_id) ||
    !setequal(site_index$development_site_id, site$development_site_id)) {
  stop("An applied development site lacks local readiness evidence.",
    call. = FALSE)
}
site_evidence[site_index[, .(
  development_id,
  site_key,
  adjudicated_development_site_id = development_site_id
)], adjudicated_development_site_id :=
  i.adjudicated_development_site_id,
on = c("development_id", "site_key")]

in_scope_site <- site_index[
  geographic_scope == "in_scope_50_states_dc"
]
address_scope <- in_scope_site[, .(
  n_developments = uniqueN(development_id),
  n_site_rows = .N
), by = address_identity_key]
shared_address_keys <- address_scope[n_developments > 1L]
shared_site <- in_scope_site[shared_address_keys,
  on = "address_identity_key"]
shared_evidence <- site_evidence[
  address_identity_key %chin% shared_address_keys$address_identity_key
]
if (nrow(in_scope_site) != 133685L ||
    nrow(shared_site) != 13414L ||
    uniqueN(shared_site$address_identity_key) != 5560L ||
    shared_site[!is.na(development_site_id), .N] != nrow(shared_site) ||
    shared_evidence[submission_approval != "not_approved", .N] > 0L ||
    shared_evidence[!is.na(proposed_query_id), .N] > 0L) {
  stop("The adjudicated shared-address scope violates query safety.",
    call. = FALSE)
}

development_address_sets <- in_scope_site[, .(
  n_all_development_addresses = .N,
  complete_address_set_key = collapse_key(address_identity_key),
  complete_address_set_examples = collapse_text(
    address_identity_key,
    5L
  )
), by = development_id]
shared_complete_sets <- development_address_sets[, .(
  n_developments_same_complete_address_set = .N,
  complete_address_set_development_examples = collapse_text(development_id)
), by = complete_address_set_key][
  n_developments_same_complete_address_set > 1L
]
setorder(shared_complete_sets, complete_address_set_key)
shared_complete_sets[, complete_address_set_group_id := sprintf(
  "ACAS_%05d",
  seq_len(.N)
)]
development_address_sets[, `:=`(
  n_developments_same_complete_address_set = 1L,
  complete_address_set_development_examples = development_id,
  complete_address_set_group_id = NA_character_
)]
development_address_sets[shared_complete_sets, `:=`(
  n_developments_same_complete_address_set =
    i.n_developments_same_complete_address_set,
  complete_address_set_development_examples =
    i.complete_address_set_development_examples,
  complete_address_set_group_id = i.complete_address_set_group_id
), on = "complete_address_set_key"]

episode_summary <- episode[, .(
  observed_project_episodes = .N,
  hud_id_examples = collapse_text(hud_id),
  state_id_set_key = collapse_key(state_id),
  matchable_state_id_set_key = collapse_key(state_id[
    !is.na(state_id) & state_id != "" &
      !str_detect(state_id, "99-99|UNKNOWN|N/A|^9{6,}$")
  ]),
  state_id_examples = collapse_text(state_id),
  primary_site_set_key = collapse_key(primary_site_key),
  primary_site_examples = collapse_text(primary_site_key, 5L),
  allocation_year_examples = collapse_text(allocation_year),
  placed_in_service_year_examples = collapse_text(pis_year),
  episode_unit_examples = collapse_text(episode_units)
), by = development_id]

development_summary <- development[, .(
  development_id,
  development_name,
  development_name_key,
  development_state,
  development_city,
  n_project_episodes,
  first_pis_year,
  last_pis_year,
  any_resyndication_reported,
  construction_type_codes,
  episode_unit_count_max,
  episode_unit_count_sum,
  unit_aggregation_status,
  n_units_development,
  li_units_development,
  n_development_sites,
  cross_address_review_decision
)]
development_summary[episode_summary, `:=`(
  observed_project_episodes = i.observed_project_episodes,
  hud_id_examples = i.hud_id_examples,
  state_id_set_key = i.state_id_set_key,
  matchable_state_id_set_key = i.matchable_state_id_set_key,
  state_id_examples = i.state_id_examples,
  primary_site_set_key = i.primary_site_set_key,
  primary_site_examples = i.primary_site_examples,
  allocation_year_examples = i.allocation_year_examples,
  placed_in_service_year_examples = i.placed_in_service_year_examples,
  episode_unit_examples = i.episode_unit_examples
), on = "development_id"]
development_summary[development_address_sets, `:=`(
  n_all_development_addresses = i.n_all_development_addresses,
  complete_address_set_key = i.complete_address_set_key,
  complete_address_set_examples = i.complete_address_set_examples,
  n_developments_same_complete_address_set =
    i.n_developments_same_complete_address_set,
  complete_address_set_development_examples =
    i.complete_address_set_development_examples,
  complete_address_set_group_id = i.complete_address_set_group_id
), on = "development_id"]
if (anyNA(development_summary$observed_project_episodes) ||
    any(development_summary$observed_project_episodes !=
      development_summary$n_project_episodes)) {
  stop("An adjudicated development summary join failed.", call. = FALSE)
}

address_members <- shared_evidence[, .(
  n_site_rows = uniqueN(adjudicated_development_site_id),
  development_site_id_examples = collapse_text(
    adjudicated_development_site_id
  ),
  pre_review_development_id_examples = collapse_text(
    pre_cross_address_review_development_id
  ),
  published_street_examples = collapse_text(site_street, 5L),
  published_city_examples = collapse_text(site_city),
  published_state_examples = collapse_text(site_state),
  published_zip_examples = collapse_text(site_zip),
  normalized_street = first_text(query_street_key),
  normalized_city = first_text(query_city_key),
  normalized_state = first_text(query_state_key),
  normalized_zip_set_key = collapse_key(query_zip_key),
  normalized_zip_examples = collapse_text(query_zip),
  n_normalized_zip_values = uniqueN(
    query_zip_key[!is.na(query_zip_key)]
  ),
  site_source_examples = collapse_text(site_source),
  source_hud_id_examples = collapse_text(source_hud_ids),
  coordinate_set_key = collapse_key(coordinate_key),
  coordinate_examples = collapse_text(
    fifelse(
      coordinate_present,
      paste(latitude, longitude, sep = ","),
      NA_character_
    ),
    5L
  ),
  n_coordinate_pairs = uniqueN(
    coordinate_key[!is.na(coordinate_key)]
  ),
  any_address_form_problem = any(
    flag_po_box | flag_administrative_address |
      flag_scattered_or_unknown_label | flag_building_label_only |
      flag_parcel_or_legal_description | flag_intersection |
      flag_multiple_addresses | flag_address_range |
      flag_missing_structure_number | flag_missing_city |
      flag_missing_zip | flag_invalid_zip | flag_malformed_text
  ),
  any_source_problem = any(
    flag_source_zip_conflict | flag_source_unparsed_zip |
      flag_source_state_conflict | flag_zip_state_internal_conflict |
      flag_zip_state_internal_ambiguity | flag_placeholder_zip
  ) | uniqueN(query_zip_key[!is.na(query_zip_key)]) > 1L,
  any_coordinate_problem = any(
    flag_coordinate_global_range |
      flag_coordinate_outside_broad_state_group |
      flag_address_coordinate_conflict |
      flag_coordinate_reused_across_addresses
  ),
  all_queries_unapproved = all(submission_approval == "not_approved"),
  all_query_ids_missing = all(is.na(proposed_query_id))
), by = .(address_identity_key, development_id)]

address_members[development_summary, `:=`(
  development_name = i.development_name,
  development_name_key = i.development_name_key,
  development_state = i.development_state,
  development_city = i.development_city,
  n_project_episodes = i.n_project_episodes,
  hud_id_examples = i.hud_id_examples,
  state_id_set_key = i.state_id_set_key,
  matchable_state_id_set_key = i.matchable_state_id_set_key,
  state_id_examples = i.state_id_examples,
  primary_site_set_key = i.primary_site_set_key,
  primary_site_examples = i.primary_site_examples,
  first_pis_year = i.first_pis_year,
  last_pis_year = i.last_pis_year,
  allocation_year_examples = i.allocation_year_examples,
  placed_in_service_year_examples = i.placed_in_service_year_examples,
  episode_unit_examples = i.episode_unit_examples,
  any_resyndication_reported = i.any_resyndication_reported,
  construction_type_codes = i.construction_type_codes,
  episode_unit_count_max = i.episode_unit_count_max,
  episode_unit_count_sum = i.episode_unit_count_sum,
  unit_aggregation_status = i.unit_aggregation_status,
  n_units_development = i.n_units_development,
  li_units_development = i.li_units_development,
  n_development_sites = i.n_development_sites,
  n_all_development_addresses = i.n_all_development_addresses,
  complete_address_set_key = i.complete_address_set_key,
  complete_address_set_examples = i.complete_address_set_examples,
  n_developments_same_complete_address_set =
    i.n_developments_same_complete_address_set,
  complete_address_set_development_examples =
    i.complete_address_set_development_examples,
  complete_address_set_group_id = i.complete_address_set_group_id,
  cross_address_review_decision = i.cross_address_review_decision
), on = "development_id"]
if (anyNA(address_members$development_name) ||
    anyNA(address_members$n_all_development_addresses) ||
    uniqueN(address_members, by = c(
      "address_identity_key", "development_id"
    )) != nrow(address_members) ||
    any(address_members$n_site_rows != 1L) ||
    any(!address_members$all_queries_unapproved) ||
    any(!address_members$all_query_ids_missing)) {
  stop("An adjudicated shared-address member contract failed.",
    call. = FALSE)
}

address_groups <- address_members[, .(
  normalized_street = first_text(normalized_street),
  normalized_city = first_text(normalized_city),
  normalized_state = first_text(normalized_state),
  n_developments = .N,
  n_site_rows = sum(n_site_rows),
  n_development_names = uniqueN(development_name_key),
  name_pattern = fcase(
    uniqueN(development_name_key) == 1L,
    "all_same_normalized_name",
    uniqueN(development_name_key) < .N,
    "some_same_normalized_names",
    default = "all_normalized_names_distinct"
  ),
  development_id_examples = collapse_text(development_id),
  development_name_examples = collapse_text(development_name, 5L),
  hud_id_examples = collapse_text(hud_id_examples, 5L),
  state_id_examples = collapse_text(state_id_examples, 5L),
  first_pis_year = as.numeric(suppressWarnings(
    min(first_pis_year, na.rm = TRUE)
  )),
  last_pis_year = as.numeric(suppressWarnings(
    max(last_pis_year, na.rm = TRUE)
  )),
  episode_unit_examples = collapse_text(episode_unit_examples, 5L),
  maximum_complete_set_developments =
    max(n_developments_same_complete_address_set),
  complete_address_set_group_examples =
    collapse_text(complete_address_set_group_id, 5L),
  n_normalized_zip_values = uniqueN(
    unlist(strsplit(
      normalized_zip_set_key[!is.na(normalized_zip_set_key)],
      "\u001F",
      fixed = TRUE
    ))
  ),
  normalized_zip_examples = collapse_text(
    normalized_zip_examples
  ),
  n_coordinate_pairs = uniqueN(
    unlist(strsplit(
      coordinate_set_key[!is.na(coordinate_set_key)],
      "\u001F",
      fixed = TRUE
    ))
  ),
  coordinate_examples = collapse_text(coordinate_examples, 5L),
  site_source_examples = collapse_text(site_source_examples),
  any_address_form_problem = any(any_address_form_problem),
  any_source_problem = any(any_source_problem),
  any_coordinate_problem = any(any_coordinate_problem)
), by = address_identity_key]
address_groups[!is.finite(first_pis_year), first_pis_year := NA_real_]
address_groups[!is.finite(last_pis_year), last_pis_year := NA_real_]
setorder(
  address_groups,
  normalized_state,
  normalized_city,
  normalized_street,
  address_identity_key,
  na.last = TRUE
)
address_groups[, shared_address_group_id := sprintf(
  "ASAG_%05d",
  seq_len(.N)
)]
address_members[address_groups, shared_address_group_id :=
  i.shared_address_group_id, on = "address_identity_key"]

pair_address_evidence <- address_members[, {
  development_ids <- sort(unique(development_id))
  pair_matrix <- combn(development_ids, 2L)
  .(
    development_id_1 = pair_matrix[1L, ],
    development_id_2 = pair_matrix[2L, ]
  )
}, by = shared_address_group_id]
pair_address_evidence[address_members, `:=`(
  coordinate_set_key_1 = i.coordinate_set_key,
  member_address_problem_1 = i.any_address_form_problem,
  member_source_problem_1 = i.any_source_problem
), on = c(
  "shared_address_group_id",
  "development_id_1" = "development_id"
)]
pair_address_evidence[address_members, `:=`(
  coordinate_set_key_2 = i.coordinate_set_key,
  member_address_problem_2 = i.any_address_form_problem,
  member_source_problem_2 = i.any_source_problem
), on = c(
  "shared_address_group_id",
  "development_id_2" = "development_id"
)]
pair_address_evidence[address_groups, `:=`(
  address_identity_key = i.address_identity_key,
  shared_street = i.normalized_street,
  shared_city = i.normalized_city,
  shared_state = i.normalized_state,
  address_group_n_developments = i.n_developments,
  address_group_zip_values = i.n_normalized_zip_values,
  address_group_problem = i.any_address_form_problem,
  address_group_source_problem = i.any_source_problem
), on = "shared_address_group_id"]
pair_address_evidence[, shared_coordinate_pair := mapply(
  keys_overlap,
  coordinate_set_key_1,
  coordinate_set_key_2
)]

development_pairs <- pair_address_evidence[, .(
  n_shared_addresses = .N,
  shared_address_group_examples = collapse_text(
    shared_address_group_id,
    5L
  ),
  shared_address_examples = collapse_text(address_identity_key, 5L),
  shared_state = first_text(shared_state),
  maximum_developments_at_one_address =
    max(address_group_n_developments),
  n_shared_addresses_with_coordinate_overlap =
    sum(shared_coordinate_pair),
  any_shared_address_problem = any(
    address_group_problem | member_address_problem_1 |
      member_address_problem_2
  ),
  any_shared_source_problem = any(
    address_group_source_problem | member_source_problem_1 |
      member_source_problem_2
  ),
  any_shared_address_zip_disagreement = any(
    address_group_zip_values > 1L
  )
), by = .(development_id_1, development_id_2)]

development_pairs[development_summary, `:=`(
  development_name_1 = i.development_name,
  development_name_key_1 = i.development_name_key,
  development_city_1 = i.development_city,
  n_project_episodes_1 = i.n_project_episodes,
  hud_id_examples_1 = i.hud_id_examples,
  state_id_set_key_1 = i.state_id_set_key,
  matchable_state_id_set_key_1 = i.matchable_state_id_set_key,
  state_id_examples_1 = i.state_id_examples,
  primary_site_set_key_1 = i.primary_site_set_key,
  primary_site_examples_1 = i.primary_site_examples,
  first_pis_year_1 = i.first_pis_year,
  last_pis_year_1 = i.last_pis_year,
  allocation_year_examples_1 = i.allocation_year_examples,
  placed_in_service_year_examples_1 =
    i.placed_in_service_year_examples,
  episode_unit_count_max_1 = i.episode_unit_count_max,
  episode_unit_examples_1 = i.episode_unit_examples,
  n_all_development_addresses_1 = i.n_all_development_addresses,
  complete_address_set_key_1 = i.complete_address_set_key,
  complete_address_set_group_id_1 = i.complete_address_set_group_id,
  n_developments_same_complete_address_set_1 =
    i.n_developments_same_complete_address_set
), on = c("development_id_1" = "development_id")]
development_pairs[development_summary, `:=`(
  development_name_2 = i.development_name,
  development_name_key_2 = i.development_name_key,
  development_city_2 = i.development_city,
  n_project_episodes_2 = i.n_project_episodes,
  hud_id_examples_2 = i.hud_id_examples,
  state_id_set_key_2 = i.state_id_set_key,
  matchable_state_id_set_key_2 = i.matchable_state_id_set_key,
  state_id_examples_2 = i.state_id_examples,
  primary_site_set_key_2 = i.primary_site_set_key,
  primary_site_examples_2 = i.primary_site_examples,
  first_pis_year_2 = i.first_pis_year,
  last_pis_year_2 = i.last_pis_year,
  allocation_year_examples_2 = i.allocation_year_examples,
  placed_in_service_year_examples_2 =
    i.placed_in_service_year_examples,
  episode_unit_count_max_2 = i.episode_unit_count_max,
  episode_unit_examples_2 = i.episode_unit_examples,
  n_all_development_addresses_2 = i.n_all_development_addresses,
  complete_address_set_key_2 = i.complete_address_set_key,
  complete_address_set_group_id_2 = i.complete_address_set_group_id,
  n_developments_same_complete_address_set_2 =
    i.n_developments_same_complete_address_set
), on = c("development_id_2" = "development_id")]
if (anyNA(development_pairs$development_name_1) ||
    anyNA(development_pairs$development_name_2)) {
  stop("A development-pair identity join failed.", call. = FALSE)
}

retained_members <- review_members[
  final_identity_decision == "retain_separate",
  .(
    identity_question_id,
    development_id = adjudicated_development_id,
    final_reason_code,
    address_overlap_class
  )
]
retained_pairs <- retained_members[, {
  development_ids <- sort(unique(development_id))
  pair_matrix <- combn(development_ids, 2L)
  .(
    development_id_1 = pair_matrix[1L, ],
    development_id_2 = pair_matrix[2L, ],
    prior_identity_review_reason_code = first(final_reason_code),
    prior_address_overlap_class = first(address_overlap_class)
  )
}, by = identity_question_id]
if (uniqueN(retained_pairs, by = c(
      "development_id_1", "development_id_2"
    )) != nrow(retained_pairs)) {
  stop("A retained development pair belongs to multiple review questions.",
    call. = FALSE)
}
development_pairs[, `:=`(
  prior_identity_review_status = "not_reviewed",
  prior_identity_question_id = NA_character_,
  prior_identity_review_reason_code = NA_character_,
  prior_address_overlap_class = NA_character_
)]
development_pairs[retained_pairs, `:=`(
  prior_identity_review_status = "reviewed_retain_separate",
  prior_identity_question_id = i.identity_question_id,
  prior_identity_review_reason_code =
    i.prior_identity_review_reason_code,
  prior_address_overlap_class = i.prior_address_overlap_class
), on = c("development_id_1", "development_id_2")]

development_pairs[, `:=`(
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
    matchable_state_id_set_key_1,
    matchable_state_id_set_key_2
  ),
  any_primary_site_overlap = mapply(
    keys_overlap,
    primary_site_set_key_1,
    primary_site_set_key_2
  ),
  identical_complete_address_set =
    complete_address_set_key_1 == complete_address_set_key_2,
  equal_nonmissing_unit_max =
    !is.na(episode_unit_count_max_1) &
    episode_unit_count_max_1 == episode_unit_count_max_2,
  first_pis_year_gap = abs(first_pis_year_1 - first_pis_year_2),
  shared_address_fraction_1 =
    n_shared_addresses / n_all_development_addresses_1,
  shared_address_fraction_2 =
    n_shared_addresses / n_all_development_addresses_2
)]
component_name_pattern <- paste0(
  "\\b(PHASE|PROJECT|SITE|LOT|BUILDING|BLDG)[[:space:]]+",
  "[A-Z0-9IVX-]+"
)
development_pairs[, phase_or_component_name_signal :=
  str_detect(development_name_key_1, component_name_pattern) |
    str_detect(development_name_key_2, component_name_pattern)]
development_pairs[, `:=`(
  high_name_edit_similarity =
    !is.na(name_edit_similarity) & name_edit_similarity >= 0.90,
  high_name_token_similarity =
    !is.na(name_token_jaccard) & name_token_jaccard >= 0.80,
  equal_units_near_pis =
    equal_nonmissing_unit_max &
      !is.na(first_pis_year_gap) & first_pis_year_gap <= 2L,
  shared_coordinate_pair =
    n_shared_addresses_with_coordinate_overlap > 0L
)]
development_pairs[, pair_review_stratum := fcase(
  prior_identity_review_status == "reviewed_retain_separate",
  "reviewed_retain_separate",
  same_normalized_name | any_state_id_overlap,
  "identity_evidence_high",
  identical_complete_address_set,
  "identical_complete_set_different_names",
  phase_or_component_name_signal & (
    high_name_edit_similarity |
      high_name_token_similarity |
      (equal_units_near_pis & any_primary_site_overlap)
  ),
  "phase_or_component_review",
  high_name_edit_similarity |
    high_name_token_similarity |
    (equal_units_near_pis & any_primary_site_overlap),
  "name_or_timing_review",
  any_primary_site_overlap,
  "shared_primary_address",
  default = "shared_secondary_address"
)]
development_pairs[, pair_review_priority := fcase(
  pair_review_stratum == "identity_evidence_high", 1L,
  pair_review_stratum == "name_or_timing_review", 2L,
  pair_review_stratum == "phase_or_component_review", 3L,
  pair_review_stratum == "identical_complete_set_different_names", 4L,
  pair_review_stratum == "shared_primary_address", 5L,
  pair_review_stratum == "shared_secondary_address", 6L,
  default = 7L
)]
development_pairs[, review_signals := apply(
  .SD,
  1L,
  function(row) {
    labels <- c(
      "same_normalized_name",
      "state_id_overlap",
      "primary_site_overlap",
      "identical_complete_address_set",
      "high_name_edit_similarity",
      "high_name_token_similarity",
      "equal_units_near_pis",
      "phase_or_component_name",
      "shared_coordinate_pair",
      "address_form_problem",
      "source_problem",
      "zip_disagreement"
    )
    paste(labels[as.logical(row)], collapse = "|")
  }
), .SDcols = c(
  "same_normalized_name",
  "any_state_id_overlap",
  "any_primary_site_overlap",
  "identical_complete_address_set",
  "high_name_edit_similarity",
  "high_name_token_similarity",
  "equal_units_near_pis",
  "phase_or_component_name_signal",
  "shared_coordinate_pair",
  "any_shared_address_problem",
  "any_shared_source_problem",
  "any_shared_address_zip_disagreement"
)]
development_pairs[, `:=`(
  development_identity_decision = fifelse(
    prior_identity_review_status == "reviewed_retain_separate",
    "retain_separate",
    "unresolved"
  ),
  shared_geocoding_query_decision = "not_approved",
  outside_evidence_status = fifelse(
    prior_identity_review_status == "reviewed_retain_separate",
    "completed_two_pass_review",
    "not_started"
  ),
  source_rows_changed = FALSE
)]
setorder(development_pairs, development_id_1, development_id_2)
development_pairs[, shared_development_pair_id := sprintf(
  "ASAP_%05d",
  seq_len(.N)
)]
setorder(
  development_pairs,
  pair_review_priority,
  shared_state,
  development_name_1,
  development_name_2,
  development_id_1,
  development_id_2,
  na.last = TRUE
)
development_pairs[, manual_review_order := seq_len(.N)]

pair_address_evidence[development_pairs, `:=`(
  shared_development_pair_id = i.shared_development_pair_id,
  pair_review_stratum = i.pair_review_stratum,
  pair_review_priority = i.pair_review_priority
), on = c("development_id_1", "development_id_2")]
address_group_pair_summary <- pair_address_evidence[, .(
  n_development_pairs = .N,
  n_reviewed_retain_pairs = sum(
    pair_review_stratum == "reviewed_retain_separate"
  ),
  n_high_identity_pairs = sum(
    pair_review_stratum == "identity_evidence_high"
  ),
  n_name_or_timing_pairs = sum(
    pair_review_stratum == "name_or_timing_review"
  ),
  n_phase_or_component_pairs = sum(
    pair_review_stratum == "phase_or_component_review"
  ),
  n_identical_complete_set_pairs = sum(
    pair_review_stratum ==
      "identical_complete_set_different_names"
  ),
  n_shared_primary_pairs = sum(
    pair_review_stratum == "shared_primary_address"
  )
), by = shared_address_group_id]
address_groups[address_group_pair_summary, `:=`(
  n_development_pairs = i.n_development_pairs,
  n_reviewed_retain_pairs = i.n_reviewed_retain_pairs,
  n_high_identity_pairs = i.n_high_identity_pairs,
  n_name_or_timing_pairs = i.n_name_or_timing_pairs,
  n_phase_or_component_pairs = i.n_phase_or_component_pairs,
  n_identical_complete_set_pairs =
    i.n_identical_complete_set_pairs,
  n_shared_primary_pairs = i.n_shared_primary_pairs
), on = "shared_address_group_id"]
address_groups[, group_review_stratum := fcase(
  n_high_identity_pairs > 0L,
  "identity_evidence_high",
  n_name_or_timing_pairs > 0L,
  "name_or_timing_review",
  n_phase_or_component_pairs > 0L,
  "phase_or_component_review",
  n_reviewed_retain_pairs == n_development_pairs,
  "reviewed_identity_address_pending",
  n_identical_complete_set_pairs > 0L | n_developments >= 10L,
  "portfolio_or_complete_set_pattern",
  any_address_form_problem | any_source_problem,
  "address_or_source_review",
  n_shared_primary_pairs > 0L,
  "shared_primary_address",
  default = "shared_secondary_address"
)]
address_groups[, query_evidence_status := fcase(
  any_address_form_problem | any_source_problem |
    n_normalized_zip_values != 1L,
  "address_or_source_review_required",
  default = "locally_consistent_identity_or_address_review_pending"
)]
address_groups[, `:=`(
  development_identity_decision = fifelse(
    n_reviewed_retain_pairs == n_development_pairs,
    "members_reviewed_retain_separate",
    "unresolved"
  ),
  shared_geocoding_query_decision = "not_approved",
  source_rows_changed = FALSE
)]
address_members[address_groups, `:=`(
  group_review_stratum = i.group_review_stratum,
  query_evidence_status = i.query_evidence_status,
  development_identity_decision = i.development_identity_decision,
  shared_geocoding_query_decision =
    i.shared_geocoding_query_decision
), on = "shared_address_group_id"]

manual_review_sample <- copy(development_pairs[
  prior_identity_review_status == "not_reviewed"
])
setorder(
  manual_review_sample,
  pair_review_priority,
  -same_normalized_name,
  -any_state_id_overlap,
  -name_edit_similarity,
  -name_token_jaccard,
  shared_state,
  development_id_1,
  development_id_2,
  na.last = TRUE
)
manual_review_sample[, stratum_sample_rank := seq_len(.N),
  by = pair_review_stratum]
manual_review_sample <- manual_review_sample[
  stratum_sample_rank <= 40L,
  .(
    stratum_sample_rank,
    shared_development_pair_id,
    manual_review_order,
    pair_review_stratum,
    pair_review_priority,
    development_id_1,
    development_name_1,
    hud_id_examples_1,
    state_id_examples_1,
    first_pis_year_1,
    episode_unit_count_max_1,
    development_id_2,
    development_name_2,
    hud_id_examples_2,
    state_id_examples_2,
    first_pis_year_2,
    episode_unit_count_max_2,
    n_shared_addresses,
    shared_address_examples,
    same_normalized_name,
    name_edit_similarity,
    name_token_jaccard,
    any_state_id_overlap,
    any_primary_site_overlap,
    identical_complete_address_set,
    equal_nonmissing_unit_max,
    first_pis_year_gap,
    phase_or_component_name_signal,
    review_signals,
    development_identity_decision,
    shared_geocoding_query_decision,
    outside_evidence_status
  )
]

group_size_counts <- address_groups[, .(
  address_groups = .N,
  site_rows = sum(n_site_rows)
), by = n_developments][order(n_developments)]
group_stratum_counts <- address_groups[, .(
  address_groups = .N,
  site_rows = sum(n_site_rows),
  development_members = sum(n_developments)
), by = group_review_stratum][order(group_review_stratum)]
pair_stratum_counts <- development_pairs[, .(
  pair_review_priority = min(pair_review_priority),
  development_pairs = .N,
  shared_address_pair_rows = sum(n_shared_addresses)
), by = pair_review_stratum][order(pair_review_priority)]
pair_stratum_counts[, pair_review_priority := NULL]
query_evidence_counts <- address_groups[, .(
  address_groups = .N,
  site_rows = sum(n_site_rows),
  development_members = sum(n_developments)
), by = query_evidence_status][order(query_evidence_status)]
largest_groups <- address_groups[
  order(-n_developments, normalized_state, normalized_city),
  .(
    shared_address_group_id,
    normalized_street,
    normalized_city,
    normalized_state,
    n_developments,
    group_review_stratum,
    development_name_examples
  )
][seq_len(min(15L, nrow(address_groups)))]

summary_lines <- c(
  "# Adjudicated LIHTC Cross-Development Shared-Address Audit",
  "",
  "## Safety contract",
  "",
  "- This task is entirely local. It calls no geocoder and transmits no address or coordinate.",
  "- It maps prior readiness evidence to adjudicated development IDs but does not edit a source row.",
  "- Previously retained identity questions remain separate; every other pair remains unresolved.",
  "- Every shared geocoding query remains `not_approved`.",
  "",
  "## Effect of the completed identity review",
  "",
  paste0(
    "- Physical developments fell from 54,725 to ",
    format(nrow(development), big.mark = ","),
    "."
  ),
  paste0(
    "- In-scope site rows fell from 133,862 to ",
    format(nrow(in_scope_site), big.mark = ","),
    "."
  ),
  paste0(
    "- Shared-address site rows fell from 13,706 to ",
    format(nrow(shared_site), big.mark = ","),
    "."
  ),
  paste0(
    "- Shared-address groups fell from 5,675 to ",
    format(nrow(address_groups), big.mark = ","),
    "."
  ),
  paste0(
    "- Unique development pairs fell from 6,688 to ",
    format(nrow(development_pairs), big.mark = ","),
    "."
  ),
  paste0(
    "- Remaining pairs already reviewed and retained separate: ",
    format(development_pairs[
      prior_identity_review_status == "reviewed_retain_separate",
      .N
    ], big.mark = ","),
    "."
  ),
  "",
  "### Shared-address group size",
  "",
  format_markdown_table(group_size_counts),
  "",
  "## Remaining pair strata",
  "",
  paste0(
    "`reviewed_retain_separate` pairs have completed internal and outside-source identity review. ",
    "All other strata still require review before an identity or address decision changes."
  ),
  "",
  format_markdown_table(pair_stratum_counts),
  "",
  "### Address-group strata",
  "",
  format_markdown_table(group_stratum_counts),
  "",
  "## Local query evidence",
  "",
  paste0(
    "Local consistency means one normalized ZIP and no detected address-form or source conflict. ",
    "It does not resolve development identity and does not authorize geocoding."
  ),
  "",
  format_markdown_table(query_evidence_counts),
  "",
  "## Large and repeated source patterns",
  "",
  paste0(
    "- Unreviewed pairs with identical complete address sets and different normalized names: ",
    format(development_pairs[
      pair_review_stratum ==
        "identical_complete_set_different_names",
      .N
    ], big.mark = ","),
    "."
  ),
  paste0(
    "- Shared-address groups containing at least ten developments: ",
    format(address_groups[n_developments >= 10L, .N], big.mark = ","),
    "."
  ),
  "",
  "### Largest shared-address groups",
  "",
  format_markdown_table(largest_groups),
  "",
  "## Next local work",
  "",
  paste0(
    "Review the remaining high name/timing and phase/component pairs, then inspect ",
    "compound addresses, ranges, placeholders, and portfolio source patterns. ",
    "No geocoding pilot is approved."
  ),
  ""
)

if (uniqueN(address_groups$shared_address_group_id) !=
      nrow(address_groups) ||
    nrow(address_groups) != 5560L ||
    nrow(address_members) != 13414L ||
    nrow(development_pairs) != 6483L ||
    development_pairs[
      prior_identity_review_status == "reviewed_retain_separate",
      .N
    ] != 37L ||
    development_pairs[pair_review_stratum == "identity_evidence_high", .N] !=
      0L ||
    uniqueN(address_groups$address_identity_key) != nrow(address_groups) ||
    uniqueN(address_members, by = c(
      "shared_address_group_id", "development_id"
    )) != nrow(address_members) ||
    uniqueN(development_pairs$shared_development_pair_id) !=
      nrow(development_pairs) ||
    uniqueN(development_pairs, by = c(
      "development_id_1", "development_id_2"
    )) != nrow(development_pairs) ||
    any(address_groups$shared_geocoding_query_decision !=
      "not_approved") ||
    any(development_pairs$shared_geocoding_query_decision !=
      "not_approved") ||
    any(address_groups$source_rows_changed) ||
    any(development_pairs$source_rows_changed) ||
    development_pairs[
      prior_identity_review_status == "reviewed_retain_separate" &
        development_identity_decision != "retain_separate",
      .N
    ] > 0L ||
    development_pairs[
      prior_identity_review_status == "not_reviewed" &
        development_identity_decision != "unresolved",
      .N
    ] > 0L) {
  stop("The adjudicated shared-address audit safety contract failed.",
    call. = FALSE)
}

setorder(address_groups, shared_address_group_id)
setorder(address_members, shared_address_group_id, development_id)
setorder(development_pairs, manual_review_order)
setindexv(address_groups, NULL)
setindexv(address_members, NULL)
setindexv(development_pairs, NULL)
fwrite(
  manual_review_sample,
  "../output/manual_review_sample.csv",
  na = ""
)
write_parquet(
  address_groups,
  paste0(
    "../output/",
    "lihtc_cross_development_address_groups_adjudicated.parquet"
  ),
  compression = "zstd"
)
write_parquet(
  address_members,
  paste0(
    "../output/",
    "lihtc_cross_development_address_members_adjudicated.parquet"
  ),
  compression = "zstd"
)
write_parquet(
  development_pairs,
  "../output/lihtc_cross_development_pairs_adjudicated.parquet",
  compression = "zstd"
)
writeLines(summary_lines, "../output/audit_summary.md")

if (!identical(
  address_groups,
  as.data.table(read_parquet(paste0(
    "../output/",
    "lihtc_cross_development_address_groups_adjudicated.parquet"
  )))
) || !identical(
  address_members,
  as.data.table(read_parquet(paste0(
    "../output/",
    "lihtc_cross_development_address_members_adjudicated.parquet"
  )))
) || !identical(
  development_pairs,
  as.data.table(read_parquet(
    "../output/lihtc_cross_development_pairs_adjudicated.parquet"
  ))
)) {
  stop("An adjudicated shared-address Parquet changed on round trip.",
    call. = FALSE)
}

cat(
  "Re-audited ",
  format(nrow(address_groups), big.mark = ","),
  " shared addresses and ",
  format(nrow(development_pairs), big.mark = ","),
  " development pairs after identity adjudication; no query approved.\n",
  sep = ""
)
