# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/apply_lihtc_mixed_site_identity_review/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
})

first_text <- function(value) {
  value <- sort(unique(value[!is.na(value) & value != ""]))
  if (length(value) == 0L) NA_character_ else value[1L]
}

collapse_delimited <- function(value) {
  tokens <- trimws(unlist(strsplit(
    value[!is.na(value) & value != ""],
    "|",
    fixed = TRUE
  )))
  tokens <- sort(unique(tokens[tokens != ""]))
  if (length(tokens) == 0L) NA_character_ else paste(tokens, collapse = "|")
}

development_input <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_source_site_repaired.parquet"
))
episode_input <- as.data.table(read_parquet(
  "../input/lihtc_project_episode_2024_source_site_repaired.parquet"
))
site_input <- as.data.table(read_parquet(
  "../input/lihtc_development_site_2024_source_site_repaired.parquet"
))
reviews <- as.data.table(read_parquet(
  "../input/lihtc_mixed_site_identity_question_reviews.parquet"
))
members <- as.data.table(read_parquet(
  "../input/lihtc_mixed_site_identity_member_partitions.parquet"
))

if (uniqueN(development_input$development_id) != nrow(development_input) ||
    uniqueN(episode_input$hud_id) != nrow(episode_input) ||
    uniqueN(site_input$development_site_id) != nrow(site_input) ||
    uniqueN(site_input, by = c("development_id", "site_key")) !=
      nrow(site_input) ||
    nrow(reviews) != 87L ||
    uniqueN(reviews$mixed_site_question_id) != nrow(reviews) ||
    nrow(members) != 195L ||
    uniqueN(members$development_id) != nrow(members) ||
    uniqueN(members$review_cluster_id) != 105L) {
  stop("A mixed-site application input count or key changed.", call. = FALSE)
}
if (reviews[final_identity_decision == "merge_all", .N] != 73L ||
    reviews[final_identity_decision == "partition", .N] != 7L ||
    reviews[final_identity_decision == "retain_each", .N] != 7L ||
    members[cluster_status == "final_physical_development",
      uniqueN(review_cluster_id)] != 104L ||
    members[cluster_status ==
      "nonphysical_financing_umbrella_requires_bridge",
      uniqueN(review_cluster_id)] != 1L ||
    members[member_action == "merge_to_review_cluster", .N] != 171L ||
    members[member_action == "retain_current_development", .N] != 23L ||
    members[member_action ==
      "retain_for_episode_to_property_bridge", .N] != 1L ||
    any(reviews$shared_geocoding_query_decision != "not_approved") ||
    any(members$shared_geocoding_query_decision != "not_approved") ||
    any(reviews$source_rows_changed) || any(members$source_rows_changed)) {
  stop("The committed mixed-site review contract changed.", call. = FALSE)
}
if (any(!members$development_id %chin% development_input$development_id) ||
    !setequal(
      members$mixed_site_question_id,
      reviews$mixed_site_question_id
    )) {
  stop("A reviewed development or question is absent from current data.",
    call. = FALSE)
}

physical_members <- members[
  cluster_status == "final_physical_development"
]
umbrella_members <- members[
  cluster_status == "nonphysical_financing_umbrella_requires_bridge"
]
if (nrow(physical_members) != 194L ||
    nrow(umbrella_members) != 1L ||
    umbrella_members$development_id != "DEV_NYC20110841" ||
    any(!physical_members$adjudicated_development_id %chin%
      development_input$development_id)) {
  stop("The physical and nonphysical member split changed.", call. = FALSE)
}

physical_cluster_contract <- physical_members[, .(
  observed_members = .N,
  declared_member_counts = uniqueN(n_review_cluster_members),
  declared_members = first(n_review_cluster_members),
  anchor_rows = sum(development_id == adjudicated_development_id),
  anchor_ids = uniqueN(adjudicated_development_id),
  anchor_hud_ids = uniqueN(adjudicated_development_anchor_hud_id)
), by = review_cluster_id]
if (physical_cluster_contract[
      declared_member_counts != 1L |
        observed_members != declared_members |
        anchor_rows != 1L |
        anchor_ids != 1L |
        anchor_hud_ids != 1L,
      .N
    ] > 0L) {
  stop("A physical cluster does not have one declared anchor.",
    call. = FALSE)
}

