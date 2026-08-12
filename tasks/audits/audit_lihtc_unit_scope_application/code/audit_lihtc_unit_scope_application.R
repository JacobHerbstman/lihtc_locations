# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/audit_lihtc_unit_scope_application/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
})

source_development <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_singleton_identity_scope_adjudicated.parquet"
))
source_episode <- as.data.table(read_parquet(
  "../input/lihtc_project_episode_2024_singleton_identity_scope_adjudicated.parquet"
))
source_site <- as.data.table(read_parquet(
  "../input/lihtc_development_site_2024_singleton_identity_scope_adjudicated.parquet"
))
development <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_unit_scope_adjudicated.parquet"
))
episode <- as.data.table(read_parquet(
  "../input/lihtc_project_episode_2024_unit_scope_adjudicated.parquet"
))
site <- as.data.table(read_parquet(
  "../input/lihtc_development_site_2024_unit_scope_adjudicated.parquet"
))
excluded_episode <- as.data.table(read_parquet(
  "../input/lihtc_excluded_episode_2024_unit_scope_evidence.parquet"
))
question_decisions <- as.data.table(read_parquet(
  "../input/lihtc_unit_scope_question_decisions.parquet"
))
member_decisions <- as.data.table(read_parquet(
  "../input/lihtc_unit_scope_member_decisions.parquet"
))

valid_states <- c(state.abb, "DC")
nonphysical_development_ids <- source_development[
  startsWith(
    singleton_identity_development_scope_status,
    "nonphysical_"
  ),
  development_id
]
territory_development_ids <- source_development[
  !startsWith(
    singleton_identity_development_scope_status,
    "nonphysical_"
  ) & !development_state %chin% valid_states,
  development_id
]
excluded_development_ids <- c(
  nonphysical_development_ids,
  territory_development_ids
)
expected_physical_development <- source_development[
  !development_id %chin% excluded_development_ids
]
expected_physical_episode <- source_episode[
  development_id %chin% expected_physical_development$development_id
]
expected_physical_site <- source_site[
  development_id %chin% expected_physical_development$development_id
]
expected_excluded_episode <- source_episode[
  development_id %chin% excluded_development_ids
]
expected_excluded_episode[, expected_unit_scope_exclusion_status := fcase(
  development_id %chin% nonphysical_development_ids,
  "nonphysical_development_scope",
  development_id %chin% territory_development_ids,
  "outside_50_states_and_dc"
)]

setorder(expected_physical_development, development_state, development_id)
setorder(expected_physical_episode, development_id, episode_number, hud_id)
setorder(expected_physical_site, development_id, site_number,
  development_site_id)
setorder(expected_excluded_episode, development_id, episode_number, hud_id)
setorder(development, development_state, development_id)
setorder(episode, development_id, episode_number, hud_id)
setorder(site, development_id, site_number, development_site_id)
setorder(excluded_episode, development_id, episode_number, hud_id)

unchanged_development_columns <- setdiff(
  names(source_development),
  c(
    "n_units_development",
    "li_units_development",
    "unit_aggregation_status",
    "unit_aggregation_rule"
  )
)
source_episode_columns <- names(source_episode)
source_site_columns <- names(source_site)
episode_source_fields_preserved <- isTRUE(all.equal(
  expected_physical_episode,
  episode[, ..source_episode_columns]
))
site_source_fields_preserved <- isTRUE(all.equal(
  expected_physical_site,
  site[, ..source_site_columns]
))
development_source_fields_preserved <- isTRUE(all.equal(
  expected_physical_development[, ..unchanged_development_columns],
  development[, ..unchanged_development_columns]
))
excluded_source_fields_preserved <- isTRUE(all.equal(
  expected_excluded_episode[, ..source_episode_columns],
  excluded_episode[, ..source_episode_columns]
))
excluded_reason_mapping <- expected_excluded_episode[, .(
  hud_id,
  development_id,
  expected_unit_scope_exclusion_status
)]
excluded_reason_mapping[excluded_episode, `:=`(
  observed_development_id = i.development_id,
  observed_unit_scope_exclusion_status = i.unit_scope_exclusion_status
), on = "hud_id"]
excluded_reasons_match_source_scope <-
  !anyNA(excluded_reason_mapping[, .(
    observed_development_id,
    observed_unit_scope_exclusion_status
  )]) &&
  excluded_reason_mapping[
    development_id != observed_development_id |
      expected_unit_scope_exclusion_status !=
        observed_unit_scope_exclusion_status,
    .N
  ] == 0L

