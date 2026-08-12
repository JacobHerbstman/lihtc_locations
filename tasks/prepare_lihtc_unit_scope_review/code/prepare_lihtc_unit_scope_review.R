# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/prepare_lihtc_unit_scope_review/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
})

collapse_numeric <- function(value) {
  value <- fifelse(
    is.na(value),
    "<MISSING>",
    format(value, trim = TRUE, scientific = FALSE)
  )
  paste(value, collapse = "|")
}

development <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_singleton_identity_scope_adjudicated.parquet"
))
episode <- as.data.table(read_parquet(
  "../input/lihtc_project_episode_2024_singleton_identity_scope_adjudicated.parquet"
))
development_linkage_evidence <- as.data.table(read_parquet(
  "../input/lihtc_development_linkage_decisions_2024.parquet"
))
name_variant_evidence <- as.data.table(read_parquet(
  "../input/lihtc_name_variant_linkage_decisions_2024.parquet"
))
cross_address_evidence <- as.data.table(read_parquet(
  "../input/lihtc_cross_development_address_decisions.parquet"
))
cross_address_round2_evidence <- as.data.table(read_parquet(
  "../input/lihtc_cross_development_address_question_reviews_round2.parquet"
))
identical_address_set_evidence <- as.data.table(read_parquet(
  "../input/lihtc_identical_address_set_reviews.parquet"
))
single_address_evidence <- as.data.table(read_parquet(
  "../input/lihtc_single_address_question_reviews.parquet"
))
source_site_evidence <- as.data.table(read_parquet(
  "../input/lihtc_source_site_episode_decisions.parquet"
))
mixed_site_evidence <- as.data.table(read_parquet(
  "../input/lihtc_mixed_site_identity_question_reviews.parquet"
))
singleton_identity_scope_evidence <- as.data.table(read_parquet(
  "../input/lihtc_singleton_identity_scope_member_partitions.parquet"
))
external_conflicts <- fread(
  "unit_scope_external_conflicts.csv",
  colClasses = "character",
  na.strings = c("", "NA")
)
external_conflicts[, `:=`(
  published_total_units = as.numeric(published_total_units),
  published_low_income_units = as.numeric(published_low_income_units),
  reviewed_on = as.Date(reviewed_on)
)]
if (nrow(development) != 53909L ||
    uniqueN(development$development_id) != nrow(development) ||
    nrow(episode) != 55345L ||
    uniqueN(episode$hud_id) != nrow(episode) ||
    anyNA(development$singleton_identity_development_scope_status) ||
    anyNA(development$development_state) ||
    any(!episode$development_id %chin% development$development_id)) {
  stop("An identity-adjudicated input count or key changed.", call. = FALSE)
}

valid_states <- c(state.abb, "DC")
nonphysical_development_ids <- development[
  startsWith(singleton_identity_development_scope_status, "nonphysical_"),
  development_id
]
territory_development_ids <- development[
  !startsWith(singleton_identity_development_scope_status, "nonphysical_") &
    !development_state %chin% valid_states,
  development_id
]
excluded_development_ids <- c(
  nonphysical_development_ids,
  territory_development_ids
)
physical_development <- development[
  !development_id %chin% excluded_development_ids
]
excluded_scope_evidence <- episode[
  development_id %chin% excluded_development_ids,
  .(
    development_id,
    hud_id,
    episode_number,
    project,
    proj_add,
    proj_cty,
    proj_st,
    proj_zip,
    state_id,
    pis_year,
    allocation_year,
    episode_units,
    episode_low_income_units,
    n_units,
    li_units,
    mixed_site_identity_question_id,
    mixed_site_identity_action,
    mixed_site_identity_reason_code,
    mixed_site_development_scope_status,
    source_site_exception_group_id,
    source_site_development_scope_status,
    singleton_identity_scope_review_id,
    singleton_identity_scope_reason_code,
    singleton_identity_development_scope_status
  )
]
excluded_scope_evidence[, unit_scope_exclusion_reason := fcase(
  startsWith(singleton_identity_development_scope_status, "nonphysical_"),
  "nonphysical_development_scope",
  !proj_st %chin% valid_states,
  "outside_50_states_and_dc"
)]
excluded_scope_evidence[, unit_scope_review_status :=
  "excluded_from_main_unit_scope_queue_preserved_as_episode_evidence"]
setorder(excluded_scope_evidence, development_id, episode_number, hud_id)

if (length(nonphysical_development_ids) != 23L ||
    length(territory_development_ids) != 417L ||
    length(intersect(
      nonphysical_development_ids,
      territory_development_ids
    )) != 0L ||
    nrow(physical_development) != 53469L ||
    nrow(excluded_scope_evidence) != 443L ||
    excluded_scope_evidence[
      unit_scope_exclusion_reason == "nonphysical_development_scope",
      .N
    ] != 26L ||
    excluded_scope_evidence[
      unit_scope_exclusion_reason == "outside_50_states_and_dc",
      .N
    ] != 417L ||
    uniqueN(excluded_scope_evidence$hud_id) !=
      nrow(excluded_scope_evidence)) {
  stop("The physical-development scope partition changed.", call. = FALSE)
}

physical_episode_counts <- episode[
  development_id %chin% physical_development$development_id,
  .(observed_project_episodes = .N),
  by = development_id
]
if (nrow(physical_episode_counts) != nrow(physical_development) ||
    uniqueN(physical_episode_counts$development_id) !=
      nrow(physical_episode_counts) ||
    sum(physical_episode_counts$observed_project_episodes) != 54902L) {
  stop("The physical episode-to-development key changed.", call. = FALSE)
}

multi_episode_ids <- physical_episode_counts[
  observed_project_episodes > 1L,
  development_id
]
summary_multi_episode_ids <- physical_development[
  development_id %chin% multi_episode_ids &
    unit_aggregation_status == "requires_review",
  development_id
]
if (length(multi_episode_ids) != 1142L ||
    !setequal(multi_episode_ids, summary_multi_episode_ids) ||
    physical_development[physical_episode_counts,
      any(n_project_episodes != i.observed_project_episodes),
      on = "development_id"
    ]) {
  stop("The unresolved multi-episode unit universe changed.", call. = FALSE)
}

