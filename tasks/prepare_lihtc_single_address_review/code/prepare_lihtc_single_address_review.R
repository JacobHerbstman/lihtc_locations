# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/prepare_lihtc_single_address_review/code")

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

collapse_delimited <- function(value) {
  tokens <- unlist(strsplit(
    value[!is.na(value) & value != ""],
    "|",
    fixed = TRUE
  ))
  tokens <- sort(unique(trimws(tokens[tokens != ""])))
  if (length(tokens) == 0L) NA_character_ else
    paste(tokens, collapse = "|")
}

shared_delimited <- function(first_value, second_value) {
  if (is.na(first_value) || is.na(second_value)) {
    return(NA_character_)
  }
  first_tokens <- strsplit(first_value, "|", fixed = TRUE)[[1L]]
  second_tokens <- strsplit(second_value, "|", fixed = TRUE)[[1L]]
  shared_tokens <- sort(intersect(first_tokens, second_tokens))
  if (length(shared_tokens) == 0L) NA_character_ else
    paste(shared_tokens, collapse = "|")
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

component_root_name <- function(value) {
  value <- str_replace_all(
    value,
    paste0(
      "\\b(PHASE|PROJECT|SITE|LOT|BUILDING|BLDG)",
      "[[:space:]]*[A-Z0-9IVX-]+\\b"
    ),
    ""
  )
  value <- str_replace_all(
    value,
    "\\b(PHASE|PROJECT|SITE|LOT|BUILDING|BLDG)\\b",
    ""
  )
  value <- str_replace_all(
    value,
    "\\b([0-9]+[A-Z]?|[IVX]{1,8}[A-B]?|[A-Z]{1,2})\\b",
    ""
  )
  value <- str_replace_all(
    value,
    "\\b(NORTH|SOUTH|EAST|WEST)\\b",
    ""
  )
  str_squish(value)
}

development <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_identical_address_adjudicated.parquet"
))
episode <- as.data.table(read_parquet(
  "../input/lihtc_project_episode_2024_identical_address_adjudicated.parquet"
))
site <- as.data.table(read_parquet(
  "../input/lihtc_development_site_2024_identical_address_adjudicated.parquet"
))

if (nrow(development) != 54257L ||
    uniqueN(development$development_id) != nrow(development) ||
    nrow(episode) != 55345L || uniqueN(episode$hud_id) != nrow(episode) ||
    nrow(site) != 133551L ||
    uniqueN(site$development_site_id) != nrow(site) ||
    uniqueN(site, by = c("development_id", "site_key")) != nrow(site) ||
    any(!episode$development_id %chin% development$development_id) ||
    any(!site$development_id %chin% development$development_id)) {
  stop("A single-address review input count or key changed.",
    call. = FALSE)
}

