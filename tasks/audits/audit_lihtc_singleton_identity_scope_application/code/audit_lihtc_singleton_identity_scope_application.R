# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/audit_lihtc_singleton_identity_scope_application/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
  library(stringr)
})

normalize_text <- function(value) {
  value <- iconv(value, from = "", to = "ASCII//TRANSLIT", sub = "")
  value <- str_to_upper(str_squish(value))
  value <- str_replace_all(value, "[^A-Z0-9]+", " ")
  value <- str_squish(value)
  value[value == ""] <- NA_character_
  value
}

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

collapse_plus <- function(value) {
  tokens <- trimws(unlist(strsplit(
    value[!is.na(value) & value != ""],
    "+",
    fixed = TRUE
  )))
  tokens <- sort(unique(tokens[tokens != ""]))
  if (length(tokens) == 0L) NA_character_ else paste(tokens, collapse = "+")
}

development_before <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_mixed_site_identity_adjudicated.parquet"
))
episode_before <- as.data.table(read_parquet(
  "../input/lihtc_project_episode_2024_mixed_site_identity_adjudicated.parquet"
))
site_before <- as.data.table(read_parquet(
  "../input/lihtc_development_site_2024_mixed_site_identity_adjudicated.parquet"
))
development_after <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_singleton_identity_scope_adjudicated.parquet"
))
episode_after <- as.data.table(read_parquet(
  "../input/lihtc_project_episode_2024_singleton_identity_scope_adjudicated.parquet"
))
site_after <- as.data.table(read_parquet(
  "../input/lihtc_development_site_2024_singleton_identity_scope_adjudicated.parquet"
))
reviews <- as.data.table(read_parquet(
  "../input/lihtc_singleton_identity_scope_question_reviews.parquet"
))
members <- as.data.table(read_parquet(
  "../input/lihtc_singleton_identity_scope_member_partitions.parquet"
))
site_decisions <- as.data.table(read_parquet(
  "../input/lihtc_singleton_identity_scope_site_decisions.parquet"
))
site_additions <- as.data.table(read_parquet(
  "../input/lihtc_singleton_identity_scope_site_additions.parquet"
))

drop_actions <- c(
  "drop_wrong_source_site",
  "drop_malformed_redundant_variant",
  "drop_historical_redundant_address_alias"
)
site_review_actions <- rbindlist(list(
  site_decisions[, .(
    adjudicated_development_id,
    site_action
  )],
  site_additions[, .(
    adjudicated_development_id = development_id,
    site_action
  )]
))
expected_development_rows <- nrow(development_before) -
  (nrow(members) - uniqueN(members$adjudicated_development_id))

if (nrow(development_before) != 53940L ||
    nrow(episode_before) != 55345L ||
    nrow(site_before) != 132559L ||
    expected_development_rows != 53909L ||
    nrow(development_after) != 53909L ||
    nrow(episode_after) != nrow(episode_before) ||
    nrow(site_after) != 132513L ||
    uniqueN(development_after$development_id) != nrow(development_after) ||
    uniqueN(episode_after$hud_id) != nrow(episode_after) ||
    uniqueN(site_after$development_site_id) != nrow(site_after) ||
    uniqueN(site_after, by = c("development_id", "site_key")) !=
      nrow(site_after)) {
  stop("A singleton application count or key contract failed.",
    call. = FALSE)
}
if (nrow(reviews) != 56L || nrow(members) != 88L ||
    nrow(site_decisions) != 166L || nrow(site_additions) != 1L ||
    site_additions[
      site_addition_id != "SISR_SITE_ADD_0001" |
        singleton_identity_scope_review_id !=
          "SISR_TX_SAVANNAH_GATEWAY" |
        development_site_id != "DEV_TXA00000096_SITE_0001" |
        development_id != "DEV_TXA00000096" |
        site_action != "add_verified_physical_site" |
        site_decision_reason !=
          "official_state_property_record_supplies_missing_physical_site" |
        site_source_type != "official_state_housing_agency" |
        geocoding_query_approval != "not_approved",
      .N
    ] > 0L) {
  stop("The reviewed official site addition contract failed.",
    call. = FALSE)
}