singleton_problem <- episode[
  development_id %chin% physical_episode_counts[
    observed_project_episodes == 1L,
    development_id
  ]
]
singleton_problem[physical_development, `:=`(
  development_unit_aggregation_status = i.unit_aggregation_status,
  development_n_units = i.n_units_development,
  development_low_income_units = i.li_units_development
), on = "development_id"]
singleton_problem <- singleton_problem[
  !development_id %chin% external_conflicts$development_id & (
    is.na(episode_units) |
      episode_units <= 0 |
      is.na(episode_low_income_units) |
      episode_low_income_units < 0 |
      episode_low_income_units > episode_units |
      development_unit_aggregation_status == "requires_review" |
      is.na(development_n_units) |
      development_n_units <= 0 |
      is.na(development_low_income_units) |
      development_low_income_units < 0 |
      development_low_income_units > development_n_units
  )
]
if (nrow(singleton_problem) != 80L ||
    uniqueN(singleton_problem$development_id) != nrow(singleton_problem) ||
    singleton_problem[
      is.na(episode_units) & is.na(episode_low_income_units),
      .N
    ] != 75L ||
    singleton_problem[
      !is.na(episode_units) & episode_units <= 0,
      .N
    ] != 5L) {
  stop("The bad-unit singleton universe changed.", call. = FALSE)
}

if (nrow(external_conflicts) != 2L ||
    uniqueN(external_conflicts$conflict_id) != nrow(external_conflicts) ||
    uniqueN(external_conflicts$development_id) != nrow(external_conflicts) ||
    any(!external_conflicts$development_id %chin%
      physical_development$development_id) ||
    any(!external_conflicts$hud_id %chin% episode$hud_id) ||
    !setequal(
      external_conflicts$conflict_id,
      c("UNITCONFLICT_0001", "UNITCONFLICT_0002")
    ) ||
    any(external_conflicts$total_count_type != "exact") ||
    any(!external_conflicts$low_income_count_type %chin%
      c("lower_bound", "not_reported")) ||
    any(is.na(external_conflicts$published_total_units)) ||
    any(
      is.na(external_conflicts$published_low_income_units) !=
        (external_conflicts$low_income_count_type == "not_reported")
    ) ||
    any(external_conflicts$development_id %chin% c(
      multi_episode_ids,
      singleton_problem$development_id
    ))) {
  stop("The frozen external unit-conflict input is invalid.", call. = FALSE)
}

question_ids <- data.table(
  development_id = c(
    multi_episode_ids,
    singleton_problem$development_id,
    external_conflicts$development_id
  ),
  review_queue_type = c(
    rep("multi_episode_unit_scope", length(multi_episode_ids)),
    rep("singleton_source_count_problem", nrow(singleton_problem)),
    rep("external_unit_count_conflict", nrow(external_conflicts))
  )
)
setorder(question_ids, development_id)
question_ids[, unit_scope_question_id := paste0("UNITQ_", development_id)]

deferred_development_ids <- physical_development[
  unit_aggregation_status == "requires_review" |
    grepl(
      "unit.*deferred",
      singleton_identity_development_scope_status
    ),
  development_id
]

if (nrow(question_ids) != 1224L ||
    uniqueN(question_ids$development_id) != nrow(question_ids) ||
    uniqueN(question_ids$unit_scope_question_id) != nrow(question_ids) ||
    any(!deferred_development_ids %chin% question_ids$development_id)) {
  stop("A unit-scope question key is duplicated.", call. = FALSE)
}

members <- episode[
  development_id %chin% question_ids$development_id
]
members[question_ids, `:=`(
  unit_scope_question_id = i.unit_scope_question_id,
  review_queue_type = i.review_queue_type
), on = "development_id"]
setorder(members, development_id, episode_number, hud_id)

bedroom_columns <- c("n_0br", "n_1br", "n_2br", "n_3br", "n_4br")
bedroom_values <- as.data.frame(lapply(
  members[, ..bedroom_columns],
  function(value) suppressWarnings(as.numeric(value))
))
members[, `:=`(
  bedroom_fields_reported = rowSums(!is.na(bedroom_values)),
  bedroom_unit_sum = rowSums(bedroom_values, na.rm = TRUE),
  original_n_units_numeric = suppressWarnings(as.numeric(n_units)),
  original_li_units_numeric = suppressWarnings(as.numeric(li_units))
)]
members[bedroom_fields_reported == 0L, bedroom_unit_sum := NA_real_]
members[external_conflicts, external_conflict_id := i.conflict_id,
  on = c("development_id", "hud_id")]

members[, `:=`(
  flag_total_missing = is.na(episode_units),
  flag_total_nonpositive = !is.na(episode_units) & episode_units <= 0,
  flag_low_income_missing = is.na(episode_low_income_units),
  flag_low_income_negative = !is.na(episode_low_income_units) &
    episode_low_income_units < 0,
  flag_low_income_exceeds_total = !is.na(episode_units) &
    !is.na(episode_low_income_units) &
    episode_low_income_units > episode_units,
  flag_bedroom_sum_exceeds_total = !is.na(bedroom_unit_sum) &
    !is.na(episode_units) & bedroom_unit_sum > episode_units,
  flag_original_total_changed_by_hud = !is.na(original_n_units_numeric) &
    !is.na(episode_units) & original_n_units_numeric != episode_units,
  flag_original_low_income_changed_by_hud =
    !is.na(original_li_units_numeric) &
    !is.na(episode_low_income_units) &
    original_li_units_numeric != episode_low_income_units
)]