source_pre_values <- expected_physical_development[, .(
  development_id,
  expected_pre_total = n_units_development,
  expected_pre_low_income = li_units_development
)]
source_pre_values[development, `:=`(
  observed_pre_total = i.pre_unit_scope_n_units_development,
  observed_pre_low_income = i.pre_unit_scope_li_units_development
), on = "development_id"]
pre_values_preserved <- isTRUE(all.equal(
  source_pre_values$expected_pre_total,
  source_pre_values$observed_pre_total
)) && isTRUE(all.equal(
  source_pre_values$expected_pre_low_income,
  source_pre_values$observed_pre_low_income
))

decision_application <- question_decisions[, .(
  unit_scope_question_id,
  development_id,
  expected_total_action = final_total_action,
  expected_total_value = final_total_value,
  expected_low_income_action = final_low_income_action,
  expected_low_income_value = final_low_income_value
)]
decision_application[development, `:=`(
  observed_question_id = i.unit_scope_question_id,
  observed_total_action = i.unit_scope_final_total_action,
  observed_total_value = i.n_units_development,
  observed_low_income_action = i.unit_scope_final_low_income_action,
  observed_low_income_value = i.li_units_development
), on = "development_id"]
decisions_applied_exactly <-
  !anyNA(decision_application$observed_question_id) &&
  isTRUE(all.equal(
    decision_application$unit_scope_question_id,
    decision_application$observed_question_id
  )) &&
  isTRUE(all.equal(
    decision_application$expected_total_action,
    decision_application$observed_total_action
  )) &&
  isTRUE(all.equal(
    decision_application$expected_total_value,
    decision_application$observed_total_value
  )) &&
  isTRUE(all.equal(
    decision_application$expected_low_income_action,
    decision_application$observed_low_income_action
  )) &&
  isTRUE(all.equal(
    decision_application$expected_low_income_value,
    decision_application$observed_low_income_value
  ))

member_application <- member_decisions[, .(
  hud_id,
  expected_total_role = final_total_member_role,
  expected_total_source = final_total_value_source,
  expected_low_income_role = final_low_income_member_role,
  expected_low_income_source = final_low_income_value_source
)]
member_application[episode, `:=`(
  observed_total_role = i.unit_scope_final_total_member_role,
  observed_total_source = i.unit_scope_final_total_value_source,
  observed_low_income_role = i.unit_scope_final_low_income_member_role,
  observed_low_income_source =
    i.unit_scope_final_low_income_value_source
), on = "hud_id"]
member_roles_applied_exactly <-
  !anyNA(member_application[, .(
    observed_total_role,
    observed_total_source,
    observed_low_income_role,
    observed_low_income_source
  )]) &&
  isTRUE(all.equal(
    member_application$expected_total_role,
    member_application$observed_total_role
  )) &&
  isTRUE(all.equal(
    member_application$expected_total_source,
    member_application$observed_total_source
  )) &&
  isTRUE(all.equal(
    member_application$expected_low_income_role,
    member_application$observed_low_income_role
  )) &&
  isTRUE(all.equal(
    member_application$expected_low_income_source,
    member_application$observed_low_income_source
  ))

independent_member_arithmetic <- source_episode[, .(
  hud_id,
  source_total_units = episode_units,
  source_low_income_units = episode_low_income_units,
  original_total_units = suppressWarnings(as.numeric(n_units)),
  original_low_income_units = suppressWarnings(as.numeric(li_units))
)]
independent_member_arithmetic[member_decisions, `:=`(
  unit_scope_question_id = i.unit_scope_question_id,
  final_total_member_role = i.final_total_member_role,
  final_total_value_source = i.final_total_value_source,
  final_low_income_member_role = i.final_low_income_member_role,
  final_low_income_value_source = i.final_low_income_value_source
), on = "hud_id"]
independent_member_arithmetic <- independent_member_arithmetic[
  !is.na(unit_scope_question_id)
]
independent_member_arithmetic[, selected_total_value := fcase(
  final_total_value_source == "reconciled_episode",
  source_total_units,
  final_total_value_source == "original_hud",
  original_total_units,
  default = NA_real_
)]
independent_member_arithmetic[, selected_low_income_value := fcase(
  final_low_income_value_source == "reconciled_episode",
  source_low_income_units,
  final_low_income_value_source == "original_hud",
  original_low_income_units,
  default = NA_real_
)]
independent_action_arithmetic <- independent_member_arithmetic[, .(
  n_members = .N,
  n_total_representatives = sum(
    final_total_member_role == "select_representative"
  ),
  n_total_components = sum(
    final_total_member_role == "include_component"
  ),
  n_total_evidence_only = sum(
    final_total_member_role == "evidence_only"
  ),
  independently_reconstructed_total = sum(
    selected_total_value[
      final_total_member_role %chin% c(
        "select_representative",
        "include_component"
      )
    ],
    na.rm = TRUE
  ),
  n_low_income_representatives = sum(
    final_low_income_member_role == "select_representative"
  ),
  n_low_income_components = sum(
    final_low_income_member_role == "include_component"
  ),
  n_low_income_evidence_only = sum(
    final_low_income_member_role == "evidence_only"
  ),
  independently_reconstructed_low_income = sum(
    selected_low_income_value[
      final_low_income_member_role %chin% c(
        "select_representative",
        "include_component"
      )
    ],
    na.rm = TRUE
  )
), by = unit_scope_question_id]
independent_action_arithmetic[question_decisions, `:=`(
  final_total_action = i.final_total_action,
  final_total_value = i.final_total_value,
  final_low_income_action = i.final_low_income_action,
  final_low_income_value = i.final_low_income_value,
  pass2_source_coverage = i.pass2_source_coverage,
  pass2_source_type = i.pass2_source_type,
  pass2_published_total_units = i.pass2_published_total_units,
  pass2_published_total_count_type =
    i.pass2_published_total_count_type,
  pass2_published_low_income_units =
    i.pass2_published_low_income_units,
  pass2_published_low_income_count_type =
    i.pass2_published_low_income_count_type
), on = "unit_scope_question_id"]

