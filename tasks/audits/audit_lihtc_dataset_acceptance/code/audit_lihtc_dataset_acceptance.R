# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/audit_lihtc_dataset_acceptance/code")

library(arrow)
library(data.table)

require_unique <- function(x, columns, label) {
  if (uniqueN(x, by = columns) != nrow(x)) {
    stop(label, " is not unique by ", paste(columns, collapse = ", "))
  }
}

append_reason <- function(current, condition, reason) {
  condition[is.na(condition)] <- FALSE
  fifelse(
    condition,
    fifelse(is.na(current) | current == "", reason, paste(current, reason, sep = "|")),
    current
  )
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
excluded_episode <- as.data.table(read_parquet(
  "../input/lihtc_excluded_episode_2024_unit_scope_evidence.parquet"
))
raw_episode <- as.data.table(read_parquet(
  "../input/lihtc_project_episode_2024_raw_built.parquet"
))
raw_site <- as.data.table(read_parquet(
  "../input/lihtc_development_site_2024_raw_built.parquet"
))
pre_singleton_site <- as.data.table(read_parquet(
  "../input/lihtc_development_site_2024_pre_singleton.parquet"
))
source_site_decision <- as.data.table(read_parquet(
  "../input/lihtc_source_site_member_decisions.parquet"
))
singleton_site_decision <- as.data.table(read_parquet(
  "../input/lihtc_singleton_identity_scope_site_decisions.parquet"
))
component <- as.data.table(read_parquet(
  "../input/lihtc_site_address_component_2024_geocoding_crosswalk.parquet"
))
query <- as.data.table(read_parquet(
  "../input/lihtc_geocoding_queries_2024.parquet"
))
pilot <- as.data.table(read_parquet(
  "../input/lihtc_census_geocoding_pilot.parquet"
))
pilot_review <- as.data.table(read_parquet(
  "../input/lihtc_census_geocoding_pilot_review_queue.parquet"
))

require_unique(development, "development_id", "Final development table")
require_unique(episode, "hud_id", "Final physical episode table")
require_unique(excluded_episode, "hud_id", "Excluded episode table")
require_unique(raw_episode, "hud_id", "Raw built episode table")
require_unique(site, "development_site_id", "Final retained site table")
require_unique(site, c("development_id", "site_key"), "Final retained site table")
require_unique(raw_site, "development_site_id", "Raw built site table")
require_unique(pre_singleton_site, "development_site_id", "Pre-singleton site table")
require_unique(component, "development_site_address_component_id", "Address component table")
require_unique(query, "geocoding_query_id", "Geocoding query table")
require_unique(pilot, "geocoding_query_id", "Census pilot table")
require_unique(pilot_review, "geocoding_query_id", "Census pilot review queue")
require_unique(singleton_site_decision, "current_development_site_id", "Singleton site ledger")

if (nrow(development) != 53469L || nrow(episode) != 54902L ||
    nrow(site) != 131473L || nrow(component) != 137255L ||
    nrow(query) != 83734L || nrow(excluded_episode) != 443L ||
    nrow(raw_episode) != 55345L || nrow(raw_site) != 135006L) {
  stop("A canonical input row count changed; re-audit the acceptance universe")
}
if (length(intersect(episode$hud_id, excluded_episode$hud_id)) != 0L ||
    !setequal(c(episode$hud_id, excluded_episode$hud_id), raw_episode$hud_id)) {
  stop("Physical and excluded episodes do not form a complete, disjoint raw partition")
}
if (!all(component$development_site_id %chin% site$development_site_id) ||
    !all(query$geocoding_query_id %chin% component$geocoding_query_id)) {
  stop("Address components or queries fall outside the final retained-site lineage")
}
if (!all(pilot$geocoding_query_id %chin% query$geocoding_query_id) ||
    !all(pilot_review$geocoding_query_id %chin% pilot$geocoding_query_id)) {
  stop("Census pilot rows fall outside the current unapproved query universe")
}

development[, explicit_identity_review :=
  development_linkage_status != "singleton" |
  !is.na(singleton_identity_scope_review_ids)]
development[, identity_evidence_status := fcase(
  source_site_unresolved_status != "none", "known_source_site_scope_unresolved",
  explicit_identity_review, "explicit_identity_or_scope_review_nonblocked",
  default = "rule_based_singleton_not_individually_reviewed"
)]

development[, unit_evidence_status := fcase(
  unit_scope_review_status == "reviewed" &
    !is.na(n_units_development) & !is.na(li_units_development),
  "explicit_unit_scope_review_static_total_and_low_income",
  unit_scope_review_status == "reviewed" &
    xor(is.na(n_units_development), is.na(li_units_development)),
  "explicit_unit_scope_review_partial_static_value",
  unit_scope_review_status == "reviewed",
  "explicit_unit_scope_review_no_static_value",
  default = "rule_based_single_episode_units_not_individually_reviewed"
)]

development[, low_income_share_evidence_status := fcase(
  low_income_share_review_action == "replace_low_income_units",
  "explicit_low_income_share_review_replacement",
  low_income_share_review_action == "retain_frozen_counts",
  "explicit_low_income_share_review_affirmed",
  low_income_share_review_action == "unresolved_exclude_low_income_share",
  "explicit_low_income_share_review_unresolved",
  !low_income_share_analysis_eligible,
  "incomplete_units_excluded_from_low_income_share",
  default = "not_flagged_not_individually_source_validated"
)]

episode[, timing_evidence_status := fcase(
  !is.na(pis_year) & !is.na(allocation_year), "pis_and_allocation_year_available",
  is.na(pis_year) & !is.na(allocation_year), "pis_year_unavailable",
  !is.na(pis_year) & is.na(allocation_year), "allocation_year_unavailable",
  default = "pis_and_allocation_year_unavailable"
)]
timing_by_development <- episode[, .(
  n_episode_timing_complete = sum(timing_evidence_status == "pis_and_allocation_year_available"),
  n_episode_timing_incomplete = sum(timing_evidence_status != "pis_and_allocation_year_available")
), by = development_id]
require_unique(timing_by_development, "development_id", "Development timing summary")
development[timing_by_development, on = "development_id", `:=`(
  n_episode_timing_complete = i.n_episode_timing_complete,
  n_episode_timing_incomplete = i.n_episode_timing_incomplete
)]
development[, timing_evidence_status := fcase(
  n_episode_timing_incomplete == 0L, "all_episode_timing_available",
  n_episode_timing_complete == 0L, "all_episode_timing_unavailable_or_partial",
  default = "some_episode_timing_unavailable_or_partial"
)]

shared_key <- site[, .(
  n_developments_at_site_key = uniqueN(development_id),
  all_members_project_primary = all(site_source == "project_primary")
), by = site_key]
require_unique(shared_key, "site_key", "Shared site-key summary")
site[shared_key, on = "site_key", `:=`(
  n_developments_at_site_key = i.n_developments_at_site_key,
  all_members_project_primary = i.all_members_project_primary
)]
site[, shared_address_status := fcase(
  n_developments_at_site_key == 1L, "not_shared_across_final_developments",
  all_members_project_primary, "shared_exact_site_key_primary_source_only_unreviewed",
  default = "shared_exact_site_key_involves_multi_address_source_unreviewed"
)]

site[, site_evidence_status := fcase(
  site_source == "external_public_record", "external_public_record_addition",
  source_site_review_scope == "reviewed_source_exception" &
    source_site_unresolved_status != "none",
  "explicit_source_site_review_retained_unresolved",
  source_site_review_scope == "reviewed_source_exception",
  "explicit_source_site_review_resolved",
  singleton_identity_scope_site_action != "not_applicable" & requires_site_review,
  "explicit_singleton_site_review_retained_unresolved",
  singleton_identity_scope_site_action != "not_applicable",
  "explicit_singleton_site_review_resolved",
  requires_site_review, "inherited_without_site_decision_review_flag_present",
  default = "inherited_without_site_decision_no_flag"
)]
development_identity_status <- development[, .(
  development_id,
  parent_identity_evidence_status = identity_evidence_status
)]
require_unique(development_identity_status, "development_id",
  "Development identity evidence crosswalk")
site[development_identity_status, on = "development_id",
  identity_evidence_status := i.parent_identity_evidence_status]
if (site[is.na(identity_evidence_status), .N] != 0L) {
  stop("A retained site lacks its parent development identity status")
}

expected_site_status <- data.table(
  site_evidence_status = c(
    "inherited_without_site_decision_no_flag",
    "inherited_without_site_decision_review_flag_present",
    "explicit_source_site_review_resolved",
    "explicit_source_site_review_retained_unresolved",
    "explicit_singleton_site_review_resolved",
    "explicit_singleton_site_review_retained_unresolved",
    "external_public_record_addition"
  ),
  expected_n = c(129433L, 1804L, 73L, 59L, 28L, 74L, 2L)
)
observed_site_status <- site[, .(observed_n = .N), by = site_evidence_status]
expected_site_status[observed_site_status, on = "site_evidence_status", observed_n := i.observed_n]
if (expected_site_status[is.na(observed_n) | observed_n != expected_n, .N] != 0L ||
    observed_site_status[!site_evidence_status %chin% expected_site_status$site_evidence_status, .N] != 0L) {
  stop("Final retained-site evidence partition changed")
}

component[site[, .(
  development_site_id,
  site_evidence_status,
  shared_address_status,
  identity_evidence_status
)], on = "development_site_id", `:=`(
  site_evidence_status = i.site_evidence_status,
  shared_address_status = i.shared_address_status,
  identity_evidence_status = i.identity_evidence_status
)]
if (component[is.na(site_evidence_status) | is.na(identity_evidence_status), .N] != 0L) {
  stop("An address component did not inherit its retained-site and development statuses")
}

component[, address_evidence_status := fcase(
  crosswalk_query_status == "ready_for_local_geocoding_pilot",
  "candidate_query_locally_prepared_not_real_world_validated",
  crosswalk_query_status == "blocked_baseline_address_issue",
  "blocked_baseline_address_issue",
  crosswalk_query_status == "blocked_unresolved_range_address",
  "blocked_unresolved_range_address",
  crosswalk_query_status == "blocked_other_address_or_source_issue",
  "blocked_other_address_or_source_issue",
  crosswalk_query_status == "blocked_unresolved_compound_address",
  "blocked_unresolved_compound_address",
  crosswalk_query_status == "excluded_nonphysical_range_description",
  "documented_nonphysical_range_exclusion",
  default = "unclassified_address_component"
)]
if (component[address_evidence_status == "unclassified_address_component", .N] != 0L ||
    component[is.na(geocoding_query_id) !=
      (crosswalk_query_status != "ready_for_local_geocoding_pilot"), .N] != 0L) {
  stop("Address-component readiness does not form the expected complete partition")
}

component_summary <- component[, .(
  n_address_components = .N,
  n_candidate_components = sum(crosswalk_query_status == "ready_for_local_geocoding_pilot"),
  n_blocked_components = sum(crosswalk_query_status != "ready_for_local_geocoding_pilot"),
  n_components_coordinate_missing = sum(coordinate_readiness_status == "missing_coordinate"),
  n_components_coordinate_review = sum(coordinate_readiness_status ==
    "requires_internal_coordinate_review")
), by = development_site_id]
require_unique(component_summary, "development_site_id", "Site address-component summary")
site[component_summary, on = "development_site_id", `:=`(
  n_address_components = i.n_address_components,
  n_candidate_components = i.n_candidate_components,
  n_blocked_components = i.n_blocked_components,
  n_components_coordinate_missing = i.n_components_coordinate_missing,
  n_components_coordinate_review = i.n_components_coordinate_review
)]
if (site[is.na(n_address_components), .N] != 0L) {
  stop("A retained final site has no address component")
}
site[, address_evidence_status := fcase(
  n_candidate_components > 0L & n_blocked_components == 0L,
  "all_components_candidate_unapproved",
  n_candidate_components > 0L, "mixed_candidate_and_blocked_components",
  default = "all_components_blocked_or_excluded"
)]
site[, coordinate_evidence_status := fcase(
  n_components_coordinate_review > 0L, "coordinate_requires_internal_review",
  n_components_coordinate_missing == n_address_components, "coordinate_missing",
  n_components_coordinate_missing > 0L, "coordinate_partially_missing",
  default = "coordinate_internally_plausible_external_validation_pending"
)]

site_summary <- site[, .(
  n_retained_sites = .N,
  n_candidate_site_queries = sum(n_candidate_components > 0L),
  n_blocked_sites = sum(n_candidate_components == 0L),
  n_shared_sites = sum(n_developments_at_site_key > 1L),
  n_unresolved_site_rows = sum(grepl("unresolved|review_flag", site_evidence_status))
), by = development_id]
require_unique(site_summary, "development_id", "Development site summary")
development[site_summary, on = "development_id", `:=`(
  n_retained_sites_audit = i.n_retained_sites,
  n_candidate_site_queries = i.n_candidate_site_queries,
  n_blocked_sites = i.n_blocked_sites,
  n_shared_sites = i.n_shared_sites,
  n_unresolved_site_rows_audit = i.n_unresolved_site_rows
)]
development[is.na(n_retained_sites_audit), `:=`(
  n_retained_sites_audit = 0L,
  n_candidate_site_queries = 0L,
  n_blocked_sites = 0L,
  n_shared_sites = 0L,
  n_unresolved_site_rows_audit = 0L
)]
development[, site_evidence_status := fcase(
  n_retained_sites_audit == 0L, "no_retained_site_record",
  source_site_unresolved_status != "none" | n_unresolved_site_rows_audit > 0L,
  "retained_sites_include_known_or_flagged_unresolved_rows",
  n_shared_sites > 0L, "retained_sites_include_unreviewed_shared_address",
  default = "retained_sites_not_individually_validated"
)]
development[, address_evidence_status := fcase(
  n_retained_sites_audit == 0L, "no_retained_site_record",
  n_candidate_site_queries > 0L & n_blocked_sites == 0L,
  "at_least_one_candidate_query_no_fully_blocked_site",
  n_candidate_site_queries > 0L, "candidate_and_blocked_sites",
  default = "all_retained_sites_blocked"
)]

raw_membership <- raw_site[, .(
  hud_id = unlist(strsplit(hud_ids, "|", fixed = TRUE))
), by = .(
  source_development_site_id = development_site_id,
  raw_development_id = development_id,
  site_key,
  street = site_street,
  city = site_city,
  state = site_state,
  zip = site_zip,
  raw_site_source = site_source
)]
final_membership <- site[, .(
  hud_id = unlist(strsplit(hud_ids, "|", fixed = TRUE))
), by = .(
  development_site_id,
  development_id,
  site_key
)]
pre_singleton_membership <- pre_singleton_site[, .(
  hud_id = unlist(strsplit(hud_ids, "|", fixed = TRUE))
), by = .(
  pre_singleton_development_site_id = development_site_id,
  site_key
)]
require_unique(raw_membership, c("hud_id", "site_key"), "Raw site membership")
require_unique(final_membership, c("hud_id", "site_key"), "Final site membership")
require_unique(pre_singleton_membership, c("hud_id", "site_key"), "Pre-singleton site membership")
if (nrow(raw_membership) != 138444L || nrow(final_membership) != 136618L) {
  stop("Source or final episode-site membership count changed")
}

raw_membership[final_membership, on = c("hud_id", "site_key"), `:=`(
  final_development_site_id = i.development_site_id,
  final_development_id = i.development_id
)]
raw_membership[pre_singleton_membership, on = c("hud_id", "site_key"),
  pre_singleton_development_site_id := i.pre_singleton_development_site_id]
raw_membership[episode[, .(hud_id, physical_development_id = development_id)],
  on = "hud_id", physical_development_id := i.physical_development_id]
raw_membership[development_identity_status[, .(
  physical_development_id = development_id,
  physical_identity_evidence_status = parent_identity_evidence_status
)], on = "physical_development_id", physical_identity_evidence_status :=
  i.physical_identity_evidence_status]
raw_membership[excluded_episode[, .(
  hud_id,
  excluded_development_id = development_id,
  unit_scope_exclusion_status
)], on = "hud_id", `:=`(
  excluded_development_id = i.excluded_development_id,
  unit_scope_exclusion_status = i.unit_scope_exclusion_status
)]

source_membership_decision <- source_site_decision[, .(
  hud_id = unlist(strsplit(hud_ids, "|", fixed = TRUE))
), by = .(
  site_key,
  source_site_operative_action = operative_site_action,
  source_site_decision_status = operative_decision_status,
  source_site_reviewed_on = final_reviewed_on,
  source_site_evidence_url = external_source_url
)]
require_unique(source_membership_decision, c("hud_id", "site_key"),
  "Source-site membership decision")
raw_membership[source_membership_decision, on = c("hud_id", "site_key"), `:=`(
  source_site_operative_action = i.source_site_operative_action,
  source_site_decision_status = i.source_site_decision_status,
  source_site_reviewed_on = i.source_site_reviewed_on,
  source_site_evidence_url = i.source_site_evidence_url
)]
raw_membership[singleton_site_decision[, .(
  pre_singleton_development_site_id = current_development_site_id,
  singleton_site_action = site_action,
  singleton_site_reviewed_on = reviewed_on,
  singleton_site_evidence_url = site_source_url
)], on = "pre_singleton_development_site_id", `:=`(
  singleton_site_action = i.singleton_site_action,
  singleton_site_reviewed_on = i.singleton_site_reviewed_on,
  singleton_site_evidence_url = i.singleton_site_evidence_url
)]

raw_membership[, membership_disposition := fcase(
  !is.na(final_development_site_id), "retained_in_final_site_table",
  unit_scope_exclusion_status == "outside_50_states_and_dc",
  "excluded_outside_50_states_and_dc",
  unit_scope_exclusion_status == "nonphysical_development_scope",
  "excluded_nonphysical_development_scope",
  source_site_operative_action == "remove_current_assignment",
  "source_review_remove_current_assignment",
  source_site_operative_action == "remove_redundant_address_variant",
  "source_review_remove_redundant_address_variant",
  source_site_operative_action == "remove_only_with_external_replacement",
  "source_review_remove_with_external_replacement",
  singleton_site_action == "drop_malformed_redundant_variant",
  "singleton_review_drop_malformed_redundant_variant",
  singleton_site_action == "drop_wrong_source_site",
  "singleton_review_drop_wrong_source_site",
  singleton_site_action == "drop_historical_redundant_address_alias",
  "singleton_review_drop_historical_redundant_address_alias",
  default = "unexplained_source_membership_disposition"
)]
if (raw_membership[membership_disposition == "unexplained_source_membership_disposition", .N] != 0L) {
  stop("A raw episode-site membership lacks a retained row or documented disposition")
}

expected_removed <- data.table(
  membership_disposition = c(
    "excluded_outside_50_states_and_dc",
    "excluded_nonphysical_development_scope",
    "source_review_remove_current_assignment",
    "source_review_remove_redundant_address_variant",
    "source_review_remove_with_external_replacement",
    "singleton_review_drop_malformed_redundant_variant",
    "singleton_review_drop_wrong_source_site",
    "singleton_review_drop_historical_redundant_address_alias"
  ),
  expected_n = c(961L, 152L, 645L, 30L, 8L, 23L, 8L, 1L)
)
observed_removed <- raw_membership[is.na(final_development_site_id),
  .(observed_n = .N), by = membership_disposition]
expected_removed[observed_removed, on = "membership_disposition", observed_n := i.observed_n]
if (expected_removed[is.na(observed_n) | observed_n != expected_n, .N] != 0L ||
    observed_removed[!membership_disposition %chin% expected_removed$membership_disposition, .N] != 0L) {
  stop("Documented raw membership removals changed")
}

external_membership <- final_membership[!raw_membership, on = c("hud_id", "site_key")]
if (nrow(external_membership) != 2L ||
    !all(external_membership$development_site_id %chin%
      site[site_source == "external_public_record", development_site_id])) {
  stop("Final external site additions changed")
}

site_status_for_membership <- site[, .(
  final_development_site_id = development_site_id,
  final_site_evidence_status = site_evidence_status,
  final_shared_address_status = shared_address_status
)]
require_unique(site_status_for_membership, "final_development_site_id",
  "Final membership site status")
raw_membership[site_status_for_membership, on = "final_development_site_id", `:=`(
  final_site_evidence_status = i.final_site_evidence_status,
  final_shared_address_status = i.final_shared_address_status
)]

pilot_status <- pilot[, .(
  geocoding_query_id,
  pilot_matched = matched,
  pilot_exact_match = exact_match
)]
pilot_status[, in_pilot_review_queue := geocoding_query_id %chin% pilot_review$geocoding_query_id]
pilot_status[, pilot_evidence_status := fcase(
  in_pilot_review_queue, "pilot_result_requires_manual_review",
  default = "pilot_result_not_flagged_but_still_unapproved"
)]
require_unique(pilot_status, "geocoding_query_id", "Pilot query status")
query[pilot_status, on = "geocoding_query_id", pilot_evidence_status := i.pilot_evidence_status]
query[is.na(pilot_evidence_status), pilot_evidence_status := "not_in_census_pilot"]

query_address_status <- query[, .(
  n_developments_at_query_address = uniqueN(development_id)
), by = .(query_street, query_city, query_state, query_zip)]
require_unique(query_address_status,
  c("query_street", "query_city", "query_state", "query_zip"),
  "Query address cross-development summary")
query[query_address_status, on = c(
  "query_street",
  "query_city",
  "query_state",
  "query_zip"
), n_developments_at_query_address := i.n_developments_at_query_address]
if (query[is.na(n_developments_at_query_address), .N] != 0L) {
  stop("A proposed query lacks its cross-development address status")
}
query[, shared_address_status := fcase(
  n_developments_at_query_address > 1L,
  "same_query_address_across_distinct_developments_unreviewed",
  n_source_sites > 1L,
  "query_shared_within_development_across_source_sites",
  default = "query_maps_to_one_source_site"
)]
query[, query_address_shared_status := shared_address_status]
component[query[, .(
  geocoding_query_id,
  pilot_evidence_status,
  query_address_shared_status
)], on = "geocoding_query_id", `:=`(
  pilot_evidence_status = i.pilot_evidence_status,
  query_address_shared_status = i.query_address_shared_status
)]
component[is.na(pilot_evidence_status), pilot_evidence_status := "not_in_census_pilot"]
component[is.na(query_address_shared_status),
  query_address_shared_status := "not_applicable_no_candidate_query"]

site_query_address_status <- component[, .(
  any_cross_development_query_address = any(
    query_address_shared_status ==
      "same_query_address_across_distinct_developments_unreviewed"
  ),
  any_candidate_query = any(!is.na(geocoding_query_id))
), by = development_site_id]
require_unique(site_query_address_status, "development_site_id",
  "Retained-site query-address summary")
site[site_query_address_status, on = "development_site_id", `:=`(
  any_cross_development_query_address = i.any_cross_development_query_address,
  any_candidate_query = i.any_candidate_query
)]
if (site[is.na(any_cross_development_query_address) | is.na(any_candidate_query), .N] != 0L) {
  stop("A retained site lacks its descendant query-address summary")
}
site[, query_address_shared_status := fcase(
  any_cross_development_query_address,
  "descendant_query_address_shared_across_distinct_developments_unreviewed",
  any_candidate_query, "descendant_query_addresses_not_shared_across_developments",
  default = "no_candidate_query"
)]

development_query_address_status <- site[, .(
  any_cross_development_query_address = any(
    query_address_shared_status ==
      "descendant_query_address_shared_across_distinct_developments_unreviewed"
  ),
  any_candidate_query = any(query_address_shared_status != "no_candidate_query")
), by = development_id]
require_unique(development_query_address_status, "development_id",
  "Development query-address summary")
development[development_query_address_status, on = "development_id", `:=`(
  any_cross_development_query_address = i.any_cross_development_query_address,
  any_candidate_query = i.any_candidate_query
)]
development[is.na(any_cross_development_query_address), `:=`(
  any_cross_development_query_address = FALSE,
  any_candidate_query = FALSE
)]
development[, query_address_shared_status := fcase(
  any_cross_development_query_address,
  "descendant_query_address_shared_across_distinct_developments_unreviewed",
  any_candidate_query, "descendant_query_addresses_not_shared_across_developments",
  default = "no_candidate_query"
)]

raw_membership[site[, .(
  final_development_site_id = development_site_id,
  final_query_address_shared_status = query_address_shared_status
)], on = "final_development_site_id",
final_query_address_shared_status := i.final_query_address_shared_status]

development_observation <- development[, .(
  observation_level = "development",
  observation_id = paste0("development|", development_id),
  development_id,
  hud_id = NA_character_,
  source_development_site_id = NA_character_,
  development_site_id = NA_character_,
  address_component_id = NA_character_,
  geocoding_query_id = NA_character_,
  display_name = development_name,
  street = NA_character_,
  city = development_city,
  state = development_state,
  zip = NA_character_,
  total_units = as.numeric(n_units_development),
  low_income_units = as.numeric(li_units_development),
  pis_year = as.integer(first_pis_year),
  allocation_year = NA_integer_,
  record_inclusion_status = "retained_physical_development_50_states_and_dc",
  provenance_status = "final_low_income_share_adjudicated_development",
  identity_evidence_status,
  site_evidence_status,
  unit_evidence_status,
  low_income_share_evidence_status,
  timing_evidence_status,
  address_evidence_status,
  coordinate_evidence_status = "not_assessed_at_development_level",
  shared_address_status = fifelse(
    n_shared_sites > 0L,
    "development_has_unreviewed_shared_site_key",
    "no_shared_site_key_in_retained_sites"
  ),
  query_address_shared_status,
  geocoding_evidence_status = "no_approved_geocoded_location",
  pilot_evidence_status = "not_assessed_at_development_level",
  review_source = "current_review_lineage_and_default_rules"
)]
development_observation[, acceptance_reason_codes := "no_approved_geocoded_location"]
development_observation[, acceptance_reason_codes := append_reason(
  acceptance_reason_codes,
  identity_evidence_status == "rule_based_singleton_not_individually_reviewed",
  "identity_not_individually_reviewed"
)]
development_observation[, acceptance_reason_codes := append_reason(
  acceptance_reason_codes,
  identity_evidence_status == "known_source_site_scope_unresolved",
  "known_source_site_scope_unresolved"
)]
development_observation[, acceptance_reason_codes := append_reason(
  acceptance_reason_codes,
  grepl("not_individually_reviewed|partial|no_static", unit_evidence_status),
  "unit_scope_not_fully_source_validated"
)]
development_observation[, acceptance_reason_codes := append_reason(
  acceptance_reason_codes,
  low_income_share_evidence_status %chin% c(
    "explicit_low_income_share_review_unresolved",
    "incomplete_units_excluded_from_low_income_share",
    "not_flagged_not_individually_source_validated"
  ),
  "low_income_share_not_fully_source_validated"
)]
development_observation[, acceptance_reason_codes := append_reason(
  acceptance_reason_codes,
  timing_evidence_status != "all_episode_timing_available",
  "episode_timing_incomplete"
)]
development_observation[, acceptance_reason_codes := append_reason(
  acceptance_reason_codes,
  rep(TRUE, .N),
  "site_inventory_requires_acceptance_review"
)]
development_observation[, acceptance_reason_codes := append_reason(
  acceptance_reason_codes,
  query_address_shared_status ==
    "descendant_query_address_shared_across_distinct_developments_unreviewed",
  "same_query_address_across_distinct_developments_unreviewed"
)]
development_observation[, acceptance_status := "not_accepted_dataset_frozen"]

episode_for_observation <- copy(episode)
episode_for_observation[development[, .(
  development_id,
  display_name = development_name,
  identity_evidence_status,
  development_site_evidence_status = site_evidence_status,
  development_unit_evidence_status = unit_evidence_status,
  low_income_share_evidence_status,
  development_address_evidence_status = address_evidence_status,
  development_shared_address_status = fifelse(
    n_shared_sites > 0L,
    "development_has_unreviewed_shared_site_key",
    "no_shared_site_key_in_retained_sites"
  ),
  development_query_address_shared_status = query_address_shared_status
)], on = "development_id", `:=`(
  display_name = i.display_name,
  identity_evidence_status = i.identity_evidence_status,
  development_site_evidence_status = i.development_site_evidence_status,
  development_unit_evidence_status = i.development_unit_evidence_status,
  low_income_share_evidence_status = i.low_income_share_evidence_status,
  development_address_evidence_status = i.development_address_evidence_status,
  development_shared_address_status = i.development_shared_address_status,
  development_query_address_shared_status = i.development_query_address_shared_status
)]
final_membership[site[, .(
  development_site_id,
  membership_site_evidence_status = site_evidence_status
)], on = "development_site_id", membership_site_evidence_status :=
  i.membership_site_evidence_status]
if (final_membership[is.na(membership_site_evidence_status), .N] != 0L) {
  stop("A final episode-site membership lacks its retained-site evidence status")
}
episode_site_count <- final_membership[, .(
  n_retained_site_memberships = .N,
  n_unresolved_site_memberships = sum(grepl(
    "unresolved|review_flag",
    membership_site_evidence_status
  ))
), by = hud_id]
require_unique(episode_site_count, "hud_id", "Episode retained-site summary")
episode_for_observation[episode_site_count, on = "hud_id", `:=`(
  n_retained_site_memberships = i.n_retained_site_memberships,
  n_unresolved_site_memberships = i.n_unresolved_site_memberships
)]
episode_for_observation[is.na(n_retained_site_memberships), `:=`(
  n_retained_site_memberships = 0L,
  n_unresolved_site_memberships = 0L
)]
episode_for_observation[, episode_unit_evidence_status := fcase(
  unit_scope_review_status == "reviewed", "episode_in_explicit_unit_scope_review",
  default = "episode_unit_values_not_individually_reviewed"
)]
episode_observation <- episode_for_observation[, .(
  observation_level = "episode",
  observation_id = paste0("episode|", hud_id),
  development_id,
  hud_id,
  source_development_site_id = NA_character_,
  development_site_id = NA_character_,
  address_component_id = NA_character_,
  geocoding_query_id = NA_character_,
  display_name,
  street = proj_add,
  city = proj_cty,
  state = proj_st,
  zip = proj_zip,
  total_units = as.numeric(episode_units),
  low_income_units = as.numeric(episode_low_income_units),
  pis_year = as.integer(pis_year),
  allocation_year = as.integer(allocation_year),
  record_inclusion_status = "retained_physical_episode_50_states_and_dc",
  provenance_status = "immutable_hud_episode_with_review_lineage",
  identity_evidence_status,
  site_evidence_status = fcase(
    n_retained_site_memberships == 0L, "no_retained_site_membership",
    n_unresolved_site_memberships > 0L, "retained_site_membership_includes_unresolved_row",
    default = "retained_site_membership_present_not_individually_validated"
  ),
  unit_evidence_status = episode_unit_evidence_status,
  low_income_share_evidence_status,
  timing_evidence_status,
  address_evidence_status = development_address_evidence_status,
  coordinate_evidence_status = "not_assessed_at_episode_level",
  shared_address_status = development_shared_address_status,
  query_address_shared_status = development_query_address_shared_status,
  geocoding_evidence_status = "no_approved_geocoded_location",
  pilot_evidence_status = "not_assessed_at_episode_level",
  review_source = "immutable_hud_episode_and_current_review_lineage",
  acceptance_reason_codes = "no_approved_geocoded_location",
  acceptance_status = "not_accepted_dataset_frozen"
)]
episode_observation[, acceptance_reason_codes := append_reason(
  acceptance_reason_codes,
  identity_evidence_status == "rule_based_singleton_not_individually_reviewed",
  "identity_not_individually_reviewed"
)]
episode_observation[, acceptance_reason_codes := append_reason(
  acceptance_reason_codes,
  identity_evidence_status == "known_source_site_scope_unresolved",
  "known_source_site_scope_unresolved"
)]
episode_observation[, acceptance_reason_codes := append_reason(
  acceptance_reason_codes,
  unit_evidence_status == "episode_unit_values_not_individually_reviewed",
  "episode_units_not_individually_reviewed"
)]
episode_observation[, acceptance_reason_codes := append_reason(
  acceptance_reason_codes,
  rep(TRUE, .N),
  "site_inventory_requires_acceptance_review"
)]
episode_observation[, acceptance_reason_codes := append_reason(
  acceptance_reason_codes,
  low_income_share_evidence_status %chin% c(
    "explicit_low_income_share_review_unresolved",
    "incomplete_units_excluded_from_low_income_share",
    "not_flagged_not_individually_source_validated"
  ),
  "low_income_share_not_fully_source_validated"
)]
episode_observation[, acceptance_reason_codes := append_reason(
  acceptance_reason_codes,
  timing_evidence_status != "pis_and_allocation_year_available",
  "episode_timing_incomplete"
)]
episode_observation[, acceptance_reason_codes := append_reason(
  acceptance_reason_codes,
  query_address_shared_status ==
    "descendant_query_address_shared_across_distinct_developments_unreviewed",
  "same_query_address_across_distinct_developments_unreviewed"
)]

excluded_observation <- excluded_episode[, .(
  observation_level = "episode",
  observation_id = paste0("episode|", hud_id),
  development_id,
  hud_id,
  source_development_site_id = NA_character_,
  development_site_id = NA_character_,
  address_component_id = NA_character_,
  geocoding_query_id = NA_character_,
  display_name = project,
  street = proj_add,
  city = proj_cty,
  state = proj_st,
  zip = proj_zip,
  total_units = suppressWarnings(as.numeric(n_unitsr)),
  low_income_units = suppressWarnings(as.numeric(li_unitr)),
  pis_year = as.integer(pis_year),
  allocation_year = as.integer(allocation_year),
  record_inclusion_status = unit_scope_exclusion_status,
  provenance_status = "immutable_hud_episode_documented_exclusion",
  identity_evidence_status = unit_scope_exclusion_status,
  site_evidence_status = "source_site_memberships_documented_separately",
  unit_evidence_status = "not_in_physical_development_unit_scope",
  low_income_share_evidence_status = fifelse(
    unit_scope_exclusion_status == "outside_50_states_and_dc",
    "outside_50_states_and_dc_share_universe",
    "nonphysical_development_outside_physical_share_universe"
  ),
  timing_evidence_status = fcase(
    !is.na(pis_year) & !is.na(allocation_year), "pis_and_allocation_year_available",
    is.na(pis_year) & !is.na(allocation_year), "pis_year_unavailable",
    !is.na(pis_year) & is.na(allocation_year), "allocation_year_unavailable",
    default = "pis_and_allocation_year_unavailable"
  ),
  address_evidence_status = fifelse(
    unit_scope_exclusion_status == "outside_50_states_and_dc",
    "outside_50_states_and_dc_geography_universe",
    "nonphysical_development_outside_physical_geography_universe"
  ),
  coordinate_evidence_status = "not_assessed_for_excluded_episode",
  shared_address_status = "not_assessed_for_excluded_episode",
  query_address_shared_status = "not_assessed_for_excluded_episode",
  geocoding_evidence_status = "documented_exclusion_no_geocoding",
  pilot_evidence_status = "not_in_census_pilot",
  review_source = "unit_scope_exclusion_partition",
  acceptance_reason_codes = unit_scope_exclusion_status,
  acceptance_status = "documented_exclusion_not_in_final_dataset"
)]
episode_observation <- rbindlist(list(episode_observation, excluded_observation), use.names = TRUE)
require_unique(episode_observation, "observation_id", "All-episode acceptance inventory")
if (nrow(episode_observation) != 55345L) {
  stop("All-episode acceptance inventory is incomplete")
}

membership_observation <- raw_membership[, .(
  observation_level = "source_site_membership",
  observation_id = paste0("source_site_membership|", hud_id, "|", site_key),
  development_id = fifelse(
    !is.na(physical_development_id),
    physical_development_id,
    fifelse(!is.na(excluded_development_id), excluded_development_id, raw_development_id)
  ),
  hud_id,
  source_development_site_id,
  development_site_id = final_development_site_id,
  address_component_id = NA_character_,
  geocoding_query_id = NA_character_,
  display_name = NA_character_,
  street,
  city,
  state,
  zip,
  total_units = NA_real_,
  low_income_units = NA_real_,
  pis_year = NA_integer_,
  allocation_year = NA_integer_,
  record_inclusion_status = membership_disposition,
  provenance_status = "raw_hud_episode_site_membership",
  identity_evidence_status = fifelse(
    !is.na(unit_scope_exclusion_status),
    unit_scope_exclusion_status,
    physical_identity_evidence_status
  ),
  site_evidence_status = fifelse(
    !is.na(final_development_site_id),
    final_site_evidence_status,
    membership_disposition
  ),
  unit_evidence_status = "not_applicable_to_site_membership",
  low_income_share_evidence_status = "not_applicable_to_site_membership",
  timing_evidence_status = "not_applicable_to_site_membership",
  address_evidence_status = fifelse(
    !is.na(final_development_site_id),
    "address_assessed_on_retained_site_component",
    "source_address_removed_or_excluded"
  ),
  coordinate_evidence_status = "not_assessed_at_source_membership_level",
  shared_address_status = fifelse(
    !is.na(final_development_site_id),
    final_shared_address_status,
    "not_applicable_to_removed_or_excluded_membership"
  ),
  query_address_shared_status = fifelse(
    !is.na(final_development_site_id),
    final_query_address_shared_status,
    "not_applicable_to_removed_or_excluded_membership"
  ),
  geocoding_evidence_status = fifelse(
    !is.na(final_development_site_id),
    "retained_membership_no_approved_geocode",
    "removed_or_excluded_no_geocoding"
  ),
  pilot_evidence_status = "not_assessed_at_source_membership_level",
  review_source = fcase(
    membership_disposition == "retained_in_final_site_table",
    "raw_to_final_site_membership_lineage",
    grepl("source_review", membership_disposition), "source_site_exception_ledger",
    grepl("singleton_review", membership_disposition), "singleton_site_decision_ledger",
    default = "unit_scope_exclusion_partition"
  ),
  acceptance_reason_codes = membership_disposition,
  acceptance_status = fifelse(
    membership_disposition == "retained_in_final_site_table",
    "retained_not_accepted_dataset_frozen",
    "documented_disposition_not_in_final_dataset"
  )
)]

external_membership[site[, .(
  development_site_id,
  site_street,
  site_city,
  site_state,
  site_zip,
  site_evidence_status,
  shared_address_status,
  query_address_shared_status,
  identity_evidence_status
)], on = "development_site_id", `:=`(
  street = i.site_street,
  city = i.site_city,
  state = i.site_state,
  zip = i.site_zip,
  site_evidence_status = i.site_evidence_status,
  shared_address_status = i.shared_address_status,
  query_address_shared_status = i.query_address_shared_status,
  identity_evidence_status = i.identity_evidence_status
)]
external_membership_observation <- external_membership[, .(
  observation_level = "source_site_membership",
  observation_id = paste0("external_site_membership|", hud_id, "|", site_key),
  development_id,
  hud_id,
  source_development_site_id = NA_character_,
  development_site_id,
  address_component_id = NA_character_,
  geocoding_query_id = NA_character_,
  display_name = NA_character_,
  street,
  city,
  state,
  zip,
  total_units = NA_real_,
  low_income_units = NA_real_,
  pis_year = NA_integer_,
  allocation_year = NA_integer_,
  record_inclusion_status = "external_public_record_site_addition",
  provenance_status = "external_public_record_site_membership",
  identity_evidence_status,
  site_evidence_status,
  unit_evidence_status = "not_applicable_to_site_membership",
  low_income_share_evidence_status = "not_applicable_to_site_membership",
  timing_evidence_status = "not_applicable_to_site_membership",
  address_evidence_status = "external_address_still_not_geocoding_approved",
  coordinate_evidence_status = "coordinate_missing",
  shared_address_status,
  query_address_shared_status,
  geocoding_evidence_status = "retained_membership_no_approved_geocode",
  pilot_evidence_status = "not_assessed_at_source_membership_level",
  review_source = "external_source_site_or_singleton_addition_ledger",
  acceptance_reason_codes = "external_addition_still_not_geocoding_approved",
  acceptance_status = "retained_not_accepted_dataset_frozen"
)]
membership_observation <- rbindlist(
  list(membership_observation, external_membership_observation),
  use.names = TRUE
)
membership_observation[, acceptance_reason_codes := append_reason(
  acceptance_reason_codes,
  identity_evidence_status == "rule_based_singleton_not_individually_reviewed",
  "parent_identity_not_individually_reviewed"
)]
membership_observation[, acceptance_reason_codes := append_reason(
  acceptance_reason_codes,
  identity_evidence_status == "known_source_site_scope_unresolved",
  "known_source_site_scope_unresolved"
)]
membership_observation[, acceptance_reason_codes := append_reason(
  acceptance_reason_codes,
  query_address_shared_status ==
    "descendant_query_address_shared_across_distinct_developments_unreviewed",
  "same_query_address_across_distinct_developments_unreviewed"
)]
require_unique(membership_observation, "observation_id", "Source membership acceptance inventory")
if (nrow(membership_observation) != 138446L) {
  stop("Source membership acceptance inventory is incomplete")
}

site_observation <- site[, .(
  observation_level = "retained_site",
  observation_id = paste0("retained_site|", development_site_id),
  development_id,
  hud_id = NA_character_,
  source_development_site_id = NA_character_,
  development_site_id,
  address_component_id = NA_character_,
  geocoding_query_id = NA_character_,
  display_name = NA_character_,
  street = site_street,
  city = site_city,
  state = site_state,
  zip = site_zip,
  total_units = as.numeric(n_units_physical_development),
  low_income_units = as.numeric(li_units_physical_development),
  pis_year = NA_integer_,
  allocation_year = NA_integer_,
  record_inclusion_status = "retained_final_site",
  provenance_status = source_site_row_origin,
  identity_evidence_status,
  site_evidence_status,
  unit_evidence_status = unit_scope_review_status,
  low_income_share_evidence_status = low_income_share_analysis_status,
  timing_evidence_status = "not_assessed_at_site_level",
  address_evidence_status,
  coordinate_evidence_status,
  shared_address_status,
  query_address_shared_status,
  geocoding_evidence_status = fifelse(
    n_candidate_components > 0L,
    "candidate_query_exists_but_not_approved",
    "no_candidate_query"
  ),
  pilot_evidence_status = "not_assessed_at_site_level",
  review_source = fcase(
    site_evidence_status == "external_public_record_addition", "external_site_addition_ledger",
    grepl("source_site", site_evidence_status), "source_site_exception_ledger",
    grepl("singleton", site_evidence_status), "singleton_site_decision_ledger",
    default = "inherited_without_individual_site_decision"
  ),
  acceptance_status = "retained_not_accepted_dataset_frozen"
)]
site_observation[, acceptance_reason_codes := "no_approved_geocoded_location"]
site_observation[, acceptance_reason_codes := append_reason(
  acceptance_reason_codes,
  grepl("inherited_without_site_decision", site_evidence_status),
  "site_not_individually_reviewed"
)]
site_observation[, acceptance_reason_codes := append_reason(
  acceptance_reason_codes,
  grepl("unresolved|review_flag", site_evidence_status),
  "site_known_or_flagged_unresolved"
)]
site_observation[, acceptance_reason_codes := append_reason(
  acceptance_reason_codes,
  shared_address_status != "not_shared_across_final_developments",
  "shared_address_not_adjudicated_for_query_reuse"
)]
site_observation[, acceptance_reason_codes := append_reason(
  acceptance_reason_codes,
  address_evidence_status != "all_components_candidate_unapproved",
  "address_component_blocked_or_mixed"
)]
site_observation[, acceptance_reason_codes := append_reason(
  acceptance_reason_codes,
  coordinate_evidence_status != "coordinate_internally_plausible_external_validation_pending",
  "coordinate_missing_or_requires_review"
)]
site_observation[, acceptance_reason_codes := append_reason(
  acceptance_reason_codes,
  identity_evidence_status == "rule_based_singleton_not_individually_reviewed",
  "parent_identity_not_individually_reviewed"
)]
site_observation[, acceptance_reason_codes := append_reason(
  acceptance_reason_codes,
  identity_evidence_status == "known_source_site_scope_unresolved",
  "known_source_site_scope_unresolved"
)]
site_observation[, acceptance_reason_codes := append_reason(
  acceptance_reason_codes,
  query_address_shared_status ==
    "descendant_query_address_shared_across_distinct_developments_unreviewed",
  "same_query_address_across_distinct_developments_unreviewed"
)]

component_observation <- component[, .(
  observation_level = "address_component",
  observation_id = paste0("address_component|", development_site_address_component_id),
  development_id,
  hud_id = NA_character_,
  source_development_site_id = NA_character_,
  development_site_id,
  address_component_id = development_site_address_component_id,
  geocoding_query_id,
  display_name = NA_character_,
  street = component_street,
  city = component_city,
  state = component_state,
  zip = component_zip,
  total_units = NA_real_,
  low_income_units = NA_real_,
  pis_year = NA_integer_,
  allocation_year = NA_integer_,
  record_inclusion_status = crosswalk_query_status,
  provenance_status = address_component_action,
  identity_evidence_status,
  site_evidence_status,
  unit_evidence_status = parent_downstream_unit_analysis_status,
  low_income_share_evidence_status = "not_carried_into_address_crosswalk",
  timing_evidence_status = "not_assessed_at_address_component_level",
  address_evidence_status,
  coordinate_evidence_status = coordinate_readiness_status,
  shared_address_status,
  query_address_shared_status,
  geocoding_evidence_status = fifelse(
    !is.na(geocoding_query_id),
    "candidate_query_exists_but_not_approved",
    "no_candidate_query"
  ),
  pilot_evidence_status,
  review_source = fcase(
    !is.na(range_address_question_id), "range_two_read_ledger",
    !is.na(compound_address_question_id), "compound_two_read_ledger",
    default = "inherited_readiness_rule"
  ),
  acceptance_status = fifelse(
    crosswalk_query_status == "excluded_nonphysical_range_description",
    "documented_exclusion_not_in_final_dataset",
    "retained_not_accepted_dataset_frozen"
  )
)]
component_observation[, acceptance_reason_codes := fcase(
  geocoding_evidence_status == "candidate_query_exists_but_not_approved",
  "candidate_query_not_real_world_validated",
  default = address_evidence_status
)]
component_observation[, acceptance_reason_codes := append_reason(
  acceptance_reason_codes,
  grepl("inherited_without_site_decision|unresolved|review_flag", site_evidence_status),
  "parent_site_not_affirmatively_accepted"
)]
component_observation[, acceptance_reason_codes := append_reason(
  acceptance_reason_codes,
  shared_address_status != "not_shared_across_final_developments",
  "shared_address_not_adjudicated_for_query_reuse"
)]
component_observation[, acceptance_reason_codes := append_reason(
  acceptance_reason_codes,
  coordinate_evidence_status != "internally_plausible_external_address_validation_pending",
  "coordinate_missing_or_requires_review"
)]
component_observation[, acceptance_reason_codes := append_reason(
  acceptance_reason_codes,
  identity_evidence_status == "rule_based_singleton_not_individually_reviewed",
  "parent_identity_not_individually_reviewed"
)]
component_observation[, acceptance_reason_codes := append_reason(
  acceptance_reason_codes,
  identity_evidence_status == "known_source_site_scope_unresolved",
  "known_source_site_scope_unresolved"
)]
component_observation[, acceptance_reason_codes := append_reason(
  acceptance_reason_codes,
  query_address_shared_status ==
    "same_query_address_across_distinct_developments_unreviewed",
  "same_query_address_across_distinct_developments_unreviewed"
)]

query_observation <- query[, .(
  observation_level = "geocoding_query",
  observation_id = paste0("geocoding_query|", geocoding_query_id),
  development_id,
  hud_id = NA_character_,
  source_development_site_id = NA_character_,
  development_site_id = NA_character_,
  address_component_id = NA_character_,
  geocoding_query_id,
  display_name = NA_character_,
  street = query_street,
  city = query_city,
  state = query_state,
  zip = query_zip,
  total_units = NA_real_,
  low_income_units = NA_real_,
  pis_year = NA_integer_,
  allocation_year = NA_integer_,
  record_inclusion_status = "candidate_query_not_approved",
  provenance_status = query_basis,
  identity_evidence_status = NA_character_,
  site_evidence_status = "source_sites_linked_in_component_crosswalk",
  unit_evidence_status = "not_applicable_to_geocoding_query",
  low_income_share_evidence_status = "not_carried_into_geocoding_query",
  timing_evidence_status = "not_applicable_to_geocoding_query",
  address_evidence_status = "locally_prepared_query_not_real_world_validated",
  coordinate_evidence_status = coordinate_readiness_examples,
  shared_address_status,
  query_address_shared_status,
  geocoding_evidence_status = "submission_not_approved",
  pilot_evidence_status,
  review_source = "local_query_construction_only",
  acceptance_reason_codes = fifelse(
    pilot_evidence_status == "pilot_result_requires_manual_review",
    "submission_not_approved|pilot_result_requires_manual_review",
    "submission_not_approved|query_not_real_world_validated"
  ),
  acceptance_status = "retained_not_accepted_dataset_frozen"
)]
query_observation[development_identity_status, on = "development_id",
  identity_evidence_status := i.parent_identity_evidence_status]
if (query_observation[is.na(identity_evidence_status), .N] != 0L) {
  stop("A proposed query lacks its parent development identity status")
}
query_observation[, acceptance_reason_codes := append_reason(
  acceptance_reason_codes,
  identity_evidence_status == "rule_based_singleton_not_individually_reviewed",
  "parent_identity_not_individually_reviewed"
)]
query_observation[, acceptance_reason_codes := append_reason(
  acceptance_reason_codes,
  identity_evidence_status == "known_source_site_scope_unresolved",
  "known_source_site_scope_unresolved"
)]
query_observation[, acceptance_reason_codes := append_reason(
  acceptance_reason_codes,
  shared_address_status == "same_query_address_across_distinct_developments_unreviewed",
  "same_query_address_across_distinct_developments_unreviewed"
)]

acceptance_inventory <- rbindlist(list(
  development_observation,
  episode_observation,
  membership_observation,
  site_observation,
  component_observation,
  query_observation
), use.names = TRUE, fill = TRUE)
setcolorder(acceptance_inventory, c(
  "observation_level",
  "observation_id",
  "development_id",
  "hud_id",
  "source_development_site_id",
  "development_site_id",
  "address_component_id",
  "geocoding_query_id"
))
require_unique(acceptance_inventory, c("observation_level", "observation_id"),
  "Complete dataset acceptance inventory")

expected_level_counts <- data.table(
  observation_level = c(
    "development",
    "episode",
    "source_site_membership",
    "retained_site",
    "address_component",
    "geocoding_query"
  ),
  expected_n = c(53469L, 55345L, 138446L, 131473L, 137255L, 83734L)
)
observed_level_counts <- acceptance_inventory[, .(observed_n = .N), by = observation_level]
expected_level_counts[observed_level_counts, on = "observation_level", observed_n := i.observed_n]
if (expected_level_counts[is.na(observed_n) | observed_n != expected_n, .N] != 0L ||
    observed_level_counts[!observation_level %chin% expected_level_counts$observation_level, .N] != 0L) {
  stop("Complete dataset acceptance inventory has the wrong observation-level coverage")
}
if (acceptance_inventory[is.na(acceptance_status) | acceptance_status == "", .N] != 0L ||
    acceptance_inventory[is.na(acceptance_reason_codes) | acceptance_reason_codes == "", .N] != 0L) {
  stop("An acceptance inventory row lacks a status or reason")
}
if (acceptance_inventory[
      observation_level == "development" &
        !grepl("site_inventory_requires_acceptance_review", acceptance_reason_codes),
      .N
    ] != 0L ||
    acceptance_inventory[
      observation_level == "episode" &
        record_inclusion_status == "retained_physical_episode_50_states_and_dc" &
        !grepl("site_inventory_requires_acceptance_review", acceptance_reason_codes),
      .N
    ] != 0L ||
    acceptance_inventory[
      observation_level == "episode" &
        low_income_share_evidence_status %chin% c(
          "explicit_low_income_share_review_unresolved",
          "incomplete_units_excluded_from_low_income_share",
          "not_flagged_not_individually_source_validated"
        ) &
        !grepl("low_income_share_not_fully_source_validated", acceptance_reason_codes),
      .N
    ] != 0L ||
    acceptance_inventory[
      identity_evidence_status == "inherits_final_development_identity_status",
      .N
    ] != 0L ||
    acceptance_inventory[
      observation_level %chin% c(
        "source_site_membership",
        "retained_site",
        "address_component",
        "geocoding_query"
      ) &
        identity_evidence_status == "known_source_site_scope_unresolved" &
        !grepl("known_source_site_scope_unresolved", acceptance_reason_codes),
      .N
    ] != 0L) {
  stop("Acceptance reason codes understate a known parent evidence gap")
}

observed_cross_development_queries <- query[
  shared_address_status == "same_query_address_across_distinct_developments_unreviewed",
  .N
]
if (observed_cross_development_queries != 4L ||
    query[
      shared_address_status == "same_query_address_across_distinct_developments_unreviewed" &
        n_developments_at_query_address != 2L,
      .N
    ] != 0L) {
  stop("Cross-development duplicate query-address inventory changed")
}
if (acceptance_inventory[
      grepl(
        "query_address_shared_across_distinct_developments_unreviewed",
        query_address_shared_status
      ) &
        !grepl(
          "same_query_address_across_distinct_developments_unreviewed",
          acceptance_reason_codes
        ),
      .N
    ] != 0L ||
    component[
      query_address_shared_status ==
        "same_query_address_across_distinct_developments_unreviewed",
      uniqueN(development_site_address_component_id)
    ] != 4L) {
  stop("Cross-development query-address risk did not propagate to every affected observation")
}

status_columns <- c(
  "record_inclusion_status",
  "provenance_status",
  "identity_evidence_status",
  "site_evidence_status",
  "unit_evidence_status",
  "low_income_share_evidence_status",
  "timing_evidence_status",
  "address_evidence_status",
  "coordinate_evidence_status",
  "shared_address_status",
  "query_address_shared_status",
  "geocoding_evidence_status",
  "pilot_evidence_status",
  "acceptance_status"
)
acceptance_status_counts <- rbindlist(lapply(status_columns, function(status_column) {
  acceptance_inventory[, .(
    n_observations = .N
  ), by = .(
    observation_level,
    status_value = get(status_column)
  )][, status_dimension := status_column]
}), use.names = TRUE)
setcolorder(acceptance_status_counts, c(
  "observation_level",
  "status_dimension",
  "status_value",
  "n_observations"
))
if (acceptance_status_counts[is.na(status_value) | status_value == "", .N] != 0L) {
  stop("A summarized acceptance dimension has a missing status")
}

write_parquet(
  acceptance_inventory,
  "../output/lihtc_dataset_acceptance_observations.parquet"
)
write_parquet(
  acceptance_status_counts,
  "../output/lihtc_dataset_acceptance_status_counts.parquet"
)

acceptance_inventory_check <- as.data.table(read_parquet(
  "../output/lihtc_dataset_acceptance_observations.parquet"
))
acceptance_status_counts_check <- as.data.table(read_parquet(
  "../output/lihtc_dataset_acceptance_status_counts.parquet"
))
if (!identical(acceptance_inventory, acceptance_inventory_check) ||
    !identical(acceptance_status_counts, acceptance_status_counts_check)) {
  stop("Acceptance audit Parquet round trip changed values")
}

shared_site_keys <- shared_key[n_developments_at_site_key > 1L, .N]
shared_site_rows <- site[n_developments_at_site_key > 1L, .N]
shared_developments <- uniqueN(site[n_developments_at_site_key > 1L, development_id])

summary_lines <- c(
  "# LIHTC dataset acceptance status",
  "",
  "**Status: frozen. The current data are not accepted for geocoding, tract assignment, or substantive analysis.**",
  "",
  "This audit inventories the present pipeline; it does not certify the observations.",
  "",
  "## Complete observation coverage",
  "",
  paste0("- Physical developments: ", format(nrow(development), big.mark = ",")),
  paste0("- Source financing episodes: ", format(nrow(raw_episode), big.mark = ","),
    " (", format(nrow(episode), big.mark = ","), " physical; ",
    format(nrow(excluded_episode), big.mark = ","), " documented exclusions)"),
  paste0("- Raw episode-site memberships plus external additions: ",
    format(nrow(membership_observation), big.mark = ",")),
  paste0("- Retained final sites: ", format(nrow(site), big.mark = ",")),
  paste0("- Address components: ", format(nrow(component), big.mark = ",")),
  paste0("- Proposed queries: ", format(nrow(query), big.mark = ","),
    "; approved queries: 0"),
  "",
  "## Identity and source-site acceptance gaps",
  "",
  paste0("- Rows carrying the source linkage label `singleton`: ",
    format(development[development_linkage_status == "singleton", .N], big.mark = ","),
    "; one is routed below to known incomplete site inventory rather than the default queue"),
  paste0("- Rule-based singleton developments without individual identity review: ",
    format(development[identity_evidence_status ==
      "rule_based_singleton_not_individually_reviewed", .N], big.mark = ",")),
  paste0("- Developments with a known unresolved source-site scope: ",
    format(development[identity_evidence_status ==
      "known_source_site_scope_unresolved", .N], big.mark = ",")),
  paste0("- Developments with no retained site: ",
    format(development[n_retained_sites_audit == 0L, .N], big.mark = ",")),
  paste0("- Retained site rows inherited without an individual site decision: ",
    format(site[grepl("^inherited_without_site_decision", site_evidence_status), .N],
      big.mark = ",")),
  paste0("- Those inherited rows already carrying a review flag: ",
    format(site[site_evidence_status ==
      "inherited_without_site_decision_review_flag_present", .N], big.mark = ",")),
  paste0("- Exact site keys shared across final developments: ",
    format(shared_site_keys, big.mark = ","), " keys, ",
    format(shared_site_rows, big.mark = ","), " retained rows, ",
    format(shared_developments, big.mark = ","), " developments"),
  "",
  "## Raw site-membership reconciliation",
  "",
  paste0("- Raw memberships retained in the final site table: ",
    format(raw_membership[membership_disposition == "retained_in_final_site_table", .N],
      big.mark = ",")),
  paste0("- Raw memberships with a documented exclusion or removal: ",
    format(raw_membership[membership_disposition != "retained_in_final_site_table", .N],
      big.mark = ",")),
  paste0("- External site memberships added after the raw build: ",
    format(nrow(external_membership), big.mark = ",")),
  "- Unexplained raw membership losses: 0",
  "",
  "## Units, timing, and geography",
  "",
  paste0("- Developments whose unit scope was not individually reviewed: ",
    format(development[unit_scope_review_status != "reviewed", .N], big.mark = ",")),
  paste0("- Developments missing both final unit counts: ",
    format(development[is.na(n_units_development) & is.na(li_units_development), .N],
      big.mark = ",")),
  paste0("- Episodes with unavailable PIS year: ",
    format(episode[is.na(pis_year), .N], big.mark = ",")),
  paste0("- Episodes with unavailable allocation year: ",
    format(episode[is.na(allocation_year), .N], big.mark = ",")),
  paste0("- Candidate address components, still unapproved: ",
    format(component[crosswalk_query_status == "ready_for_local_geocoding_pilot", .N],
      big.mark = ",")),
  paste0("- Blocked or excluded address components: ",
    format(component[crosswalk_query_status != "ready_for_local_geocoding_pilot", .N],
      big.mark = ",")),
  paste0("- Census pilot queries requiring manual review: ",
    format(nrow(pilot_review), big.mark = ","), " of ",
    format(nrow(pilot), big.mark = ",")),
  "",
  "## Governing acceptance rule",
  "",
  "No downstream work resumes until each default or unresolved class is replaced by an approved evidence rule or observation-level decision, the full inventory is independently audited, and the researcher explicitly accepts the resulting dataset."
)
writeLines(summary_lines, "../output/dataset_acceptance_summary.md")

if (!file.exists("../output/dataset_acceptance_summary.md") ||
    length(readLines("../output/dataset_acceptance_summary.md", warn = FALSE)) == 0L) {
  stop("Acceptance summary validation failed")
}