episode_summary <- members[, .(
  n_episode_members = .N,
  hud_ids = paste(hud_id, collapse = "|"),
  project_names = paste(project, collapse = " || "),
  state_ids = paste(fcoalesce(state_id, "<MISSING>"), collapse = "|"),
  pis_years = paste(
    fcoalesce(as.character(pis_year), "<MISSING>"),
    collapse = "|"
  ),
  episode_total_unit_values = collapse_numeric(episode_units),
  n_total_missing = sum(is.na(episode_units)),
  n_total_nonpositive = sum(!is.na(episode_units) & episode_units <= 0),
  n_distinct_nonmissing_total_values = uniqueN(
    episode_units[!is.na(episode_units)]
  ),
  all_episode_total_values_equal = all(!is.na(episode_units)) &
    uniqueN(episode_units) == 1L,
  episode_total_unit_min = if (all(is.na(episode_units))) {
    NA_real_
  } else {
    min(episode_units, na.rm = TRUE)
  },
  episode_total_unit_max = if (all(is.na(episode_units))) {
    NA_real_
  } else {
    max(episode_units, na.rm = TRUE)
  },
  episode_total_unit_sum = if (all(is.na(episode_units))) {
    NA_real_
  } else {
    sum(episode_units, na.rm = TRUE)
  },
  episode_low_income_unit_values = collapse_numeric(
    episode_low_income_units
  ),
  n_low_income_missing = sum(is.na(episode_low_income_units)),
  n_low_income_negative = sum(
    !is.na(episode_low_income_units) & episode_low_income_units < 0
  ),
  n_low_income_exceeds_total = sum(flag_low_income_exceeds_total),
  n_distinct_nonmissing_low_income_values = uniqueN(
    episode_low_income_units[!is.na(episode_low_income_units)]
  ),
  all_episode_low_income_values_equal =
    all(!is.na(episode_low_income_units)) &
    uniqueN(episode_low_income_units) == 1L,
  episode_low_income_unit_min = if (
    all(is.na(episode_low_income_units))
  ) {
    NA_real_
  } else {
    min(episode_low_income_units, na.rm = TRUE)
  },
  episode_low_income_unit_max = if (
    all(is.na(episode_low_income_units))
  ) {
    NA_real_
  } else {
    max(episode_low_income_units, na.rm = TRUE)
  },
  episode_low_income_unit_sum = if (
    all(is.na(episode_low_income_units))
  ) {
    NA_real_
  } else {
    sum(episode_low_income_units, na.rm = TRUE)
  },
  n_bedroom_sum_flags = sum(flag_bedroom_sum_exceeds_total),
  n_original_total_reconciliations = sum(flag_original_total_changed_by_hud),
  n_original_low_income_reconciliations = sum(
    flag_original_low_income_changed_by_hud
  )
), by = development_id]

questions <- development[
  development_id %chin% question_ids$development_id
]
questions[question_ids, `:=`(
  unit_scope_question_id = i.unit_scope_question_id,
  review_queue_type = i.review_queue_type
), on = "development_id"]
questions[external_conflicts, external_conflict_id := i.conflict_id,
  on = "development_id"]
questions[episode_summary, names(episode_summary)[-1L] :=
  mget(paste0("i.", names(episode_summary)[-1L])),
on = "development_id"]

reason_columns <- c(
  "linkage_review_reason_code",
  "name_variant_review_reason_code",
  "cross_address_review_reason_code",
  "cross_address_round2_review_reason_codes",
  "identical_address_set_review_reason_codes",
  "single_address_review_reason_codes",
  "mixed_site_identity_reason_codes",
  "source_site_development_scope_status",
  "singleton_identity_scope_reason_codes",
  "singleton_identity_development_scope_status"
)
questions[, prior_identity_reason_text := do.call(
  paste,
  c(
    lapply(.SD, function(value) fcoalesce(value, "")),
    sep = "|"
  )
), .SDcols = reason_columns]

questions[, prior_component_scope_reason := grepl(
  paste(
    c(
      "single_building_split_financing_applications",
      "paired_financing_components_same_physical_development",
      "paired_financing_same_physical_development",
      "combined_components_one_physical_development",
      "paired_financing_components_one_physical_development",
      "documented_components_one_physical_development",
      "one_property_constructed_in_two_financing_phases"
    ),
    collapse = "|"
  ),
  prior_identity_reason_text
)]
questions[, prior_scattered_site_scope_reason := grepl(
  "same_named_scattered_site_development",
  prior_identity_reason_text
)]
questions[, prior_repeat_episode_reason := grepl(
  paste(
    c(
      "duplicate_hud_records",
      "duplicate_or_parallel_financing_records",
      "same_property_recapitalization",
      "duplicate_reporting",
      "later_financing",
      "renamed_same_physical_development",
      "later_preservation_episode",
      "later_rehabilitation",
      "redevelopment_episode",
      "same_component_duplicate_reporting",
      "outside_source_confirms_duplicate_or_later_episode",
      "legal_and_operating_names_same_physical_development",
      "duplicate_source_records_same_physical_development",
      "duplicate_source_records_same_scattered_site_development",
      "duplicate_records_within_distinct_named_phases",
      "duplicate_records_within_distinct_named_buildings",
      "duplicate_records_within_distinct_physical_buildings",
      "duplicate_records_partitioned_within_distinct_phases",
      "same_property_later_financing_episode",
      "official_alias_same_physical_development",
      "same_name_same_financing_identity_same_address_with_street_suffix_error",
      "same_state_project_year_allocation_and_duplex_with_official_address_correction",
      "official_inventory_identifies_both_names_at_same_historic_property",
      "official_sponsor_reports_same_sixteen_unit_property_and_address"
    ),
    collapse = "|"
  ),
  prior_identity_reason_text
)]
questions[, prior_ambiguous_unit_scope_reason := grepl(
  paste(
    c(
      "same_property_changed_or_component_totals",
      "same_named_scattered_site_development",
      "same_multisite_physical_development",
      "same_named_multisite_or_aggregate_physical_development",
      "same_physical_development_different_unit_scope",
      "reconfigured_episode_same_physical_development",
      "portfolio_episode_overlaps_distinct_development",
      "distinct_named_phases_no_same_property_proof",
      "single_shared_address_crosslist_between_distinct_rehabs",
      "single_shared_address_crosslist_between_distinct_properties",
      "official_component_and_umbrella_same_physical_development",
      "two_physical_buildings_plus_nonphysical_umbrella_records",
      "copied_crosslisted_addresses_between_distinct_properties",
      "physical_development_same_property_merge_pending",
      "physical_development_site_confirmation_pending"
    ),
    collapse = "|"
  ),
  prior_identity_reason_text
)]
questions[, hierarchical_mixed_scope_evidence :=
  (prior_component_scope_reason | prior_scattered_site_scope_reason) &
    prior_repeat_episode_reason]