representative_actions <- c(
  "use_once_reporting_value",
  "select_current_episode_value"
)
static_value_actions <- c(
  representative_actions,
  "sum_selected_components",
  "use_external_property_value"
)
nonstatic_actions <- c(
  "retain_episode_specific_no_static_value",
  "unavailable_after_review"
)
independent_role_arithmetic_valid <-
  independent_action_arithmetic[
    final_total_action %chin% representative_actions & (
      n_total_representatives != 1L |
        n_total_components != 0L |
        independently_reconstructed_total != final_total_value
    ) |
      final_total_action == "sum_selected_components" & (
        n_total_representatives != 0L |
          n_total_components < 2L |
          independently_reconstructed_total != final_total_value
      ) |
      final_total_action %chin% c(
        "use_external_property_value",
        nonstatic_actions
      ) & (
        n_total_representatives != 0L |
          n_total_components != 0L |
          n_total_evidence_only != n_members
      ) |
      final_low_income_action %chin% representative_actions & (
        n_low_income_representatives != 1L |
          n_low_income_components != 0L |
          independently_reconstructed_low_income !=
            final_low_income_value
      ) |
      final_low_income_action == "sum_selected_components" & (
        n_low_income_representatives != 0L |
          n_low_income_components < 2L |
          independently_reconstructed_low_income !=
            final_low_income_value
      ) |
      final_low_income_action %chin% c(
        "use_external_property_value",
        nonstatic_actions
      ) & (
        n_low_income_representatives != 0L |
          n_low_income_components != 0L |
          n_low_income_evidence_only != n_members
      ),
    .N
  ] == 0L
external_source_contract_valid <-
  question_decisions[
    final_total_action == "use_external_property_value" & (
      pass2_published_total_count_type != "exact" |
        is.na(pass2_published_total_units) |
        final_total_value != pass2_published_total_units
    ) |
      final_low_income_action == "use_external_property_value" & (
        pass2_published_low_income_count_type != "exact" |
          is.na(pass2_published_low_income_units) |
          final_low_income_value != pass2_published_low_income_units
      ) |
      pass2_source_type %chin% c(
        "public_property_directory",
        "independent_public_housing_directory"
      ) & pass2_source_coverage != "identity_only",
    .N
  ] == 0L
static_value_semantics_valid <- question_decisions[
  final_total_action %chin% static_value_actions & (
    is.na(final_total_value) |
      final_total_value <= 0 |
      final_total_value != floor(final_total_value)
  ) |
    final_total_action %chin% nonstatic_actions &
      !is.na(final_total_value) |
    final_low_income_action %chin% static_value_actions & (
      is.na(final_low_income_value) |
        final_low_income_value < 0 |
        final_low_income_value != floor(final_low_income_value)
    ) |
    final_low_income_action %chin% nonstatic_actions &
      !is.na(final_low_income_value) |
    !is.na(final_total_value) & !is.na(final_low_income_value) &
      final_low_income_value > final_total_value,
  .N
] == 0L
decision_queue_coverage_exact <-
  nrow(question_decisions) == 1224L &&
  nrow(member_decisions) == 2657L &&
  uniqueN(question_decisions$unit_scope_question_id) == 1224L &&
  uniqueN(question_decisions$development_id) == 1224L &&
  uniqueN(member_decisions$hud_id) == 2657L &&
  setequal(
    question_decisions$unit_scope_question_id,
    member_decisions$unit_scope_question_id
  )