mapping <- members[, .(
  current_development_id = development_id,
  mixed_site_question_id,
  review_cluster_id,
  cluster_status,
  member_action,
  episode_to_property_bridge_status,
  adjudicated_development_id,
  adjudicated_development_anchor_hud_id,
  shared_geocoding_query_decision
)]
mapping[reviews[, .(
  mixed_site_question_id,
  final_identity_decision,
  final_reason_code,
  final_reviewed_on
)], `:=`(
  final_identity_decision = i.final_identity_decision,
  final_reason_code = i.final_reason_code,
  final_reviewed_on = i.final_reviewed_on
), on = "mixed_site_question_id"]
if (uniqueN(mapping$current_development_id) != nrow(mapping) ||
    anyNA(mapping[, .(
      final_identity_decision,
      final_reason_code,
      final_reviewed_on,
      cluster_status,
      episode_to_property_bridge_status
    )])) {
  stop("A reviewed development has an incomplete mapping.", call. = FALSE)
}

anchor_ownership <- unique(physical_members[, .(
  adjudicated_development_id,
  adjudicated_development_anchor_hud_id
)])
anchor_ownership[episode_input[, .(
  adjudicated_development_anchor_hud_id = hud_id,
  anchor_source_development_id = development_id
)], anchor_source_development_id := i.anchor_source_development_id,
on = "adjudicated_development_anchor_hud_id"]
if (anyNA(anchor_ownership$anchor_source_development_id) ||
    any(
      anchor_ownership$adjudicated_development_id !=
        anchor_ownership$anchor_source_development_id
    )) {
  stop("A committed anchor HUD ID does not belong to its development.",
    call. = FALSE)
}

episode <- copy(episode_input)
episode[, `:=`(
  pre_mixed_site_identity_development_id = development_id,
  mixed_site_identity_question_id = NA_character_,
  mixed_site_identity_cluster_id = NA_character_,
  mixed_site_identity_decision = "not_applicable",
  mixed_site_identity_action = "not_applicable",
  mixed_site_identity_reason_code = NA_character_,
  mixed_site_identity_cluster_status = "not_reviewed",
  mixed_site_identity_reviewed_on = as.Date(NA),
  mixed_site_identity_shared_query_decision = "not_reviewed",
  mixed_site_episode_to_property_bridge_status = "not_required"
)]
episode[mapping, `:=`(
  mixed_site_identity_question_id = i.mixed_site_question_id,
  mixed_site_identity_cluster_id = i.review_cluster_id,
  mixed_site_identity_decision = i.final_identity_decision,
  mixed_site_identity_action = i.member_action,
  mixed_site_identity_reason_code = i.final_reason_code,
  mixed_site_identity_cluster_status = i.cluster_status,
  mixed_site_identity_reviewed_on = as.Date(i.final_reviewed_on),
  mixed_site_identity_shared_query_decision =
    i.shared_geocoding_query_decision,
  mixed_site_episode_to_property_bridge_status =
    i.episode_to_property_bridge_status
), on = c(
  pre_mixed_site_identity_development_id = "current_development_id"
)]
episode[physical_members, `:=`(
  development_id = i.adjudicated_development_id,
  development_anchor_hud_id = i.adjudicated_development_anchor_hud_id
), on = c(
  pre_mixed_site_identity_development_id = "development_id"
)]
episode[mixed_site_identity_action == "merge_to_review_cluster", `:=`(
  development_linkage_status = "mixed_site_identity_adjudicated_linked",
  development_linkage_basis = "mixed_site_two_read_review",
  requires_linkage_review = FALSE
)]
episode[mixed_site_identity_action == "retain_current_development", `:=`(
  development_linkage_status = "mixed_site_identity_reviewed_distinct",
  requires_linkage_review = FALSE
)]
episode[
  mixed_site_identity_cluster_status ==
    "nonphysical_financing_umbrella_requires_bridge",
  `:=`(
    development_linkage_status =
      "nonphysical_umbrella_requires_episode_property_bridge",
    development_linkage_basis = "mixed_site_two_read_review",
    requires_linkage_review = TRUE
  )
]
episode[, anchor_sort_year := fcase(
  !is.na(pis_year), pis_year,
  !is.na(allocation_year), allocation_year,
  default = 9999L
)]
setorder(
  episode,
  development_id,
  anchor_sort_year,
  allocation_year,
  hud_id,
  na.last = TRUE
)
episode[, `:=`(
  episode_number = seq_len(.N),
  n_project_episodes = .N
), by = development_id]
episode[, is_development_anchor := hud_id == development_anchor_hud_id]
if (episode[is_development_anchor == TRUE, .N] !=
      uniqueN(episode$development_id)) {
  stop("An adjudicated episode group has an invalid anchor.", call. = FALSE)
}