questions[, internal_total_candidate_action := fcase(
  review_queue_type == "external_unit_count_conflict",
  "review_external_numeric_conflict",
  review_queue_type == "singleton_source_count_problem",
  "recover_or_confirm_source_total",
  n_total_missing > 0L | n_total_nonpositive > 0L,
  "recover_or_confirm_episode_totals",
  hierarchical_mixed_scope_evidence,
  "review_mixed_component_and_repeat_scope",
  prior_component_scope_reason,
  "review_possible_component_combination",
  prior_ambiguous_unit_scope_reason,
  "review_ambiguous_unit_scope",
  all_episode_total_values_equal & prior_repeat_episode_reason,
  "review_possible_use_once",
  all_episode_total_values_equal,
  "review_equal_episode_totals_scope_unclear",
  default = "review_changed_episode_totals"
)]
questions[, internal_low_income_candidate_action := fcase(
  review_queue_type == "external_unit_count_conflict",
  "review_external_numeric_conflict",
  review_queue_type == "singleton_source_count_problem",
  "recover_or_confirm_source_low_income_total",
  n_low_income_missing > 0L | n_low_income_negative > 0L |
    n_low_income_exceeds_total > 0L,
  "recover_or_confirm_episode_low_income_totals",
  hierarchical_mixed_scope_evidence,
  "review_mixed_component_and_repeat_scope",
  prior_component_scope_reason,
  "review_possible_component_combination",
  prior_ambiguous_unit_scope_reason,
  "review_ambiguous_unit_scope",
  all_episode_low_income_values_equal & prior_repeat_episode_reason,
  "review_possible_use_once",
  all_episode_low_income_values_equal,
  "review_equal_episode_totals_scope_unclear",
  default = "review_changed_episode_totals"
)]
questions[, `:=`(
  outside_unit_source_required = TRUE,
  preparation_status = "candidate_only_requires_two_read_adjudication",
  final_total_unit_action = "not_adjudicated",
  final_low_income_unit_action = "not_adjudicated"
)]

evidence_member_keys <- unique(rbindlist(list(
  members[!is.na(provisional_development_id), .(
    evidence_stage = "development_linkage",
    prior_review_id = provisional_development_id,
    unit_scope_question_id,
    development_id,
    hud_id
  )],
  members[!is.na(name_variant_candidate_group_id), .(
    evidence_stage = "name_variant_linkage",
    prior_review_id = name_variant_candidate_group_id,
    unit_scope_question_id,
    development_id,
    hud_id
  )],
  members[!is.na(cross_address_identity_question_id), .(
    evidence_stage = "cross_address",
    prior_review_id = cross_address_identity_question_id,
    unit_scope_question_id,
    development_id,
    hud_id
  )],
  members[!is.na(cross_address_round2_identity_question_id), .(
    evidence_stage = "cross_address_round2",
    prior_review_id = cross_address_round2_identity_question_id,
    unit_scope_question_id,
    development_id,
    hud_id
  )],
  members[!is.na(identical_address_set_review_question_id), .(
    evidence_stage = "identical_address_set",
    prior_review_id = identical_address_set_review_question_id,
    unit_scope_question_id,
    development_id,
    hud_id
  )],
  members[!is.na(single_address_review_question_id), .(
    evidence_stage = "single_address",
    prior_review_id = single_address_review_question_id,
    unit_scope_question_id,
    development_id,
    hud_id
  )],
  members[!is.na(source_site_exception_group_id), .(
    evidence_stage = "source_site_exception",
    prior_review_id = source_site_exception_group_id,
    unit_scope_question_id,
    development_id,
    hud_id
  )],
  members[!is.na(mixed_site_identity_question_id), .(
    evidence_stage = "mixed_site_identity",
    prior_review_id = mixed_site_identity_question_id,
    unit_scope_question_id,
    development_id,
    hud_id
  )],
  members[!is.na(singleton_identity_scope_review_id), .(
    evidence_stage = "singleton_identity_scope",
    prior_review_id = singleton_identity_scope_review_id,
    unit_scope_question_id,
    development_id,
    hud_id
  )],
  members[!is.na(external_conflict_id), .(
    evidence_stage = "unit_scope_external_conflict",
    prior_review_id = external_conflict_id,
    unit_scope_question_id,
    development_id,
    hud_id
  )]
)), by = c(
  "evidence_stage",
  "prior_review_id",
  "unit_scope_question_id",
  "hud_id"
))

evidence_coverage <- evidence_member_keys[, .(
  development_ids = list(unique(development_id)),
  n_covered_episode_members = uniqueN(hud_id),
  covered_hud_ids = paste(sort(unique(hud_id)), collapse = "|")
), by = .(
  evidence_stage,
  prior_review_id,
  unit_scope_question_id
)]
if (any(lengths(evidence_coverage$development_ids) != 1L)) {
  stop("A prior review key crosses current developments.", call. = FALSE)
}
evidence_coverage[, development_id := vapply(
  development_ids,
  `[`,
  character(1L),
  1L
)]
evidence_coverage[, development_ids := NULL]

