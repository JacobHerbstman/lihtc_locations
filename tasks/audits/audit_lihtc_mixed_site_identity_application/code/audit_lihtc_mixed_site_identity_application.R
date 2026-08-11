# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/audit_lihtc_mixed_site_identity_application/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
})

development_before <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_source_site_repaired.parquet"
))
episode_before <- as.data.table(read_parquet(
  "../input/lihtc_project_episode_2024_source_site_repaired.parquet"
))
site_before <- as.data.table(read_parquet(
  "../input/lihtc_development_site_2024_source_site_repaired.parquet"
))
development_after <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_mixed_site_identity_adjudicated.parquet"
))
episode_after <- as.data.table(read_parquet(
  "../input/lihtc_project_episode_2024_mixed_site_identity_adjudicated.parquet"
))
site_after <- as.data.table(read_parquet(
  "../input/lihtc_development_site_2024_mixed_site_identity_adjudicated.parquet"
))
members <- as.data.table(read_parquet(
  "../input/lihtc_mixed_site_identity_member_partitions.parquet"
))

if (nrow(development_before) != 54030L ||
    nrow(episode_before) != 55345L ||
    uniqueN(development_before$development_id) != nrow(development_before) ||
    uniqueN(episode_before$hud_id) != nrow(episode_before) ||
    uniqueN(site_before$development_site_id) != nrow(site_before) ||
    uniqueN(site_before, by = c("development_id", "site_key")) !=
      nrow(site_before) ||
    nrow(development_after) != 53940L ||
    nrow(episode_after) != 55345L ||
    uniqueN(development_after$development_id) != nrow(development_after) ||
    uniqueN(episode_after$hud_id) != nrow(episode_after) ||
    uniqueN(site_after$development_site_id) != nrow(site_after) ||
    uniqueN(site_after, by = c("development_id", "site_key")) !=
      nrow(site_after)) {
  stop("An application input or output count/key contract failed.",
    call. = FALSE)
}

physical_members <- members[
  cluster_status == "final_physical_development"
]
umbrella_members <- members[
  cluster_status == "nonphysical_financing_umbrella_requires_bridge"
]
if (nrow(physical_members) != 194L ||
    uniqueN(physical_members$review_cluster_id) != 104L ||
    nrow(umbrella_members) != 1L ||
    umbrella_members$development_id != "DEV_NYC20110841") {
  stop("The reviewed physical/nonphysical partition changed.", call. = FALSE)
}

expected_episode_assignment <- episode_before[, .(
  hud_id,
  expected_development_id = development_id
)]
expected_episode_assignment[physical_members, expected_development_id :=
  i.adjudicated_development_id,
on = c(expected_development_id = "development_id")]
expected_episode_assignment[episode_after[, .(
  hud_id,
  observed_development_id = development_id
)], observed_development_id := i.observed_development_id, on = "hud_id"]
if (anyNA(expected_episode_assignment$observed_development_id) ||
    expected_episode_assignment[
      expected_development_id != observed_development_id,
      .N
    ] > 0L) {
  stop("A project episode was lost or assigned to the wrong development.",
    call. = FALSE)
}

changed_episode_fields <- c(
  "development_id", "development_anchor_hud_id", "episode_number",
  "n_project_episodes", "is_development_anchor", "development_linkage_status",
  "development_linkage_basis", "requires_linkage_review",
  "pre_mixed_site_identity_development_id", "mixed_site_identity_question_id",
  "mixed_site_identity_cluster_id", "mixed_site_identity_decision",
  "mixed_site_identity_action", "mixed_site_identity_reason_code",
  "mixed_site_identity_cluster_status", "mixed_site_identity_reviewed_on",
  "mixed_site_identity_shared_query_decision",
  "mixed_site_episode_to_property_bridge_status",
  "mixed_site_development_scope_status"
)
immutable_episode_fields <- setdiff(
  intersect(names(episode_before), names(episode_after)),
  changed_episode_fields
)
setkey(episode_before, hud_id)
setkey(episode_after, hud_id)
episode_before_comparison <- episode_before[, ..immutable_episode_fields]
episode_after_comparison <- episode_after[, ..immutable_episode_fields]
if (!isTRUE(all.equal(
      episode_before_comparison,
      episode_after_comparison,
      check.attributes = TRUE
    ))) {
  stop("A source episode value changed outside authorized linkage fields.",
    call. = FALSE)
}

expected_site_keys <- site_before[, .(
  pre_development_id = development_id,
  development_id,
  site_key
)]
expected_site_keys[physical_members, development_id :=
  i.adjudicated_development_id,
on = c(pre_development_id = "development_id")]
expected_site_keys <- unique(expected_site_keys[, .(development_id, site_key)])
observed_site_keys <- site_after[, .(development_id, site_key)]
setorder(expected_site_keys, development_id, site_key)
setorder(observed_site_keys, development_id, site_key)
if (!identical(expected_site_keys, observed_site_keys)) {
  stop("The source-repaired site union changed during identity application.",
    call. = FALSE)
}

