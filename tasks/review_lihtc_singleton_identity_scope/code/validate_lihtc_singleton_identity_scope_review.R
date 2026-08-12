# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/review_lihtc_singleton_identity_scope/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
})

same_text <- function(left, right) {
  fifelse(is.na(left), "<MISSING>", left) ==
    fifelse(is.na(right), "<MISSING>", right)
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

development <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_mixed_site_identity_adjudicated.parquet"
))
episode <- as.data.table(read_parquet(
  "../input/lihtc_project_episode_2024_mixed_site_identity_adjudicated.parquet"
))
site <- as.data.table(read_parquet(
  "../input/lihtc_development_site_2024_mixed_site_identity_adjudicated.parquet"
))
members <- fread(
  "singleton_identity_scope_reviews.csv",
  colClasses = "character",
  na.strings = c("", "NA")
)
sites <- fread(
  "singleton_identity_scope_site_decisions.csv",
  colClasses = "character",
  na.strings = c("", "NA")
)
site_additions <- fread(
  "singleton_identity_scope_site_additions.csv",
  colClasses = "character",
  na.strings = c("", "NA")
)
if (unname(tools::md5sum("singleton_identity_scope_reviews.csv")) !=
      "4e37c5b6bfb59ba18d59c310f11c73cd" ||
    unname(tools::md5sum("singleton_identity_scope_site_decisions.csv")) !=
      "14625fa7ee8564389d71011ac2255cf1" ||
    unname(tools::md5sum("singleton_identity_scope_site_additions.csv")) !=
      "110edb2e11ba0d1ac7f1327707e7123a") {
  stop("A frozen singleton review ledger changed byte-for-byte.",
    call. = FALSE)
}
members[, `:=`(
  n_review_group_members = as.integer(n_review_group_members),
  requires_episode_property_bridge =
    requires_episode_property_bridge == "TRUE",
  reviewed_on = as.Date(reviewed_on),
  source_rows_changed = source_rows_changed == "TRUE"
)]
sites[, reviewed_on := as.Date(reviewed_on)]
site_additions[, `:=`(
  site_number = as.integer(site_number),
  n_project_episodes = as.integer(n_project_episodes),
  n_bin_values = as.integer(n_bin_values),
  n_coordinate_pairs = as.integer(n_coordinate_pairs),
  latitude = as.numeric(latitude),
  longitude = as.numeric(longitude),
  requires_site_review = requires_site_review == "TRUE",
  reviewed_on = as.Date(reviewed_on)
)]
members[development_name_correction_reason == "not_applicable",
  development_name_correction_reason := NA_character_]
members[development_name_correction_source == "not_applicable",
  development_name_correction_source := NA_character_]

member_columns <- c(
  "singleton_identity_scope_review_id", "review_type",
  "current_development_id", "current_hud_id",
  "current_development_name", "current_scope_status",
  "n_review_group_members",
  "final_identity_decision", "member_action",
  "adjudicated_development_id", "adjudicated_anchor_hud_id",
  "cluster_status", "reviewed_development_name", "final_reason_code",
  "physical_property_members", "identity_source_title",
  "identity_source_type", "identity_source_url",
  "identity_source_statement", "count_source_title",
  "count_source_type", "count_source_url", "count_source_statement",
  "source_assessment", "final_scope_status",
  "requires_episode_property_bridge",
  "episode_to_property_bridge_status", "geocoding_query_approval",
  "development_name_correction_reason",
  "development_name_correction_source", "reviewed_on", "review_status",
  "source_rows_changed"
)
site_columns <- c(
  "singleton_identity_scope_review_id", "current_development_id",
  "current_development_site_id", "site_key", "site_street", "site_city",
  "site_state", "site_zip", "site_action", "adjudicated_development_id",
  "site_decision_reason", "site_source_title", "site_source_type",
  "site_source_url", "site_source_statement",
  "geocoding_query_approval", "reviewed_on"
)
site_addition_columns <- c(
  "site_addition_id", "singleton_identity_scope_review_id",
  "development_site_id", "development_id", "site_number", "site_key",
  "site_street", "site_city", "site_state", "site_zip", "site_source",
  "n_project_episodes", "hud_ids", "n_bin_values", "bin_example",
  "n_coordinate_pairs", "latitude", "longitude", "requires_site_review",
  "site_action", "site_decision_reason", "site_source_title", "site_source_type",
  "site_source_url", "site_source_statement", "geocoding_query_approval",
  "reviewed_on"
)
if (!identical(names(members), member_columns) ||
    !identical(names(sites), site_columns) ||
    !identical(names(site_additions), site_addition_columns)) {
  stop("A singleton review ledger schema changed.", call. = FALSE)
}