source_site_sources <- unique(source_site_evidence[, .(
  evidence_stage = "source_site_exception",
  prior_review_id = source_exception_group_id,
  search_engine = NA_character_,
  search_url = NA_character_,
  source_title = external_source_title,
  source_type = external_source_type,
  source_url = external_source_url,
  prior_reason_code = reviewed_group_decision,
  source_notes = trimws(paste(
    fcoalesce(external_notes, ""),
    fcoalesce(final_review_notes, "")
  )),
  reviewed_on = final_reviewed_on
)], by = c("evidence_stage", "prior_review_id"))
source_site_sources <- source_site_sources[, .(
  source_url = trimws(unlist(strsplit(
    source_url,
    " | ",
    fixed = TRUE
  )))
), by = .(
  evidence_stage,
  prior_review_id,
  search_engine,
  search_url,
  source_title,
  source_type,
  prior_reason_code,
  source_notes,
  reviewed_on
)]
source_site_sources[, source_index := seq_len(.N), by = .(
  evidence_stage,
  prior_review_id
)]

source_candidates <- rbindlist(list(
  development_linkage_evidence[, .(
    evidence_stage = "development_linkage",
    prior_review_id = development_id,
    source_index = 1L,
    search_engine = pass2_search_engine,
    search_url = pass2_search_url,
    source_title = pass2_source_1_title,
    source_type = pass2_source_1_type,
    source_url = pass2_source_1_url,
    prior_reason_code = final_reason_code,
    source_notes = trimws(paste(
      fcoalesce(pass2_notes, ""),
      fcoalesce(final_notes, "")
    )),
    reviewed_on = final_reviewed_on
  )],
  development_linkage_evidence[, .(
    evidence_stage = "development_linkage",
    prior_review_id = development_id,
    source_index = 2L,
    search_engine = pass2_search_engine,
    search_url = pass2_search_url,
    source_title = pass2_source_2_title,
    source_type = pass2_source_2_type,
    source_url = pass2_source_2_url,
    prior_reason_code = final_reason_code,
    source_notes = trimws(paste(
      fcoalesce(pass2_notes, ""),
      fcoalesce(final_notes, "")
    )),
    reviewed_on = final_reviewed_on
  )],
  name_variant_evidence[, .(
    evidence_stage = "name_variant_linkage",
    prior_review_id = candidate_group_id,
    source_index = 1L,
    search_engine = pass2_search_engine,
    search_url = pass2_search_url,
    source_title = pass2_source_1_title,
    source_type = pass2_source_1_type,
    source_url = pass2_source_1_url,
    prior_reason_code = final_reason_code,
    source_notes = trimws(paste(
      fcoalesce(pass2_notes, ""),
      fcoalesce(final_notes, "")
    )),
    reviewed_on = final_reviewed_on
  )],
  cross_address_evidence[, .(
    evidence_stage = "cross_address",
    prior_review_id = identity_question_id,
    source_index = 1L,
    search_engine = pass2_search_engine,
    search_url = pass2_search_url,
    source_title = pass2_source_title,
    source_type = pass2_source_type,
    source_url = pass2_source_url,
    prior_reason_code = final_reason_code,
    source_notes = trimws(paste(
      fcoalesce(pass2_notes, ""),
      fcoalesce(final_notes, "")
    )),
    reviewed_on = final_reviewed_on
  )],
  cross_address_round2_evidence[, .(
    evidence_stage = "cross_address_round2",
    prior_review_id = identity_question_id,
    source_index = 1L,
    search_engine = pass2_search_engine,
    search_url = pass2_search_url,
    source_title = pass2_source_title,
    source_type = pass2_source_type,
    source_url = pass2_source_url,
    prior_reason_code = final_reason_code,
    source_notes = trimws(paste(
      fcoalesce(pass2_notes, ""),
      fcoalesce(final_notes, "")
    )),
    reviewed_on = final_reviewed_on
  )],
  identical_address_set_evidence[, .(
    evidence_stage = "identical_address_set",
    prior_review_id = review_question_id,
    source_index = 1L,
    search_engine = external_search_engine,
    search_url = external_search_url,
    source_title = external_source_title,
    source_type = external_source_type,
    source_url = external_source_url,
    prior_reason_code = final_reason_code,
    source_notes = trimws(paste(
      fcoalesce(external_notes, ""),
      fcoalesce(final_notes, "")
    )),
    reviewed_on = final_reviewed_on
  )],
  single_address_evidence[, .(
    evidence_stage = "single_address",
    prior_review_id = single_address_question_id,
    source_index = 1L,
    search_engine = outside_discovery_method,
    search_url = outside_discovery_url,
    source_title = outside_source_title,
    source_type = outside_source_type,
    source_url = outside_source_url,
    prior_reason_code = final_reason_code,
    source_notes = trimws(paste(
      fcoalesce(outside_identity_assessment, ""),
      fcoalesce(final_reason_code, "")
    )),
    reviewed_on = final_reviewed_on
  )],
  source_site_sources,
  mixed_site_evidence[, .(
    evidence_stage = "mixed_site_identity",
    prior_review_id = mixed_site_question_id,
    source_index = 1L,
    search_engine = outside_discovery_method,
    search_url = outside_discovery_url,
    source_title = outside_source_title,
    source_type = outside_source_type,
    source_url = outside_source_url,
    prior_reason_code = final_reason_code,
    source_notes = outside_identity_assessment,
    reviewed_on = final_reviewed_on
  )],
  unique(singleton_identity_scope_evidence[, .(
    evidence_stage = "singleton_identity_scope",
    prior_review_id = singleton_identity_scope_review_id,
    source_index = 1L,
    search_engine = NA_character_,
    search_url = NA_character_,
    source_title = count_source_title,
    source_type = count_source_type,
    source_url = count_source_url,
    prior_reason_code = final_reason_code,
    source_notes = trimws(paste(
      fcoalesce(count_source_statement, ""),
      fcoalesce(source_assessment, "")
    )),
    reviewed_on
  )]),
  external_conflicts[, .(
    evidence_stage = "unit_scope_external_conflict",
    prior_review_id = conflict_id,
    source_index = 1L,
    search_engine = NA_character_,
    search_url = NA_character_,
    source_title,
    source_type,
    source_url,
    prior_reason_code = "external_numeric_conflict_with_hud_record",
    source_notes,
    reviewed_on,
    published_total_units,
    total_count_type,
    published_low_income_units,
    low_income_count_type
  )]
), fill = TRUE)
source_candidates <- source_candidates[
  !is.na(source_url) & trimws(source_url) != ""
]

