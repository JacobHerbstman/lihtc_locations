# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/prepare_lihtc_no_site_development_review/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
})

require_unique <- function(table, columns, label) {
  if (uniqueN(table, by = columns) != nrow(table)) {
    stop(label, " is not unique by ", paste(columns, collapse = ", "),
      call. = FALSE)
  }
}

development <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_low_income_share_adjudicated.parquet"
))
episode <- as.data.table(read_parquet(
  "../input/lihtc_project_episode_2024_low_income_share_adjudicated.parquet"
))
site <- as.data.table(read_parquet(
  "../input/lihtc_development_site_2024_low_income_share_adjudicated.parquet"
))

if (nrow(development) != 53469L || nrow(episode) != 54902L ||
    nrow(site) != 131473L) {
  stop("A final low-income-share input row count changed.", call. = FALSE)
}
require_unique(development, "development_id", "Development input")
require_unique(episode, "hud_id", "Episode input")
require_unique(site, "development_site_id", "Site input")
require_unique(site, c("development_id", "site_key"), "Site input")
if (anyNA(development$development_id) ||
    any(development$development_id == "") ||
    anyNA(episode$development_id) || any(episode$development_id == "") ||
    anyNA(site$development_id) || any(site$development_id == "") ||
    anyNA(site$site_key) || any(site$site_key == "") ||
    any(!episode$development_id %chin% development$development_id) ||
    any(!site$development_id %chin% development$development_id)) {
  stop("An input key or foreign-key contract failed.", call. = FALSE)
}

retained_site_count <- site[, .(
  observed_retained_site_count = .N
), by = development_id]
development[retained_site_count,
  observed_retained_site_count := i.observed_retained_site_count,
on = "development_id"]
development[is.na(observed_retained_site_count),
  observed_retained_site_count := 0L]
if (anyNA(development$n_development_sites) ||
    any(development$n_development_sites !=
      development$observed_retained_site_count)) {
  stop("Stored and observed retained-site counts disagree.", call. = FALSE)
}

no_site <- development[observed_retained_site_count == 0L]
if (nrow(no_site) != 797L ||
    uniqueN(no_site$development_id) != nrow(no_site) ||
    any(no_site$n_development_sites != 0L) ||
    any(site$development_id %chin% no_site$development_id) ||
    any(!no_site$development_state %chin% c(state.abb, "DC")) ||
    anyNA(no_site$development_name) || any(no_site$development_name == "") ||
    anyNA(no_site$development_state) || any(no_site$development_state == "")) {
  stop("The no-retained-site development universe changed.", call. = FALSE)
}

no_site_episode <- episode[development_id %chin% no_site$development_id]
if (nrow(no_site_episode) != 797L ||
    uniqueN(no_site_episode$hud_id) != nrow(no_site_episode) ||
    uniqueN(no_site_episode$development_id) != nrow(no_site) ||
    any(no_site[, .N, by = development_id]$N != 1L) ||
    any(no_site_episode[, .N, by = development_id]$N != 1L) ||
    !setequal(no_site_episode$development_id, no_site$development_id) ||
    any(no_site$n_project_episodes != 1L)) {
  stop("The no-retained-site episode membership is not one-to-one.",
    call. = FALSE)
}

questions <- no_site[, .(
  no_site_review_question_id = paste0("NSDQ_", development_id),
  development_id,
  development_anchor_hud_id,
  development_name,
  development_name_key,
  development_state,
  development_city,
  n_project_episodes,
  first_pis_year,
  last_pis_year,
  n_units_development,
  li_units_development,
  episode_unit_count_max,
  unit_aggregation_status,
  unit_scope_review_status,
  downstream_unit_analysis_status,
  low_income_share_review_scope,
  low_income_share_review_action,
  low_income_share_analysis_status,
  n_development_sites,
  observed_retained_site_count,
  n_sites_with_hud_coordinates,
  n_sites_requiring_review,
  development_linkage_status,
  development_linkage_basis,
  requires_linkage_review,
  linkage_review_decision,
  linkage_review_reason_code,
  name_variant_candidate_group_id,
  name_variant_review_decision,
  mixed_site_identity_question_ids,
  mixed_site_identity_action,
  single_address_review_question_ids,
  single_address_review_action,
  identical_address_set_review_question_ids,
  identical_address_set_review_action,
  cross_address_identity_question_id,
  cross_address_review_decision,
  cross_address_round2_identity_question_ids,
  cross_address_round2_review_action,
  singleton_identity_scope_review_ids,
  singleton_identity_scope_action,
  singleton_identity_scope_cluster_status,
  singleton_identity_scope_reviewed_scope_status,
  singleton_identity_development_scope_status,
  source_site_review_scope,
  source_site_group_decision,
  source_site_inventory_status,
  source_site_property_structure_status,
  source_site_development_scope_status,
  source_site_unresolved_status,
  source_site_requires_episode_property_bridge,
  source_site_repair_status,
  source_site_rows_removed,
  source_site_rows_added,
  source_site_unresolved_rows,
  review_status = "not_adjudicated",
  geocoding_query_approval = "not_approved"
)]