expected_episode_assignment <- episode_before[, .(
  hud_id,
  expected_development_id = development_id,
  expected_anchor_hud_id = development_anchor_hud_id
)]
expected_episode_assignment[members[, .(
  current_development_id,
  adjudicated_development_id,
  adjudicated_anchor_hud_id
)], `:=`(
  expected_development_id = i.adjudicated_development_id,
  expected_anchor_hud_id = i.adjudicated_anchor_hud_id
), on = c(expected_development_id = "current_development_id")]
expected_episode_assignment[episode_after[, .(
  hud_id,
  observed_development_id = development_id,
  observed_anchor_hud_id = development_anchor_hud_id
)], `:=`(
  observed_development_id = i.observed_development_id,
  observed_anchor_hud_id = i.observed_anchor_hud_id
), on = "hud_id"]
if (anyNA(expected_episode_assignment[, .(
      observed_development_id,
      observed_anchor_hud_id
    )]) ||
    expected_episode_assignment[
      expected_development_id != observed_development_id |
        expected_anchor_hud_id != observed_anchor_hud_id,
      .N
    ] > 0L) {
  stop("An episode was lost or assigned to the wrong reviewed cluster.",
    call. = FALSE)
}

changed_episode_fields <- c(
  "development_id", "development_anchor_hud_id", "episode_number",
  "n_project_episodes", "is_development_anchor",
  "development_linkage_status", "development_linkage_basis",
  "requires_linkage_review"
)
immutable_episode_fields <- setdiff(
  intersect(names(episode_before), names(episode_after)),
  changed_episode_fields
)
setkey(episode_before, hud_id)
setkey(episode_after, hud_id)
if (!isTRUE(all.equal(
      episode_before[, ..immutable_episode_fields],
      episode_after[, ..immutable_episode_fields],
      check.attributes = TRUE
    ))) {
  stop("A source episode value changed outside authorized linkage fields.",
    call. = FALSE)
}

unreviewed_development_ids <- setdiff(
  development_before$development_id,
  members$current_development_id
)
upstream_development_fields <- intersect(
  names(development_before),
  names(development_after)
)
unreviewed_before <- development_before[
  development_id %chin% unreviewed_development_ids,
  ..upstream_development_fields
]
unreviewed_after <- development_after[
  development_id %chin% unreviewed_development_ids,
  ..upstream_development_fields
]
setorder(unreviewed_before, development_id)
setorder(unreviewed_after, development_id)
if (!isTRUE(all.equal(
      unreviewed_before,
      unreviewed_after,
      check.attributes = TRUE
    ))) {
  stop("An unreviewed development changed in an upstream field.",
    call. = FALSE)
}

expected_site_additions <- site_before[0L]
expected_site_additions <- rbindlist(list(
  expected_site_additions,
  site_additions[, .(
    development_site_id,
    development_id,
    pre_mixed_site_identity_development_id = development_id,
    mixed_site_development_scope_status = "not_in_review",
    site_number,
    site_key,
    site_street,
    site_city,
    site_state,
    site_zip,
    site_source,
    n_project_episodes,
    hud_ids,
    n_bin_values,
    bin_example,
    n_coordinate_pairs,
    latitude,
    longitude,
    requires_site_review,
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
    source_site_row_origin = "external_public_record"
  )]
), use.names = TRUE)
expected_sites <- rbindlist(list(site_before, expected_site_additions),
  use.names = TRUE)
expected_sites[, pre_singleton_identity_scope_development_id := development_id]
expected_sites[, `:=`(
  singleton_identity_scope_review_id = NA_character_,
  singleton_identity_scope_action = "not_applicable",
  singleton_identity_scope_reason_code = NA_character_,
  singleton_identity_scope_cluster_status = "not_reviewed",
  singleton_identity_scope_reviewed_on = as.Date(NA),
  singleton_identity_scope_geocoding_query_approval = "not_reviewed",
  singleton_identity_scope_episode_to_property_bridge_status =
    "not_required",
  singleton_identity_scope_reviewed_scope_status = NA_character_,
  singleton_identity_scope_site_action = "not_applicable",
  singleton_identity_scope_site_decision_reason = NA_character_,
  singleton_identity_scope_site_source_title = NA_character_,
  singleton_identity_scope_site_source_type = NA_character_,
  singleton_identity_scope_site_source_url = NA_character_,
  singleton_identity_scope_site_source_statement = NA_character_
)]
expected_sites[members, `:=`(
  singleton_identity_scope_review_id = i.singleton_identity_scope_review_id,
  singleton_identity_scope_action = i.member_action,
  singleton_identity_scope_reason_code = i.final_reason_code,
  singleton_identity_scope_cluster_status = i.cluster_status,
  singleton_identity_scope_reviewed_on = as.Date(i.reviewed_on),
  singleton_identity_scope_geocoding_query_approval =
    i.geocoding_query_approval,
  singleton_identity_scope_episode_to_property_bridge_status =
    i.episode_to_property_bridge_status,
  singleton_identity_scope_reviewed_scope_status = i.final_scope_status
), on = c(
  pre_singleton_identity_scope_development_id = "current_development_id"
)]
expected_sites[site_decisions, `:=`(
  singleton_identity_scope_site_action = i.site_action,
  singleton_identity_scope_site_decision_reason = i.site_decision_reason,
  singleton_identity_scope_site_source_title = i.site_source_title,
  singleton_identity_scope_site_source_type = i.site_source_type,
  singleton_identity_scope_site_source_url = i.site_source_url,
  singleton_identity_scope_site_source_statement = i.site_source_statement,
  development_id = i.adjudicated_development_id
), on = c(development_site_id = "current_development_site_id")]
expected_sites[site_additions, `:=`(
  singleton_identity_scope_site_action = i.site_action,
  singleton_identity_scope_site_decision_reason = i.site_decision_reason,
  singleton_identity_scope_site_source_title = i.site_source_title,
  singleton_identity_scope_site_source_type = i.site_source_type,
  singleton_identity_scope_site_source_url = i.site_source_url,
  singleton_identity_scope_site_source_statement = i.site_source_statement,
  development_id = i.development_id
), on = c(development_site_id = "development_site_id")]
expected_sites[, adjudicated_site_key := paste(
  development_id,
  site_key,
  sep = "\r"
)]
retained_site_keys <- unique(expected_sites[
  !singleton_identity_scope_site_action %chin% drop_actions,
  adjudicated_site_key
])
expected_sites[, include_in_site_lineage :=
  !singleton_identity_scope_site_action %chin% drop_actions |
    (singleton_identity_scope_site_action ==
      "drop_malformed_redundant_variant" &
      adjudicated_site_key %chin% retained_site_keys)]