reviewed_physical_ids <- unique(
  physical_members$adjudicated_development_id
)
if (development_after[
      development_id %chin% reviewed_physical_ids,
      uniqueN(development_id)
    ] != 104L ||
    development_after[
      mixed_site_identity_action == "merge_to_review_cluster",
      .N
    ] != 81L ||
    development_after[
      mixed_site_identity_action == "retain_current_development",
      .N
    ] != 23L ||
    development_after[
      mixed_site_identity_action == "merge_to_review_cluster",
      any(!is.na(n_units_development) | !is.na(li_units_development) |
        !is.na(episode_unit_count_sum))
    ]) {
  stop("A reviewed physical cluster or unit-scope guardrail changed.",
    call. = FALSE)
}

nonphysical_financing_status <-
  "nonphysical_financing_umbrella_requires_bridge"
nonphysical_portfolio_status <-
  "nonphysical_portfolio_placeholder_requires_sites_and_bridge"
mixed_umbrella_id <- development_after[
  mixed_site_identity_action == "retain_for_episode_to_property_bridge",
  development_id
]
if (length(mixed_umbrella_id) != 1L ||
    mixed_umbrella_id != "DEV_NYC20110841" ||
    development_after[
      source_site_development_scope_status ==
        nonphysical_financing_status &
        mixed_site_identity_action !=
          "retain_for_episode_to_property_bridge",
      .N
    ] != 2L ||
    development_after[
      source_site_development_scope_status ==
        nonphysical_portfolio_status,
      .N
    ] != 10L ||
    development_after[
      startsWith(mixed_site_development_scope_status, "nonphysical_"),
      .N
    ] != 13L ||
    development_after[
      !startsWith(mixed_site_development_scope_status, "nonphysical_"),
      .N
    ] != 53927L ||
    episode_after[
      development_id == "DEV_NYC20110841",
      unique(hud_id)
    ] != "NYC20110841" ||
    site_after[
      development_id == "DEV_NYC20110841",
      uniqueN(development_id)
    ] != 1L) {
  stop("A physical or nonphysical development-scope count changed.",
    call. = FALSE)
}

development_scope <- development_after[, .(
  development_id,
  expected_scope_status = mixed_site_development_scope_status
)]
episode_scope <- merge(
  episode_after[, .(development_id, observed_scope_status =
    mixed_site_development_scope_status)],
  development_scope,
  by = "development_id",
  all.x = TRUE,
  sort = FALSE
)
site_scope <- merge(
  site_after[, .(development_id, observed_scope_status =
    mixed_site_development_scope_status)],
  development_scope,
  by = "development_id",
  all.x = TRUE,
  sort = FALSE
)
if (anyNA(episode_scope$expected_scope_status) ||
    anyNA(site_scope$expected_scope_status) ||
    episode_scope[observed_scope_status != expected_scope_status, .N] > 0L ||
    site_scope[observed_scope_status != expected_scope_status, .N] > 0L) {
  stop("A development-scope status was not propagated exactly.",
    call. = FALSE)
}

if (episode_after[
      mixed_site_identity_action != "not_applicable",
      any(mixed_site_identity_shared_query_decision != "not_approved")
    ] ||
    development_after[
      mixed_site_identity_action != "not_applicable",
      any(mixed_site_identity_shared_query_decision != "not_approved")
    ]) {
  stop("A reviewed development was approved for geocoding.", call. = FALSE)
}

summary_lines <- c(
  "# LIHTC Mixed-Site Identity Application Audit",
  "",
  "- Source-site-repaired development rows: 54,030.",
  "- Applied development-scope rows: 53,940.",
  "- Final physical developments: 53,927.",
  "- Flagged nonphysical development rows: 13.",
  "- Source financing umbrellas: 2.",
  "- Source portfolio placeholders: 10.",
  "- Mixed-review Hobbs/Ciena financing umbrella: 1.",
  "- Project episodes before and after: 55,345.",
  paste0("- Development sites after safe union: ", nrow(site_after), "."),
  "- Reviewed physical clusters: 104.",
  "- Reviewed source records collapsed: 90.",
  "- Episode source values changed outside linkage fields: 0.",
  "- Source-repaired site keys lost or invented: 0.",
  "- Development-level unit totals inferred for merged clusters: 0.",
  "- Shared geocoding queries approved: 0.",
  ""
)
writeLines(summary_lines, "../output/audit_summary.md")

cat(
  "Audited 53,927 physical developments, 13 nonphysical rows, ",
  "55,345 preserved episodes, and ", nrow(site_after),
  " safely unioned sites.\n",
  sep = ""
)
