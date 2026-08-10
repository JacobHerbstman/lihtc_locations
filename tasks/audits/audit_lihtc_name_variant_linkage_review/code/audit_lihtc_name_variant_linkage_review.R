# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/audit_lihtc_name_variant_linkage_review/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
})

current_development <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_adjudicated.parquet"
))
current_episode <- as.data.table(read_parquet(
  "../input/lihtc_project_episode_2024_adjudicated.parquet"
))
current_site <- as.data.table(read_parquet(
  "../input/lihtc_development_site_2024_adjudicated.parquet"
))
development <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_name_adjudicated.parquet"
))
episode <- as.data.table(read_parquet(
  "../input/lihtc_project_episode_2024_name_adjudicated.parquet"
))
site <- as.data.table(read_parquet(
  "../input/lihtc_development_site_2024_name_adjudicated.parquet"
))
decisions <- as.data.table(read_parquet(
  "../input/lihtc_name_variant_linkage_decisions_2024.parquet"
))
members <- as.data.table(read_parquet(
  "../input/lihtc_name_variant_linkage_member_decisions_2024.parquet"
))

if (uniqueN(current_development$development_id) !=
      nrow(current_development) ||
    uniqueN(current_episode$hud_id) != nrow(current_episode) ||
    uniqueN(current_site$development_site_id) != nrow(current_site) ||
    uniqueN(development$development_id) != nrow(development) ||
    uniqueN(episode$hud_id) != nrow(episode) ||
    uniqueN(site$development_site_id) != nrow(site) ||
    uniqueN(site, by = c("development_id", "site_key")) != nrow(site) ||
    uniqueN(decisions$candidate_group_id) != nrow(decisions) ||
    uniqueN(members$current_development_id) != nrow(members)) {
  stop("An audit input key is not unique.", call. = FALSE)
}
if (nrow(current_development) != 54879L ||
    nrow(current_episode) != 55345L || nrow(current_site) != 135013L ||
    nrow(development) != 54725L || nrow(episode) != 55345L ||
    nrow(site) != 134823L) {
  stop("An input or output table has an unexpected row count.",
    call. = FALSE)
}
if (any(!episode$development_id %chin% development$development_id) ||
    any(!site$development_id %chin% development$development_id)) {
  stop("An episode or site points to an unknown development.",
    call. = FALSE)
}

protected_episode_columns <- setdiff(
  names(current_episode),
  c(
    "development_id", "development_anchor_hud_id", "episode_number",
    "is_development_anchor", "development_linkage_status",
    "development_linkage_basis", "requires_linkage_review",
    "n_project_episodes"
  )
)
setorder(current_episode, hud_id)
episode_source_check <- copy(episode)
setorder(episode_source_check, hud_id)
if (!identical(
  current_episode[, ..protected_episode_columns],
  episode_source_check[, ..protected_episode_columns]
)) {
  stop("The second linkage pass changed a protected episode value.",
    call. = FALSE)
}

development_mapping <- unique(members[, .(
  current_development_id,
  expected_development_id = name_adjudicated_development_id,
  expected_anchor_hud_id =
    name_adjudicated_development_anchor_hud_id,
  expected_candidate_group_id = candidate_group_id,
  expected_review_decision = final_decision
)])
expected_episode_mapping <- current_episode[, .(
  hud_id,
  expected_pre_name_review_development_id = development_id,
  expected_development_id = development_id,
  expected_anchor_hud_id = development_anchor_hud_id,
  expected_candidate_group_id = NA_character_,
  expected_review_decision = "not_applicable"
)]
expected_episode_mapping[development_mapping, `:=`(
  expected_development_id = i.expected_development_id,
  expected_anchor_hud_id = i.expected_anchor_hud_id,
  expected_candidate_group_id = i.expected_candidate_group_id,
  expected_review_decision = i.expected_review_decision
), on = c(
  expected_pre_name_review_development_id = "current_development_id"
)]
mapping_check <- expected_episode_mapping[episode, on = "hud_id"]
if (any(mapping_check$expected_pre_name_review_development_id !=
      mapping_check$pre_name_review_development_id) ||
    any(mapping_check$expected_development_id !=
      mapping_check$development_id) ||
    any(mapping_check$expected_anchor_hud_id !=
      mapping_check$development_anchor_hud_id) ||
    any(fcoalesce(mapping_check$expected_candidate_group_id, "") !=
      fcoalesce(mapping_check$name_variant_candidate_group_id, "")) ||
    any(mapping_check$expected_review_decision !=
      mapping_check$name_variant_review_decision)) {
  stop("An episode does not implement its reviewed development mapping.",
    call. = FALSE)
}

episode_counts <- episode[, .(
  observed_project_episodes = .N
), by = development_id]
development[episode_counts, observed_project_episodes :=
  i.observed_project_episodes, on = "development_id"]
if (anyNA(development$observed_project_episodes) ||
    any(development$n_project_episodes !=
      development$observed_project_episodes)) {
  stop("Development episode counts do not reconcile.", call. = FALSE)
}
development[, observed_project_episodes := NULL]