development <- copy(development_input)
development[, `:=`(
  current_development_id = development_id,
  pre_mixed_site_identity_development_ids = development_id,
  mixed_site_identity_question_ids = NA_character_,
  mixed_site_identity_cluster_id = NA_character_,
  mixed_site_identity_decision = "not_applicable",
  mixed_site_identity_action = "not_applicable",
  mixed_site_identity_reason_codes = NA_character_,
  mixed_site_identity_cluster_status = "not_reviewed",
  mixed_site_identity_reviewed_on = as.Date(NA),
  mixed_site_identity_shared_query_decision = "not_reviewed",
  mixed_site_episode_to_property_bridge_status = "not_required"
)]
development[mapping, `:=`(
  mixed_site_identity_question_ids = i.mixed_site_question_id,
  mixed_site_identity_cluster_id = i.review_cluster_id,
  mixed_site_identity_decision = i.final_identity_decision,
  mixed_site_identity_action = i.member_action,
  mixed_site_identity_reason_codes = i.final_reason_code,
  mixed_site_identity_cluster_status = i.cluster_status,
  mixed_site_identity_reviewed_on = as.Date(i.final_reviewed_on),
  mixed_site_identity_shared_query_decision =
    i.shared_geocoding_query_decision,
  mixed_site_episode_to_property_bridge_status =
    i.episode_to_property_bridge_status
), on = c(current_development_id = "current_development_id")]
development[physical_members, `:=`(
  development_id = i.adjudicated_development_id,
  development_anchor_hud_id = i.adjudicated_development_anchor_hud_id
), on = c(current_development_id = "development_id")]
development[mixed_site_identity_action == "merge_to_review_cluster", `:=`(
  development_linkage_status = "mixed_site_identity_adjudicated_linked",
  development_linkage_basis = "mixed_site_two_read_review",
  requires_linkage_review = FALSE
)]
development[mixed_site_identity_action == "retain_current_development", `:=`(
  development_linkage_status = "mixed_site_identity_reviewed_distinct",
  requires_linkage_review = FALSE
)]
development[
  mixed_site_identity_cluster_status ==
    "nonphysical_financing_umbrella_requires_bridge",
  `:=`(
    development_linkage_status =
      "nonphysical_umbrella_requires_episode_property_bridge",
    development_linkage_basis = "mixed_site_two_read_review",
    requires_linkage_review = TRUE
  )
]

merged_members <- development[
  mixed_site_identity_action == "merge_to_review_cluster"
]
merged_development <- merged_members[current_development_id == development_id]
if (nrow(merged_development) != 81L ||
    uniqueN(merged_development$development_id) !=
      nrow(merged_development)) {
  stop("A multi-member physical cluster lacks one anchor row.",
    call. = FALSE)
}

