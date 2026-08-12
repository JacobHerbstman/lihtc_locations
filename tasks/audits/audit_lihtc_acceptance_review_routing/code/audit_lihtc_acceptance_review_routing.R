# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/audit_lihtc_acceptance_review_routing/code")

suppressPackageStartupMessages({ library(arrow); library(data.table) })

development <- as.data.table(read_parquet("../input/lihtc_development_2024_low_income_share_adjudicated.parquet"))
episode <- as.data.table(read_parquet("../input/lihtc_project_episode_2024_low_income_share_adjudicated.parquet"))
site <- as.data.table(read_parquet("../input/lihtc_development_site_2024_low_income_share_adjudicated.parquet"))
acceptance <- as.data.table(read_parquet("../input/lihtc_dataset_acceptance_observations.parquet"))[observation_level == "development"]
shared <- as.data.table(read_parquet("../input/lihtc_shared_site_network_development_members.parquet"))
no_site <- as.data.table(read_parquet("../input/lihtc_no_site_development_questions.parquet"))
site_exception <- as.data.table(read_parquet("../input/lihtc_site_exception_questions.parquet"))

if (nrow(development) != 53469L || nrow(episode) != 54902L || nrow(site) != 131473L ||
    uniqueN(development$development_id) != nrow(development) || uniqueN(episode$hud_id) != nrow(episode) ||
    uniqueN(site$development_site_id) != nrow(site) || uniqueN(acceptance$development_id) != nrow(acceptance) ||
    uniqueN(shared$development_id) != nrow(shared) || uniqueN(no_site$development_id) != nrow(no_site) ||
    uniqueN(site_exception$development_id) != nrow(site_exception) ||
    nrow(acceptance) != nrow(development) || !setequal(acceptance$development_id, development$development_id) ||
    any(!shared$development_id %chin% development$development_id) ||
    any(!no_site$development_id %chin% development$development_id) ||
    any(!site_exception$development_id %chin% development$development_id) ||
    any(!episode$development_id %chin% development$development_id) || any(!site$development_id %chin% development$development_id)) {
  stop("An input key or final LIHTC row-count contract failed.", call. = FALSE)
}

site_summary <- site[, .(n_retained_sites = .N, n_project_primary_sites = sum(site_source == "project_primary")), by = development_id]
episode_summary <- episode[, .(n_retained_episodes = .N), by = development_id]
shared_summary <- shared[, .(shared_site_network_ids = paste(sort(unique(shared_site_network_id)), collapse = "|")), by = development_id]
development[site_summary, `:=`(n_retained_sites = i.n_retained_sites, n_project_primary_sites = i.n_project_primary_sites), on = "development_id"]
development[is.na(n_retained_sites), `:=`(n_retained_sites = 0L, n_project_primary_sites = 0L)]
development[episode_summary, n_retained_episodes := i.n_retained_episodes, on = "development_id"]
development[acceptance, `:=`(acceptance_site_evidence_status = i.site_evidence_status, acceptance_identity_evidence_status = i.identity_evidence_status, acceptance_status = i.acceptance_status), on = "development_id"]
development[shared_summary, shared_site_network_ids := i.shared_site_network_ids, on = "development_id"]
development[site_exception, site_exception_review_question_id := i.site_exception_review_question_id, on = "development_id"]
development[no_site, no_site_review_question_id := i.no_site_review_question_id, on = "development_id"]

# Only the unresolved prepared site-exception queue takes priority. Four
# explicitly resolved/addition cases (Mechanic Mill, Springfield Village,
# Savannah Gateway, and Trinity Oaks) are not silently re-routed as exceptions.
development[, site_exception_or_flag := !is.na(site_exception_review_question_id)]
development[, `:=`(
  no_retained_site = !is.na(no_site_review_question_id),
  shared_site_network = !is.na(shared_site_network_ids),
  explicit_identity_review_nonblocked = development_linkage_status != "singleton" | !is.na(singleton_identity_scope_review_ids)
)]
development[, routing_status := fcase(
  site_exception_or_flag, "site_exception_or_flag",
  no_retained_site, "no_retained_site",
  shared_site_network, "shared_site_network",
  explicit_identity_review_nonblocked, "explicit_identity_review_nonblocked",
  n_retained_sites == 1L & n_project_primary_sites == 1L, "default_singleton_one_primary_site",
  n_retained_sites == 1L, "default_singleton_one_nonprimary_site",
  default = "default_singleton_multisite"
)]
development[, routing_priority := match(routing_status, c("site_exception_or_flag", "no_retained_site", "shared_site_network", "explicit_identity_review_nonblocked", "default_singleton_one_primary_site", "default_singleton_one_nonprimary_site", "default_singleton_multisite"))]

if (anyNA(development$n_retained_episodes) || any(development$n_retained_sites != development$n_development_sites) ||
    any(development$no_retained_site != (development$n_retained_sites == 0L)) ||
    any(development[routing_status == "default_singleton_one_primary_site", n_project_primary_sites != 1L]) ||
    any(development[routing_status == "default_singleton_one_nonprimary_site", n_project_primary_sites != 0L]) ||
    any(development$acceptance_status != "not_accepted_dataset_frozen")) {
  stop("A routing foreign key, singleton distinction, or acceptance-status contract failed.", call. = FALSE)
}

counts <- development[, .(n_developments = .N), by = .(routing_priority, routing_status)][order(routing_priority)]
expected_routes <- c("site_exception_or_flag", "no_retained_site", "shared_site_network", "explicit_identity_review_nonblocked", "default_singleton_one_primary_site", "default_singleton_one_nonprimary_site", "default_singleton_multisite")
if (!identical(counts$routing_status, expected_routes) || sum(counts$n_developments) != nrow(development) ||
    uniqueN(development$development_id) != nrow(development) ||
    !identical(counts$n_developments, c(211L, 797L, 5928L, 913L, 28701L, 9214L, 7705L)) ||
    sum(development$site_exception_or_flag & development$shared_site_network) != 43L) {
  stop("The routing partition has a hidden remainder or duplicate route.", call. = FALSE)
}

routing <- development[, .(development_id, development_name, development_state, development_city, n_retained_sites, n_project_primary_sites, n_retained_episodes, acceptance_identity_evidence_status, acceptance_site_evidence_status, acceptance_status, site_exception_review_question_id, no_site_review_question_id, shared_site_network_ids, source_site_group_decision, source_site_unresolved_status, singleton_identity_scope_review_ids, routing_priority, routing_status)]
setorder(routing, routing_priority, development_state, development_id)
write_parquet(routing, "../output/lihtc_acceptance_review_routing.parquet", compression = "zstd")
write_parquet(counts, "../output/lihtc_acceptance_review_routing_status_counts.parquet", compression = "zstd")

routing_roundtrip <- as.data.table(read_parquet("../output/lihtc_acceptance_review_routing.parquet"))
counts_roundtrip <- as.data.table(read_parquet("../output/lihtc_acceptance_review_routing_status_counts.parquet"))
if (!isTRUE(all.equal(routing, routing_roundtrip)) || !isTRUE(all.equal(counts, counts_roundtrip))) stop("A routing Parquet round trip changed data.", call. = FALSE)
message("Routed ", nrow(routing), " developments across ", nrow(counts), " read-only acceptance-review routes.")