site_counts <- site[, .(
  observed_development_sites = .N,
  observed_sites_with_coordinates = sum(
    !is.na(latitude) & !is.na(longitude)
  ),
  observed_sites_requiring_review = sum(requires_site_review)
), by = development_id]
development[, `:=`(
  observed_development_sites = 0L,
  observed_sites_with_coordinates = 0L,
  observed_sites_requiring_review = 0L
)]
development[site_counts, `:=`(
  observed_development_sites = i.observed_development_sites,
  observed_sites_with_coordinates = i.observed_sites_with_coordinates,
  observed_sites_requiring_review = i.observed_sites_requiring_review
), on = "development_id"]
if (any(development$n_development_sites !=
      development$observed_development_sites) ||
    any(development$n_sites_with_hud_coordinates !=
      development$observed_sites_with_coordinates) ||
    any(development$n_sites_requiring_review !=
      development$observed_sites_requiring_review)) {
  stop("Development site summaries do not reconcile.", call. = FALSE)
}
development[, c(
  "observed_development_sites", "observed_sites_with_coordinates",
  "observed_sites_requiring_review"
) := NULL]

affected_current_developments <- members$current_development_id
unaffected_current_site <- current_site[
  !development_id %chin% affected_current_developments
]
unaffected_site <- site[
  !development_id %chin% affected_current_developments
]
setorder(unaffected_current_site, development_id, site_key)
setorder(unaffected_site, development_id, site_key)
if (!identical(unaffected_current_site, unaffected_site)) {
  stop("Rebuilding sites changed an unaffected development site.",
    call. = FALSE)
}

remaining_candidates <- episode[
  !is.na(state_id) & state_id != "" &
    !is.na(primary_site_key) &
    !grepl("99-99|UNKNOWN|N/A", state_id),
  .(
    n_developments = uniqueN(development_id),
    n_names = uniqueN(name_key)
  ),
  by = .(proj_st, state_id, primary_site_key)
][n_developments > 1L & n_names > 1L]
retained_keys <- unique(decisions[
  final_decision == "retain_separate",
  .(proj_st = development_state, state_id, primary_site_key)
])
if (nrow(remaining_candidates) != 9L ||
    !setequal(
      paste(
        remaining_candidates$proj_st,
        remaining_candidates$state_id,
        remaining_candidates$primary_site_key
      ),
      paste(
        retained_keys$proj_st,
        retained_keys$state_id,
        retained_keys$primary_site_key
      )
    )) {
  stop("The remaining candidate blocks are not exactly the retained groups.",
    call. = FALSE)
}

if (development[name_variant_review_decision == "merge", .N] != 154L ||
    development[name_variant_review_decision == "retain_separate", .N] !=
      19L ||
    episode[name_variant_review_decision == "merge", .N] != 317L ||
    episode[name_variant_review_decision == "retain_separate", .N] != 19L) {
  stop("The reviewed development or episode counts changed.", call. = FALSE)
}
if (development[
    name_variant_review_decision == "merge",
    any(!is.na(n_units_development) | !is.na(li_units_development))
  ] || development[
    name_variant_review_reason_code == "duplicate_reporting_name_variant",
    any(unit_aggregation_rule != "candidate_duplicate_records_use_once")
  ] || development[
    name_variant_review_reason_code ==
      "single_building_split_financing_applications",
    any(
      unit_aggregation_rule != "candidate_financing_components_sum" |
        candidate_n_units_development != 229 |
        candidate_li_units_development != 226
    )
  ]) {
  stop("A reviewed unit aggregation contract failed.", call. = FALSE)
}

retained_groups <- decisions[
  final_decision == "retain_separate",
  .(
    review_index,
    candidate_group_id,
    development_state,
    state_id,
    primary_site_key,
    project_names,
    allocation_pis_years,
    episode_unit_totals,
    final_reason_code,
    pass2_source_1_title,
    pass2_source_1_url
  )
]
setorder(retained_groups, review_index)
fwrite(retained_groups, "../output/retained_name_variant_groups.csv", na = "")

review_counts <- decisions[, .N, by = .(
  evidence_class,
  final_decision
)]
setorder(review_counts, evidence_class, final_decision)

format_markdown_table <- function(table) {
  header <- paste0("| ", paste(names(table), collapse = " | "), " |")
  divider <- paste0(
    "| ",
    paste(rep("---", ncol(table)), collapse = " | "),
    " |"
  )
  rows <- apply(table, 1L, function(row) {
    paste0("| ", paste(row, collapse = " | "), " |")
  })
  c(header, divider, rows)
}

summary_lines <- c(
  "# LIHTC Name-Variant Linkage Review Audit",
  "",
  "## Data contract",
  "",
  "- The committed ledger covers all 163 same-state-ID, same-standardized-primary-address blocks with different normalized names.",
  "- All 120 exact timing-and-unit blocks merge after separate HUD-only and outside-source reads.",
  "- In total, 154 blocks merge and nine remain separate physical developments.",
  "- The output contains 54,725 developments, 55,345 project episodes, and 134,823 development sites.",
  "- Every HUD episode is retained, protected source values are unchanged, and all published keys are unique.",
  "- Whole current developments are reassigned, so 317 episodes fall in merged developments even though the candidate ledger has 308 representative merge members.",
  "- All 154 merged development-level unit totals remain unresolved.",
  "- The only remaining same-state-ID/address/name-variant blocks are the nine explicitly retained phase, component, or common-address groups.",
  "",
  "## Review results",
  "",
  format_markdown_table(review_counts)
)
writeLines(summary_lines, "../output/audit_summary.md")

cat(
  "Audited 163 name-variant blocks: 154 merged and 9 retained; ",
  "all 55,345 HUD episodes remain present.\n",
  sep = ""
)
