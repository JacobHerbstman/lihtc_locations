# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/apply_lihtc_source_site_exception_review/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
})

development <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_single_address_adjudicated.parquet"
))
episode <- as.data.table(read_parquet(
  "../input/lihtc_project_episode_2024_single_address_adjudicated.parquet"
))
site <- as.data.table(read_parquet(
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

development_original_columns <- copy(names(development))
episode_original_columns <- copy(names(episode))
site_original_columns <- copy(names(site))
development_before <- copy(development)
episode_before <- copy(episode)
site_before <- copy(site)

new_development_columns <- c(
  "source_site_review_scope", "source_site_exception_group_id",
  "source_site_group_decision", "source_site_inventory_status",
  "source_site_property_structure_status",
  "source_site_development_scope_status",
  "source_site_unresolved_status",
  "source_site_requires_episode_property_bridge",
  "source_site_repair_status", "source_site_rows_removed",
  "source_site_rows_added", "source_site_unresolved_rows",
  "source_site_replacement_transaction_id",
  "source_site_reviewed_on", "source_site_geocoding_query_approval"
)
new_episode_columns <- c(
  "source_site_review_scope", "source_site_exception_group_id",
  "source_site_group_decision", "source_site_inventory_status",
  "source_site_property_structure_status",
  "source_site_development_scope_status",
  "source_site_unresolved_status",
  "source_site_requires_episode_property_bridge",
  "source_site_episode_action", "source_site_episode_decision_status",
  "source_site_repair_status", "source_site_replacement_transaction_id",
  "source_site_reviewed_on", "source_site_geocoding_query_approval"
)
new_site_columns <- c(
  "source_site_review_scope", "source_site_exception_group_id",
  "source_site_group_decision", "source_site_operative_action",
  "source_site_decision_status", "source_site_inventory_status",
  "source_site_property_structure_status",
  "source_site_development_scope_status",
  "source_site_unresolved_status",
  "source_site_requires_episode_property_bridge",
  "source_site_replacement_transaction_id", "source_site_reviewed_on",
  "source_site_geocoding_query_approval",
  "source_site_application_status", "source_site_row_origin"
)
if (nrow(development) != 54030L ||
    uniqueN(development$development_id) != nrow(development) ||
    nrow(episode) != 55345L || uniqueN(episode$hud_id) != nrow(episode) ||
    nrow(site) != 133324L ||
    uniqueN(site$development_site_id) != nrow(site) ||
    uniqueN(site, by = c("development_id", "site_key")) != nrow(site) ||
    nrow(member_decisions) != 869L ||
    uniqueN(member_decisions$development_site_id) !=
      nrow(member_decisions) ||
    nrow(episode_decisions) != 68L ||
    uniqueN(episode_decisions$hud_id) != nrow(episode_decisions) ||
    nrow(replacements) != 1L ||
    any(new_development_columns %chin% development_original_columns) ||
    any(new_episode_columns %chin% episode_original_columns) ||
    any(new_site_columns %chin% site_original_columns) ||
    any(!episode$development_id %chin% development$development_id) ||
    any(!site$development_id %chin% development$development_id) ||
    any(!member_decisions$development_site_id %chin%
      site$development_site_id) ||
    any(!episode_decisions$hud_id %chin% episode$hud_id)) {
  stop("A source-site application input count or key changed.",
    call. = FALSE)
}

reviewed_site_snapshot <- member_decisions[, ..site_original_columns]
current_reviewed_sites <- site[
  development_site_id %chin% member_decisions$development_site_id,
  ..site_original_columns
]
setorder(reviewed_site_snapshot, development_site_id)
setorder(current_reviewed_sites, development_site_id)
reviewed_episode_snapshot <- episode_decisions[, ..episode_original_columns]
current_reviewed_episodes <- episode[
  hud_id %chin% episode_decisions$hud_id,
  ..episode_original_columns
]
setorder(reviewed_episode_snapshot, hud_id)
setorder(current_reviewed_episodes, hud_id)
if (!identical(reviewed_site_snapshot, current_reviewed_sites) ||
    !identical(reviewed_episode_snapshot, current_reviewed_episodes)) {
  stop("A reviewed source row changed before application.", call. = FALSE)
}

removal_actions <- c(
  "remove_current_assignment",
  "remove_redundant_address_variant",
  "remove_only_with_external_replacement"
)
removal_ids <- member_decisions[
  operative_site_action %chin% removal_actions,
  development_site_id
]
mechanic_removal_ids <- member_decisions[
  operative_site_action == "remove_only_with_external_replacement",
  development_site_id
]
if (length(removal_ids) != 676L || uniqueN(removal_ids) != 676L ||
    member_decisions[
      operative_site_action == "remove_current_assignment",
      .N
    ] != 640L ||
    member_decisions[
      operative_site_action == "remove_redundant_address_variant",
      .N
    ] != 28L ||
    length(mechanic_removal_ids) != 8L ||
    member_decisions[
      development_site_id %chin% mechanic_removal_ids,
      uniqueN(development_id)
    ] != 1L ||
    member_decisions[
      development_site_id %chin% mechanic_removal_ids,
      unique(development_id)
    ] != replacements$development_id ||
    member_decisions[
      development_site_id %chin% mechanic_removal_ids,
      unique(replacement_transaction_id)
    ] != replacements$replacement_transaction_id ||
    replacements$replacement_transaction_status !=
      "approved_not_applied" ||
    replacements$repair_application_status != "not_applied" ||
    replacements$source_rows_changed ||
    replacements$geocoding_query_approval != "not_approved" ||
    replacements$replacement_site_key %chin% site$site_key[
      site$development_id == replacements$development_id
    ] ||
    "DEV_MAB20191004_SITE_0009" %chin% site$development_site_id) {
  stop("The Mechanic Mill replacement transaction is incomplete.",
    call. = FALSE)
}

development_review <- member_decisions[, .(
  source_site_exception_group_id = unique(source_exception_group_id),
  source_site_group_decision = unique(reviewed_group_decision),
  source_site_inventory_status = unique(operative_site_inventory_status),
  source_site_property_structure_status =
    unique(reviewed_property_structure_status),
  source_site_unresolved_status = unique(reviewed_unresolved_status),
  source_site_unresolved_rows = sum(
    operative_site_action == "hold_current_assignment_unresolved"
  ),
  source_site_requires_episode_property_bridge =
    any(requires_episode_property_bridge),
  source_site_rows_removed = sum(
    operative_site_action %chin% removal_actions
  ),
  source_site_rows_added = as.integer(
    first(development_id) == replacements$development_id
  ),
  source_site_replacement_transaction_id = paste(
    sort(unique(replacement_transaction_id[
      replacement_transaction_id != "none"
    ])),
    collapse = "|"
  ),
  source_site_reviewed_on = unique(final_reviewed_on),
  source_site_geocoding_query_approval =
    unique(review_geocoding_query_approval)
), by = development_id]
development_review[
  source_site_replacement_transaction_id == "",
  source_site_replacement_transaction_id := "none"
]
if (nrow(development_review) != 57L ||
    uniqueN(development_review$development_id) != nrow(development_review) ||
    anyNA(development_review)) {
  stop("A development has inconsistent source-site review metadata.",
    call. = FALSE)
}

development_review[
  source_site_exception_group_id == "IAS0670",
  `:=`(
    source_site_property_structure_status =
      "retain_current_development_structure",
    source_site_unresolved_status = "none"
  )
]
development_review[
  development_id %chin% c("DEV_MAB20200014", "DEV_MAB20200016"),
  `:=`(
    source_site_property_structure_status =
      "retain_structure_pending_inventory_completion",
    source_site_unresolved_status = "site_inventory_incomplete"
  )
]
development_review[
  development_id == "DEV_MAB20191004",
  source_site_inventory_status :=
    "current_site_partition_resolved_after_replacement"
]
development_review[, source_site_development_scope_status := fcase(
  development_id %chin% c("DEV_INA20220018", "DEV_WAA20140993"),
  "nonphysical_financing_umbrella_requires_bridge",
  development_id %chin% c("DEV_INA19970165", "DEV_WAA19950035"),
  "physical_development_component_with_overlapping_umbrella",
  source_site_exception_group_id %chin% c(
    "XDAQ_0113", "XDAQ_0114", "XDAQ_0115"
  ),
  "nonphysical_portfolio_placeholder_requires_sites_and_bridge",
  source_site_exception_group_id == "XDAQ_0116",
  "physical_development_same_property_merge_pending",
  source_site_unresolved_status == "site_inventory_incomplete",
  "physical_development_incomplete_site_inventory",
  source_site_exception_group_id == "IASR_003",
  "physical_development_unresolved_site_inventory",
  source_site_unresolved_rows > 0L,
  "physical_development_site_confirmation_pending",
  default = "physical_development_resolved_site_inventory"
)]
development_review[, source_site_repair_status := fcase(
  development_id == "DEV_MAB20191004",
  "applied_transactional_replacement",
  source_site_unresolved_status == "site_inventory_incomplete",
  "applied_current_rows_inventory_incomplete",
  source_site_rows_removed > 0L & source_site_unresolved_status != "none",
  "applied_resolved_rows_unresolved_rows_retained",
  source_site_rows_removed > 0L,
  "applied_reviewed_site_repairs",
  source_site_unresolved_status != "none",
  "unchanged_unresolved",
  source_site_property_structure_status !=
    "retain_current_development_structure",
  "unchanged_property_structure_pending",
  default = "no_row_change_review_recorded"
)]

site[, `:=`(
  source_site_review_scope = "not_in_source_exception_review",
  source_site_exception_group_id = NA_character_,
  source_site_group_decision = "not_in_review",
  source_site_operative_action = "not_in_review",
  source_site_decision_status = "not_in_review",
  source_site_inventory_status = "not_in_review",
  source_site_property_structure_status = "not_in_review",
  source_site_development_scope_status = "not_in_review",
  source_site_unresolved_status = "none",
  source_site_requires_episode_property_bridge = FALSE,
  source_site_replacement_transaction_id = "none",
  source_site_reviewed_on = as.Date(NA),
  source_site_geocoding_query_approval = "not_reviewed",
  source_site_application_status = "not_in_review",
  source_site_row_origin = "existing_hud_assignment"
)]
site[member_decisions, `:=`(
  source_site_review_scope = "reviewed_source_exception",
  source_site_exception_group_id = i.source_exception_group_id,
  source_site_group_decision = i.reviewed_group_decision,
  source_site_operative_action = i.operative_site_action,
  source_site_decision_status = i.operative_decision_status,
  source_site_replacement_transaction_id =
    i.replacement_transaction_id,
  source_site_reviewed_on = i.final_reviewed_on,
  source_site_geocoding_query_approval =
    i.review_geocoding_query_approval
), on = "development_site_id"]
site[development_review, `:=`(
  source_site_inventory_status = i.source_site_inventory_status,
  source_site_property_structure_status =
    i.source_site_property_structure_status,
  source_site_development_scope_status =
    i.source_site_development_scope_status,
  source_site_unresolved_status = i.source_site_unresolved_status,
  source_site_requires_episode_property_bridge =
    i.source_site_requires_episode_property_bridge
), on = "development_id"]
site[source_site_review_scope == "reviewed_source_exception",
  source_site_application_status := fcase(
    source_site_operative_action ==
      "hold_current_assignment_unresolved",
    "retained_unresolved_unchanged",
    source_site_operative_action ==
      "retain_current_assignment_bridge_blocked",
    "retained_bridge_blocked_unchanged",
    source_site_operative_action ==
      "retain_current_assignment_same_property_merge_pending",
    "retained_structure_pending_unchanged",
    source_site_operative_action == "retain_current_assignment",
    "retained_reviewed_unchanged",
    default = "removed_by_review"
  )
]

site <- site[!development_site_id %chin% removal_ids]
mechanic_hud_ids <- sort(episode[
  development_id == replacements$development_id,
  hud_id
])
if (length(mechanic_hud_ids) != 1L) {
  stop("Mechanic Mill does not have exactly one preserved episode.",
    call. = FALSE)
}
replacement_site <- data.table(
  development_site_id = "DEV_MAB20191004_SITE_0009",
  development_id = replacements$development_id,
  site_number = 9L,
  site_key = replacements$replacement_site_key,
  site_street = replacements$replacement_site_street,
  site_city = replacements$replacement_site_city,
  site_state = replacements$replacement_site_state,
  site_zip = replacements$replacement_site_zip,
  site_source = "external_public_record",
  n_project_episodes = length(mechanic_hud_ids),
  hud_ids = paste(mechanic_hud_ids, collapse = "|"),
  n_bin_values = 0L,
  bin_example = NA_character_,
  n_coordinate_pairs = 0L,
  latitude = NA_real_,
  longitude = NA_real_,
  requires_site_review = TRUE,
  source_site_review_scope = "reviewed_source_exception",
  source_site_exception_group_id = "IAS0670",
  source_site_group_decision =
    "approve_current_rows_with_transaction_and_incomplete_flags",
  source_site_operative_action = "add_external_replacement",
  source_site_decision_status = "transaction_applied",
  source_site_inventory_status =
    "current_site_partition_resolved_after_replacement",
  source_site_property_structure_status =
    "retain_current_development_structure",
  source_site_development_scope_status =
    "physical_development_resolved_site_inventory",
  source_site_unresolved_status = "none",
  source_site_requires_episode_property_bridge = FALSE,
  source_site_replacement_transaction_id =
    replacements$replacement_transaction_id,
  source_site_reviewed_on = replacements$source_reviewed_on,
  source_site_geocoding_query_approval = "not_approved",
  source_site_application_status = "added_external_replacement",
  source_site_row_origin = "external_public_record_replacement"
)
site <- rbindlist(list(site, replacement_site), use.names = TRUE)
setorder(site, development_id, site_number, site_key)

kept_original_sites <- site[
  development_site_id %chin% site_before$development_site_id,
  ..site_original_columns
]
expected_kept_sites <- site_before[
  !development_site_id %chin% removal_ids,
  ..site_original_columns
]
setorder(kept_original_sites, development_site_id)
setorder(expected_kept_sites, development_site_id)
unresolved_or_bridge_ids <- member_decisions[
  operative_site_action %chin% c(
    "hold_current_assignment_unresolved",
    "retain_current_assignment_bridge_blocked"
  ),
  development_site_id
]
if (nrow(site) != 132649L ||
    uniqueN(site$development_site_id) != nrow(site) ||
    uniqueN(site, by = c("development_id", "site_key")) != nrow(site) ||
    any(removal_ids %chin% site$development_site_id) ||
    !all(unresolved_or_bridge_ids %chin% site$development_site_id) ||
    !identical(kept_original_sites, expected_kept_sites) ||
    site[development_site_id == "DEV_MAB20191004_SITE_0009", .N] != 1L ||
    site[
      development_site_id == "DEV_MAB20191004_SITE_0009",
      site_key
    ] != replacements$replacement_site_key ||
    site[
      development_site_id == "DEV_MAB20191004_SITE_0009",
      source_site_replacement_transaction_id
    ] != replacements$replacement_transaction_id ||
    site[
      source_site_application_status ==
        "retained_unresolved_unchanged",
      .N
    ] != 36L ||
    site[
      source_site_application_status ==
        "retained_bridge_blocked_unchanged",
      .N
    ] != 52L) {
  stop("The repaired site table violates the reviewed row contract.",
    call. = FALSE)
}

development[, `:=`(
  source_site_review_scope = "not_in_source_exception_review",
  source_site_exception_group_id = NA_character_,
  source_site_group_decision = "not_in_review",
  source_site_inventory_status = "not_in_review",
  source_site_property_structure_status = "not_in_review",
  source_site_development_scope_status = "not_in_review",
  source_site_unresolved_status = "none",
  source_site_requires_episode_property_bridge = FALSE,
  source_site_repair_status = "not_in_review",
  source_site_rows_removed = 0L,
  source_site_rows_added = 0L,
  source_site_unresolved_rows = 0L,
  source_site_replacement_transaction_id = "none",
  source_site_reviewed_on = as.Date(NA),
  source_site_geocoding_query_approval = "not_reviewed"
)]
development[development_review, `:=`(
  source_site_review_scope = "reviewed_source_exception",
  source_site_exception_group_id = i.source_site_exception_group_id,
  source_site_group_decision = i.source_site_group_decision,
  source_site_inventory_status = i.source_site_inventory_status,
  source_site_property_structure_status =
    i.source_site_property_structure_status,
  source_site_development_scope_status =
    i.source_site_development_scope_status,
  source_site_unresolved_status = i.source_site_unresolved_status,
  source_site_requires_episode_property_bridge =
    i.source_site_requires_episode_property_bridge,
  source_site_repair_status = i.source_site_repair_status,
  source_site_rows_removed = i.source_site_rows_removed,
  source_site_rows_added = i.source_site_rows_added,
  source_site_unresolved_rows = i.source_site_unresolved_rows,
  source_site_replacement_transaction_id =
    i.source_site_replacement_transaction_id,
  source_site_reviewed_on = i.source_site_reviewed_on,
  source_site_geocoding_query_approval =
    i.source_site_geocoding_query_approval
), on = "development_id"]
development[
  development_id == replacements$development_id,
  development_city := replacements$replacement_site_city
]

site_counts <- site[, .(
  repaired_n_development_sites = .N,
  repaired_n_sites_with_hud_coordinates = sum(
    !is.na(latitude) & !is.na(longitude)
  ),
  repaired_n_sites_requiring_review = sum(requires_site_review)
), by = development_id]
development[site_counts, `:=`(
  n_development_sites = i.repaired_n_development_sites,
  n_sites_with_hud_coordinates =
    i.repaired_n_sites_with_hud_coordinates,
  n_sites_requiring_review = i.repaired_n_sites_requiring_review
), on = "development_id"]

unchanged_development_columns <- setdiff(
  development_original_columns,
  c(
    "development_city", "n_development_sites",
    "n_sites_with_hud_coordinates", "n_sites_requiring_review"
  )
)
development_unchanged <- development[, ..unchanged_development_columns]
development_before_unchanged <- development_before[,
  ..unchanged_development_columns
]
setorder(development_unchanged, development_id)
setorder(development_before_unchanged, development_id)
if (nrow(development) != 54030L ||
    uniqueN(development$development_id) != nrow(development) ||
    !identical(development_unchanged, development_before_unchanged) ||
    development[
      development_id != replacements$development_id &
        development_city != development_before$development_city[
          match(development_id, development_before$development_id)
        ],
      .N
    ] != 0L ||
    development[
      development_id == replacements$development_id,
      development_city
    ] != "ATTLEBORO" ||
    development[
      development_id == replacements$development_id,
      n_development_sites
    ] != 1L ||
    sum(development$source_site_rows_removed) != 676L ||
    sum(development$source_site_rows_added) != 1L ||
    sum(development$source_site_unresolved_rows) != 36L ||
    development[
      source_site_development_scope_status ==
        "nonphysical_financing_umbrella_requires_bridge",
      .N
    ] != 2L ||
    development[
      source_site_development_scope_status ==
        "physical_development_component_with_overlapping_umbrella",
      .N
    ] != 2L ||
    development[
      source_site_development_scope_status ==
        "nonphysical_portfolio_placeholder_requires_sites_and_bridge",
      .N
    ] != 10L ||
    development[
      source_site_review_scope == "reviewed_source_exception",
      .N
    ] != 57L) {
  stop("The repaired development table violates the reviewed contract.",
    call. = FALSE)
}

episode[, `:=`(
  source_site_review_scope = "not_in_source_exception_review",
  source_site_exception_group_id = NA_character_,
  source_site_group_decision = "not_in_review",
  source_site_inventory_status = "not_in_review",
  source_site_property_structure_status = "not_in_review",
  source_site_development_scope_status = "not_in_review",
  source_site_unresolved_status = "none",
  source_site_requires_episode_property_bridge = FALSE,
  source_site_episode_action = "not_in_review",
  source_site_episode_decision_status = "not_in_review",
  source_site_repair_status = "not_in_review",
  source_site_replacement_transaction_id = "none",
  source_site_reviewed_on = as.Date(NA),
  source_site_geocoding_query_approval = "not_reviewed"
)]
episode[episode_decisions, `:=`(
  source_site_review_scope = "reviewed_source_exception",
  source_site_exception_group_id = i.source_exception_group_id,
  source_site_group_decision = i.reviewed_group_decision,
  source_site_episode_action = i.operative_episode_action,
  source_site_episode_decision_status =
    i.operative_episode_decision_status,
  source_site_reviewed_on = i.final_reviewed_on,
  source_site_geocoding_query_approval =
    i.review_geocoding_query_approval
), on = "hud_id"]
episode[development_review, `:=`(
  source_site_inventory_status = i.source_site_inventory_status,
  source_site_property_structure_status =
    i.source_site_property_structure_status,
  source_site_development_scope_status =
    i.source_site_development_scope_status,
  source_site_unresolved_status = i.source_site_unresolved_status,
  source_site_requires_episode_property_bridge =
    i.source_site_requires_episode_property_bridge,
  source_site_repair_status = i.source_site_repair_status,
  source_site_replacement_transaction_id =
    i.source_site_replacement_transaction_id
), on = "development_id"]
episode[
  source_site_repair_status == "applied_transactional_replacement",
  source_site_episode_decision_status :=
    "replacement_applied_episode_retained"
]
episode[
  source_site_repair_status ==
    "applied_current_rows_inventory_incomplete",
  source_site_episode_decision_status := "retained_inventory_incomplete"
]
episode[
  source_site_repair_status ==
    "applied_resolved_rows_unresolved_rows_retained",
  source_site_episode_decision_status :=
    "retained_after_partial_site_repair_unresolved_rows"
]
episode[
  source_site_repair_status == "applied_reviewed_site_repairs",
  source_site_episode_decision_status := "retained_after_site_repair"
]

episode_original_after <- episode[, ..episode_original_columns]
setorder(episode_original_after, hud_id)
setorder(episode_before, hud_id)
if (nrow(episode) != 55345L || uniqueN(episode$hud_id) != nrow(episode) ||
    !identical(episode_original_after, episode_before) ||
    episode[
      source_site_review_scope == "reviewed_source_exception",
      .N
    ] != 68L ||
    episode[
      source_site_requires_episode_property_bridge == TRUE,
      .N
    ] != 16L ||
    episode[
      source_site_development_scope_status %chin% c(
        "nonphysical_financing_umbrella_requires_bridge",
        "nonphysical_portfolio_placeholder_requires_sites_and_bridge"
      ),
      .N
    ] != 14L ||
    episode[
      source_site_episode_decision_status ==
        "replacement_applied_episode_retained",
      .N
    ] != 1L) {
  stop("The repaired episode table violates the preservation contract.",
    call. = FALSE)
}

setorder(development, development_id)
setorder(episode, development_id, episode_number, hud_id)
write_parquet(
  development,
  "../output/lihtc_development_2024_source_site_repaired.parquet"
)
write_parquet(
  episode,
  "../output/lihtc_project_episode_2024_source_site_repaired.parquet"
)
write_parquet(
  site,
  "../output/lihtc_development_site_2024_source_site_repaired.parquet"
)

roundtrip_development <- as.data.table(read_parquet(
  "../output/lihtc_development_2024_source_site_repaired.parquet"
))
roundtrip_episode <- as.data.table(read_parquet(
  "../output/lihtc_project_episode_2024_source_site_repaired.parquet"
))
roundtrip_site <- as.data.table(read_parquet(
  "../output/lihtc_development_site_2024_source_site_repaired.parquet"
))
if (!identical(development, roundtrip_development) ||
    !identical(episode, roundtrip_episode) ||
    !identical(site, roundtrip_site)) {
  stop("A source-site application output failed its Parquet round trip.",
    call. = FALSE)
}

message(
  "Applied 648 foreign-site removals, 28 redundant-variant removals, ",
  "and one transactional replacement; preserved 54,030 developments ",
  "and 55,345 episodes."
)