valid_states <- c(state.abb, "DC")
site_scope <- development[, .(
  development_id,
  n_development_sites,
  development_name,
  cross_address_review_reason_code,
  cross_address_round2_review_reason_codes
)][site, on = "development_id", nomatch = 0L]
site_scope[, address_review_text := fcoalesce(
  str_to_upper(str_squish(site_street)),
  ""
)]
site_scope[, `:=`(
  flag_scattered_or_unknown_label = str_detect(
    address_review_text,
    paste0(
      "^(MULTIPLE|VARIOUS|SCATTERED)[[:space:]]+",
      "(BUILDING[[:space:]]+)?",
      "(ADDRESS|ADDRESSES|LOCATIONS)([^A-Z]|$)"
    )
  ),
  flag_multiple_addresses =
    str_detect(address_review_text, ";") |
      str_detect(
        address_review_text,
        "^[0-9]+[A-Z]?([[:space:]]*,[[:space:]]*[0-9]+[A-Z]?)+"
      ) |
      str_detect(
        address_review_text,
        paste0(
          "^[0-9]+[A-Z]?[[:space:]]+(&|AND)",
          "[[:space:]]+[0-9]+[A-Z]?"
        )
      ) |
      str_detect(
        address_review_text,
        "[0-9]+[[:space:]]*/[[:space:]]*[0-9]+"
      ) |
      str_detect(
        address_review_text,
        "[[:space:]][+][[:space:]]*[0-9]+"
      ) |
      str_detect(address_review_text, "&AMP;"),
  flag_address_range = str_detect(
    address_review_text,
    "^[0-9]+[A-Z]?[[:space:]]*(-|–|TO)[[:space:]]*[0-9]+"
  ),
  flag_po_box = str_detect(
    address_review_text,
    paste0(
      "(^|[^A-Z])(P[.]?[[:space:]]*O[.]?|POST OFFICE)",
      "[[:space:]]*BOX([^A-Z]|$)|^BOX[[:space:]]+[0-9]"
    )
  ),
  flag_administrative_address = str_detect(
    address_review_text,
    "^(C/O|CARE OF|OFFICE|MANAGEMENT OFFICE)([^A-Z]|$)"
  ),
  flag_parcel_or_legal_description = str_detect(
    address_review_text,
    paste0(
      "(^|[^A-Z])(VACANT PARCEL|PARCEL|TAX MAP|APN|",
      "LEGAL DESCRIPTION|PLAT NO[.]?|TOWNSHIP)([^A-Z]|$)|",
      "^LOT[[:space:]]+[A-Z0-9]"
    )
  ),
  flag_intersection = str_detect(
    address_review_text,
    "(^|[^A-Z])(INTERSECTION|CORNER OF)([^A-Z]|$)"
  ) | (
    !str_detect(
      address_review_text,
      "^[0-9]+[A-Z]?([^0-9A-Z]|$)"
    ) &
      str_detect(
        address_review_text,
        "[[:space:]](&|AND)[[:space:]]"
      )
  ),
  flag_building_label_only = str_detect(
    address_review_text,
    paste0(
      "^(TBD[[:space:]]+)?(BLDG|BUILDING)[[:space:]]+",
      "[A-Z0-9.-]+([[:space:]]+ADDRESS[[:space:]]+TBD)?$"
    )
  ),
  flag_missing_structure_number = !str_detect(
    address_review_text,
    "^[0-9]+[A-Z]?([^0-9A-Z]|$)"
  ),
  flag_prior_source_or_portfolio_problem =
    str_detect(fcoalesce(development_name, ""), "PORTFOLIO") |
      str_detect(
        fcoalesce(cross_address_review_reason_code, ""),
        "bad_or_placeholder_shared_source_address|source_cross_listing|portfolio"
      ) |
      str_detect(
        fcoalesce(cross_address_round2_review_reason_codes, ""),
        "bad_or_placeholder_shared_source_address|source_cross_listing|portfolio"
      )
)]
site_scope[, deferred_address_form :=
  flag_scattered_or_unknown_label |
    flag_multiple_addresses |
    flag_address_range |
    flag_po_box |
    flag_administrative_address |
    flag_parcel_or_legal_description |
    flag_intersection |
    flag_building_label_only |
    flag_missing_structure_number |
    flag_prior_source_or_portfolio_problem]

shared_one_key_groups <- site_scope[, .(
  n_developments = uniqueN(development_id),
  all_members_single_address = all(n_development_sites == 1L),
  all_members_in_scope = all(site_state %chin% valid_states),
  all_members_have_singular_physical_address = all(
    deferred_address_form == FALSE
  )
), by = site_key][
  n_developments > 1L &
    all_members_single_address == TRUE &
    all_members_in_scope == TRUE
]
shared_single_address_groups <- shared_one_key_groups[
  all_members_have_singular_physical_address == TRUE
]
shared_single_address_members <- unique(site_scope[
  shared_single_address_groups,
  on = "site_key",
  nomatch = 0L
])
setorder(shared_single_address_members, site_key, development_id)

all_pairs <- shared_single_address_members[, {
  development_ids <- sort(unique(development_id))
  combinations <- combn(development_ids, 2L)
  .(
    development_id_1 = combinations[1L, ],
    development_id_2 = combinations[2L, ]
  )
}, by = site_key]

