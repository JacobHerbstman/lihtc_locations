# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/review_lihtc_development_linkage/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
})

decisions <- fread("development_linkage_decisions.csv", na.strings = "")
members <- fread("development_linkage_member_decisions.csv", na.strings = "")
development <- as.data.table(read_parquet(
  "../input/lihtc_development_2024.parquet"
))
episode <- as.data.table(read_parquet(
  "../input/lihtc_project_episode_2024.parquet"
))

if (uniqueN(decisions$development_id) != nrow(decisions)) {
  stop("Manual group decisions are not unique by development ID.", call. = FALSE)
}
if (uniqueN(members$hud_id) != nrow(members)) {
  stop("Manual member decisions are not unique by HUD ID.", call. = FALSE)
}
if (!identical(decisions$review_index, seq_len(nrow(decisions)))) {
  stop("Manual group decisions are not in stable review order.", call. = FALSE)
}

expected_groups <- development[n_project_episodes > 1L, .(
  development_id,
  expected_project_episodes = n_project_episodes
)]
expected_members <- episode[n_project_episodes > 1L, .(
  development_id,
  development_anchor_hud_id,
  hud_id
)]

if (nrow(decisions) != 325L || nrow(members) != 798L) {
  stop("The manual review row counts changed.", call. = FALSE)
}
if (!setequal(decisions$development_id, expected_groups$development_id)) {
  stop("Manual decisions do not cover the provisional groups exactly.", call. = FALSE)
}
if (!setequal(members$hud_id, expected_members$hud_id)) {
  stop("Manual member decisions do not cover the provisional members exactly.", call. = FALSE)
}

group_counts <- members[, .(observed_project_episodes = .N), by = development_id]
group_counts[expected_groups, expected_project_episodes :=
  i.expected_project_episodes, on = "development_id"]
if (anyNA(group_counts$expected_project_episodes) ||
    any(group_counts$observed_project_episodes !=
      group_counts$expected_project_episodes)) {
  stop("A manual group has the wrong member count.", call. = FALSE)
}

member_keys <- expected_members[members, on = "hud_id"]
if (anyNA(member_keys$development_id) ||
    any(member_keys$development_id != member_keys$i.development_id) ||
    any(member_keys$development_anchor_hud_id !=
      member_keys$i.development_anchor_hud_id)) {
  stop("A manual member is assigned to the wrong provisional group.", call. = FALSE)
}

review_fields <- c(
  "pass1_decision", "pass1_reason_code", "pass1_notes", "pass1_reviewed_on",
  "pass2_decision", "pass2_reason_code", "pass2_search_engine",
  "pass2_search_url", "pass2_source_1_title", "pass2_source_1_type",
  "pass2_source_1_url", "pass2_notes", "pass2_reviewed_on",
  "final_decision", "final_reason_code", "final_notes", "final_reviewed_on"
)
if (anyNA(decisions[, ..review_fields])) {
  stop("A required two-pass review field is missing.", call. = FALSE)
}
if (!all(decisions$pass1_decision %chin% c("accept", "defer")) ||
    !all(decisions$pass2_decision %chin% c("accept", "reject")) ||
    !all(decisions$final_decision %chin% c("accept", "reject")) ||
    any(decisions$pass2_decision != decisions$final_decision)) {
  stop("A review decision has an invalid or inconsistent value.", call. = FALSE)
}
if (!all(grepl("^https://", decisions$pass2_search_url)) ||
    !all(grepl("^https://", decisions$pass2_source_1_url)) ||
    any(grepl("duckduckgo.com/y.js", decisions$pass2_source_1_url,
      fixed = TRUE))) {
  stop("An outside-read URL is missing, non-HTTPS, or an advertisement.",
    call. = FALSE)
}
if (decisions[final_decision == "accept", .N] != 322L ||
    decisions[final_decision == "reject", .N] != 3L ||
    members[final_decision == "accept", .N] != 788L ||
    members[final_decision == "reject", .N] != 10L) {
  stop("The adjudication decision counts changed.", call. = FALSE)
}

member_group_decisions <- decisions[, .(
  development_id,
  expected_final_decision = final_decision,
  expected_final_reason_code = final_reason_code
)]
member_group_decisions <- member_group_decisions[members, on = "development_id"]
if (any(member_group_decisions$expected_final_decision !=
      member_group_decisions$final_decision) ||
    any(member_group_decisions$expected_final_reason_code !=
      member_group_decisions$final_reason_code)) {
  stop("A member decision disagrees with its group decision.", call. = FALSE)
}

if (members[
    final_decision == "accept",
    any(adjudicated_development_id != development_id |
      adjudicated_development_anchor_hud_id != development_anchor_hud_id |
      member_action != "retain_provisional_group")
  ] || members[
    final_decision == "reject",
    any(adjudicated_development_id != paste0("DEV_", hud_id) |
      adjudicated_development_anchor_hud_id != hud_id |
      member_action != "separate_hud_episode")
  ]) {
  stop("A member action does not implement its final decision.", call. = FALSE)
}

all_episode_ids <- episode[, .(
  hud_id,
  adjudicated_development_id = development_id
)]
all_episode_ids[members, adjudicated_development_id :=
  i.adjudicated_development_id, on = "hud_id"]
adjudicated_groups <- all_episode_ids[, .N, by = adjudicated_development_id]
if (sum(adjudicated_groups$N) != nrow(episode) ||
    uniqueN(adjudicated_groups$adjudicated_development_id) != 54879L) {
  stop("The adjudicated development identifiers do not partition the episodes.",
    call. = FALSE)
}

setorder(decisions, review_index)
setorder(members, development_id, episode_number, hud_id)
decisions[, c(
  "pass1_reviewed_on", "pass2_reviewed_on", "final_reviewed_on"
) := lapply(.SD, as.Date), .SDcols = c(
  "pass1_reviewed_on", "pass2_reviewed_on", "final_reviewed_on"
)]
setindexv(decisions, NULL)
setindexv(members, NULL)
write_parquet(
  decisions,
  "../output/lihtc_development_linkage_decisions_2024.parquet",
  compression = "zstd"
)
write_parquet(
  members,
  "../output/lihtc_development_linkage_member_decisions_2024.parquet",
  compression = "zstd"
)

if (!identical(
  decisions,
  as.data.table(read_parquet(
    "../output/lihtc_development_linkage_decisions_2024.parquet"
  ))
) || !identical(
  members,
  as.data.table(read_parquet(
    "../output/lihtc_development_linkage_member_decisions_2024.parquet"
  ))
)) {
  stop("A validated review Parquet changed on round trip.", call. = FALSE)
}

cat(
  "Validated 325 two-pass group decisions and 798 member decisions: ",
  "322 groups accepted and 3 groups rejected.\n",
  sep = ""
)