lineage_fields <- c(
  "pre_single_address_review_development_ids",
  "single_address_review_question_ids",
  "single_address_review_cluster_id",
  "single_address_review_action",
  "single_address_review_reason_codes",
  "single_address_review_shared_query_decision",
  "pre_identical_address_set_review_development_ids",
  "identical_address_set_review_question_ids",
  "identical_address_set_review_cluster_id",
  "identical_address_set_review_action",
  "identical_address_set_review_reason_codes",
  "identical_address_set_address_assessments",
  "identical_address_set_shared_query_decision",
  "pre_cross_address_round2_development_ids",
  "cross_address_round2_review_cluster_id",
  "cross_address_round2_identity_question_ids",
  "cross_address_round2_review_action",
  "cross_address_round2_review_reason_codes",
  "cross_address_round2_overlap_classes",
  "cross_address_round2_shared_query_decision",
  "pre_cross_address_review_development_ids",
  "cross_address_identity_question_id",
  "cross_address_review_decision",
  "cross_address_review_reason_code",
  "cross_address_overlap_class",
  "cross_address_shared_query_decision",
  "pre_name_review_development_ids",
  "linkage_review_decision",
  "linkage_review_reason_code",
  "name_variant_candidate_group_id",
  "name_variant_review_decision",
  "name_variant_review_reason_code"
)
if (!all(lineage_fields %chin% names(merged_members))) {
  stop("An upstream development-lineage field is missing.", call. = FALSE)
}
merged_summary <- merged_members[, c(
  list(
    pre_mixed_site_identity_development_ids = paste(
      sort(current_development_id),
      collapse = "|"
    ),
    mixed_site_identity_question_ids = collapse_delimited(
      mixed_site_identity_question_ids
    ),
    mixed_site_identity_reason_codes = collapse_delimited(
      mixed_site_identity_reason_codes
    )
  ),
  lapply(.SD, collapse_delimited)
), by = development_id, .SDcols = lineage_fields]

source_site_character_fields <- c(
  "source_site_review_scope",
  "source_site_development_scope_status",
  "source_site_exception_group_id",
  "source_site_group_decision",
  "source_site_inventory_status",
  "source_site_property_structure_status",
  "source_site_unresolved_status",
  "source_site_repair_status",
  "source_site_replacement_transaction_id",
  "source_site_geocoding_query_approval"
)
if (!all(c(
      source_site_character_fields,
      "source_site_requires_episode_property_bridge",
      "source_site_rows_removed",
      "source_site_rows_added",
      "source_site_unresolved_rows",
      "source_site_reviewed_on"
    ) %chin% names(merged_members))) {
  stop("An upstream source-site development field is missing.",
    call. = FALSE)
}
source_site_summary <- merged_members[, c(
  lapply(.SD, collapse_delimited),
  list(
    source_site_requires_episode_property_bridge = any(
      source_site_requires_episode_property_bridge,
      na.rm = TRUE
    ),
    source_site_rows_removed = sum(source_site_rows_removed, na.rm = TRUE),
    source_site_rows_added = sum(source_site_rows_added, na.rm = TRUE),
    source_site_unresolved_rows = sum(
      source_site_unresolved_rows,
      na.rm = TRUE
    ),
    source_site_reviewed_on = if (all(is.na(source_site_reviewed_on))) {
      as.Date(NA)
    } else {
      max(source_site_reviewed_on, na.rm = TRUE)
    }
  )
), by = development_id, .SDcols = source_site_character_fields]

episode_summary <- episode[
  development_id %chin% merged_development$development_id,
  .(
    n_project_episodes = .N,
    first_pis_year = if (all(is.na(pis_year))) {
      NA_integer_
    } else {
      min(pis_year, na.rm = TRUE)
    },
    last_pis_year = if (all(is.na(pis_year))) {
      NA_integer_
    } else {
      max(pis_year, na.rm = TRUE)
    },
    any_resyndication_reported = any(resyndication_cd == "1", na.rm = TRUE),
    construction_type_codes = paste(
      sort(unique(type[!is.na(type)])),
      collapse = "|"
    ),
    episode_unit_count_max = if (all(is.na(episode_units))) {
      NA_real_
    } else {
      max(episode_units, na.rm = TRUE)
    }
  ),
  by = development_id
]
if (nrow(episode_summary) != 81L) {
  stop("A merged physical development lacks its episode summary.",
    call. = FALSE)
}

merged_fields <- setdiff(names(merged_summary), "development_id")
merged_development[merged_summary,
  (merged_fields) := mget(paste0("i.", merged_fields)),
  on = "development_id"]
source_site_fields <- setdiff(names(source_site_summary), "development_id")
merged_development[source_site_summary,
  (source_site_fields) := mget(paste0("i.", source_site_fields)),
  on = "development_id"]