source_counts <- source_candidates[, .N, by = .(
  evidence_stage,
  prior_review_id
)]
question_counts <- evidence_coverage[, .(
  N = uniqueN(unit_scope_question_id)
), by = .(
  evidence_stage,
  prior_review_id
)]
many_to_many_keys <- source_counts[N > 1L][
  question_counts[N > 1L],
  on = c("evidence_stage", "prior_review_id"),
  nomatch = 0L
]
if (nrow(many_to_many_keys) > 0L ||
    uniqueN(
      source_candidates,
      by = c("evidence_stage", "prior_review_id", "source_index")
    ) != nrow(source_candidates)) {
  stop("A prior evidence key would create a many-to-many join.",
    call. = FALSE)
}

prior_evidence <- source_candidates[
  evidence_coverage,
  on = c("evidence_stage", "prior_review_id"),
  nomatch = 0L
]
prior_evidence[questions[, .(
  unit_scope_question_id,
  n_episode_members
)], n_episode_members := i.n_episode_members,
on = "unit_scope_question_id"]
prior_evidence[, prior_review_group_links_all_members :=
  n_covered_episode_members == n_episode_members]
prior_evidence[, `:=`(
  prior_unit_language_flag = grepl(
    "[0-9][0-9, -]*(unit|apartment|residence|home)",
    paste(source_title, source_notes),
    ignore.case = TRUE
  ),
  explicit_unit_deferral = grepl(
    paste(
      c(
        "unit aggregation.*separate",
        "unit aggregation remains.*unresolved",
        "do not resolve.*unit",
        "do not (sum|aggregate).*unit",
        "does not adjudicate.*unit"
      ),
      collapse = "|"
    ),
    source_notes,
    ignore.case = TRUE
  ),
  full_group_repeat_source =
    prior_review_group_links_all_members & grepl(
      paste(
        c(
          "duplicate_hud_records",
          "duplicate_or_parallel_financing_records",
          "duplicate_reporting",
          "same_component_duplicate_reporting",
          "duplicate_source_records_same_physical_development",
          "duplicate_source_records_same_scattered_site_development",
          "duplicate_records_within_distinct_named_phases",
          "duplicate_records_within_distinct_named_buildings",
          "duplicate_records_within_distinct_physical_buildings",
          "duplicate_records_partitioned_within_distinct_phases",
          "name_or_reporting_variant_same_physical_development",
          "later_financing_or_renamed_same_physical_development",
          "outside_source_confirms_duplicate_or_later_episode",
          "later_financing_episode_same_physical_development",
          "later_preservation_episode_same_physical_development",
          "later_rehabilitation_same_physical_development",
          "later_rehabilitation_same_multisite_development",
          "redevelopment_episode_same_physical_development",
          "renamed_same_physical_development",
          "duplicate_reporting_same_physical_development",
          "duplicate_reporting_with_bad_source_address",
          "duplicate_reporting_or_later_episode_same_physical_development",
          "same_property_recapitalization",
          "same_property_recapitalization_or_rename",
          "official_alias_same_physical_development",
          "same_property_later_financing_episode",
          "same_name_same_financing_identity_same_address_with_street_suffix_error",
          "same_state_project_year_allocation_and_duplex_with_official_address_correction",
          "official_inventory_identifies_both_names_at_same_historic_property",
          "official_sponsor_reports_same_sixteen_unit_property_and_address"
        ),
        collapse = "|"
      ),
      prior_reason_code
    )
)]
prior_evidence[, prior_evidence_use := fcase(
  explicit_unit_deferral,
  "identity_only_explicit_unit_deferral",
  !is.na(total_count_type) | !is.na(low_income_count_type),
  "outside_numeric_claim_requires_unit_adjudication",
  prior_unit_language_flag,
  "unit_language_not_previously_adjudicated",
  default = "identity_only_no_unit_language"
)]
setorder(
  prior_evidence,
  unit_scope_question_id,
  evidence_stage,
  prior_review_id,
  source_index
)
prior_evidence[, prior_evidence_id := sprintf(
  "PRIOR_%05d",
  .I
)]
setcolorder(prior_evidence, c(
  "prior_evidence_id",
  "unit_scope_question_id",
  "development_id",
  "evidence_stage",
  "prior_review_id",
  "source_index",
  "search_engine",
  "search_url",
  "source_title",
  "source_type",
  "source_url",
  "prior_reason_code",
  "source_notes",
  "reviewed_on",
  "published_total_units",
  "total_count_type",
  "published_low_income_units",
  "low_income_count_type",
  "n_covered_episode_members",
  "covered_hud_ids",
  "n_episode_members",
  "prior_review_group_links_all_members",
  "full_group_repeat_source",
  "prior_unit_language_flag",
  "explicit_unit_deferral",
  "prior_evidence_use"
))

