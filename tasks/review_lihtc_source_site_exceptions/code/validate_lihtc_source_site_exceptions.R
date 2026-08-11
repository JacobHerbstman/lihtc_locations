# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/review_lihtc_source_site_exceptions/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
})

reviews <- fread("source_site_group_reviews.csv", na.strings = "")
action_contract <- fread("source_site_action_contract.csv", na.strings = "")
replacements <- fread("external_site_replacements.csv", na.strings = "")
site <- as.data.table(read_parquet(
  "../input/lihtc_source_site_exception_assignments.parquet"
))
episode <- as.data.table(read_parquet(
  "../input/lihtc_source_site_exception_episodes.parquet"
))

replacements[, replacement_site_zip := as.character(replacement_site_zip)]
reviews[, final_reviewed_on := as.Date(final_reviewed_on)]
replacements[, source_reviewed_on := as.Date(source_reviewed_on)]

if (nrow(reviews) != 22L ||
    uniqueN(reviews$source_exception_group_id) != nrow(reviews) ||
    nrow(action_contract) != 8L ||
    uniqueN(action_contract$prepared_site_disposition) !=
      nrow(action_contract) ||
    nrow(replacements) != 1L ||
    uniqueN(replacements$replacement_transaction_id) != 1L ||
    nrow(site) != 869L ||
    uniqueN(site$development_site_id) != nrow(site) ||
    uniqueN(site$source_exception_group_id) != 22L ||
    uniqueN(site$development_id) != 57L ||
    nrow(episode) != 68L || uniqueN(episode$hud_id) != nrow(episode) ||
    !setequal(
      reviews$source_exception_group_id,
      site$source_exception_group_id
    ) ||
    !setequal(
      reviews$source_exception_group_id,
      episode$source_exception_group_id
    ) ||
    !setequal(
      action_contract$prepared_site_disposition,
      site$proposed_site_disposition
    )) {
  stop("The committed review ledgers do not cover the prepared queue exactly.",
    call. = FALSE)
}

required_review_fields <- c(
  "source_exception_group_id", "expected_n_developments",
  "expected_n_episodes", "expected_n_site_assignments",
  "prepared_site_dispositions", "group_decision",
  "site_inventory_status", "property_structure_status",
  "unresolved_status", "episode_decision_status",
  "external_replacement_transaction_id", "internal_read_status",
  "outside_read_status", "final_review_notes", "final_reviewed_on",
  "repair_application_status", "source_rows_changed",
  "geocoding_query_approval"
)
required_action_fields <- c(
  "prepared_site_disposition", "operative_site_action",
  "operative_decision_status", "requires_external_replacement",
  "requires_episode_property_bridge", "current_row_change_authorized"
)
required_replacement_fields <- c(
  "replacement_transaction_id", "replacement_record_id",
  "development_id", "development_name", "replacement_site_street",
  "replacement_site_city", "replacement_site_state",
  "replacement_site_key", "replaces_n_current_assignments",
  "replacement_transaction_status", "source_title", "source_type",
  "source_url", "source_address_excerpt", "source_notes",
  "source_reviewed_on", "repair_application_status",
  "source_rows_changed", "geocoding_query_approval"
)
if (anyNA(reviews[, ..required_review_fields]) ||
    any(vapply(
      reviews[, ..required_review_fields],
      function(value) any(as.character(value) == ""),
      logical(1L)
    )) ||
    anyNA(action_contract[, ..required_action_fields]) ||
    any(vapply(
      action_contract[, ..required_action_fields],
      function(value) any(as.character(value) == ""),
      logical(1L)
    )) ||
    anyNA(replacements[, ..required_replacement_fields]) ||
    any(vapply(
      replacements[, ..required_replacement_fields],
      function(value) any(as.character(value) == ""),
      logical(1L)
    ))) {
  stop("A required review field is empty.", call. = FALSE)
}