expected_sites <- expected_sites[include_in_site_lineage == TRUE]
expected_sites[, c(
  "adjudicated_site_key",
  "include_in_site_lineage"
) := NULL]

expected_sites[, duplicate_adjudicated_site_key := .N > 1L,
  by = .(development_id, site_key)]
expected_singleton_sites <- expected_sites[
  duplicate_adjudicated_site_key == FALSE
]
expected_duplicate_sites <- expected_sites[
  duplicate_adjudicated_site_key == TRUE
]
expected_singleton_sites[, duplicate_adjudicated_site_key := NULL]
expected_duplicate_sites[, duplicate_adjudicated_site_key := NULL]
expected_duplicate_sites[, site_drop_sort :=
  singleton_identity_scope_site_action %chin% drop_actions]
setorder(
  expected_duplicate_sites,
  development_id,
  site_key,
  site_drop_sort,
  -n_project_episodes,
  development_site_id
)
expected_duplicate_sites <- expected_duplicate_sites[, {
  group <- copy(.SD)
  group[, site_drop_sort := NULL]
  retained_group <- group[
    !singleton_identity_scope_site_action %chin% drop_actions
  ]
  row <- retained_group[1L]
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
    pre_singleton_identity_scope_development_id = collapse_delimited(
      group$pre_singleton_identity_scope_development_id
    ),
    pre_mixed_site_identity_development_id = collapse_delimited(
      group$pre_mixed_site_identity_development_id
    ),
    site_street = first_text(retained_group$site_street),
    site_city = first_text(retained_group$site_city),
    site_state = first_text(retained_group$site_state),
    site_zip = first_text(retained_group$site_zip),
    site_source = collapse_plus(group$site_source),
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
  source_site_text_fields <- c(
    "source_site_review_scope", "source_site_exception_group_id",
    "source_site_group_decision", "source_site_operative_action",
    "source_site_decision_status", "source_site_inventory_status",
    "source_site_property_structure_status",
    "source_site_development_scope_status", "source_site_unresolved_status",
    "source_site_replacement_transaction_id",
    "source_site_geocoding_query_approval",
    "source_site_application_status", "source_site_row_origin"
  )
  row[, (source_site_text_fields) := lapply(
    group[, source_site_text_fields, with = FALSE],
    collapse_delimited
  )]
  row[, `:=`(
    source_site_requires_episode_property_bridge = any(
      group$source_site_requires_episode_property_bridge,
      na.rm = TRUE
    ),
    source_site_reviewed_on = if (all(is.na(group$source_site_reviewed_on))) {
      as.Date(NA)
    } else {
      max(group$source_site_reviewed_on, na.rm = TRUE)
    },
    singleton_identity_scope_review_id = collapse_delimited(
      retained_group$singleton_identity_scope_review_id
    ),
    singleton_identity_scope_action = collapse_delimited(
      retained_group$singleton_identity_scope_action
    ),
    singleton_identity_scope_reason_code = collapse_delimited(
      retained_group$singleton_identity_scope_reason_code
    ),
    singleton_identity_scope_cluster_status = collapse_delimited(
      retained_group$singleton_identity_scope_cluster_status
    ),
    singleton_identity_scope_reviewed_on = max(
      retained_group$singleton_identity_scope_reviewed_on,
      na.rm = TRUE
    ),
    singleton_identity_scope_geocoding_query_approval = collapse_delimited(
      retained_group$singleton_identity_scope_geocoding_query_approval
    ),
    singleton_identity_scope_episode_to_property_bridge_status =
      collapse_delimited(
        retained_group$
          singleton_identity_scope_episode_to_property_bridge_status
      ),
    singleton_identity_scope_reviewed_scope_status = collapse_delimited(
      retained_group$singleton_identity_scope_reviewed_scope_status
    ),
    singleton_identity_scope_site_action = if (
      any(retained_group$singleton_identity_scope_site_action ==
        "retain_unresolved_source_site_for_review")
    ) {
      "retain_unresolved_source_site_for_review"
    } else {
      first_text(retained_group$singleton_identity_scope_site_action)
    },
    singleton_identity_scope_site_decision_reason = collapse_delimited(
      retained_group$singleton_identity_scope_site_decision_reason
    ),
    singleton_identity_scope_site_source_title = collapse_delimited(
      retained_group$singleton_identity_scope_site_source_title
    ),
    singleton_identity_scope_site_source_type = collapse_delimited(
      retained_group$singleton_identity_scope_site_source_type
    ),
    singleton_identity_scope_site_source_url = collapse_delimited(
      retained_group$singleton_identity_scope_site_source_url
    ),
    singleton_identity_scope_site_source_statement = collapse_delimited(
      retained_group$singleton_identity_scope_site_source_statement
    )
  )]
  row
}, by = .(development_id, site_key)]
expected_sites <- rbindlist(list(
  expected_singleton_sites,
  expected_duplicate_sites
), use.names = TRUE)
expected_sites[
  singleton_identity_scope_site_action %chin% c(
    "retain_unresolved_source_site_for_review",
    "keep_nonphysical_bridge_site"
  ),
  requires_site_review := TRUE
]
expected_scope <- development_before[, .(
  development_id,
  expected_scope_status = mixed_site_development_scope_status
)]
expected_scope[unique(members[, .(
  development_id = adjudicated_development_id,
  final_scope_status
)]), expected_scope_status := i.final_scope_status,
on = "development_id"]
setorder(expected_sites, development_id, site_key)
expected_sites[, site_number := seq_len(.N), by = development_id]
expected_sites[, development_site_id := paste0(
  development_id,
  "_SITE_",
  sprintf("%04d", site_number)
)]
expected_sites[, singleton_identity_development_scope_status :=
  expected_scope$expected_scope_status[
    match(development_id, expected_scope$development_id)
  ]]