if (nrow(members) != 88L ||
    uniqueN(members$singleton_identity_scope_review_id) != 56L ||
    uniqueN(members$current_development_id) != 88L ||
    uniqueN(members$current_hud_id) != 88L ||
    uniqueN(members$adjudicated_development_id) != 57L ||
    nrow(sites) != 166L ||
    uniqueN(sites$current_development_site_id) != 166L ||
    nrow(site_additions) != 1L ||
    uniqueN(site_additions$site_addition_id) != 1L ||
    uniqueN(site_additions$development_site_id) != 1L ||
    members[member_action == "merge_to_review_cluster", .N] != 30L ||
    members[member_action == "retain_physical_development", .N] != 47L ||
    members[member_action ==
      "merge_to_nonphysical_episode_bridge", .N] != 1L ||
    members[member_action ==
      "retain_nonphysical_episode_bridge", .N] != 8L ||
    members[member_action ==
      "retain_nonphysical_excluded_source_row", .N] != 2L ||
    members[startsWith(cluster_status, "nonphysical_"), .N] != 11L ||
    sites[site_action == "keep_verified_physical_site", .N] != 28L ||
    sites[site_action == "keep_nonphysical_bridge_site", .N] != 16L ||
    sites[site_action ==
      "retain_unresolved_source_site_for_review", .N] != 76L ||
    sites[site_action == "drop_malformed_redundant_variant", .N] != 36L ||
    sites[site_action ==
      "drop_historical_redundant_address_alias", .N] != 1L ||
    sites[site_action == "drop_wrong_source_site", .N] != 9L) {
  stop("A frozen singleton review group, member, or site count changed.",
    call. = FALSE)
}

required_member_fields <- c(
  "singleton_identity_scope_review_id", "review_type",
  "current_development_id", "current_hud_id",
  "current_development_name", "current_scope_status",
  "n_review_group_members",
  "final_identity_decision", "member_action",
  "adjudicated_development_id", "adjudicated_anchor_hud_id",
  "cluster_status", "reviewed_development_name", "final_reason_code",
  "physical_property_members", "identity_source_title",
  "identity_source_type", "identity_source_url",
  "identity_source_statement", "source_assessment", "final_scope_status",
  "episode_to_property_bridge_status", "geocoding_query_approval",
  "reviewed_on", "review_status"
)
required_site_fields <- c(
  "singleton_identity_scope_review_id", "current_development_id",
  "current_development_site_id", "site_key", "site_action",
  "adjudicated_development_id", "site_decision_reason",
  "site_source_title", "site_source_type", "site_source_url",
  "site_source_statement", "geocoding_query_approval", "reviewed_on"
)
required_site_addition_fields <- c(
  "site_addition_id", "singleton_identity_scope_review_id",
  "development_site_id", "development_id", "site_number", "site_key",
  "site_street", "site_city", "site_state", "site_zip", "site_source",
  "n_project_episodes", "hud_ids", "n_bin_values", "n_coordinate_pairs",
  "requires_site_review", "site_action", "site_source_title",
  "site_decision_reason",
  "site_source_type", "site_source_url", "site_source_statement",
  "geocoding_query_approval", "reviewed_on"
)
if (anyNA(members[, ..required_member_fields]) ||
    anyNA(sites[, ..required_site_fields]) ||
    anyNA(site_additions[, ..required_site_addition_fields]) ||
    anyDuplicated(members$current_development_id) ||
    anyDuplicated(members$current_hud_id) ||
    anyDuplicated(sites$current_development_site_id) ||
    anyDuplicated(site_additions$site_addition_id) ||
    anyDuplicated(site_additions$development_site_id) ||
    any(members$source_rows_changed) ||
    any(members$review_status != "two_read_complete") ||
    any(members$geocoding_query_approval != "not_approved") ||
    any(sites$geocoding_query_approval != "not_approved") ||
    any(site_additions$geocoding_query_approval != "not_approved")) {
  stop("A singleton review row is incomplete or violates the source guard.",
    call. = FALSE)
}
internal_hud_url <- "https://www.huduser.gov/portal/datasets/lihtc.html"
if (any(members$identity_source_url == internal_hud_url) ||
    sites[
      site_action == "keep_verified_physical_site" &
        site_source_url == internal_hud_url,
      .N
    ] > 0L ||
    any(site_additions$site_source_url == internal_hud_url)) {
  stop("The HUD LIHTC input was reused as the required outside read.",
    call. = FALSE)
}