review_queue_development_ids <- source_episode[, .N, by = development_id][
  N > 1L,
  development_id
]
source_singletons <- source_episode[
  !development_id %chin% review_queue_development_ids
]
source_singleton_development_values <- source_development[
  source_singletons,
  .(
    development_id,
    episode_units = i.episode_units,
    episode_low_income_units = i.episode_low_income_units,
    n_units_development,
    li_units_development,
    unit_aggregation_status
  ),
  on = "development_id"
]
review_queue_development_ids <- c(
  review_queue_development_ids,
  source_singleton_development_values[
    is.na(episode_units) |
      episode_units <= 0 |
      is.na(episode_low_income_units) |
      episode_low_income_units < 0 |
      episode_low_income_units > episode_units |
      unit_aggregation_status == "requires_review" |
      is.na(n_units_development) |
      n_units_development <= 0 |
      is.na(li_units_development) |
      li_units_development < 0 |
      li_units_development > n_units_development,
    development_id
  ],
  c("DEV_MAB20191004", "DEV_NJA20040125")
)
review_queue_development_ids <- unique(review_queue_development_ids)
review_queue_development_ids <- setdiff(
  review_queue_development_ids,
  excluded_development_ids
)
decision_queue_reconstructed_from_source <-
  setequal(
    question_decisions$development_id,
    review_queue_development_ids
  )
documented_second_reads_complete <- question_decisions[
  is.na(pass2_search_engine) |
    trimws(pass2_search_engine) == "" |
    is.na(pass2_search_url) |
    !grepl("^https?://", pass2_search_url) |
    is.na(pass2_notes) |
    trimws(pass2_notes) == "",
  .N
] == 0L

unreviewed_values <- expected_physical_development[
  !development_id %chin% question_decisions$development_id,
  .(
    development_id,
    expected_total = n_units_development,
    expected_low_income = li_units_development
  )
]
unreviewed_values[development, `:=`(
  observed_total = i.n_units_development,
  observed_low_income = i.li_units_development,
  observed_review_status = i.unit_scope_review_status
), on = "development_id"]
unreviewed_values_unchanged <- isTRUE(all.equal(
  unreviewed_values$expected_total,
  unreviewed_values$observed_total
)) && isTRUE(all.equal(
  unreviewed_values$expected_low_income,
  unreviewed_values$observed_low_income
)) && all(
  unreviewed_values$observed_review_status == "not_in_unit_scope_review"
)

episode_partition_complete_disjoint <-
  length(intersect(episode$hud_id, excluded_episode$hud_id)) == 0L &&
  uniqueN(c(episode$hud_id, excluded_episode$hud_id)) ==
    nrow(source_episode) &&
  setequal(
    c(episode$hud_id, excluded_episode$hud_id),
    source_episode$hud_id
  )