allowed_group_decisions <- c(
  "approve_current_rows_with_transaction_and_incomplete_flags",
  "approve_prepared_site_actions",
  "hold_unresolved_site_partition",
  "retain_sites_bridge_blocked",
  "hold_unresolved_external_replacement",
  "approve_same_property_identity_merge",
  "approve_resolved_rows_hold_unresolved_campus_rows"
)
allowed_episode_statuses <- c(
  "retained_inventory_repair_pending",
  "retained_not_applied",
  "retained_site_partition_unresolved",
  "retained_bridge_blocked",
  "retained_replacement_and_bridge_blocked",
  "same_property_merge_approved_not_applied",
  "retained_site_confirmation_pending"
)
allowed_site_actions <- c(
  "remove_redundant_address_variant",
  "hold_current_assignment_unresolved",
  "remove_current_assignment",
  "retain_current_assignment",
  "retain_current_assignment_same_property_merge_pending",
  "retain_current_assignment_bridge_blocked"
)
allowed_site_statuses <- c(
  "approved_not_applied", "unresolved_unchanged",
  "identity_merge_approved_not_applied", "bridge_blocked_unchanged"
)
if (!all(reviews$group_decision %chin% allowed_group_decisions) ||
    !all(reviews$episode_decision_status %chin% allowed_episode_statuses) ||
    !all(action_contract$operative_site_action %chin%
      allowed_site_actions) ||
    !all(action_contract$operative_decision_status %chin%
      allowed_site_statuses) ||
    anyNA(reviews$final_reviewed_on) ||
    anyNA(replacements$source_reviewed_on) ||
    any(reviews$repair_application_status != "not_applied") ||
    any(reviews$source_rows_changed) ||
    any(reviews$geocoding_query_approval != "not_approved") ||
    any(replacements$repair_application_status != "not_applied") ||
    any(replacements$source_rows_changed) ||
    any(replacements$geocoding_query_approval != "not_approved") ||
    any(site$repair_application_status != "not_applied") ||
    any(site$source_rows_changed) ||
    any(site$submission_approval != "not_approved") ||
    any(episode$repair_application_status != "not_applied") ||
    any(episode$source_rows_changed) ||
    any(episode$submission_approval != "not_approved")) {
  stop("A review decision or safety field is invalid.", call. = FALSE)
}

group_evidence <- site[, .(
  observed_n_developments = uniqueN(development_id),
  observed_n_site_assignments = .N,
  observed_site_dispositions = paste(
    sort(unique(proposed_site_disposition)),
    collapse = "|"
  )
), by = source_exception_group_id]
group_evidence[episode[, .(
  observed_n_episodes = .N
), by = source_exception_group_id],
  observed_n_episodes := i.observed_n_episodes,
  on = "source_exception_group_id"
]
group_evidence[reviews, `:=`(
  reviewed_n_developments = i.expected_n_developments,
  reviewed_n_episodes = i.expected_n_episodes,
  reviewed_n_site_assignments = i.expected_n_site_assignments,
  reviewed_site_dispositions = i.prepared_site_dispositions
), on = "source_exception_group_id"]
if (anyNA(group_evidence$reviewed_n_developments) ||
    any(group_evidence$observed_n_developments !=
      group_evidence$reviewed_n_developments) ||
    any(group_evidence$observed_n_episodes !=
      group_evidence$reviewed_n_episodes) ||
    any(group_evidence$observed_n_site_assignments !=
      group_evidence$reviewed_n_site_assignments) ||
    any(group_evidence$observed_site_dispositions !=
      group_evidence$reviewed_site_dispositions) ||
    sum(reviews$expected_n_developments) != 57L ||
    sum(reviews$expected_n_episodes) != 68L ||
    sum(reviews$expected_n_site_assignments) != 869L) {
  stop("Prepared group evidence changed after review.", call. = FALSE)
}