evidence_summary <- prior_evidence[, .(
  n_prior_outside_evidence_rows = .N,
  n_prior_identity_sources_linked_to_full_review_group = sum(
    prior_review_group_links_all_members
  ),
  n_prior_repeat_sources_linked_to_full_review_group = sum(
    full_group_repeat_source
  ),
  n_members_linked_by_prior_review_groups = uniqueN(unlist(strsplit(
    covered_hud_ids,
    "|",
    fixed = TRUE
  ))),
  prior_review_groups_union_link_all_members = uniqueN(unlist(strsplit(
    covered_hud_ids,
    "|",
    fixed = TRUE
  ))) == first(n_episode_members),
  prior_evidence_unit_language_flag = any(prior_unit_language_flag),
  prior_evidence_explicit_unit_deferral = any(explicit_unit_deferral)
), by = unit_scope_question_id]
questions[evidence_summary, `:=`(
  n_prior_outside_evidence_rows = i.n_prior_outside_evidence_rows,
  n_prior_identity_sources_linked_to_full_review_group =
    i.n_prior_identity_sources_linked_to_full_review_group,
  n_prior_repeat_sources_linked_to_full_review_group =
    i.n_prior_repeat_sources_linked_to_full_review_group,
  n_members_linked_by_prior_review_groups =
    i.n_members_linked_by_prior_review_groups,
  prior_review_groups_union_link_all_members =
    i.prior_review_groups_union_link_all_members,
  prior_evidence_unit_language_flag =
    i.prior_evidence_unit_language_flag,
  prior_evidence_explicit_unit_deferral =
    i.prior_evidence_explicit_unit_deferral
), on = "unit_scope_question_id"]
questions[, `:=`(
  n_prior_outside_evidence_rows = fcoalesce(
    n_prior_outside_evidence_rows,
    0L
  ),
  n_prior_identity_sources_linked_to_full_review_group = fcoalesce(
    n_prior_identity_sources_linked_to_full_review_group,
    0L
  ),
  n_prior_repeat_sources_linked_to_full_review_group = fcoalesce(
    n_prior_repeat_sources_linked_to_full_review_group,
    0L
  ),
  n_members_linked_by_prior_review_groups = fcoalesce(
    n_members_linked_by_prior_review_groups,
    0L
  ),
  prior_review_groups_union_link_all_members = fcoalesce(
    prior_review_groups_union_link_all_members,
    FALSE
  ),
  prior_evidence_unit_language_flag = fcoalesce(
    prior_evidence_unit_language_flag,
    FALSE
  ),
  prior_evidence_explicit_unit_deferral = fcoalesce(
    prior_evidence_explicit_unit_deferral,
    FALSE
  )
)]
questions[, has_prior_outside_evidence :=
  n_prior_outside_evidence_rows > 0L]

question_columns <- c(
  "unit_scope_question_id",
  "development_id",
  "development_anchor_hud_id",
  "development_name",
  "development_state",
  "development_city",
  "review_queue_type",
  "external_conflict_id",
  "n_project_episodes",
  "first_pis_year",
  "last_pis_year",
  "any_resyndication_reported",
  "construction_type_codes",
  "hud_ids",
  "project_names",
  "state_ids",
  "pis_years",
  "n_episode_members",
  "episode_total_unit_values",
  "n_total_missing",
  "n_total_nonpositive",
  "n_distinct_nonmissing_total_values",
  "all_episode_total_values_equal",
  "episode_total_unit_min",
  "episode_total_unit_max",
  "episode_total_unit_sum",
  "episode_low_income_unit_values",
  "n_low_income_missing",
  "n_low_income_negative",
  "n_low_income_exceeds_total",
  "n_distinct_nonmissing_low_income_values",
  "all_episode_low_income_values_equal",
  "episode_low_income_unit_min",
  "episode_low_income_unit_max",
  "episode_low_income_unit_sum",
  "n_bedroom_sum_flags",
  "n_original_total_reconciliations",
  "n_original_low_income_reconciliations",
  "unit_aggregation_status",
  "unit_aggregation_rule",
  "linkage_review_reason_code",
  "name_variant_review_reason_code",
  "cross_address_review_reason_code",
  "cross_address_round2_review_reason_codes",
  "identical_address_set_review_reason_codes",
  "single_address_review_reason_codes",
  "mixed_site_identity_question_ids",
  "mixed_site_identity_action",
  "mixed_site_identity_reason_codes",
  "mixed_site_development_scope_status",
  "source_site_exception_group_id",
  "source_site_development_scope_status",
  "singleton_identity_scope_review_ids",
  "singleton_identity_scope_reason_codes",
  "singleton_identity_development_scope_status",
  "prior_component_scope_reason",
  "prior_scattered_site_scope_reason",
  "prior_repeat_episode_reason",
  "prior_ambiguous_unit_scope_reason",
  "hierarchical_mixed_scope_evidence",
  "internal_total_candidate_action",
  "internal_low_income_candidate_action",
  "has_prior_outside_evidence",
  "n_prior_outside_evidence_rows",
  "n_prior_identity_sources_linked_to_full_review_group",
  "n_prior_repeat_sources_linked_to_full_review_group",
  "n_members_linked_by_prior_review_groups",
  "prior_review_groups_union_link_all_members",
  "prior_evidence_unit_language_flag",
  "prior_evidence_explicit_unit_deferral",
  "outside_unit_source_required",
  "preparation_status",
  "final_total_unit_action",
  "final_low_income_unit_action"
)
questions <- questions[, ..question_columns]
setorder(questions, development_state, development_id)