if (nrow(development) != 53940L ||
    nrow(episode) != 55345L ||
    nrow(site) != 132559L ||
    uniqueN(development$development_id) != nrow(development) ||
    uniqueN(episode$hud_id) != nrow(episode) ||
    uniqueN(site$development_site_id) != nrow(site) ||
    uniqueN(site, by = c("development_id", "site_key")) != nrow(site)) {
  stop("A mixed-site applied review input count or key changed.",
    call. = FALSE)
}

member_source_contract <- copy(members)
member_source_contract[development[, .(
  current_development_id = development_id,
  observed_anchor_hud_id = development_anchor_hud_id,
  observed_development_name = development_name,
  observed_scope_status = mixed_site_development_scope_status
)], `:=`(
  observed_anchor_hud_id = i.observed_anchor_hud_id,
  observed_development_name = i.observed_development_name,
  observed_scope_status = i.observed_scope_status
), on = "current_development_id"]
member_source_contract[episode[, .(
  current_hud_id = hud_id,
  episode_source_development_id = development_id
)], episode_source_development_id := i.episode_source_development_id,
on = "current_hud_id"]
if (anyNA(member_source_contract[, .(
      observed_anchor_hud_id,
      observed_development_name,
      observed_scope_status,
      episode_source_development_id
    )]) ||
    member_source_contract[
      current_hud_id != observed_anchor_hud_id |
        current_development_id != episode_source_development_id |
        !same_text(current_development_name, observed_development_name) |
        current_scope_status != observed_scope_status,
      .N
    ] > 0L) {
  stop("A reviewed member does not match its current anchor, name, or scope.",
    call. = FALSE)
}