setcolorder(expected_sites, names(site_after))
setorder(expected_sites, development_id, site_number)
setorder(site_after, development_id, site_number)
if (!isTRUE(all.equal(
      expected_sites,
      site_after,
      check.attributes = TRUE
    ))) {
  stop("The final site rows differ from the independently rebuilt lineage.",
    call. = FALSE)
}
if (site_after[
      singleton_identity_scope_site_action %chin% c(
        "retain_unresolved_source_site_for_review",
        "keep_nonphysical_bridge_site"
      ) & !requires_site_review,
      .N
    ] > 0L) {
  stop("An unresolved or nonphysical retained site is marked review-ready.",
    call. = FALSE)
}

reviewed_target_site_summary <- unique(members[, .(
  development_id = adjudicated_development_id
)])
reviewed_target_site_summary[, `:=`(
  n_development_sites = 0L,
  n_sites_with_hud_coordinates = 0L,
  n_sites_requiring_review = 0L,
  singleton_identity_scope_site_rows_reviewed = 0L,
  singleton_identity_scope_site_rows_retained = 0L,
  singleton_identity_scope_site_rows_removed = 0L,
  singleton_identity_scope_site_rows_unresolved = 0L
)]
reviewed_target_site_summary[expected_sites[, .(
  n_development_sites = .N,
  n_sites_with_hud_coordinates = sum(!is.na(latitude) & !is.na(longitude)),
  n_sites_requiring_review = sum(requires_site_review)
), by = development_id], `:=`(
  n_development_sites = i.n_development_sites,
  n_sites_with_hud_coordinates = i.n_sites_with_hud_coordinates,
  n_sites_requiring_review = i.n_sites_requiring_review
), on = "development_id"]
reviewed_target_site_summary[site_review_actions[, .(
  singleton_identity_scope_site_rows_reviewed = .N,
  singleton_identity_scope_site_rows_retained = sum(
    !site_action %chin% drop_actions
  ),
  singleton_identity_scope_site_rows_removed = sum(
    site_action %chin% drop_actions
  ),
  singleton_identity_scope_site_rows_unresolved = sum(
    site_action == "retain_unresolved_source_site_for_review"
  )
), by = .(development_id = adjudicated_development_id)], `:=`(
  singleton_identity_scope_site_rows_reviewed =
    i.singleton_identity_scope_site_rows_reviewed,
  singleton_identity_scope_site_rows_retained =
    i.singleton_identity_scope_site_rows_retained,
  singleton_identity_scope_site_rows_removed =
    i.singleton_identity_scope_site_rows_removed,
  singleton_identity_scope_site_rows_unresolved =
    i.singleton_identity_scope_site_rows_unresolved
), on = "development_id"]
observed_reviewed_target_site_summary <- development_after[
  development_id %chin% reviewed_target_site_summary$development_id,
  names(reviewed_target_site_summary),
  with = FALSE
]
setorder(reviewed_target_site_summary, development_id)
setorder(observed_reviewed_target_site_summary, development_id)
if (!identical(
      reviewed_target_site_summary,
      observed_reviewed_target_site_summary
    )) {
  stop("A reviewed development site summary was not rebuilt exactly.",
    call. = FALSE)
}

