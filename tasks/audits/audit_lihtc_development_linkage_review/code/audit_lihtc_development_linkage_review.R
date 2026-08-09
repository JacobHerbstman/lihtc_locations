# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/audit_lihtc_development_linkage_review/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
})

development <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_adjudicated.parquet"
))
episode <- as.data.table(read_parquet(
  "../input/lihtc_project_episode_2024_adjudicated.parquet"
))
site <- as.data.table(read_parquet(
  "../input/lihtc_development_site_2024_adjudicated.parquet"
))
provisional_episode <- as.data.table(read_parquet(
  "../input/lihtc_project_episode_2024.parquet"
))
decisions <- as.data.table(read_parquet(
  "../input/lihtc_development_linkage_decisions_2024.parquet"
))
members <- as.data.table(read_parquet(
  "../input/lihtc_development_linkage_member_decisions_2024.parquet"
))

if (uniqueN(development$development_id) != nrow(development) ||
    uniqueN(episode$hud_id) != nrow(episode) ||
    uniqueN(site$development_site_id) != nrow(site) ||
    uniqueN(site, by = c("development_id", "site_key")) != nrow(site) ||
    uniqueN(decisions$development_id) != nrow(decisions) ||
    uniqueN(members$hud_id) != nrow(members)) {
  stop("An adjudicated or review key is not unique.", call. = FALSE)
}
if (nrow(development) != 54879L || nrow(episode) != 55345L ||
    nrow(site) != 135013L) {
  stop("An adjudicated table has an unexpected row count.", call. = FALSE)
}
if (any(!episode$development_id %chin% development$development_id) ||
    any(!site$development_id %chin% development$development_id)) {
  stop("An episode or site points to an unknown development.", call. = FALSE)
}

protected_episode_columns <- setdiff(
  names(provisional_episode),
  c(
    "development_id", "development_anchor_hud_id", "episode_number",
    "is_development_anchor", "development_linkage_status",
    "development_linkage_basis", "requires_linkage_review",
    "n_project_episodes"
  )
)
setorder(provisional_episode, hud_id)
episode_source_check <- copy(episode)
setorder(episode_source_check, hud_id)
if (!identical(
  provisional_episode[, ..protected_episode_columns],
  episode_source_check[, ..protected_episode_columns]
)) {
  stop("Adjudication changed a protected episode value.", call. = FALSE)
}

expected_episode_mapping <- provisional_episode[, .(
  hud_id,
  expected_provisional_development_id = development_id,
  expected_development_id = development_id,
  expected_review_decision = "not_applicable_singleton"
)]
expected_episode_mapping[members, `:=`(
  expected_development_id = i.adjudicated_development_id,
  expected_review_decision = i.final_decision
), on = "hud_id"]
mapping_check <- expected_episode_mapping[episode, on = "hud_id"]
if (any(mapping_check$expected_provisional_development_id !=
      mapping_check$provisional_development_id) ||
    any(mapping_check$expected_development_id != mapping_check$development_id) ||
    any(mapping_check$expected_review_decision !=
      mapping_check$linkage_review_decision)) {
  stop("An episode does not implement its reviewed development mapping.",
    call. = FALSE)
}

episode_counts <- episode[, .(observed_project_episodes = .N), by = development_id]
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
  observed_sites_with_coordinates = sum(!is.na(latitude) & !is.na(longitude)),
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
  stop("Development site counts do not reconcile.", call. = FALSE)
}
development[, c(
  "observed_development_sites", "observed_sites_with_coordinates",
  "observed_sites_requiring_review"
) := NULL]