merged_development[episode_summary, `:=`(
  n_project_episodes = i.n_project_episodes,
  first_pis_year = i.first_pis_year,
  last_pis_year = i.last_pis_year,
  any_resyndication_reported = i.any_resyndication_reported,
  construction_type_codes = i.construction_type_codes,
  episode_unit_count_max = i.episode_unit_count_max
), on = "development_id"]
merged_development[, `:=`(
  episode_unit_count_sum = NA_real_,
  unit_aggregation_status = "requires_review",
  unit_aggregation_rule = "mixed_site_identity_merge_requires_unit_review",
  n_units_development = NA_real_,
  li_units_development = NA_real_,
  candidate_n_units_development = NA_real_,
  candidate_li_units_development = NA_real_
)]

development <- rbindlist(list(
  development[mixed_site_identity_action != "merge_to_review_cluster"],
  merged_development
), use.names = TRUE)
development[, mixed_site_development_scope_status :=
  source_site_development_scope_status]
development[
  mixed_site_identity_action == "retain_for_episode_to_property_bridge",
  mixed_site_development_scope_status :=
    "nonphysical_financing_umbrella_requires_bridge"
]

site <- copy(site_input)
site[, pre_mixed_site_identity_development_id := development_id]
site[physical_members, development_id := i.adjudicated_development_id,
  on = c(pre_mixed_site_identity_development_id = "development_id")]
expected_site_keys <- unique(site[, .(development_id, site_key)])

setorder(
  site,
  development_id,
  site_key,
  -n_project_episodes,
  development_site_id
)
site[, duplicate_adjudicated_site_key := .N > 1L,
  by = .(development_id, site_key)]
singleton_sites <- site[duplicate_adjudicated_site_key == FALSE]
duplicate_sites <- site[duplicate_adjudicated_site_key == TRUE]
singleton_sites[, duplicate_adjudicated_site_key := NULL]
duplicate_sites[, duplicate_adjudicated_site_key := NULL]

duplicate_sites <- duplicate_sites[, {
  group <- .SD
  row <- group[1L]
  hud_id_values <- collapse_delimited(group$hud_ids)
  hud_id_tokens <- trimws(unlist(strsplit(
    hud_id_values,
    "|",
    fixed = TRUE
  )))
  coordinate_pairs <- unique(data.table(
    latitude = group$latitude[
      !is.na(group$latitude) & !is.na(group$longitude)
    ],
    longitude = group$longitude[
      !is.na(group$latitude) & !is.na(group$longitude)
    ]
  ))
  row[, `:=`(
    pre_mixed_site_identity_development_id = paste(
      sort(unique(group$pre_mixed_site_identity_development_id)),
      collapse = "|"
    ),
    site_street = first_text(group$site_street),
    site_city = first_text(group$site_city),
    site_state = first_text(group$site_state),
    site_zip = first_text(group$site_zip),
    site_source = paste(sort(unique(group$site_source)), collapse = "+"),
    n_project_episodes = uniqueN(hud_id_tokens[hud_id_tokens != ""]),
    hud_ids = hud_id_values,
    n_bin_values = max(group$n_bin_values, na.rm = TRUE),
    bin_example = first_text(group$bin_example),
    n_coordinate_pairs = nrow(coordinate_pairs),
    latitude = if (nrow(coordinate_pairs) == 1L) {
      coordinate_pairs$latitude[1L]
    } else {
      NA_real_
    },
    longitude = if (nrow(coordinate_pairs) == 1L) {
      coordinate_pairs$longitude[1L]
    } else {
      NA_real_
    },
    requires_site_review = any(group$requires_site_review)
  )]
  row[, `:=`(
    source_site_review_scope = collapse_delimited(
      group$source_site_review_scope
    ),
    source_site_exception_group_id = collapse_delimited(
      group$source_site_exception_group_id
    ),
    source_site_group_decision = collapse_delimited(
      group$source_site_group_decision
    ),
    source_site_operative_action = collapse_delimited(
      group$source_site_operative_action
    ),
    source_site_decision_status = collapse_delimited(
      group$source_site_decision_status
    ),
    source_site_inventory_status = collapse_delimited(
      group$source_site_inventory_status
    ),
    source_site_property_structure_status = collapse_delimited(
      group$source_site_property_structure_status
    ),
    source_site_unresolved_status = collapse_delimited(
      group$source_site_unresolved_status
    ),
    source_site_requires_episode_property_bridge = any(
      group$source_site_requires_episode_property_bridge,
      na.rm = TRUE
    ),
    source_site_replacement_transaction_id = collapse_delimited(
      group$source_site_replacement_transaction_id
    ),
    source_site_reviewed_on = if (all(is.na(group$source_site_reviewed_on))) {
      as.Date(NA)
    } else {
      max(group$source_site_reviewed_on, na.rm = TRUE)
    },
    source_site_geocoding_query_approval = collapse_delimited(
      group$source_site_geocoding_query_approval
    ),
    source_site_application_status = collapse_delimited(
      group$source_site_application_status
    ),
    source_site_row_origin = collapse_delimited(group$source_site_row_origin)
  )]
  row
}, by = .(development_id, site_key)]
site <- rbindlist(list(singleton_sites, duplicate_sites), use.names = TRUE)
setorder(site, development_id, site_key)
site[, site_number := seq_len(.N), by = development_id]
site[, development_site_id := paste0(
  development_id,
  "_SITE_",
  sprintf("%04d", site_number)
)]
site[, mixed_site_development_scope_status :=
  development$mixed_site_development_scope_status[
    match(development_id, development$development_id)
  ]]
