# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/audit_lihtc_source_site_exception_review_applied/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
})

development_before <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_single_address_adjudicated.parquet"
))
episode_before <- as.data.table(read_parquet(
  "../input/lihtc_project_episode_2024_single_address_adjudicated.parquet"
))
site_before <- as.data.table(read_parquet(
  "../input/lihtc_development_site_2024_single_address_adjudicated.parquet"
))
member_decisions <- as.data.table(read_parquet(
  "../input/lihtc_source_site_member_decisions.parquet"
))
episode_decisions <- as.data.table(read_parquet(
  "../input/lihtc_source_site_episode_decisions.parquet"
))
replacements <- as.data.table(read_parquet(
  "../input/lihtc_source_site_external_replacements.parquet"
))
development_after <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_source_site_repaired.parquet"
))
episode_after <- as.data.table(read_parquet(
  "../input/lihtc_project_episode_2024_source_site_repaired.parquet"
))
site_after <- as.data.table(read_parquet(
  "../input/lihtc_development_site_2024_source_site_repaired.parquet"
))

development_before_columns <- copy(names(development_before))
episode_before_columns <- copy(names(episode_before))
site_before_columns <- copy(names(site_before))

if (nrow(development_before) != 54030L ||
    nrow(development_after) != 54030L ||
    uniqueN(development_before$development_id) !=
      nrow(development_before) ||
    uniqueN(development_after$development_id) != nrow(development_after) ||
    nrow(episode_before) != 55345L || nrow(episode_after) != 55345L ||
    uniqueN(episode_before$hud_id) != nrow(episode_before) ||
    uniqueN(episode_after$hud_id) != nrow(episode_after) ||
    nrow(site_before) != 133324L || nrow(site_after) != 132649L ||
    uniqueN(site_before$development_site_id) != nrow(site_before) ||
    uniqueN(site_after$development_site_id) != nrow(site_after) ||
    uniqueN(site_before, by = c("development_id", "site_key")) !=
      nrow(site_before) ||
    uniqueN(site_after, by = c("development_id", "site_key")) !=
      nrow(site_after) ||
    nrow(member_decisions) != 869L ||
    uniqueN(member_decisions$development_site_id) !=
      nrow(member_decisions) ||
    nrow(episode_decisions) != 68L ||
    uniqueN(episode_decisions$hud_id) != nrow(episode_decisions) ||
    nrow(replacements) != 1L) {
  stop("A source-site audit input count or key changed.", call. = FALSE)
}

episode_before_ordered <- copy(episode_before)
episode_after_original <- episode_after[, ..episode_before_columns]
setorder(episode_before_ordered, hud_id)
setorder(episode_after_original, hud_id)
if (!identical(episode_before_ordered, episode_after_original) ||
    !setequal(episode_before$hud_id, episode_after$hud_id) ||
    !all(episode_decisions$hud_id %chin% episode_after$hud_id)) {
  stop("A source episode or original episode value changed.", call. = FALSE)
}

allowed_development_changes <- c(
  "development_city", "n_development_sites",
  "n_sites_with_hud_coordinates", "n_sites_requiring_review"
)
unchanged_development_columns <- setdiff(
  development_before_columns,
  allowed_development_changes
)
development_before_unchanged <- development_before[,
  ..unchanged_development_columns
]
development_after_unchanged <- development_after[,
  ..unchanged_development_columns
]
setorder(development_before_unchanged, development_id)
setorder(development_after_unchanged, development_id)
city_comparison <- development_before[, .(
  development_id,
  city_before = development_city
)][development_after[, .(
  development_id,
  city_after = development_city
)], on = "development_id"]
city_changes <- city_comparison[
  !fcoalesce(
    city_before == city_after,
    is.na(city_before) & is.na(city_after)
  )
]
if (!identical(
      development_before_unchanged,
      development_after_unchanged
    ) ||
    nrow(city_changes) != 1L ||
    city_changes$development_id != "DEV_MAB20191004" ||
    city_changes$city_before != "BOSTON" ||
    city_changes$city_after != "ATTLEBORO") {
  stop("An unapproved development value changed.", call. = FALSE)
}