prior_evidence <- development[, .(
  development_id,
  prior_cross_address_question_ids =
    cross_address_identity_question_id,
  prior_cross_address_review_decisions =
    cross_address_review_decision,
  prior_cross_address_review_reason_codes =
    cross_address_review_reason_code
)]
all_pairs[prior_evidence, `:=`(
  prior_cross_address_question_ids_1 =
    i.prior_cross_address_question_ids,
  prior_cross_address_review_decisions_1 =
    i.prior_cross_address_review_decisions,
  prior_cross_address_review_reason_codes_1 =
    i.prior_cross_address_review_reason_codes
), on = c(development_id_1 = "development_id")]
all_pairs[prior_evidence, `:=`(
  prior_cross_address_question_ids_2 =
    i.prior_cross_address_question_ids,
  prior_cross_address_review_decisions_2 =
    i.prior_cross_address_review_decisions,
  prior_cross_address_review_reason_codes_2 =
    i.prior_cross_address_review_reason_codes
), on = c(development_id_2 = "development_id")]
all_pairs[, prior_review_question_ids := mapply(
  shared_delimited,
  prior_cross_address_question_ids_1,
  prior_cross_address_question_ids_2
)]
all_pairs[, prior_reviewed_distinct :=
  !is.na(prior_review_question_ids) &
    !is.na(prior_cross_address_review_decisions_1) &
    !is.na(prior_cross_address_review_decisions_2) &
    str_detect(
      prior_cross_address_review_decisions_1,
      "(^|\\|)retain_separate($|\\|)"
    ) &
    str_detect(
      prior_cross_address_review_decisions_2,
      "(^|\\|)retain_separate($|\\|)"
    )]

if (nrow(shared_one_key_groups) != 1332L ||
    shared_one_key_groups[
      all_members_have_singular_physical_address == FALSE,
      .N
    ] != 177L ||
    nrow(shared_single_address_groups) != 1155L ||
    nrow(shared_single_address_members) != 2476L ||
    nrow(all_pairs) != 1626L ||
    all_pairs[prior_reviewed_distinct == TRUE, .N] != 9L) {
  stop("The complete single-address shared-address scope changed.",
    call. = FALSE)
}

question_scope <- all_pairs[, .(
  n_unresolved_pairs = sum(!prior_reviewed_distinct),
  n_prior_reviewed_distinct_pairs = sum(prior_reviewed_distinct)
), by = site_key][n_unresolved_pairs > 0L]
question_members <- shared_single_address_members[
  site_key %chin% question_scope$site_key,
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
]
question_pairs <- all_pairs[
  site_key %chin% question_scope$site_key
]

question_order <- question_members[, .(
  site_state = collapse_text(site_state),
  site_city = collapse_text(site_city),
  site_street = collapse_text(site_street),
  site_zip = collapse_text(site_zip)
), by = site_key]
setorder(
  question_order,
  site_state,
  site_city,
  site_street,
  site_zip,
  site_key
)
question_order[, single_address_question_id := sprintf(
  "SAQ_%04d",
  seq_len(.N)
)]
question_members[question_order, single_address_question_id :=
  i.single_address_question_id, on = "site_key"]
question_pairs[question_order, single_address_question_id :=
  i.single_address_question_id, on = "site_key"]

episode_summary <- episode[, .(
  hud_ids = collapse_text(hud_id),
  state_id_examples = collapse_text(state_id),
  state_id_set_key = collapse_delimited(state_id[
    !is.na(state_id) & state_id != "" &
      !str_detect(state_id, "99-99|UNKNOWN|N/A|^9{6,}$")
  ]),
  primary_site_set_key = collapse_delimited(primary_site_key),
  project_name_examples = collapse_text(project),
  project_address_examples = collapse_text(proj_add),
  project_city_examples = collapse_text(proj_cty),
  project_zip_examples = collapse_text(proj_zip),
  allocation_year_examples = collapse_text(allocation_year),
  placed_in_service_year_examples = collapse_text(pis_year),
  episode_unit_examples = collapse_text(episode_units),
  episode_low_income_unit_examples = collapse_text(
    episode_low_income_units
  )
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
  cross_address_identity_question_id,
  cross_address_review_decision,
  cross_address_review_reason_code
)]
question_members[development_evidence, `:=`(
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
  prior_cross_address_question_ids =
    i.cross_address_identity_question_id,
  prior_cross_address_review_decisions =
    i.cross_address_review_decision,
  prior_cross_address_review_reason_codes =
    i.cross_address_review_reason_code
), on = "development_id"]
question_members[episode_summary, `:=`(
  hud_ids = i.hud_ids,
  state_id_examples = i.state_id_examples,
  state_id_set_key = i.state_id_set_key,
  primary_site_set_key = i.primary_site_set_key,
  project_name_examples = i.project_name_examples,
  project_address_examples = i.project_address_examples,
  project_city_examples = i.project_city_examples,
  project_zip_examples = i.project_zip_examples,
  allocation_year_examples = i.allocation_year_examples,
  placed_in_service_year_examples =
    i.placed_in_service_year_examples,
  episode_unit_examples = i.episode_unit_examples,
  episode_low_income_unit_examples =
    i.episode_low_income_unit_examples
), on = "development_id"]