episode[, mixed_site_development_scope_status :=
  development$mixed_site_development_scope_status[
    match(development_id, development$development_id)
  ]]
if (anyNA(site$mixed_site_development_scope_status) ||
    anyNA(episode$mixed_site_development_scope_status)) {
  stop("A site or episode lacks its final development-scope status.",
    call. = FALSE)
}

observed_site_keys <- site[, .(development_id, site_key)]
setorder(expected_site_keys, development_id, site_key)
setorder(observed_site_keys, development_id, site_key)
if (!identical(expected_site_keys, observed_site_keys)) {
  stop("A source-repaired site key was lost or invented.", call. = FALSE)
}

site_summary <- site[, .(
  n_development_sites = .N,
  n_sites_with_hud_coordinates = sum(!is.na(latitude) & !is.na(longitude)),
  n_sites_requiring_review = sum(requires_site_review)
), by = development_id]
development[, `:=`(
  n_development_sites = 0L,
  n_sites_with_hud_coordinates = 0L,
  n_sites_requiring_review = 0L
)]
development[site_summary, `:=`(
  n_development_sites = i.n_development_sites,
  n_sites_with_hud_coordinates = i.n_sites_with_hud_coordinates,
  n_sites_requiring_review = i.n_sites_requiring_review
), on = "development_id"]

development[, current_development_id := NULL]
episode[, anchor_sort_year := NULL]
setorder(development, development_id)
setorder(episode, development_id, episode_number, hud_id)
setorder(site, development_id, site_number, site_key)

development_front <- c(
  "development_id", "pre_mixed_site_identity_development_ids",
  "mixed_site_identity_question_ids", "mixed_site_identity_cluster_id",
  "mixed_site_identity_decision", "mixed_site_identity_action",
  "mixed_site_identity_reason_codes", "mixed_site_identity_cluster_status",
  "mixed_site_identity_reviewed_on",
  "mixed_site_identity_shared_query_decision",
  "mixed_site_episode_to_property_bridge_status",
  "mixed_site_development_scope_status"
)
episode_front <- c(
  "development_id", "pre_mixed_site_identity_development_id",
  "mixed_site_identity_question_id", "mixed_site_identity_cluster_id",
  "mixed_site_identity_decision", "mixed_site_identity_action",
  "mixed_site_identity_reason_code", "mixed_site_identity_cluster_status",
  "mixed_site_identity_reviewed_on",
  "mixed_site_identity_shared_query_decision",
  "mixed_site_episode_to_property_bridge_status",
  "mixed_site_development_scope_status"
)
site_front <- c(
  "development_site_id", "development_id",
  "pre_mixed_site_identity_development_id",
  "mixed_site_development_scope_status", "site_number", "site_key"
)
setcolorder(development, c(
  development_front,
  setdiff(names(development), development_front)
))
setcolorder(episode, c(episode_front, setdiff(names(episode), episode_front)))
setcolorder(site, c(site_front, setdiff(names(site), site_front)))