removal_actions <- c(
  "remove_current_assignment",
  "remove_redundant_address_variant",
  "remove_only_with_external_replacement"
)
expected_removed_ids <- member_decisions[
  operative_site_action %chin% removal_actions,
  development_site_id
]
observed_removed_ids <- setdiff(
  site_before$development_site_id,
  site_after$development_site_id
)
observed_added_ids <- setdiff(
  site_after$development_site_id,
  site_before$development_site_id
)
expected_kept_sites <- site_before[
  !development_site_id %chin% expected_removed_ids,
  ..site_before_columns
]
observed_kept_sites <- site_after[
  development_site_id %chin% site_before$development_site_id,
  ..site_before_columns
]
setorder(expected_kept_sites, development_site_id)
setorder(observed_kept_sites, development_site_id)
if (!setequal(expected_removed_ids, observed_removed_ids) ||
    length(observed_removed_ids) != 676L ||
    length(observed_added_ids) != 1L ||
    observed_added_ids != "DEV_MAB20191004_SITE_0009" ||
    !identical(expected_kept_sites, observed_kept_sites) ||
    member_decisions[
      development_site_id %chin% observed_removed_ids &
        operative_site_action == "remove_current_assignment",
      .N
    ] != 640L ||
    member_decisions[
      development_site_id %chin% observed_removed_ids &
        operative_site_action ==
          "remove_only_with_external_replacement",
      .N
    ] != 8L ||
    member_decisions[
      development_site_id %chin% observed_removed_ids &
        operative_site_action == "remove_redundant_address_variant",
      .N
    ] != 28L) {
  stop("The observed site delta does not match the operative decisions.",
    call. = FALSE)
}

replacement_site <- site_after[
  development_site_id == "DEV_MAB20191004_SITE_0009"
]
if (nrow(replacement_site) != 1L ||
    replacement_site$development_id != replacements$development_id ||
    replacement_site$site_key != replacements$replacement_site_key ||
    replacement_site$site_street != replacements$replacement_site_street ||
    replacement_site$site_city != replacements$replacement_site_city ||
    replacement_site$site_state != replacements$replacement_site_state ||
    !is.na(replacement_site$site_zip) ||
    replacement_site$source_site_replacement_transaction_id !=
      replacements$replacement_transaction_id ||
    replacement_site$source_site_application_status !=
      "added_external_replacement" ||
    replacement_site$source_site_row_origin !=
      "external_public_record_replacement" ||
    member_decisions[
      replacement_transaction_id ==
        replacements$replacement_transaction_id,
      .N
    ] != replacements$replaces_n_current_assignments ||
    site_after[
      development_id == replacements$development_id,
      .N
    ] != 1L) {
  stop("The Mechanic Mill replacement was not applied transactionally.",
    call. = FALSE)
}

unresolved_ids <- member_decisions[
  operative_site_action == "hold_current_assignment_unresolved",
  development_site_id
]
umbrella_ids <- member_decisions[
  operative_site_action ==
    "retain_current_assignment_bridge_blocked",
  development_site_id
]
plaza_ids <- member_decisions[
  operative_site_action ==
    "retain_current_assignment_same_property_merge_pending",
  development_site_id
]
if (length(unresolved_ids) != 36L ||
    length(umbrella_ids) != 52L || length(plaza_ids) != 6L ||
    !all(c(unresolved_ids, umbrella_ids, plaza_ids) %chin%
      site_after$development_site_id) ||
    site_after[
      development_site_id %chin% unresolved_ids,
      unique(source_site_application_status)
    ] != "retained_unresolved_unchanged" ||
    site_after[
      development_site_id %chin% umbrella_ids,
      unique(source_site_application_status)
    ] != "retained_bridge_blocked_unchanged" ||
    site_after[
      development_site_id %chin% plaza_ids,
      unique(source_site_application_status)
    ] != "retained_structure_pending_unchanged") {
  stop("An unresolved or structure-blocked site did not remain intact.",
    call. = FALSE)
}

site_counts <- site_after[, .(
  audited_n_development_sites = .N,
  audited_n_sites_with_hud_coordinates = sum(
    !is.na(latitude) & !is.na(longitude)
  ),
  audited_n_sites_requiring_review = sum(requires_site_review)
), by = development_id]
development_site_counts <- development_after[, .(
  development_id,
  n_development_sites,
  n_sites_with_hud_coordinates,
  n_sites_requiring_review
)]
development_site_counts[site_counts, `:=`(
  audited_n_development_sites = i.audited_n_development_sites,
  audited_n_sites_with_hud_coordinates =
    i.audited_n_sites_with_hud_coordinates,
  audited_n_sites_requiring_review =
    i.audited_n_sites_requiring_review
), on = "development_id"]
development_site_counts[
  is.na(audited_n_development_sites),
  `:=`(
    audited_n_development_sites = 0L,
    audited_n_sites_with_hud_coordinates = 0L,
    audited_n_sites_requiring_review = 0L
  )
]
if (nrow(development_site_counts) != nrow(development_after) ||
    any(development_site_counts$n_development_sites !=
      development_site_counts$audited_n_development_sites) ||
    any(development_site_counts$n_sites_with_hud_coordinates !=
      development_site_counts$audited_n_sites_with_hud_coordinates) ||
    any(development_site_counts$n_sites_requiring_review !=
      development_site_counts$audited_n_sites_requiring_review)) {
  stop("A repaired development site count is inconsistent.",
    call. = FALSE)
}