member_columns <- c(
  "unit_scope_question_id",
  "development_id",
  "review_queue_type",
  "hud_id",
  "episode_number",
  "is_development_anchor",
  "n_project_episodes",
  "project",
  "proj_add",
  "proj_cty",
  "proj_st",
  "proj_zip",
  "state_id",
  "pis_year",
  "allocation_year",
  "episode_units",
  "episode_low_income_units",
  "n_units",
  "li_units",
  "n_unitsr",
  "li_unitr",
  "n_0br",
  "n_1br",
  "n_2br",
  "n_3br",
  "n_4br",
  "ceilunit",
  "bedroom_fields_reported",
  "bedroom_unit_sum",
  "flag_total_missing",
  "flag_total_nonpositive",
  "flag_low_income_missing",
  "flag_low_income_negative",
  "flag_low_income_exceeds_total",
  "flag_bedroom_sum_exceeds_total",
  "flag_original_total_changed_by_hud",
  "flag_original_low_income_changed_by_hud",
  "resyndication_cd",
  "type",
  "datanote",
  "record_stat",
  "external_conflict_id",
  "pre_mixed_site_identity_development_id",
  "mixed_site_identity_question_id",
  "mixed_site_identity_action",
  "mixed_site_identity_reason_code",
  "mixed_site_development_scope_status",
  "provisional_development_id",
  "pre_name_review_development_id",
  "name_variant_review_decision",
  "name_variant_review_reason_code",
  "pre_cross_address_review_development_id",
  "cross_address_review_decision",
  "cross_address_review_reason_code",
  "pre_cross_address_round2_development_id",
  "cross_address_round2_review_action",
  "cross_address_round2_review_reason_code",
  "pre_identical_address_set_review_development_id",
  "identical_address_set_review_action",
  "identical_address_set_review_reason_code",
  "pre_single_address_review_development_id",
  "single_address_review_action",
  "single_address_review_reason_code",
  "source_site_exception_group_id",
  "source_site_episode_action",
  "source_site_development_scope_status",
  "pre_singleton_identity_scope_development_id",
  "singleton_identity_scope_review_id",
  "singleton_identity_scope_action",
  "singleton_identity_scope_reason_code",
  "singleton_identity_development_scope_status"
)
members <- members[, ..member_columns]
members[, `:=`(
  internal_total_member_role = "not_adjudicated",
  internal_low_income_member_role = "not_adjudicated"
)]
setorder(members, unit_scope_question_id, episode_number, hud_id)

observed_member_counts <- members[, .(
  observed_episode_members = .N
), by = unit_scope_question_id]
questions[observed_member_counts, observed_episode_members :=
  i.observed_episode_members,
on = "unit_scope_question_id"]

validation_checks <- c(
  question_rows = nrow(questions) == 1224L,
  multi_episode_questions = questions[
    review_queue_type == "multi_episode_unit_scope",
    .N
  ] == 1142L,
  singleton_problem_questions = questions[
    review_queue_type == "singleton_source_count_problem",
    .N
  ] == 80L,
  external_conflict_questions = questions[
    review_queue_type == "external_unit_count_conflict",
    .N
  ] == 2L,
  member_rows = nrow(members) == 2657L,
  unique_member_ids = uniqueN(members$hud_id) == nrow(members),
  multi_episode_member_rows = members[
    review_queue_type == "multi_episode_unit_scope",
    .N
  ] == 2575L,
  question_member_counts_present =
    !anyNA(questions$observed_episode_members),
  question_member_counts_agree = !any(
    questions$n_episode_members != questions$observed_episode_members
  ),
  valid_states = !any(!questions$development_state %chin% valid_states),
  outside_source_required = all(questions$outside_unit_source_required),
  questions_unadjudicated = all(
    questions$preparation_status ==
      "candidate_only_requires_two_read_adjudication" &
      questions$final_total_unit_action == "not_adjudicated" &
      questions$final_low_income_unit_action == "not_adjudicated"
  ),
  members_unadjudicated = all(
    members$internal_total_member_role == "not_adjudicated" &
      members$internal_low_income_member_role == "not_adjudicated"
  ),
  unique_prior_evidence_ids =
    uniqueN(prior_evidence$prior_evidence_id) == nrow(prior_evidence),
  evidence_questions_exist = all(
    prior_evidence$unit_scope_question_id %chin%
      questions$unit_scope_question_id
  ),
  evidence_required_fields_complete = !anyNA(prior_evidence[, .(
    prior_evidence_id,
    unit_scope_question_id,
    development_id,
    evidence_stage,
    prior_review_id,
    source_title,
    source_type,
    source_url,
    prior_reason_code,
    reviewed_on,
    n_covered_episode_members,
    n_episode_members,
    prior_review_group_links_all_members,
    prior_evidence_use
  )]),
  evidence_coverage_not_excessive = prior_evidence[
    n_covered_episode_members > n_episode_members,
    .N
  ] == 0L,
  prior_review_groups_union_link_members = questions[
    has_prior_outside_evidence &
      !prior_review_groups_union_link_all_members,
    .N
  ] == 0L,
  excluded_developments_absent = !any(
    questions$development_id %chin% excluded_development_ids
  ),
  excluded_episode_rows_preserved =
    nrow(excluded_scope_evidence) == 443L
)
if (any(!validation_checks)) {
  stop(
    paste(
      "The prepared unit-scope review contract failed:",
      paste(names(validation_checks)[!validation_checks], collapse = ", ")
    ),
    call. = FALSE
  )
}
questions[, observed_episode_members := NULL]

write_parquet(
  questions,
  "../output/lihtc_unit_scope_questions.parquet",
  compression = "zstd"
)
write_parquet(
  members,
  "../output/lihtc_unit_scope_question_members.parquet",
  compression = "zstd"
)
write_parquet(
  prior_evidence,
  "../output/lihtc_unit_scope_prior_evidence.parquet",
  compression = "zstd"
)

questions_round_trip <- as.data.table(read_parquet(
  "../output/lihtc_unit_scope_questions.parquet"
))
members_round_trip <- as.data.table(read_parquet(
  "../output/lihtc_unit_scope_question_members.parquet"
))
prior_evidence_round_trip <- as.data.table(read_parquet(
  "../output/lihtc_unit_scope_prior_evidence.parquet"
))
if (!isTRUE(all.equal(questions, questions_round_trip)) ||
    !isTRUE(all.equal(members, members_round_trip)) ||
    !isTRUE(all.equal(prior_evidence, prior_evidence_round_trip))) {
  stop("A prepared unit-scope Parquet round trip changed data.",
    call. = FALSE)
}

message(
  "Prepared 1,224 unit-scope questions and 2,657 episode members; ",
  format(nrow(prior_evidence), big.mark = ","),
  " prior evidence rows are frozen. Preserved 443 excluded episodes ",
  "outside the 50-state-and-DC queue; all unit decisions remain ",
  "unadjudicated."
)