unreviewed_site_before <- site_before[
  !development_id %chin% members$current_development_id,
  .(development_id, site_key, development_site_id, site_number)
]
unreviewed_site_after <- site_after[
  singleton_identity_scope_site_action == "not_applicable",
  .(development_id, site_key, development_site_id, site_number)
]
setorder(unreviewed_site_before, development_id, site_key)
setorder(unreviewed_site_after, development_id, site_key)
if (!identical(unreviewed_site_before, unreviewed_site_after)) {
  stop("An unreviewed site identifier or site number changed.",
    call. = FALSE)
}

name_contract <- unique(members[, .(
  development_id = adjudicated_development_id,
  expected_development_name = reviewed_development_name,
  expected_development_name_key = normalize_text(reviewed_development_name),
  expected_name_reason = development_name_correction_reason,
  expected_name_source = development_name_correction_source
)])
name_contract[development_after[, .(
  development_id,
  observed_development_name = development_name,
  observed_development_name_key = development_name_key,
  observed_name_reason = development_name_correction_reason,
  observed_name_source = development_name_correction_source
)], `:=`(
  observed_development_name = i.observed_development_name,
  observed_development_name_key = i.observed_development_name_key,
  observed_name_reason = i.observed_name_reason,
  observed_name_source = i.observed_name_source
), on = "development_id"]
if (anyNA(name_contract$observed_development_name) ||
    name_contract[
      expected_development_name != observed_development_name |
        expected_development_name_key != observed_development_name_key |
        fifelse(is.na(expected_name_reason), "<MISSING>",
          expected_name_reason) !=
          fifelse(is.na(observed_name_reason), "<MISSING>",
            observed_name_reason) |
        fifelse(is.na(expected_name_source), "<MISSING>",
          expected_name_source) !=
          fifelse(is.na(observed_name_source), "<MISSING>",
            observed_name_source),
      .N
    ] > 0L) {
  stop("A reviewed development name or provenance was not applied exactly.",
    call. = FALSE)
}

expected_reviewed_development_linkage <- members[
  current_development_id == adjudicated_development_id,
  .(
    development_id = adjudicated_development_id,
    expected_linkage_status = fcase(
      cluster_status == "final_physical_development",
        "singleton_identity_scope_reviewed_physical",
      cluster_status == "nonphysical_financing_portfolio_requires_bridge",
        "nonphysical_financing_portfolio_requires_property_bridge",
      cluster_status ==
        "nonphysical_unresolved_bad_source_identity_requires_recovery",
        "nonphysical_unresolved_bad_source_identity_requires_recovery",
      cluster_status == "nonphysical_invalid_synthetic_test_source_row",
        "nonphysical_invalid_synthetic_test_source_row"
    ),
    expected_requires_review = cluster_status %chin% c(
      "nonphysical_financing_portfolio_requires_bridge",
      "nonphysical_unresolved_bad_source_identity_requires_recovery"
    )
  )
]
expected_reviewed_development_linkage[development_after[, .(
  development_id,
  observed_linkage_status = development_linkage_status,
  observed_requires_review = requires_linkage_review
)], `:=`(
  observed_linkage_status = i.observed_linkage_status,
  observed_requires_review = i.observed_requires_review
), on = "development_id"]
if (anyNA(expected_reviewed_development_linkage[, .(
      expected_linkage_status,
      observed_linkage_status,
      observed_requires_review
    )]) ||
    expected_reviewed_development_linkage[
      expected_linkage_status != observed_linkage_status |
        expected_requires_review != observed_requires_review,
      .N
    ] > 0L) {
  stop("A reviewed development received the wrong linkage status.",
    call. = FALSE)
}