expected_nonphysical_umbrellas <- c(
  "DEV_INA20220018", "DEV_WAA20140993"
)
expected_physical_components <- c(
  "DEV_INA19970165", "DEV_WAA19950035"
)
expected_hcci_placeholders <- sort(unique(member_decisions[
  source_exception_group_id %chin% c(
    "XDAQ_0113", "XDAQ_0114", "XDAQ_0115"
  ),
  development_id
]))
if (!setequal(
      development_after[
        source_site_development_scope_status ==
          "nonphysical_financing_umbrella_requires_bridge",
        development_id
      ],
      expected_nonphysical_umbrellas
    ) ||
    !setequal(
      development_after[
        source_site_development_scope_status ==
          "physical_development_component_with_overlapping_umbrella",
        development_id
      ],
      expected_physical_components
    ) ||
    length(expected_hcci_placeholders) != 10L ||
    !setequal(
      development_after[
        source_site_development_scope_status ==
          "nonphysical_portfolio_placeholder_requires_sites_and_bridge",
        development_id
      ],
      expected_hcci_placeholders
    ) ||
    episode_after[
      source_site_development_scope_status %chin% c(
        "nonphysical_financing_umbrella_requires_bridge",
        "nonphysical_portfolio_placeholder_requires_sites_and_bridge"
      ),
      .N
    ] != 14L ||
    episode_after[
      source_site_development_scope_status ==
        "physical_development_component_with_overlapping_umbrella",
      .N
    ] != 2L ||
    episode_after[
      source_site_requires_episode_property_bridge == TRUE,
      .N
    ] != 16L) {
  stop("A physical versus nonphysical development scope status is wrong.",
    call. = FALSE)
}

unit_columns <- c(
  "episode_unit_count_max", "episode_unit_count_sum",
  "unit_aggregation_status", "unit_aggregation_rule",
  "n_units_development", "li_units_development",
  "candidate_n_units_development", "candidate_li_units_development"
)
development_units_before <- development_before[, c(
  "development_id", unit_columns
), with = FALSE]
development_units_after <- development_after[, c(
  "development_id", unit_columns
), with = FALSE]
setorder(development_units_before, development_id)
setorder(development_units_after, development_id)
if (!identical(development_units_before, development_units_after) ||
    development_after[
      source_site_review_scope == "reviewed_source_exception",
      .N
    ] != 57L ||
    episode_after[
      source_site_review_scope == "reviewed_source_exception",
      .N
    ] != 68L ||
    site_after[
      source_site_review_scope == "reviewed_source_exception",
      .N
    ] != 194L ||
    sum(development_after$source_site_rows_removed) != 676L ||
    sum(development_after$source_site_rows_added) != 1L ||
    sum(development_after$source_site_unresolved_rows) != 36L ||
    any(development_after[
      source_site_review_scope == "reviewed_source_exception",
      source_site_geocoding_query_approval
    ] != "not_approved") ||
    any(episode_after[
      source_site_review_scope == "reviewed_source_exception",
      source_site_geocoding_query_approval
    ] != "not_approved") ||
    any(site_after[
      source_site_review_scope == "reviewed_source_exception",
      source_site_geocoding_query_approval
    ] != "not_approved")) {
  stop("A unit or application safety invariant failed.", call. = FALSE)
}

audit <- data.table(
  audit_status = "pass",
  audited_on = as.Date("2026-08-11"),
  developments_before = nrow(development_before),
  developments_after = nrow(development_after),
  episodes_before = nrow(episode_before),
  episodes_after = nrow(episode_after),
  sites_before = nrow(site_before),
  sites_after = nrow(site_after),
  foreign_site_assignments_removed = 648L,
  redundant_address_variants_removed = 28L,
  external_replacements_added = 1L,
  unresolved_assignments_retained = length(unresolved_ids),
  umbrella_assignments_retained = length(umbrella_ids),
  same_property_assignments_retained = length(plaza_ids),
  nonphysical_developments_flagged =
    length(expected_nonphysical_umbrellas) +
      length(expected_hcci_placeholders),
  original_episode_values_changed = 0L,
  development_unit_values_changed = 0L,
  geocoding_queries_approved = 0L
)
write_parquet(
  audit,
  "../output/lihtc_source_site_exception_application_audit.parquet"
)
roundtrip_audit <- as.data.table(read_parquet(
  "../output/lihtc_source_site_exception_application_audit.parquet"
))
if (!identical(audit, roundtrip_audit)) {
  stop("The source-site application audit failed its Parquet round trip.",
    call. = FALSE)
}

message(
  "Audit passed: 54,030 developments and 55,345 episodes preserved; ",
  "site count changed from 133,324 to 132,649 under the reviewed contract."
)