checks <- data.table(
  check_name = c(
    "source_development_key_unique",
    "source_episode_key_unique",
    "source_site_key_unique",
    "development_key_unique",
    "episode_key_unique",
    "site_key_unique",
    "physical_development_partition_exact",
    "physical_episode_partition_exact",
    "physical_site_partition_exact",
    "excluded_episode_partition_exact",
    "development_source_fields_preserved",
    "episode_source_fields_preserved",
    "site_source_fields_preserved",
    "excluded_episode_source_fields_preserved",
    "pre_review_development_values_preserved",
    "question_decisions_applied_exactly",
    "member_roles_applied_exactly",
    "decision_queue_coverage_exact",
    "decision_queue_reconstructed_from_source",
    "documented_second_reads_complete",
    "independent_member_role_arithmetic_valid",
    "external_source_contract_valid",
    "static_value_semantics_valid",
    "unreviewed_development_values_unchanged",
    "episode_partition_complete_and_disjoint",
    "excluded_reason_partition_exact",
    "excluded_reason_mapping_matches_source_scope",
    "physical_outputs_follow_50_state_dc_scope",
    "applied_values_valid"
  ),
  passed = c(
    uniqueN(source_development$development_id) ==
      nrow(source_development),
    uniqueN(source_episode$hud_id) == nrow(source_episode),
    uniqueN(source_site$development_site_id) == nrow(source_site),
    uniqueN(development$development_id) == nrow(development),
    uniqueN(episode$hud_id) == nrow(episode),
    uniqueN(site$development_site_id) == nrow(site),
    setequal(
      development$development_id,
      expected_physical_development$development_id
    ),
    setequal(episode$hud_id, expected_physical_episode$hud_id),
    setequal(site$development_site_id,
      expected_physical_site$development_site_id),
    setequal(excluded_episode$hud_id, expected_excluded_episode$hud_id),
    development_source_fields_preserved,
    episode_source_fields_preserved,
    site_source_fields_preserved,
    excluded_source_fields_preserved,
    pre_values_preserved,
    decisions_applied_exactly,
    member_roles_applied_exactly,
    decision_queue_coverage_exact,
    decision_queue_reconstructed_from_source,
    documented_second_reads_complete,
    independent_role_arithmetic_valid,
    external_source_contract_valid,
    static_value_semantics_valid,
    unreviewed_values_unchanged,
    episode_partition_complete_disjoint,
    nrow(excluded_episode) == 443L &&
      excluded_episode[
        unit_scope_exclusion_status == "nonphysical_development_scope",
        .N
      ] == 26L &&
      excluded_episode[
        unit_scope_exclusion_status == "outside_50_states_and_dc",
        .N
      ] == 417L,
    excluded_reasons_match_source_scope,
    nrow(development) == 53469L &&
      nrow(episode) == 54902L &&
      nrow(site) == 131473L &&
      !any(development$development_id %chin%
        excluded_development_ids) &&
      !any(startsWith(
        development$singleton_identity_development_scope_status,
        "nonphysical_"
      )) &&
      all(development$development_state %chin% valid_states) &&
      !any(episode$development_id %chin%
        excluded_development_ids) &&
      !any(site$development_id %chin% excluded_development_ids),
    development[
      !is.na(n_units_development) & n_units_development <= 0 |
        !is.na(li_units_development) & li_units_development < 0 |
        !is.na(n_units_development) & !is.na(li_units_development) &
          li_units_development > n_units_development,
      .N
    ] == 0L
  ),
  observed = c(
    nrow(source_development),
    nrow(source_episode),
    nrow(source_site),
    nrow(development),
    nrow(episode),
    nrow(site),
    nrow(development),
    nrow(episode),
    nrow(site),
    nrow(excluded_episode),
    as.integer(development_source_fields_preserved),
    as.integer(episode_source_fields_preserved),
    as.integer(site_source_fields_preserved),
    as.integer(excluded_source_fields_preserved),
    as.integer(pre_values_preserved),
    as.integer(decisions_applied_exactly),
    as.integer(member_roles_applied_exactly),
    as.integer(decision_queue_coverage_exact),
    as.integer(decision_queue_reconstructed_from_source),
    as.integer(documented_second_reads_complete),
    as.integer(independent_role_arithmetic_valid),
    as.integer(external_source_contract_valid),
    as.integer(static_value_semantics_valid),
    as.integer(unreviewed_values_unchanged),
    as.integer(episode_partition_complete_disjoint),
    nrow(excluded_episode),
    as.integer(excluded_reasons_match_source_scope),
    sum(development$development_id %chin%
      excluded_development_ids) +
      sum(startsWith(
        development$singleton_identity_development_scope_status,
        "nonphysical_"
      )) +
      sum(episode$development_id %chin%
        excluded_development_ids) +
      sum(site$development_id %chin% excluded_development_ids) +
      sum(!development$development_state %chin% valid_states),
    development[
      !is.na(n_units_development) & n_units_development <= 0 |
        !is.na(li_units_development) & li_units_development < 0 |
        !is.na(n_units_development) & !is.na(li_units_development) &
          li_units_development > n_units_development,
      .N
    ]
  ),
  expected = c(
    nrow(source_development),
    nrow(source_episode),
    nrow(source_site),
    nrow(expected_physical_development),
    nrow(expected_physical_episode),
    nrow(expected_physical_site),
    nrow(expected_physical_development),
    nrow(expected_physical_episode),
    nrow(expected_physical_site),
    nrow(expected_excluded_episode),
    rep(1L, 15L),
    443L,
    1L,
    0L,
    0L
  )
)

if (checks[passed == FALSE, .N] > 0L) {
  stop(
    paste(
      "The unit-scope application audit failed:",
      paste(checks[passed == FALSE, check_name], collapse = ", ")
    ),
    call. = FALSE
  )
}

write_parquet(
  checks,
  "../output/lihtc_unit_scope_application_audit.parquet",
  compression = "zstd"
)

checks_round_trip <- as.data.table(read_parquet(
  "../output/lihtc_unit_scope_application_audit.parquet"
))
if (!isTRUE(all.equal(checks, checks_round_trip))) {
  stop("The unit-scope audit Parquet round trip changed data.",
    call. = FALSE)
}

message(
  "Passed ", nrow(checks), " independent unit-scope application checks."
)