expected_reviewed_episode_linkage <- episode_before[
  development_id %chin% members$current_development_id,
  .(hud_id, current_development_id = development_id)
]
expected_reviewed_episode_linkage[members[, .(
  current_development_id,
  member_action,
  cluster_status
)], `:=`(
  member_action = i.member_action,
  cluster_status = i.cluster_status
), on = "current_development_id"]
expected_reviewed_episode_linkage[, `:=`(
  expected_linkage_status = fcase(
    member_action == "merge_to_review_cluster",
      "singleton_identity_scope_adjudicated_linked",
    member_action == "retain_physical_development",
      "singleton_identity_scope_reviewed_physical",
    cluster_status == "nonphysical_financing_portfolio_requires_bridge",
      "nonphysical_financing_portfolio_requires_property_bridge",
    cluster_status ==
      "nonphysical_unresolved_bad_source_identity_requires_recovery",
      "nonphysical_unresolved_bad_source_identity_requires_recovery",
    cluster_status == "nonphysical_invalid_synthetic_test_source_row",
      "nonphysical_invalid_synthetic_test_source_row"
  ),
  expected_requires_review = cluster_status %chin% c(
    "nonphysical_financing_portfolio_requires_bridge",
    "nonphysical_unresolved_bad_source_identity_requires_recovery"
  )
)]
expected_reviewed_episode_linkage[episode_after[, .(
  hud_id,
  observed_linkage_status = development_linkage_status,
  observed_requires_review = requires_linkage_review
)], `:=`(
  observed_linkage_status = i.observed_linkage_status,
  observed_requires_review = i.observed_requires_review
), on = "hud_id"]
if (anyNA(expected_reviewed_episode_linkage[, .(
      expected_linkage_status,
      observed_linkage_status,
      observed_requires_review
    )]) ||
    expected_reviewed_episode_linkage[
      expected_linkage_status != observed_linkage_status |
        expected_requires_review != observed_requires_review,
      .N
    ] > 0L) {
  stop("A reviewed episode received the wrong linkage status.",
    call. = FALSE)
}

merged_ids <- members[
  member_action %chin% c(
    "merge_to_review_cluster",
    "merge_to_nonphysical_episode_bridge"
  ),
  unique(adjudicated_development_id)
]