episode_members <- no_site_episode[, .(
  no_site_review_question_id = paste0("NSDQ_", development_id),
  development_id,
  hud_id,
  episode_number,
  is_development_anchor,
  source_property_row,
  project,
  name_key,
  proj_add,
  proj_cty,
  proj_st,
  proj_zip,
  state_id,
  primary_site_key,
  pis_year,
  allocation_year,
  yr_pis,
  yr_alloc,
  latitude,
  longitude,
  episode_units,
  episode_low_income_units,
  n_units,
  li_units,
  scattered_site_cd,
  resyndication_cd,
  datanote,
  record_stat,
  development_linkage_status,
  development_linkage_basis,
  requires_linkage_review,
  linkage_review_decision,
  linkage_review_reason_code,
  name_variant_candidate_group_id,
  name_variant_review_decision,
  mixed_site_identity_question_id,
  mixed_site_identity_action,
  single_address_review_question_id,
  single_address_review_action,
  identical_address_set_review_question_id,
  identical_address_set_review_action,
  cross_address_identity_question_id,
  cross_address_review_decision,
  cross_address_round2_identity_question_id,
  cross_address_round2_review_action,
  singleton_identity_scope_review_id,
  singleton_identity_scope_action,
  singleton_identity_scope_cluster_status,
  singleton_identity_scope_reviewed_scope_status,
  singleton_identity_development_scope_status,
  source_site_review_scope,
  source_site_group_decision,
  source_site_inventory_status,
  source_site_property_structure_status,
  source_site_development_scope_status,
  source_site_unresolved_status,
  source_site_requires_episode_property_bridge,
  source_site_episode_action,
  source_site_episode_decision_status,
  source_site_repair_status,
  unit_scope_review_status,
  unit_scope_final_total_action,
  unit_scope_final_low_income_action,
  downstream_unit_analysis_status,
  low_income_share_review_scope,
  low_income_share_review_action,
  low_income_share_analysis_status,
  review_status = "not_adjudicated",
  geocoding_query_approval = "not_approved"
)]

setorder(questions, development_id)
setorder(episode_members, development_id, hud_id)
require_unique(questions, "no_site_review_question_id", "Question output")
require_unique(questions, "development_id", "Question output")
require_unique(episode_members, "hud_id", "Episode-member output")
require_unique(episode_members, "development_id", "Episode-member output")
if (!setequal(questions$no_site_review_question_id,
      episode_members$no_site_review_question_id) ||
    any(questions$review_status != "not_adjudicated") ||
    any(episode_members$review_status != "not_adjudicated") ||
    any(questions$geocoding_query_approval != "not_approved") ||
    any(episode_members$geocoding_query_approval != "not_approved")) {
  stop("The prepared review-safety contract failed.", call. = FALSE)
}

write_parquet(
  questions,
  "../output/lihtc_no_site_development_questions.parquet"
)
write_parquet(
  episode_members,
  "../output/lihtc_no_site_development_episode_members.parquet"
)

questions_roundtrip <- as.data.table(read_parquet(
  "../output/lihtc_no_site_development_questions.parquet"
))
episodes_roundtrip <- as.data.table(read_parquet(
  "../output/lihtc_no_site_development_episode_members.parquet"
))
if (!isTRUE(all.equal(
      as.data.frame(questions_roundtrip),
      as.data.frame(questions),
      check.attributes = FALSE
    )) ||
    !isTRUE(all.equal(
      as.data.frame(episodes_roundtrip),
      as.data.frame(episode_members),
      check.attributes = FALSE
    ))) {
  stop("A prepared parquet failed its exact round-trip check.",
    call. = FALSE)
}