replacement_urls <- trimws(unlist(strsplit(
  replacements$source_url,
  "|",
  fixed = TRUE
)))
if (replacements$replacement_transaction_id != "SRC_TXN_0001" ||
    replacements$replacement_record_id != "SRC_REPL_0001" ||
    replacements$development_id != "DEV_MAB20191004" ||
    replacements$development_name != "MECHANIC MILL" ||
    replacements$replacement_site_street != "67 MECHANIC STREET" ||
    replacements$replacement_site_city != "ATTLEBORO" ||
    replacements$replacement_site_state != "MA" ||
    !is.na(replacements$replacement_site_zip) ||
    replacements$replacement_site_key !=
      "MA|67 MECHANIC ST|ATTLEBORO" ||
    replacements$replaces_n_current_assignments != 8L ||
    replacements$replacement_transaction_status !=
      "approved_not_applied" ||
    length(replacement_urls) != 2L ||
    !all(grepl("^https://", replacement_urls)) ||
    site[
      development_id == "DEV_MAB20191004" &
        site_key == replacements$replacement_site_key,
      .N
    ] != 0L ||
    reviews[
      external_replacement_transaction_id == "SRC_TXN_0001",
      .N
    ] != 1L ||
    reviews[
      external_replacement_transaction_id == "SRC_TXN_0001",
      source_exception_group_id
    ] != "IAS0670") {
  stop("The Mechanic Mill replacement transaction is invalid.",
    call. = FALSE)
}

member_decisions <- copy(site)
member_decisions[action_contract, `:=`(
  operative_site_action = i.operative_site_action,
  operative_decision_status = i.operative_decision_status,
  requires_external_replacement = i.requires_external_replacement,
  requires_episode_property_bridge =
    i.requires_episode_property_bridge,
  current_row_change_authorized = i.current_row_change_authorized
), on = c(
  "proposed_site_disposition" = "prepared_site_disposition"
)]
member_decisions[, replacement_transaction_id := "none"]

review_metadata <- reviews[, .(
  source_exception_group_id,
  reviewed_group_decision = group_decision,
  reviewed_site_inventory_status = site_inventory_status,
  reviewed_property_structure_status = property_structure_status,
  reviewed_unresolved_status = unresolved_status,
  reviewed_episode_decision_status = episode_decision_status,
  reviewed_external_replacement_transaction_id =
    external_replacement_transaction_id,
  internal_read_status,
  outside_read_status,
  final_review_notes,
  final_reviewed_on,
  review_repair_application_status = repair_application_status,
  review_source_rows_changed = source_rows_changed,
  review_geocoding_query_approval = geocoding_query_approval
)]
member_decisions[review_metadata, `:=`(
  reviewed_group_decision = i.reviewed_group_decision,
  reviewed_site_inventory_status = i.reviewed_site_inventory_status,
  reviewed_property_structure_status =
    i.reviewed_property_structure_status,
  reviewed_unresolved_status = i.reviewed_unresolved_status,
  reviewed_episode_decision_status = i.reviewed_episode_decision_status,
  reviewed_external_replacement_transaction_id =
    i.reviewed_external_replacement_transaction_id,
  internal_read_status = i.internal_read_status,
  outside_read_status = i.outside_read_status,
  final_review_notes = i.final_review_notes,
  final_reviewed_on = i.final_reviewed_on,
  review_repair_application_status =
    i.review_repair_application_status,
  review_source_rows_changed = i.review_source_rows_changed,
  review_geocoding_query_approval =
    i.review_geocoding_query_approval
), on = "source_exception_group_id"]

member_decisions[
  development_id == "DEV_MAB20191004",
  `:=`(
    operative_site_action =
      "remove_only_with_external_replacement",
    operative_decision_status =
      "approved_only_as_transaction_not_applied",
    requires_external_replacement = TRUE,
    current_row_change_authorized = TRUE,
    replacement_transaction_id = "SRC_TXN_0001"
  )
]
member_decisions[, operative_site_inventory_status :=
  reviewed_site_inventory_status]
member_decisions[
  source_exception_group_id == "IAS0670",
  operative_site_inventory_status := "current_site_partition_resolved"
]
member_decisions[
  episode_scope_assessment ==
    "multibuilding_property_with_incomplete_source_site_list",
  operative_site_inventory_status := "confirmed_partial_inventory"
]
member_decisions[
  episode_scope_assessment == "true_property_absent_from_source_site_set",
  operative_site_inventory_status := "external_replacement_required"
]