if (nrow(question_scope) != 1149L ||
    nrow(question_members) != 2463L ||
    nrow(question_pairs) != 1618L ||
    question_pairs[prior_reviewed_distinct == FALSE, .N] != 1617L ||
    question_pairs[prior_reviewed_distinct == TRUE, .N] != 1L ||
    uniqueN(question_members$development_id) != nrow(question_members) ||
    any(question_members$n_development_sites != 1L) ||
    any(!question_members$site_state %chin% valid_states) ||
    anyNA(question_members[, .(
      single_address_question_id,
      development_name,
      development_state,
      hud_ids
    )])) {
  stop("The unresolved single-address question scope is inconsistent.",
    call. = FALSE)
}

pair_evidence <- question_members[, .(
  development_id,
  development_name,
  development_name_key,
  development_city,
  hud_ids,
  state_id_set_key,
  primary_site_set_key,
  first_pis_year,
  last_pis_year,
  episode_unit_count_max,
  n_units_development,
  li_units_development
)]
question_pairs[pair_evidence, `:=`(
  development_name_1 = i.development_name,
  development_name_key_1 = i.development_name_key,
  development_city_1 = i.development_city,
  hud_ids_1 = i.hud_ids,
  state_id_set_key_1 = i.state_id_set_key,
  primary_site_set_key_1 = i.primary_site_set_key,
  first_pis_year_1 = i.first_pis_year,
  last_pis_year_1 = i.last_pis_year,
  episode_unit_count_max_1 = i.episode_unit_count_max,
  n_units_development_1 = i.n_units_development,
  li_units_development_1 = i.li_units_development
), on = c(development_id_1 = "development_id")]
question_pairs[pair_evidence, `:=`(
  development_name_2 = i.development_name,
  development_name_key_2 = i.development_name_key,
  development_city_2 = i.development_city,
  hud_ids_2 = i.hud_ids,
  state_id_set_key_2 = i.state_id_set_key,
  primary_site_set_key_2 = i.primary_site_set_key,
  first_pis_year_2 = i.first_pis_year,
  last_pis_year_2 = i.last_pis_year,
  episode_unit_count_max_2 = i.episode_unit_count_max,
  n_units_development_2 = i.n_units_development,
  li_units_development_2 = i.li_units_development
), on = c(development_id_2 = "development_id")]

question_pairs[, `:=`(
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
  shared_state_ids = mapply(
    shared_delimited,
    state_id_set_key_1,
    state_id_set_key_2
  ),
  shared_primary_site_keys = mapply(
    shared_delimited,
    primary_site_set_key_1,
    primary_site_set_key_2
  ),
  equal_nonmissing_unit_max =
    !is.na(episode_unit_count_max_1) &
      episode_unit_count_max_1 == episode_unit_count_max_2,
  first_pis_year_gap = abs(first_pis_year_1 - first_pis_year_2)
)]
component_name_pattern <-
  "\\b(PHASE|PROJECT|SITE|LOT|BUILDING|BLDG)([[:space:]]+|$)"
component_marker_pattern <-
  "\\b([0-9]+[A-Z]?|[IVX]{1,8}[A-B]?)\\b"
question_pairs[, `:=`(
  component_root_name_1 = component_root_name(development_name_key_1),
  component_root_name_2 = component_root_name(development_name_key_2),
  component_marker_1 =
    !str_detect(development_name_key_1, "^[0-9]+\\b") &
      str_detect(development_name_key_1, component_marker_pattern),
  component_marker_2 =
    !str_detect(development_name_key_2, "^[0-9]+\\b") &
      str_detect(development_name_key_2, component_marker_pattern)
)]
question_pairs[, phase_or_component_name_signal :=
  str_detect(development_name_key_1, component_name_pattern) |
    str_detect(development_name_key_2, component_name_pattern) |
    component_marker_1 |
    component_marker_2 |
    (
      component_root_name_1 != "" &
        component_root_name_1 == component_root_name_2 &
        development_name_key_1 != development_name_key_2
    )]
