# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/apply_lihtc_singleton_identity_scope_review/code")

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

same_text <- function(left, right) {
  fifelse(is.na(left), "<MISSING>", left) ==
    fifelse(is.na(right), "<MISSING>", right)
}

development_input <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_mixed_site_identity_adjudicated.parquet"
))
episode_input <- as.data.table(read_parquet(
  "../input/lihtc_project_episode_2024_mixed_site_identity_adjudicated.parquet"
))
site_input <- as.data.table(read_parquet(
  "../input/lihtc_development_site_2024_mixed_site_identity_adjudicated.parquet"
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

if (nrow(development_input) != 53940L ||
    nrow(episode_input) != 55345L ||
    nrow(site_input) != 132559L ||
    uniqueN(development_input$development_id) != nrow(development_input) ||
    uniqueN(episode_input$hud_id) != nrow(episode_input) ||
    uniqueN(site_input$development_site_id) != nrow(site_input) ||
    uniqueN(site_input, by = c("development_id", "site_key")) !=
      nrow(site_input)) {
  stop("A singleton correction input count or key changed.", call. = FALSE)
}
if (uniqueN(reviews$singleton_identity_scope_review_id) != nrow(reviews) ||
    uniqueN(members$current_development_id) != nrow(members) ||
    any(!members$current_development_id %chin%
      development_input$development_id) ||
    !setequal(
      reviews$singleton_identity_scope_review_id,
      members$singleton_identity_scope_review_id
    )) {
  stop("The singleton review mapping is incomplete or duplicated.",
    call. = FALSE)
}

reviewed_site_ids <- site_input[
  development_id %chin% members$current_development_id,
  development_site_id
]
if (uniqueN(site_decisions$current_development_site_id) !=
      nrow(site_decisions) ||
    !setequal(
      reviewed_site_ids,
      site_decisions$current_development_site_id
    ) ||
    any(!site_decisions$site_action %chin% c(
      "keep_verified_physical_site",
      "keep_nonphysical_bridge_site",
      "retain_unresolved_source_site_for_review",
      "drop_wrong_source_site",
      "drop_malformed_redundant_variant",
      "drop_historical_redundant_address_alias"
    )) ||
    anyNA(site_decisions[, .(
      singleton_identity_scope_review_id,
      current_development_id,
      current_development_site_id,
      site_key,
      site_action,
      adjudicated_development_id,
      site_decision_reason,
      site_source_title,
      site_source_url,
      site_source_statement,
      geocoding_query_approval,
      reviewed_on
    )])) {
  stop("The singleton site decision contract is incomplete.",
    call. = FALSE)
}
addition_contract <- copy(site_additions)
addition_contract[members[, .(
  singleton_identity_scope_review_id,
  expected_development_id = adjudicated_development_id,
  cluster_status,
  member_action
)], `:=`(
  expected_development_id = i.expected_development_id,
  cluster_status = i.cluster_status,
  member_action = i.member_action
), on = "singleton_identity_scope_review_id"]
if (nrow(addition_contract) != 1L ||
    uniqueN(addition_contract$site_addition_id) != 1L ||
    uniqueN(addition_contract$development_site_id) != 1L ||
    anyNA(addition_contract[, .(
      expected_development_id,
      development_site_id,
      development_id,
      site_key,
      site_street,
      site_city,
      site_state,
      site_zip,
      site_source,
      site_action,
      site_decision_reason,
      site_source_title,
      site_source_type,
      site_source_url,
      site_source_statement,
      geocoding_query_approval,
      reviewed_on
    )]) ||
    addition_contract[
      development_id != expected_development_id |
        cluster_status != "final_physical_development" |
        member_action != "retain_physical_development" |
        site_action != "add_verified_physical_site" |
        site_decision_reason !=
          "official_state_property_record_supplies_missing_physical_site" |
        geocoding_query_approval != "not_approved",
      .N
    ] > 0L ||
    any(addition_contract$development_site_id %chin%
      site_input$development_site_id) ||
    site_input[addition_contract,
      .N,
      on = .(development_id, site_key),
      nomatch = 0L
    ] > 0L) {
  stop("The singleton site addition contract is incomplete or duplicated.",
    call. = FALSE)
}

mapping <- members[, .(
  singleton_identity_scope_review_id,
  current_development_id,
  current_hud_id,
  member_action,
  adjudicated_development_id,
  adjudicated_anchor_hud_id,
  cluster_status,
  reviewed_development_name,
  final_identity_decision,
  final_reason_code,
  final_scope_status,
  development_name_correction_reason,
  development_name_correction_source,
  episode_to_property_bridge_status,
  geocoding_query_approval,
  reviewed_on
)]

site_contract <- copy(site_decisions)
site_contract[mapping[, .(
  current_development_id,
  expected_review_id = singleton_identity_scope_review_id,
  expected_adjudicated_development_id = adjudicated_development_id
)], `:=`(
  expected_review_id = i.expected_review_id,
  expected_adjudicated_development_id =
    i.expected_adjudicated_development_id
), on = "current_development_id"]
site_contract[site_input[, .(
  current_development_site_id = development_site_id,
  observed_development_id = development_id,
  observed_site_key = site_key,
  observed_site_street = site_street,
  observed_site_city = site_city,
  observed_site_state = site_state,
  observed_site_zip = site_zip
)], `:=`(
  observed_development_id = i.observed_development_id,
  observed_site_key = i.observed_site_key,
  observed_site_street = i.observed_site_street,
  observed_site_city = i.observed_site_city,
  observed_site_state = i.observed_site_state,
  observed_site_zip = i.observed_site_zip
), on = "current_development_site_id"]
if (anyNA(site_contract[, .(
      expected_review_id,
      expected_adjudicated_development_id,
      observed_development_id,
      observed_site_key
    )]) ||
    site_contract[
      singleton_identity_scope_review_id != expected_review_id |
        adjudicated_development_id !=
          expected_adjudicated_development_id |
        current_development_id != observed_development_id |
        !same_text(site_key, observed_site_key) |
        !same_text(site_street, observed_site_street) |
        !same_text(site_city, observed_site_city) |
        !same_text(site_state, observed_site_state) |
        !same_text(site_zip, observed_site_zip),
      .N
    ] > 0L) {
  stop("A singleton site decision does not match its source row or target.",
    call. = FALSE)
}

if (anyNA(mapping[, .(
      member_action, adjudicated_development_id,
      adjudicated_anchor_hud_id, cluster_status,
      reviewed_development_name, episode_to_property_bridge_status,
      geocoding_query_approval, final_identity_decision,
      final_reason_code, final_scope_status, reviewed_on
    )])) {
  stop("A singleton review member lacks an operative decision.",
    call. = FALSE)
}

physical_mapping <- mapping[cluster_status == "final_physical_development"]
nonphysical_mapping <- mapping[
  startsWith(cluster_status, "nonphysical_")
]
physical_clusters <- physical_mapping[, .(
  n_members = .N,
  n_anchor_ids = uniqueN(adjudicated_development_id),
  n_anchor_hud_ids = uniqueN(adjudicated_anchor_hud_id),
  anchor_rows = sum(current_development_id == adjudicated_development_id)
), by = adjudicated_development_id]
nonphysical_clusters <- nonphysical_mapping[, .(
  n_members = .N,
  n_anchor_ids = uniqueN(adjudicated_development_id),
  n_anchor_hud_ids = uniqueN(adjudicated_anchor_hud_id),
  anchor_rows = sum(current_development_id == adjudicated_development_id)
), by = adjudicated_development_id]
if (physical_clusters[
      n_anchor_ids != 1L | n_anchor_hud_ids != 1L | anchor_rows != 1L,
      .N
    ] > 0L ||
    nonphysical_clusters[
      n_anchor_ids != 1L | n_anchor_hud_ids != 1L | anchor_rows != 1L,
      .N
    ] > 0L ||
    any(!nonphysical_mapping$member_action %chin% c(
      "retain_nonphysical_episode_bridge",
      "merge_to_nonphysical_episode_bridge",
      "retain_nonphysical_excluded_source_row"
    ))) {
  stop("A reviewed physical cluster or nonphysical bridge is invalid.",
    call. = FALSE)
}

episode <- copy(episode_input)
episode[, `:=`(
  pre_singleton_identity_scope_development_id = development_id,
  singleton_identity_scope_review_id = NA_character_,
  singleton_identity_scope_decision = "not_applicable",
  singleton_identity_scope_action = "not_applicable",
  singleton_identity_scope_reason_code = NA_character_,
  singleton_identity_scope_cluster_status = "not_reviewed",
  singleton_identity_scope_reviewed_on = as.Date(NA),
  singleton_identity_scope_geocoding_query_approval = "not_reviewed",
  singleton_identity_scope_episode_to_property_bridge_status =
    "not_required",
  singleton_identity_scope_reviewed_scope_status = NA_character_
)]
episode[mapping, `:=`(
  singleton_identity_scope_review_id =
    i.singleton_identity_scope_review_id,
  singleton_identity_scope_decision = i.final_identity_decision,
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
episode[mapping, `:=`(
  development_id = i.adjudicated_development_id,
  development_anchor_hud_id = i.adjudicated_anchor_hud_id
), on = c(
  pre_singleton_identity_scope_development_id = "current_development_id"
)]
episode[singleton_identity_scope_action == "merge_to_review_cluster", `:=`(
  development_linkage_status =
    "singleton_identity_scope_adjudicated_linked",
  development_linkage_basis = "singleton_outside_two_read_review",
  requires_linkage_review = FALSE
)]
episode[singleton_identity_scope_action == "retain_physical_development", `:=`(
  development_linkage_status = "singleton_identity_scope_reviewed_physical",
  development_linkage_basis = "singleton_outside_two_read_review",
  requires_linkage_review = FALSE
)]
episode[
  singleton_identity_scope_cluster_status ==
    "nonphysical_financing_portfolio_requires_bridge",
  `:=`(
    development_linkage_status =
      "nonphysical_financing_portfolio_requires_property_bridge",
    development_linkage_basis = "singleton_outside_two_read_review",
    requires_linkage_review = TRUE
  )
]
episode[
  singleton_identity_scope_cluster_status ==
    "nonphysical_unresolved_bad_source_identity_requires_recovery",
  `:=`(
    development_linkage_status =
      "nonphysical_unresolved_bad_source_identity_requires_recovery",
    development_linkage_basis = "singleton_outside_two_read_review",
    requires_linkage_review = TRUE
  )
]
episode[
  singleton_identity_scope_cluster_status ==
    "nonphysical_invalid_synthetic_test_source_row",
  `:=`(
    development_linkage_status =
      "nonphysical_invalid_synthetic_test_source_row",
    development_linkage_basis = "singleton_outside_two_read_review",
    requires_linkage_review = FALSE
  )
]
episode[, singleton_anchor_sort_year := fcase(
  !is.na(pis_year), pis_year,
  !is.na(allocation_year), allocation_year,
  default = 9999L
)]
setorder(
  episode,
  development_id,
  singleton_anchor_sort_year,
  allocation_year,
  hud_id,
  na.last = TRUE
)
episode[, `:=`(
  episode_number = seq_len(.N),
  n_project_episodes = .N
), by = development_id]
episode[, is_development_anchor := hud_id == development_anchor_hud_id]
episode[, singleton_anchor_sort_year := NULL]
if (episode[is_development_anchor == TRUE, .N] !=
      uniqueN(episode$development_id)) {
  stop("A singleton-adjudicated episode group has an invalid anchor.",
    call. = FALSE)
}

development <- copy(development_input)
development[, `:=`(
  current_singleton_identity_scope_development_id = development_id,
  pre_singleton_identity_scope_development_ids = development_id,
  pre_singleton_identity_scope_development_names = development_name,
  singleton_identity_scope_review_ids = NA_character_,
  singleton_identity_scope_decision = "not_applicable",
  singleton_identity_scope_action = "not_applicable",
  singleton_identity_scope_reason_codes = NA_character_,
  singleton_identity_scope_cluster_status = "not_reviewed",
  singleton_identity_scope_reviewed_on = as.Date(NA),
  singleton_identity_scope_geocoding_query_approval = "not_reviewed",
  singleton_identity_scope_episode_to_property_bridge_status =
    "not_required",
  singleton_identity_scope_reviewed_scope_status = NA_character_,
  singleton_identity_scope_site_rows_reviewed = 0L,
  singleton_identity_scope_site_rows_retained = 0L,
  singleton_identity_scope_site_rows_removed = 0L,
  singleton_identity_scope_site_rows_unresolved = 0L,
  development_name_correction_reason = NA_character_,
  development_name_correction_source = NA_character_
)]
development[mapping, `:=`(
  singleton_identity_scope_review_ids =
    i.singleton_identity_scope_review_id,
  singleton_identity_scope_decision = i.final_identity_decision,
  singleton_identity_scope_action = i.member_action,
  singleton_identity_scope_reason_codes = i.final_reason_code,
  singleton_identity_scope_cluster_status = i.cluster_status,
  singleton_identity_scope_reviewed_on = as.Date(i.reviewed_on),
  singleton_identity_scope_geocoding_query_approval =
    i.geocoding_query_approval,
  singleton_identity_scope_episode_to_property_bridge_status =
    i.episode_to_property_bridge_status,
  singleton_identity_scope_reviewed_scope_status = i.final_scope_status,
  development_name_correction_reason =
    i.development_name_correction_reason,
  development_name_correction_source =
    i.development_name_correction_source,
  development_name = i.reviewed_development_name
), on = c(
  current_singleton_identity_scope_development_id =
    "current_development_id"
)]
development[mapping, `:=`(
  development_id = i.adjudicated_development_id,
  development_anchor_hud_id = i.adjudicated_anchor_hud_id
), on = c(
  current_singleton_identity_scope_development_id =
    "current_development_id"
)]
development[singleton_identity_scope_action == "merge_to_review_cluster", `:=`(
  development_linkage_status =
    "singleton_identity_scope_adjudicated_linked",
  development_linkage_basis = "singleton_outside_two_read_review",
  requires_linkage_review = FALSE
)]
development[singleton_identity_scope_action == "retain_physical_development", `:=`(
  development_linkage_status = "singleton_identity_scope_reviewed_physical",
  development_linkage_basis = "singleton_outside_two_read_review",
  requires_linkage_review = FALSE
)]
development[
  singleton_identity_scope_cluster_status ==
    "nonphysical_financing_portfolio_requires_bridge",
  `:=`(
    development_linkage_status =
      "nonphysical_financing_portfolio_requires_property_bridge",
    development_linkage_basis = "singleton_outside_two_read_review",
    requires_linkage_review = TRUE
  )
]
development[
  singleton_identity_scope_cluster_status ==
    "nonphysical_unresolved_bad_source_identity_requires_recovery",
  `:=`(
    development_linkage_status =
      "nonphysical_unresolved_bad_source_identity_requires_recovery",
    development_linkage_basis = "singleton_outside_two_read_review",
    requires_linkage_review = TRUE
  )
]
development[
  singleton_identity_scope_cluster_status ==
    "nonphysical_invalid_synthetic_test_source_row",
  `:=`(
    development_linkage_status =
      "nonphysical_invalid_synthetic_test_source_row",
    development_linkage_basis = "singleton_outside_two_read_review",
    requires_linkage_review = FALSE
  )
]

review_cluster_sizes <- mapping[, .N, by = adjudicated_development_id]
merged_target_ids <- review_cluster_sizes[N > 1L, adjudicated_development_id]
merged_members <- development[development_id %chin% merged_target_ids]
merged_development <- merged_members[
  current_singleton_identity_scope_development_id == development_id
]
expected_merged_clusters <- length(merged_target_ids)
if (nrow(merged_development) != expected_merged_clusters ||
    uniqueN(merged_development$development_id) !=
      nrow(merged_development)) {
  stop("A singleton merge cluster lacks exactly one anchor row.",
    call. = FALSE)
}

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
if (!all(upstream_lineage_fields %chin% names(merged_members))) {
  stop("An upstream development-lineage field is missing.", call. = FALSE)
}
merged_lineage <- merged_members[, c(
  list(
    pre_singleton_identity_scope_development_ids = paste(
      sort(current_singleton_identity_scope_development_id),
      collapse = "|"
    ),
    pre_singleton_identity_scope_development_names = paste(
      sort(unique(pre_singleton_identity_scope_development_names)),
      collapse = "|"
    ),
    singleton_identity_scope_review_ids = collapse_delimited(
      singleton_identity_scope_review_ids
    ),
    singleton_identity_scope_reason_codes = collapse_delimited(
      singleton_identity_scope_reason_codes
    )
  ),
  lapply(.SD, collapse_delimited)
), by = development_id, .SDcols = upstream_lineage_fields]

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
if (nrow(episode_summary) != nrow(merged_development)) {
  stop("A merged singleton development lacks an episode summary.",
    call. = FALSE)
}

merged_lineage_fields <- setdiff(names(merged_lineage), "development_id")
merged_development[merged_lineage,
  (merged_lineage_fields) := mget(paste0("i.", merged_lineage_fields)),
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
  unit_aggregation_rule =
    "singleton_identity_scope_requires_unit_review",
  n_units_development = NA_real_,
  li_units_development = NA_real_,
  candidate_n_units_development = NA_real_,
  candidate_li_units_development = NA_real_
)]

development <- rbindlist(list(
  development[!development_id %chin% merged_target_ids],
  merged_development
), use.names = TRUE)
unit_deferred_target_ids <- mapping[
  cluster_status == "final_physical_development" &
    grepl(
      "unit_aggregation_deferred|units_deferred",
      final_scope_status
    ),
  unique(adjudicated_development_id)
]
development[development_id %chin% unit_deferred_target_ids, `:=`(
  episode_unit_count_sum = NA_real_,
  unit_aggregation_status = "requires_review",
  unit_aggregation_rule = "singleton_identity_scope_requires_unit_review",
  n_units_development = NA_real_,
  li_units_development = NA_real_,
  candidate_n_units_development = NA_real_,
  candidate_li_units_development = NA_real_
)]
development[
  !is.na(singleton_identity_scope_review_ids),
  development_name_key := normalize_text(development_name)
]
development[, singleton_identity_development_scope_status :=
  mixed_site_development_scope_status]
development[
  !is.na(singleton_identity_scope_reviewed_scope_status),
  singleton_identity_development_scope_status :=
    singleton_identity_scope_reviewed_scope_status
]
nonphysical_target_ids <- mapping[
  startsWith(final_scope_status, "nonphysical_"),
  unique(adjudicated_development_id)
]
nonphysical_multi_city_ids <- site_decisions[
  adjudicated_development_id %chin% nonphysical_target_ids &
    !site_action %chin% c(
      "drop_wrong_source_site",
      "drop_malformed_redundant_variant",
      "drop_historical_redundant_address_alias"
    ) &
    !is.na(site_city) & site_city != "",
  .(n_site_cities = uniqueN(site_city)),
  by = adjudicated_development_id
][n_site_cities > 1L, adjudicated_development_id]
development[
  development_id %chin% nonphysical_multi_city_ids,
  development_city := NA_character_
]

site_review_rows <- rbindlist(list(
  site_decisions[, .(
    adjudicated_development_id,
    site_action
  )],
  site_additions[, .(
    adjudicated_development_id = development_id,
    site_action
  )]
))
site_decision_summary <- site_review_rows[, .(
  singleton_identity_scope_site_rows_reviewed = .N,
  singleton_identity_scope_site_rows_retained = sum(
    !site_action %chin% c(
      "drop_wrong_source_site",
      "drop_malformed_redundant_variant",
      "drop_historical_redundant_address_alias"
    )
  ),
  singleton_identity_scope_site_rows_removed = sum(
    site_action %chin% c(
      "drop_wrong_source_site",
      "drop_malformed_redundant_variant",
      "drop_historical_redundant_address_alias"
    )
  ),
  singleton_identity_scope_site_rows_unresolved = sum(
    site_action == "retain_unresolved_source_site_for_review"
  )
), by = adjudicated_development_id]
development[site_decision_summary, `:=`(
  singleton_identity_scope_site_rows_reviewed =
    i.singleton_identity_scope_site_rows_reviewed,
  singleton_identity_scope_site_rows_retained =
    i.singleton_identity_scope_site_rows_retained,
  singleton_identity_scope_site_rows_removed =
    i.singleton_identity_scope_site_rows_removed,
  singleton_identity_scope_site_rows_unresolved =
    i.singleton_identity_scope_site_rows_unresolved
), on = c(development_id = "adjudicated_development_id")]

site_addition_rows <- site_input[0L]
site_addition_rows <- rbindlist(list(
  site_addition_rows,
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
site <- rbindlist(list(site_input, site_addition_rows), use.names = TRUE)
site[, pre_singleton_identity_scope_development_id := development_id]
site[, `:=`(
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
site[mapping, `:=`(
  singleton_identity_scope_review_id =
    i.singleton_identity_scope_review_id,
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
site[site_decisions, `:=`(
  singleton_identity_scope_site_action = i.site_action,
  singleton_identity_scope_site_decision_reason = i.site_decision_reason,
  singleton_identity_scope_site_source_title = i.site_source_title,
  singleton_identity_scope_site_source_type = i.site_source_type,
  singleton_identity_scope_site_source_url = i.site_source_url,
  singleton_identity_scope_site_source_statement = i.site_source_statement,
  development_id = i.adjudicated_development_id
), on = c(
  development_site_id = "current_development_site_id"
)]
site[site_additions, `:=`(
  singleton_identity_scope_site_action = i.site_action,
  singleton_identity_scope_site_decision_reason = i.site_decision_reason,
  singleton_identity_scope_site_source_title = i.site_source_title,
  singleton_identity_scope_site_source_type = i.site_source_type,
  singleton_identity_scope_site_source_url = i.site_source_url,
  singleton_identity_scope_site_source_statement = i.site_source_statement,
  development_id = i.development_id
), on = c(development_site_id = "development_site_id")]
drop_site_actions <- c(
  "drop_wrong_source_site",
  "drop_malformed_redundant_variant",
  "drop_historical_redundant_address_alias"
)
site[, adjudicated_site_key := paste(development_id, site_key, sep = "\r")]
retained_site_keys <- unique(site[
  !singleton_identity_scope_site_action %chin% drop_site_actions,
  adjudicated_site_key
])
site[, include_in_site_lineage :=
  !singleton_identity_scope_site_action %chin% drop_site_actions |
    (singleton_identity_scope_site_action ==
      "drop_malformed_redundant_variant" &
      adjudicated_site_key %chin% retained_site_keys)]
site <- site[include_in_site_lineage == TRUE]
site[, c("adjudicated_site_key", "include_in_site_lineage") := NULL]
expected_site_keys <- unique(site[, .(development_id, site_key)])

site[, duplicate_adjudicated_site_key := .N > 1L,
  by = .(development_id, site_key)]
singleton_sites <- site[duplicate_adjudicated_site_key == FALSE]
duplicate_sites <- site[duplicate_adjudicated_site_key == TRUE]
singleton_sites[, duplicate_adjudicated_site_key := NULL]
duplicate_sites[, duplicate_adjudicated_site_key := NULL]
duplicate_sites[, site_drop_sort :=
  singleton_identity_scope_site_action %chin% drop_site_actions]
setorder(
  duplicate_sites,
  development_id,
  site_key,
  site_drop_sort,
  -n_project_episodes,
  development_site_id
)
duplicate_sites <- duplicate_sites[, {
  group <- copy(.SD)
  group[, site_drop_sort := NULL]
  retained_group <- group[
    !singleton_identity_scope_site_action %chin% drop_site_actions
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
site <- rbindlist(list(singleton_sites, duplicate_sites), use.names = TRUE)
site[
  singleton_identity_scope_site_action %chin% c(
    "retain_unresolved_source_site_for_review",
    "keep_nonphysical_bridge_site"
  ),
  requires_site_review := TRUE
]
setorder(site, development_id, site_key)
observed_site_keys <- site[, .(development_id, site_key)]
setorder(expected_site_keys, development_id, site_key)
setorder(observed_site_keys, development_id, site_key)
if (!identical(expected_site_keys, observed_site_keys)) {
  stop("A reviewed retained site key was lost or invented.", call. = FALSE)
}
site[, site_number := seq_len(.N), by = development_id]
site[, development_site_id := paste0(
  development_id,
  "_SITE_",
  sprintf("%04d", site_number)
)]
site[, singleton_identity_development_scope_status :=
  development$singleton_identity_development_scope_status[
    match(development_id, development$development_id)
  ]]
episode[, singleton_identity_development_scope_status :=
  development$singleton_identity_development_scope_status[
    match(development_id, development$development_id)
  ]]
if (anyNA(site$singleton_identity_development_scope_status) ||
    anyNA(episode$singleton_identity_development_scope_status)) {
  stop("A site or episode lacks its singleton scope status.",
    call. = FALSE)
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

if (nrow(reviews) != 56L || nrow(members) != 88L ||
    nrow(site_decisions) != 166L ||
    nrow(site_additions) != 1L ||
    nrow(development) != 53909L || nrow(episode) != 55345L ||
    nrow(site) != 132513L ||
    development[
      startsWith(singleton_identity_development_scope_status,
        "nonphysical_"),
      .N
    ] != 23L ||
    development[
      !startsWith(singleton_identity_development_scope_status,
        "nonphysical_"),
      .N
    ] != 53886L ||
    development[
      singleton_identity_scope_cluster_status ==
        "nonphysical_financing_portfolio_requires_bridge",
      .N
    ] != 8L ||
    development[
      singleton_identity_scope_cluster_status ==
        "nonphysical_unresolved_bad_source_identity_requires_recovery",
      .N
    ] != 1L ||
    development[
      singleton_identity_scope_cluster_status ==
        "nonphysical_invalid_synthetic_test_source_row",
      .N
    ] != 1L) {
  stop("A final singleton identity/scope output count changed.",
    call. = FALSE)
}
if (development[
      singleton_identity_scope_cluster_status ==
        "nonphysical_financing_portfolio_requires_bridge" &
        (development_linkage_status !=
          "nonphysical_financing_portfolio_requires_property_bridge" |
          !requires_linkage_review),
      .N
    ] > 0L ||
    development[
      singleton_identity_scope_cluster_status ==
        "nonphysical_unresolved_bad_source_identity_requires_recovery" &
        (development_linkage_status !=
          "nonphysical_unresolved_bad_source_identity_requires_recovery" |
          !requires_linkage_review),
      .N
    ] > 0L ||
    development[
      singleton_identity_scope_cluster_status ==
        "nonphysical_invalid_synthetic_test_source_row" &
        (development_linkage_status !=
          "nonphysical_invalid_synthetic_test_source_row" |
          requires_linkage_review),
      .N
    ] > 0L) {
  stop("A nonphysical singleton row received the wrong linkage status.",
    call. = FALSE)
}

setorder(development, development_id)
setorder(episode, development_id, episode_number, hud_id)
setorder(site, development_id, site_number)
write_parquet(
  development,
  "../output/lihtc_development_2024_singleton_identity_scope_adjudicated.parquet"
)
write_parquet(
  episode,
  "../output/lihtc_project_episode_2024_singleton_identity_scope_adjudicated.parquet"
)
write_parquet(
  site,
  "../output/lihtc_development_site_2024_singleton_identity_scope_adjudicated.parquet"
)
development_round_trip <- as.data.table(read_parquet(
  "../output/lihtc_development_2024_singleton_identity_scope_adjudicated.parquet"
))
episode_round_trip <- as.data.table(read_parquet(
  "../output/lihtc_project_episode_2024_singleton_identity_scope_adjudicated.parquet"
))
site_round_trip <- as.data.table(read_parquet(
  "../output/lihtc_development_site_2024_singleton_identity_scope_adjudicated.parquet"
))
if (!isTRUE(all.equal(development, development_round_trip)) ||
    !isTRUE(all.equal(episode, episode_round_trip)) ||
    !isTRUE(all.equal(site, site_round_trip))) {
  stop("A singleton identity/scope Parquet changed on round trip.",
    call. = FALSE)
}