expected_actions <- data.table(
  operative_site_action = c(
    "remove_current_assignment",
    "remove_only_with_external_replacement",
    "remove_redundant_address_variant",
    "retain_current_assignment",
    "hold_current_assignment_unresolved",
    "retain_current_assignment_bridge_blocked",
    "retain_current_assignment_same_property_merge_pending"
  ),
  expected_n = c(640L, 8L, 28L, 99L, 36L, 52L, 6L)
)
observed_actions <- member_decisions[, .N, by = operative_site_action]
expected_actions[observed_actions,
  observed_n := i.N,
  on = "operative_site_action"
]
incomplete_developments <- member_decisions[
  operative_site_inventory_status == "confirmed_partial_inventory",
  unique(development_id)
]
rows_removed_without_replacement <- member_decisions[
  operative_site_action %chin% c(
    "remove_current_assignment",
    "remove_redundant_address_variant"
  ),
  unique(development_id)
]
developments_with_rows_remaining <- member_decisions[
  !operative_site_action %chin% c(
    "remove_current_assignment",
    "remove_redundant_address_variant"
  ),
  unique(development_id)
]
if (anyNA(member_decisions$operative_site_action) ||
    anyNA(member_decisions$operative_decision_status) ||
    anyNA(member_decisions$reviewed_group_decision) ||
    anyNA(member_decisions$operative_site_inventory_status) ||
    anyNA(expected_actions$observed_n) ||
    any(expected_actions$expected_n != expected_actions$observed_n) ||
    !setequal(
      incomplete_developments,
      c("DEV_MAB20200014", "DEV_MAB20200016")
    ) ||
    member_decisions[
      operative_site_inventory_status == "external_replacement_required",
      uniqueN(development_id)
    ] != 1L ||
    member_decisions[
      operative_site_inventory_status == "external_replacement_required",
      unique(development_id)
    ] != "DEV_MAB20191004" ||
    member_decisions[
      operative_decision_status == "unresolved_unchanged",
      .N
    ] != 36L ||
    member_decisions[
      operative_site_action ==
        "retain_current_assignment_bridge_blocked",
      .N
    ] != 52L ||
    member_decisions[
      replacement_transaction_id == "SRC_TXN_0001",
      .N
    ] != replacements$replaces_n_current_assignments ||
    member_decisions[
      replacement_transaction_id == "SRC_TXN_0001",
      uniqueN(development_id)
    ] != 1L ||
    member_decisions[
      replacement_transaction_id == "SRC_TXN_0001",
      unique(development_id)
    ] != replacements$development_id ||
    !all(rows_removed_without_replacement %chin%
      developments_with_rows_remaining) ||
    any(member_decisions$repair_application_status != "not_applied") ||
    any(member_decisions$source_rows_changed) ||
    any(member_decisions$submission_approval != "not_approved") ||
    any(member_decisions$review_repair_application_status !=
      "not_applied") ||
    any(member_decisions$review_source_rows_changed) ||
    any(member_decisions$review_geocoding_query_approval !=
      "not_approved")) {
  print(expected_actions)
  stop("An operative source-site decision is invalid.", call. = FALSE)
}

episode_decisions <- copy(episode)
episode_decisions[review_metadata, `:=`(
  reviewed_group_decision = i.reviewed_group_decision,
  reviewed_site_inventory_status = i.reviewed_site_inventory_status,
  reviewed_property_structure_status =
    i.reviewed_property_structure_status,
  reviewed_unresolved_status = i.reviewed_unresolved_status,
  operative_episode_decision_status =
    i.reviewed_episode_decision_status,
  reviewed_external_replacement_transaction_id =
    i.reviewed_external_replacement_transaction_id,
  internal_read_status = i.internal_read_status,
  outside_read_status = i.outside_read_status,
  final_review_notes = i.final_review_notes,
  final_reviewed_on = i.final_reviewed_on,
  review_repair_application_status =
    i.review_repair_application_status,
  review_source_rows_changed = i.review_source_rows_changed,
  review_geocoding_query_approval =
    i.review_geocoding_query_approval
), on = "source_exception_group_id"]
episode_decisions[, operative_episode_action := proposed_episode_action]