application_checks <- c(
  development_row_count = nrow(development) == nrow(development_input) - 90L,
  development_key_unique = uniqueN(development$development_id) ==
    nrow(development),
  episode_row_count = nrow(episode) == nrow(episode_input),
  episode_key_unique = uniqueN(episode$hud_id) == nrow(episode),
  site_row_count = nrow(site) == nrow(expected_site_keys),
  site_id_unique = uniqueN(site$development_site_id) == nrow(site),
  site_key_unique = uniqueN(
    site,
    by = c("development_id", "site_key")
  ) == nrow(site),
  episode_referential_integrity = all(
    episode$development_id %chin% development$development_id
  ),
  site_referential_integrity = all(
    site$development_id %chin% development$development_id
  ),
  merged_physical_cluster_count = development[
    mixed_site_identity_action == "merge_to_review_cluster",
    .N
  ] == 81L,
  retained_physical_cluster_count = development[
    mixed_site_identity_action == "retain_current_development",
    .N
  ] == 23L,
  nonphysical_umbrella_count = development[
    mixed_site_identity_action ==
      "retain_for_episode_to_property_bridge",
    .N
  ] == 1L,
  merged_units_not_inferred = !development[
    mixed_site_identity_action == "merge_to_review_cluster",
    any(!is.na(n_units_development) | !is.na(li_units_development) |
      !is.na(episode_unit_count_sum))
  ],
  nonphysical_cluster_status_count = development[
    mixed_site_identity_cluster_status ==
      "nonphysical_financing_umbrella_requires_bridge",
    .N
  ] == 1L,
  source_financing_umbrella_count = development[
    source_site_development_scope_status ==
      "nonphysical_financing_umbrella_requires_bridge" &
      mixed_site_identity_action !=
        "retain_for_episode_to_property_bridge",
    .N
  ] == 2L,
  source_portfolio_placeholder_count = development[
    source_site_development_scope_status ==
      "nonphysical_portfolio_placeholder_requires_sites_and_bridge",
    .N
  ] == 10L,
  final_financing_umbrella_scope_count = development[
    mixed_site_development_scope_status ==
      "nonphysical_financing_umbrella_requires_bridge",
    .N
  ] == 3L,
  all_nonphysical_development_count = development[
    startsWith(mixed_site_development_scope_status, "nonphysical_"),
    .N
  ] == 13L,
  physical_development_count = development[
    !startsWith(mixed_site_development_scope_status, "nonphysical_"),
    .N
  ] == 53927L,
  no_reviewed_query_approved = !episode[
    mixed_site_identity_action != "not_applicable",
    any(mixed_site_identity_shared_query_decision != "not_approved")
  ]
)
if (any(!application_checks)) {
  stop(
    "Mixed-site application checks failed: ",
    paste(names(application_checks)[!application_checks], collapse = ", "),
    ".",
    call. = FALSE
  )
}

write_parquet(
  development,
  "../output/lihtc_development_2024_mixed_site_identity_adjudicated.parquet",
  compression = "zstd"
)
write_parquet(
  episode,
  "../output/lihtc_project_episode_2024_mixed_site_identity_adjudicated.parquet",
  compression = "zstd"
)
write_parquet(
  site,
  "../output/lihtc_development_site_2024_mixed_site_identity_adjudicated.parquet",
  compression = "zstd"
)

development_round_trip <- as.data.table(read_parquet(
  "../output/lihtc_development_2024_mixed_site_identity_adjudicated.parquet"
))
episode_round_trip <- as.data.table(read_parquet(
  "../output/lihtc_project_episode_2024_mixed_site_identity_adjudicated.parquet"
))
site_round_trip <- as.data.table(read_parquet(
  "../output/lihtc_development_site_2024_mixed_site_identity_adjudicated.parquet"
))
if (!isTRUE(all.equal(development, development_round_trip)) ||
    !isTRUE(all.equal(episode, episode_round_trip)) ||
    !isTRUE(all.equal(site, site_round_trip))) {
  stop("An applied mixed-site Parquet changed on round trip.", call. = FALSE)
}

cat(
  "Applied 87 mixed-site questions to build ",
  format(nrow(development), big.mark = ","),
  " rows containing 104 reviewed physical developments and one nonphysical ",
  "umbrella bridge case; all project episodes were preserved.\n",
  sep = ""
)