question_pairs[, `:=`(
  any_state_id_overlap = !is.na(shared_state_ids),
  any_primary_site_overlap = !is.na(shared_primary_site_keys),
  high_name_similarity =
    (!is.na(name_edit_similarity) & name_edit_similarity >= 0.90) |
      (!is.na(name_token_jaccard) & name_token_jaccard >= 0.80),
  equal_units_near_pis =
    equal_nonmissing_unit_max &
      !is.na(first_pis_year_gap) & first_pis_year_gap <= 2L
)]
question_pairs[, pair_review_stratum := fcase(
  prior_reviewed_distinct,
  "prior_reviewed_distinct",
  phase_or_component_name_signal &
    (high_name_similarity | equal_units_near_pis),
  "phase_or_component",
  high_name_similarity | equal_units_near_pis,
  "name_or_timing",
  default = "shared_address_only"
)]
question_pairs[, `:=`(
  requires_new_identity_review = !prior_reviewed_distinct,
  current_identity_decision = fifelse(
    prior_reviewed_distinct,
    "retain_separate",
    "unresolved"
  ),
  outside_evidence_status = fifelse(
    prior_reviewed_distinct,
    "completed_prior_two_pass_review",
    "not_started"
  ),
  shared_geocoding_query_decision = "not_approved",
  source_rows_changed = FALSE
)]

setorder(
  question_pairs,
  single_address_question_id,
  development_id_1,
  development_id_2
)
question_pairs[, single_address_pair_id := sprintf(
  "SAP_%05d",
  seq_len(.N)
)]