expected_episode_statuses <- data.table(
  operative_episode_decision_status = c(
    "retained_inventory_repair_pending",
    "retained_not_applied",
    "retained_site_partition_unresolved",
    "retained_bridge_blocked",
    "retained_replacement_and_bridge_blocked",
    "same_property_merge_approved_not_applied",
    "retained_site_confirmation_pending"
  ),
  expected_n = c(6L, 35L, 2L, 6L, 10L, 2L, 7L)
)
observed_episode_statuses <- episode_decisions[, .N,
  by = operative_episode_decision_status
]
expected_episode_statuses[observed_episode_statuses,
  observed_n := i.N,
  on = "operative_episode_decision_status"
]
if (anyNA(episode_decisions$operative_episode_decision_status) ||
    anyNA(episode_decisions$operative_episode_action) ||
    anyNA(expected_episode_statuses$observed_n) ||
    any(expected_episode_statuses$expected_n !=
      expected_episode_statuses$observed_n) ||
    episode_decisions[
      operative_episode_decision_status == "retained_bridge_blocked",
      uniqueN(development_id)
    ] != 4L ||
    episode_decisions[
      operative_episode_decision_status == "retained_bridge_blocked",
      uniqueN(source_exception_group_id)
    ] != 2L ||
    episode_decisions[
      operative_episode_decision_status ==
        "same_property_merge_approved_not_applied",
      uniqueN(development_id)
    ] != 2L ||
    any(episode_decisions$repair_application_status != "not_applied") ||
    any(episode_decisions$source_rows_changed) ||
    any(episode_decisions$submission_approval != "not_approved") ||
    any(episode_decisions$review_repair_application_status !=
      "not_applied") ||
    any(episode_decisions$review_source_rows_changed) ||
    any(episode_decisions$review_geocoding_query_approval !=
      "not_approved")) {
  print(expected_episode_statuses)
  stop("An operative episode decision is invalid.", call. = FALSE)
}

setorder(reviews, source_exception_group_id)
setorder(member_decisions,
  source_exception_group_id,
  development_id,
  site_number
)
setorder(episode_decisions,
  source_exception_group_id,
  development_id,
  episode_number,
  hud_id
)
setorder(replacements, replacement_transaction_id, replacement_record_id)

write_parquet(
  member_decisions,
  "../output/lihtc_source_site_member_decisions.parquet"
)
write_parquet(
  reviews,
  "../output/lihtc_source_site_group_reviews.parquet"
)
write_parquet(
  episode_decisions,
  "../output/lihtc_source_site_episode_decisions.parquet"
)
write_parquet(
  replacements,
  "../output/lihtc_source_site_external_replacements.parquet"
)

roundtrip_member <- as.data.table(read_parquet(
  "../output/lihtc_source_site_member_decisions.parquet"
))
roundtrip_group <- as.data.table(read_parquet(
  "../output/lihtc_source_site_group_reviews.parquet"
))
roundtrip_episode <- as.data.table(read_parquet(
  "../output/lihtc_source_site_episode_decisions.parquet"
))
roundtrip_replacement <- as.data.table(read_parquet(
  "../output/lihtc_source_site_external_replacements.parquet"
))
if (!identical(member_decisions, roundtrip_member) ||
    !identical(reviews, roundtrip_group) ||
    !identical(episode_decisions, roundtrip_episode) ||
    !identical(replacements, roundtrip_replacement)) {
  stop("A source-site review output failed its Parquet round trip.",
    call. = FALSE)
}

message(
  "Reviewed 22 groups, 68 episodes, and 869 site assignments; ",
  "36 assignments and all bridge-dependent structure remain blocked."
)