expected_reviewed_site_ids <- site[
  development_id %chin% members$current_development_id,
  development_site_id
]
if (!setequal(
      expected_reviewed_site_ids,
      sites$current_development_site_id
    )) {
  stop("The site ledger does not cover every site of every reviewed member.",
    call. = FALSE)
}
site_addition_contract <- copy(site_additions)
site_addition_contract[members[, .(
  singleton_identity_scope_review_id,
  expected_development_id = adjudicated_development_id,
  cluster_status,
  member_action
)], `:=`(
  expected_development_id = i.expected_development_id,
  cluster_status = i.cluster_status,
  member_action = i.member_action
), on = "singleton_identity_scope_review_id"]
if (anyNA(site_addition_contract[, .(
      expected_development_id,
      cluster_status,
      member_action
    )]) ||
    site_addition_contract[
      development_id != expected_development_id |
        cluster_status != "final_physical_development" |
        member_action != "retain_physical_development",
      .N
    ] > 0L ||
    any(site_additions$development_site_id %chin% site$development_site_id) ||
    site[
      site_key %chin% site_additions$site_key &
        development_id %chin% site_additions$development_id,
      .N
    ] > 0L ||
    site_additions[
      site_addition_id != "SISR_SITE_ADD_0001" |
        singleton_identity_scope_review_id !=
          "SISR_TX_SAVANNAH_GATEWAY" |
        development_site_id != "DEV_TXA00000096_SITE_0001" |
        development_id != "DEV_TXA00000096" |
        site_number != 1L |
        site_key != "TX|401 N SHILOH RD|PLANO" |
        site_street != "401 N SHILOH ROAD" |
        site_city != "PLANO" | site_state != "TX" |
        site_zip != "75074" |
        site_source != "external_public_record" |
        n_project_episodes != 1L | hud_ids != "TXA00000096" |
        n_bin_values != 0L | !is.na(bin_example) |
        n_coordinate_pairs != 0L | !is.na(latitude) |
        !is.na(longitude) | !requires_site_review |
        site_action != "add_verified_physical_site" |
        site_decision_reason !=
          "official_state_property_record_supplies_missing_physical_site" |
        site_source_type != "official_state_housing_agency" |
        !startsWith(site_source_url, "https://") |
        geocoding_query_approval != "not_approved",
      .N
    ] > 0L) {
  stop("The reviewed site addition is incomplete or conflicts with source sites.",
    call. = FALSE)
}
site_source_contract <- copy(sites)
site_source_contract[site[, .(
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
if (anyNA(site_source_contract[, .(
      observed_development_id,
      observed_site_key
    )]) ||
    site_source_contract[
      current_development_id != observed_development_id |
        !same_text(site_key, observed_site_key) |
        !same_text(site_street, observed_site_street) |
        !same_text(site_city, observed_site_city) |
        !same_text(site_state, observed_site_state) |
        !same_text(site_zip, observed_site_zip),
      .N
    ] > 0L) {
  stop("A frozen site decision does not match its current source row.",
    call. = FALSE)
}

allowed_member_actions <- c(
  "merge_to_review_cluster",
  "retain_physical_development",
  "retain_nonphysical_episode_bridge",
  "merge_to_nonphysical_episode_bridge",
  "retain_nonphysical_excluded_source_row"
)
allowed_site_actions <- c(
  "keep_verified_physical_site",
  "keep_nonphysical_bridge_site",
  "retain_unresolved_source_site_for_review",
  "drop_wrong_source_site",
  "drop_malformed_redundant_variant",
  "drop_historical_redundant_address_alias"
)
if (any(!members$member_action %chin% allowed_member_actions) ||
    any(!sites$site_action %chin% allowed_site_actions) ||
    any(!members$cluster_status %chin% c(
      "final_physical_development",
      "nonphysical_financing_portfolio_requires_bridge",
      "nonphysical_unresolved_bad_source_identity_requires_recovery",
      "nonphysical_invalid_synthetic_test_source_row"
    )) ||
    members[
      cluster_status == "final_physical_development" &
        !startsWith(final_scope_status, "physical_"),
      .N
    ] > 0L ||
    members[
      startsWith(cluster_status, "nonphysical_") &
        final_scope_status != cluster_status,
      .N
    ] > 0L) {
  stop("A singleton review uses an unrecognized action or scope status.",
    call. = FALSE)
}
if (members[
      cluster_status == "final_physical_development" &
        !member_action %chin% c(
          "merge_to_review_cluster",
          "retain_physical_development"
        ),
      .N
    ] > 0L ||
    members[
      startsWith(cluster_status, "nonphysical_") &
        !member_action %chin% c(
          "merge_to_nonphysical_episode_bridge",
          "retain_nonphysical_episode_bridge",
          "retain_nonphysical_excluded_source_row"
        ),
      .N
    ] > 0L ||
    members[
      review_type == "physical_identity_merge" &
        cluster_status != "final_physical_development",
      .N
    ] > 0L ||
    members[
      cluster_status == "final_physical_development" &
        requires_episode_property_bridge,
      .N
    ] > 0L ||
    members[
      cluster_status ==
        "nonphysical_financing_portfolio_requires_bridge" &
        (!requires_episode_property_bridge |
          episode_to_property_bridge_status != "required"),
      .N
    ] > 0L) {
  stop("A singleton identity action conflicts with its scope or bridge.",
    call. = FALSE)
}

question_fields <- c(
  "review_type", "n_review_group_members", "final_identity_decision",
  "identity_source_title", "identity_source_type", "identity_source_url",
  "identity_source_statement", "geocoding_query_approval",
  "reviewed_on", "review_status",
  "source_rows_changed"
)
consistent_group_fields <- setdiff(
  question_fields,
  "n_review_group_members"
)
group_contract <- members[, c(
  list(
    observed_members = .N,
    declared_member_counts = uniqueN(n_review_group_members),
    declared_members = first(n_review_group_members)
  ),
  lapply(.SD, uniqueN)
), by = singleton_identity_scope_review_id, .SDcols = consistent_group_fields]
inconsistent_group_fields <- rowSums(
  group_contract[, ..consistent_group_fields] != 1L
) > 0L
if (any(
      group_contract$declared_member_counts != 1L |
        group_contract$observed_members != group_contract$declared_members |
        inconsistent_group_fields
    )) {
  stop("A singleton review group has inconsistent frozen evidence.",
    call. = FALSE)
}

cluster_contract <- members[, .(
  n_anchor_ids = uniqueN(adjudicated_development_id),
  n_anchor_hud_ids = uniqueN(adjudicated_anchor_hud_id),
  anchor_rows = sum(current_development_id == adjudicated_development_id),
  review_id_values = uniqueN(singleton_identity_scope_review_id),
  status_values = uniqueN(cluster_status),
  reviewed_name_values = uniqueN(reviewed_development_name),
  reason_values = uniqueN(final_reason_code),
  physical_member_values = uniqueN(physical_property_members),
  count_title_values = uniqueN(count_source_title),
  count_type_values = uniqueN(count_source_type),
  count_url_values = uniqueN(count_source_url),
  count_statement_values = uniqueN(count_source_statement),
  assessment_values = uniqueN(source_assessment),
  final_scope_values = uniqueN(final_scope_status),
  bridge_values = uniqueN(requires_episode_property_bridge),
  bridge_status_values = uniqueN(episode_to_property_bridge_status),
  name_reason_values = uniqueN(development_name_correction_reason),
  name_source_values = uniqueN(development_name_correction_source)
), by = adjudicated_development_id]
if (cluster_contract[
      n_anchor_ids != 1L | n_anchor_hud_ids != 1L | anchor_rows != 1L |
        review_id_values != 1L |
        status_values != 1L | reviewed_name_values != 1L |
        reason_values != 1L | physical_member_values != 1L |
        count_title_values != 1L | count_type_values != 1L |
        count_url_values != 1L | count_statement_values != 1L |
        assessment_values != 1L | final_scope_values != 1L |
        bridge_values != 1L | bridge_status_values != 1L |
        name_reason_values != 1L | name_source_values != 1L,
      .N
    ] > 0L) {
  stop("A singleton operative cluster lacks one anchor, status, or name.",
    call. = FALSE)
}

site_member_contract <- sites[members[, .(
  singleton_identity_scope_review_id,
  current_development_id,
  expected_adjudicated_development_id = adjudicated_development_id,
  cluster_status
)], on = c(
  "singleton_identity_scope_review_id",
  "current_development_id"
), nomatch = 0L]
if (nrow(site_member_contract) != nrow(sites) ||
    anyNA(site_member_contract$cluster_status) ||
    any(
      site_member_contract$adjudicated_development_id !=
        site_member_contract$expected_adjudicated_development_id
    ) ||
    site_member_contract[
      cluster_status == "final_physical_development" &
        site_action == "keep_nonphysical_bridge_site",
      .N
    ] > 0L ||
    site_member_contract[
      startsWith(cluster_status, "nonphysical_") &
        site_action == "keep_verified_physical_site",
      .N
    ] > 0L) {
  stop("A singleton site action conflicts with its identity decision.",
    call. = FALSE)
}

question_reviews <- members[, c(
  list(
    current_development_ids = paste(
      sort(current_development_id),
      collapse = "|"
    ),
    current_hud_ids = paste(sort(current_hud_id), collapse = "|"),
    reviewed_development_names = paste(
      sort(unique(reviewed_development_name)),
      collapse = "|"
    ),
    n_operative_clusters = uniqueN(adjudicated_development_id),
    final_scope_statuses = paste(
      sort(unique(final_scope_status)),
      collapse = "|"
    ),
    final_reason_codes = collapse_delimited(final_reason_code),
    physical_property_member_sets = paste(
      sort(unique(physical_property_members)),
      collapse = "|"
    ),
    count_source_statements = paste(
      sort(unique(count_source_statement)),
      collapse = "|"
    )
  ),
  lapply(.SD, first)
), by = singleton_identity_scope_review_id, .SDcols = question_fields]

setorder(question_reviews, singleton_identity_scope_review_id)
setorder(members, singleton_identity_scope_review_id, current_development_id)
setorder(sites, singleton_identity_scope_review_id, current_development_site_id)
setorder(site_additions, site_addition_id)
write_parquet(
  question_reviews,
  "../output/lihtc_singleton_identity_scope_question_reviews.parquet"
)
write_parquet(
  members,
  "../output/lihtc_singleton_identity_scope_member_partitions.parquet"
)
write_parquet(
  sites,
  "../output/lihtc_singleton_identity_scope_site_decisions.parquet"
)
write_parquet(
  site_additions,
  "../output/lihtc_singleton_identity_scope_site_additions.parquet"
)