pair_summary <- question_pairs[, .(
  n_pairs = .N,
  n_unresolved_pairs = sum(requires_new_identity_review),
  n_prior_reviewed_distinct_pairs = sum(prior_reviewed_distinct),
  n_phase_or_component_pairs = sum(
    pair_review_stratum == "phase_or_component"
  ),
  n_name_or_timing_pairs = sum(
    pair_review_stratum == "name_or_timing"
  ),
  n_shared_address_only_pairs = sum(
    pair_review_stratum == "shared_address_only"
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
  any_equal_units_near_pis = any(equal_units_near_pis)
), by = single_address_question_id]
pair_summary[!is.finite(maximum_name_edit_similarity),
  maximum_name_edit_similarity := NA_real_]
pair_summary[!is.finite(maximum_name_token_jaccard),
  maximum_name_token_jaccard := NA_real_]
pair_summary[!is.finite(minimum_first_pis_year_gap),
  minimum_first_pis_year_gap := NA_real_]

questions <- question_members[, .(
  site_key = site_key[1L],
  site_street_examples = collapse_text(site_street),
  site_city_examples = collapse_text(site_city),
  site_state = collapse_text(site_state),
  site_zip_examples = collapse_text(site_zip),
  n_developments = .N,
  n_normalized_names = uniqueN(development_name_key),
  development_ids = collapse_text(development_id),
  development_names = collapse_text(development_name),
  development_cities = collapse_text(development_city),
  development_anchor_hud_ids = collapse_text(
    development_anchor_hud_id
  ),
  first_pis_year_examples = collapse_text(first_pis_year),
  last_pis_year_examples = collapse_text(last_pis_year),
  episode_unit_max_examples = collapse_text(episode_unit_count_max),
  development_unit_examples = collapse_text(n_units_development),
  low_income_unit_examples = collapse_text(li_units_development)
), by = single_address_question_id]
questions[pair_summary, `:=`(
  n_pairs = i.n_pairs,
  n_unresolved_pairs = i.n_unresolved_pairs,
  n_prior_reviewed_distinct_pairs =
    i.n_prior_reviewed_distinct_pairs,
  n_phase_or_component_pairs = i.n_phase_or_component_pairs,
  n_name_or_timing_pairs = i.n_name_or_timing_pairs,
  n_shared_address_only_pairs = i.n_shared_address_only_pairs,
  maximum_name_edit_similarity = i.maximum_name_edit_similarity,
  maximum_name_token_jaccard = i.maximum_name_token_jaccard,
  minimum_first_pis_year_gap = i.minimum_first_pis_year_gap,
  any_equal_units_near_pis = i.any_equal_units_near_pis
), on = "single_address_question_id"]
questions[, review_stratum := fcase(
  n_prior_reviewed_distinct_pairs > 0L,
  "prior_distinct_constraint",
  n_phase_or_component_pairs > 0L,
  "phase_or_component_evidence",
  n_name_or_timing_pairs > 0L,
  "name_or_timing_evidence",
  default = "shared_address_only"
)]
questions[, `:=`(
  review_scope = "two_read_single_address_identity_partition",
  outside_evidence_status = "not_started",
  current_identity_decision = "unresolved",
  shared_geocoding_query_decision = "not_approved",
  source_rows_changed = FALSE
)]
setorder(
  questions,
  site_state,
  review_stratum,
  site_city_examples,
  site_street_examples,
  single_address_question_id
)
questions[, manual_review_order := seq_len(.N)]
setorder(questions, single_address_question_id)
setorder(question_members, single_address_question_id, development_id)

if (uniqueN(questions$single_address_question_id) != nrow(questions) ||
    uniqueN(question_members$development_id) != nrow(question_members) ||
    uniqueN(question_pairs$single_address_pair_id) != nrow(question_pairs) ||
    uniqueN(question_pairs, by = c(
      "development_id_1", "development_id_2"
    )) != nrow(question_pairs) ||
    any(question_pairs$development_id_1 >=
      question_pairs$development_id_2) ||
    question_pairs[
      pair_review_stratum == "prior_reviewed_distinct",
      .N
    ] != 1L ||
    question_pairs[
      requires_new_identity_review == TRUE,
      any(same_normalized_name | any_state_id_overlap)
    ] ||
    any(questions$shared_geocoding_query_decision != "not_approved") ||
    any(question_pairs$shared_geocoding_query_decision != "not_approved") ||
    any(questions$source_rows_changed) ||
    any(question_pairs$source_rows_changed)) {
  stop("A prepared single-address review invariant failed.",
    call. = FALSE)
}

setcolorder(question_members, c(
  "single_address_question_id",
  "site_key",
  "development_id",
  setdiff(names(question_members), c(
    "single_address_question_id",
    "site_key",
    "development_id"
  ))
))
setcolorder(question_pairs, c(
  "single_address_question_id",
  "single_address_pair_id",
  "site_key",
  "development_id_1",
  "development_id_2",
  setdiff(names(question_pairs), c(
    "single_address_question_id",
    "single_address_pair_id",
    "site_key",
    "development_id_1",
    "development_id_2"
  ))
))

write_parquet(
  questions,
  "../output/lihtc_single_address_identity_questions.parquet",
  compression = "zstd"
)
write_parquet(
  question_members,
  "../output/lihtc_single_address_identity_question_members.parquet",
  compression = "zstd"
)
write_parquet(
  question_pairs,
  "../output/lihtc_single_address_identity_question_pairs.parquet",
  compression = "zstd"
)

questions_round_trip <- as.data.table(read_parquet(
  "../output/lihtc_single_address_identity_questions.parquet"
))
members_round_trip <- as.data.table(read_parquet(
  "../output/lihtc_single_address_identity_question_members.parquet"
))
pairs_round_trip <- as.data.table(read_parquet(
  "../output/lihtc_single_address_identity_question_pairs.parquet"
))
if (!isTRUE(all.equal(questions, questions_round_trip)) ||
    !isTRUE(all.equal(question_members, members_round_trip)) ||
    !isTRUE(all.equal(question_pairs, pairs_round_trip))) {
  stop("A single-address review Parquet changed on round trip.",
    call. = FALSE)
}

cat(
  "Prepared ", format(nrow(questions), big.mark = ","),
  " single-address identity questions with ",
  format(nrow(question_members), big.mark = ","),
  " developments and ",
  format(question_pairs[requires_new_identity_review == TRUE, .N],
    big.mark = ","),
  " unresolved pairs; no query approved.\n",
  sep = ""
)