upstream_lineage_fields <- c(
  "pre_mixed_site_identity_development_ids",
  "mixed_site_identity_question_ids",
  "mixed_site_identity_reason_codes",
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
authorized_merged_upstream_fields <- c(
  "development_name", "development_name_key", "development_city",
  "development_anchor_hud_id", "development_linkage_status",
  "development_linkage_basis", "requires_linkage_review",
  "n_project_episodes", "first_pis_year", "last_pis_year",
  "any_resyndication_reported", "construction_type_codes",
  "episode_unit_count_max", "episode_unit_count_sum",
  "unit_aggregation_status", "unit_aggregation_rule",
  "n_units_development", "li_units_development",
  "candidate_n_units_development", "candidate_li_units_development",
  "n_development_sites", "n_sites_with_hud_coordinates",
  "n_sites_requiring_review", upstream_lineage_fields,
  source_site_character_fields,
  "source_site_requires_episode_property_bridge",
  "source_site_rows_removed", "source_site_rows_added",
  "source_site_unresolved_rows", "source_site_reviewed_on"
)
immutable_merged_fields <- setdiff(
  intersect(names(development_before), names(development_after)),
  authorized_merged_upstream_fields
)
merged_anchor_before <- development_before[
  development_id %chin% merged_ids,
  ..immutable_merged_fields
]
merged_anchor_after <- development_after[
  development_id %chin% merged_ids,
  ..immutable_merged_fields
]
setorder(merged_anchor_before, development_id)
setorder(merged_anchor_after, development_id)
if (!isTRUE(all.equal(
      merged_anchor_before,
      merged_anchor_after,
      check.attributes = TRUE
    ))) {
  stop("A merged anchor changed outside authorized development fields.",
    call. = FALSE)
}

merged_member_map <- members[
  adjudicated_development_id %chin% merged_ids,
  .(current_development_id, adjudicated_development_id)
]
merged_source <- copy(development_before[
  development_id %chin% merged_member_map$current_development_id
])
setnames(merged_source, "development_id", "current_development_id")
merged_source[merged_member_map,
  development_id := i.adjudicated_development_id,
  on = "current_development_id"]
merged_source[members[, .(
  current_development_id,
  singleton_identity_scope_review_id,
  final_reason_code
)], `:=`(
  singleton_identity_scope_review_id =
    i.singleton_identity_scope_review_id,
  final_reason_code = i.final_reason_code
), on = "current_development_id"]
expected_merged_lineage <- merged_source[, c(
  list(
    pre_singleton_identity_scope_development_ids = paste(
      sort(current_development_id),
      collapse = "|"
    ),
    pre_singleton_identity_scope_development_names = paste(
      sort(unique(development_name)),
      collapse = "|"
    ),
    singleton_identity_scope_review_ids = collapse_delimited(
      singleton_identity_scope_review_id
    ),
    singleton_identity_scope_reason_codes = collapse_delimited(
      final_reason_code
    )
  ),
  lapply(.SD, collapse_delimited)
), by = development_id,
.SDcols = upstream_lineage_fields]
expected_source_site_summary <- merged_source[, c(
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

expected_episode_source <- copy(episode_before)
expected_episode_source[members[, .(
  current_development_id,
  adjudicated_development_id
)], development_id := i.adjudicated_development_id,
on = c(development_id = "current_development_id")]
expected_episode_summary <- expected_episode_source[
  development_id %chin% merged_ids,
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
expected_retained_site_summary <- expected_sites[
  development_id %chin% merged_ids,
  .(
    n_development_sites = .N,
    n_sites_with_hud_coordinates = sum(
      !is.na(latitude) & !is.na(longitude)
    ),
    n_sites_requiring_review = sum(requires_site_review)
  ),
  by = development_id
]
expected_reviewed_site_summary <- site_review_actions[
  adjudicated_development_id %chin% merged_ids,
  .(
    singleton_identity_scope_site_rows_reviewed = .N,
    singleton_identity_scope_site_rows_retained = sum(
      !site_action %chin% drop_actions
    ),
    singleton_identity_scope_site_rows_removed = sum(
      site_action %chin% drop_actions
    ),
    singleton_identity_scope_site_rows_unresolved = sum(
      site_action == "retain_unresolved_source_site_for_review"
    )
  ),
  by = .(development_id = adjudicated_development_id)
]

expected_merged_fields <- Reduce(
  function(left, right) merge(
    left,
    right,
    by = "development_id",
    all = TRUE,
    sort = FALSE
  ),
  list(
    expected_merged_lineage,
    expected_source_site_summary,
    expected_episode_summary,
    expected_retained_site_summary,
    expected_reviewed_site_summary
  )
)
expected_merged_fields[, `:=`(
  episode_unit_count_sum = NA_real_,
  unit_aggregation_status = "requires_review",
  unit_aggregation_rule =
    "singleton_identity_scope_requires_unit_review",
  n_units_development = NA_real_,
  li_units_development = NA_real_,
  candidate_n_units_development = NA_real_,
  candidate_li_units_development = NA_real_
)]
observed_merged_fields <- development_after[
  development_id %chin% merged_ids,
  names(expected_merged_fields),
  with = FALSE
]
setorder(expected_merged_fields, development_id)
setorder(observed_merged_fields, development_id)
if (!isTRUE(all.equal(
      expected_merged_fields,
      observed_merged_fields,
      check.attributes = TRUE
    ))) {
  stop("A merged development summary differs from its source reconstruction.",
    call. = FALSE)
}
if (development_after[
      development_id %chin% merged_ids,
      any(!is.na(n_units_development) | !is.na(li_units_development) |
        !is.na(episode_unit_count_sum) |
        unit_aggregation_status != "requires_review")
    ]) {
  stop("A newly merged cluster received an inferred unit count.",
    call. = FALSE)
}
unit_deferred_target_ids <- members[
  cluster_status == "final_physical_development" &
    grepl(
      "unit_aggregation_deferred|units_deferred",
      final_scope_status
    ),
  unique(adjudicated_development_id)
]
if (development_after[
      development_id %chin% unit_deferred_target_ids,
      any(!is.na(n_units_development) | !is.na(li_units_development) |
        !is.na(episode_unit_count_sum) |
        !is.na(candidate_n_units_development) |
        !is.na(candidate_li_units_development) |
        unit_aggregation_status != "requires_review" |
        unit_aggregation_rule !=
          "singleton_identity_scope_requires_unit_review")
    ] ||
    !"DEV_NJA20040125" %chin% unit_deferred_target_ids) {
  stop("A reviewed units-deferred physical target escaped unit review.",
    call. = FALSE)
}

development_scope <- development_after[, .(
  development_id,
  expected_scope_status = singleton_identity_development_scope_status
)]
episode_scope <- merge(
  episode_after[, .(
    development_id,
    observed_scope_status = singleton_identity_development_scope_status
  )],
  development_scope,
  by = "development_id",
  all.x = TRUE,
  sort = FALSE
)
site_scope <- merge(
  site_after[, .(
    development_id,
    observed_scope_status = singleton_identity_development_scope_status
  )],
  development_scope,
  by = "development_id",
  all.x = TRUE,
  sort = FALSE
)
if (anyNA(episode_scope$expected_scope_status) ||
    anyNA(site_scope$expected_scope_status) ||
    episode_scope[observed_scope_status != expected_scope_status, .N] > 0L ||
    site_scope[observed_scope_status != expected_scope_status, .N] > 0L) {
  stop("A final singleton scope status was not propagated exactly.",
    call. = FALSE)
}

reviewed_scope_contract <- unique(members[, .(
  development_id = adjudicated_development_id,
  expected_scope_status = final_scope_status
)])
reviewed_scope_contract[development_after[, .(
  development_id,
  observed_scope_status = singleton_identity_development_scope_status
)], observed_scope_status := i.observed_scope_status, on = "development_id"]
if (anyNA(reviewed_scope_contract$observed_scope_status) ||
    reviewed_scope_contract[
      expected_scope_status != observed_scope_status,
      .N
    ] > 0L) {
  stop("A reviewed physical or nonphysical status changed during apply.",
    call. = FALSE)
}

if (development_after[
      startsWith(singleton_identity_development_scope_status,
        "nonphysical_"),
      .N
    ] != 23L ||
    development_after[
      !startsWith(singleton_identity_development_scope_status,
        "nonphysical_"),
      .N
    ] != 53886L) {
  stop("The final physical/nonphysical development counts changed.",
    call. = FALSE)
}

expected_nonphysical_linkage <- data.table(
  singleton_identity_scope_cluster_status = c(
    "nonphysical_financing_portfolio_requires_bridge",
    "nonphysical_unresolved_bad_source_identity_requires_recovery",
    "nonphysical_invalid_synthetic_test_source_row"
  ),
  expected_linkage_status = c(
    "nonphysical_financing_portfolio_requires_property_bridge",
    "nonphysical_unresolved_bad_source_identity_requires_recovery",
    "nonphysical_invalid_synthetic_test_source_row"
  ),
  expected_requires_review = c(TRUE, TRUE, FALSE)
)
observed_nonphysical_development <- development_after[
  singleton_identity_scope_cluster_status %chin%
    expected_nonphysical_linkage$singleton_identity_scope_cluster_status,
  .(
    singleton_identity_scope_cluster_status,
    observed_linkage_status = development_linkage_status,
    observed_requires_review = requires_linkage_review
  )
]
observed_nonphysical_development[expected_nonphysical_linkage, `:=`(
  expected_linkage_status = i.expected_linkage_status,
  expected_requires_review = i.expected_requires_review
), on = "singleton_identity_scope_cluster_status"]
observed_nonphysical_episode <- episode_after[
  singleton_identity_scope_cluster_status %chin%
    expected_nonphysical_linkage$singleton_identity_scope_cluster_status,
  .(
    singleton_identity_scope_cluster_status,
    observed_linkage_status = development_linkage_status,
    observed_requires_review = requires_linkage_review
  )
]
observed_nonphysical_episode[expected_nonphysical_linkage, `:=`(
  expected_linkage_status = i.expected_linkage_status,
  expected_requires_review = i.expected_requires_review
), on = "singleton_identity_scope_cluster_status"]
if (observed_nonphysical_development[
      observed_linkage_status != expected_linkage_status |
        observed_requires_review != expected_requires_review,
      .N
    ] > 0L ||
    observed_nonphysical_episode[
      observed_linkage_status != expected_linkage_status |
        observed_requires_review != expected_requires_review,
      .N
    ] > 0L) {
  stop("A nonphysical linkage status was flattened during application.",
    call. = FALSE)
}

audit <- data.table(
  check = c(
    "review_groups", "review_members", "reviewed_sites",
    "site_rows_added_by_frozen_transaction",
    "site_rows_removed_by_frozen_action",
    "site_rows_collapsed_by_adjudicated_key", "development_rows_all_scope",
    "development_rows_physical", "development_rows_nonphysical",
    "episode_rows_preserved", "site_rows_retained"
  ),
  value = c(
    nrow(reviews), nrow(members), nrow(site_decisions),
    nrow(site_additions),
    site_decisions[site_action %chin% drop_actions, .N],
    nrow(site_before) +
      nrow(site_additions) -
      site_decisions[site_action %chin% drop_actions, .N] -
      nrow(site_after),
    nrow(development_after),
    development_after[
      !startsWith(singleton_identity_development_scope_status,
        "nonphysical_"),
      .N
    ],
    development_after[
      startsWith(singleton_identity_development_scope_status,
        "nonphysical_"),
      .N
    ],
    nrow(episode_after), nrow(site_after)
  )
)
fwrite(
  audit,
  "../output/lihtc_singleton_identity_scope_application_audit.csv"
)
written_audit <- fread(
  "../output/lihtc_singleton_identity_scope_application_audit.csv"
)
if (!identical(audit, written_audit)) {
  stop("The singleton identity/scope audit CSV changed on write.",
    call. = FALSE)
}