development_review_counts <- development[, .N, by = linkage_review_decision]
episode_review_counts <- episode[, .N, by = linkage_review_decision]
if (development[
    linkage_review_decision == "accept",
    .N
  ] != 322L || development[
    linkage_review_decision == "reject",
    .N
  ] != 10L || episode[
    linkage_review_decision == "accept",
    .N
  ] != 788L || episode[
    linkage_review_decision == "reject",
    .N
  ] != 10L) {
  stop("Reviewed development or episode counts are wrong.", call. = FALSE)
}
if (any(development$requires_linkage_review) ||
    any(episode$requires_linkage_review)) {
  stop("A provisional linkage review flag remains.", call. = FALSE)
}
if (development[
    linkage_review_decision == "accept",
    any(unit_aggregation_status != "requires_review" |
      !is.na(n_units_development) | !is.na(li_units_development))
  ]) {
  stop("An accepted group had its unit totals adjudicated implicitly.",
    call. = FALSE)
}
if (development[
    linkage_review_decision == "reject",
    any(n_project_episodes != 1L |
      unit_aggregation_status != "resolved_single_episode" |
      unit_aggregation_rule != "single_episode_source")
  ]) {
  stop("A rejected linkage was not converted to single episodes.",
    call. = FALSE)
}

rejected_sites <- site[
  development_id %chin% development[
    linkage_review_decision == "reject",
    development_id
  ]
]
if (nrow(rejected_sites) != 10L || any(!rejected_sites$requires_site_review)) {
  stop("Rejected street-only groups did not retain ten review-flagged sites.",
    call. = FALSE)
}

rejected_members <- decisions[final_decision == "reject", .(
  provisional_development_id = development_id,
  development_name,
  final_reason_code,
  pass2_source_1_title,
  pass2_source_1_url,
  pass2_source_2_title,
  pass2_source_2_url
)][members[final_decision == "reject"],
  on = c(provisional_development_id = "development_id")]
rejected_members <- episode[rejected_members, on = "hud_id"]
rejected_members <- rejected_members[, .(
  provisional_development_id,
  adjudicated_development_id = development_id,
  hud_id,
  development_name,
  project,
  proj_add,
  proj_cty,
  proj_st,
  n_unitsr,
  li_unitr,
  final_reason_code,
  pass2_source_1_title,
  pass2_source_1_url,
  pass2_source_2_title,
  pass2_source_2_url
)]
setorder(rejected_members, provisional_development_id, hud_id)
fwrite(rejected_members, "../output/rejected_linkage_members.csv", na = "")

format_markdown_table <- function(table) {
  header <- paste0("| ", paste(names(table), collapse = " | "), " |")
  divider <- paste0("| ", paste(rep("---", ncol(table)), collapse = " | "), " |")
  rows <- apply(table, 1L, function(row) {
    paste0("| ", paste(row, collapse = " | "), " |")
  })
  c(header, divider, rows)
}

setorder(development_review_counts, linkage_review_decision)
setorder(episode_review_counts, linkage_review_decision)
summary_lines <- c(
  "# LIHTC Development Linkage Review Audit",
  "",
  "## Data contract",
  "",
  "- 325 provisional groups and 798 HUD episodes received both an internal and outside read.",
  "- 322 groups covering 788 episodes were accepted as physical developments.",
  "- Three HCCI street-only groups covering ten episodes were rejected and split into ten developments.",
  "- The adjudicated tables contain 54,879 developments, 55,345 project episodes, and 135,013 development sites.",
  "- Episode values outside the development-assignment fields are unchanged from the provisional build.",
  "- All development, episode, site, decision, and member keys pass uniqueness checks.",
  "- Every episode and site points to an existing development, and published episode and site counts reconcile.",
  "",
  "## Development review result",
  "",
  format_markdown_table(development_review_counts),
  "",
  "## Project-episode review result",
  "",
  format_markdown_table(episode_review_counts),
  "",
  "Accepted multi-episode developments retain unresolved development-level unit totals. Rejected groups use each HUD episode's own unit totals. Outside addresses were not imported; all ten resulting HCCI sites retain a review flag."
)
writeLines(summary_lines, "../output/audit_summary.md")

cat(
  "Audited 325 linkage decisions: 322 groups retained and 3 groups split ",
  "into 10 episode-level developments.\n",
  sep = ""
)
