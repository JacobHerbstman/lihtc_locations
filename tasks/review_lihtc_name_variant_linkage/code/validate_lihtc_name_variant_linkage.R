# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/review_lihtc_name_variant_linkage/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
})

decisions <- fread("name_variant_linkage_decisions.csv", na.strings = "")
members <- fread(
  "name_variant_linkage_member_decisions.csv",
  na.strings = ""
)
development <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_adjudicated.parquet"
))
episode <- as.data.table(read_parquet(
  "../input/lihtc_project_episode_2024_adjudicated.parquet"
))

if (uniqueN(development$development_id) != nrow(development) ||
    uniqueN(episode$hud_id) != nrow(episode) ||
    uniqueN(decisions$candidate_group_id) != nrow(decisions) ||
    uniqueN(members$current_development_id) != nrow(members) ||
    uniqueN(members$hud_id) != nrow(members)) {
  stop("An input or review key is not unique.", call. = FALSE)
}

candidate_keys <- episode[
  !is.na(state_id) & state_id != "" &
    !is.na(primary_site_key) &
    !grepl("99-99|UNKNOWN|N/A", state_id),
  .(
    n_current_developments = uniqueN(development_id),
    n_names = uniqueN(name_key)
  ),
  by = .(proj_st, state_id, primary_site_key)
][n_current_developments > 1L & n_names > 1L]
setorder(candidate_keys, proj_st, state_id, primary_site_key)
candidate_keys[, candidate_group_id := sprintf("NVAR_%04d", seq_len(.N))]

expected_members <- candidate_keys[
  episode,
  on = .(proj_st, state_id, primary_site_key),
  nomatch = 0L
]
expected_members[, timing_unit_signature := paste(
  yr_pis,
  yr_alloc,
  n_unitsr,
  li_unitr,
  sep = "|"
)]
expected_groups <- expected_members[, .(
  n_current_developments = uniqueN(development_id),
  n_hud_ids = uniqueN(hud_id),
  n_names = uniqueN(name_key),
  n_timing_unit_signatures = uniqueN(timing_unit_signature),
  same_units = uniqueN(paste(n_unitsr, li_unitr, sep = "|")) == 1L
), by = candidate_group_id]
expected_groups[, evidence_class := fcase(
  n_timing_unit_signatures == 1L,
  "exact_timing_units",
  same_units,
  "same_units_different_timing",
  default = "different_timing_or_units"
)]
expected_groups[, review_order_class := fcase(
  evidence_class == "exact_timing_units", 1L,
  evidence_class == "same_units_different_timing", 2L,
  default = 3L
)]
setorder(expected_groups, review_order_class, candidate_group_id)
expected_groups[, expected_review_index := seq_len(.N)]

if (nrow(candidate_keys) != 163L || nrow(expected_members) != 327L ||
    nrow(decisions) != 163L || nrow(members) != 327L) {
  stop("The name-variant review queue row counts changed.", call. = FALSE)
}
if (!setequal(
  decisions$candidate_group_id,
  expected_groups$candidate_group_id
) || !setequal(
  members$hud_id,
  expected_members$hud_id
)) {
  stop("The review ledgers do not cover the candidate queue exactly.",
    call. = FALSE)
}

group_check <- expected_groups[
  decisions,
  on = "candidate_group_id"
]
if (any(group_check$expected_review_index != group_check$review_index) ||
    any(group_check$evidence_class != group_check$i.evidence_class) ||
    any(group_check$n_current_developments !=
      group_check$i.n_current_developments) ||
    any(group_check$n_hud_ids != group_check$i.n_hud_ids)) {
  stop("A group decision does not match its reconstructed candidate block.",
    call. = FALSE)
}

member_check <- expected_members[
  members,
  on = "hud_id"
]
if (anyNA(member_check$candidate_group_id) ||
    any(member_check$candidate_group_id !=
      member_check$i.candidate_group_id) ||
    any(member_check$development_id !=
      member_check$i.current_development_id)) {
  stop("A member decision is assigned to the wrong candidate block.",
    call. = FALSE)
}

review_fields <- c(
  "name_standardization_basis",
  "pass1_decision", "pass1_reason_code", "pass1_notes",
  "pass1_reviewed_on", "pass2_decision", "pass2_reason_code",
  "pass2_search_engine", "pass2_search_url", "pass2_source_1_title",
  "pass2_source_1_type", "pass2_source_1_url", "pass2_notes",
  "pass2_reviewed_on", "final_decision", "final_reason_code",
  "final_notes", "final_reviewed_on"
)
empty_check_fields <- setdiff(
  review_fields,
  c("pass1_reviewed_on", "pass2_reviewed_on", "final_reviewed_on")
)
if (anyNA(decisions[, ..review_fields]) ||
    any(vapply(
      decisions[, ..empty_check_fields],
      function(value) any(as.character(value) == ""),
      logical(1L)
    ))) {
  stop("A required two-pass review field is empty.", call. = FALSE)
}
if (!all(decisions$pass1_decision %chin% c("merge", "defer")) ||
    !all(decisions$pass2_decision %chin%
      c("merge", "retain_separate")) ||
    !all(decisions$final_decision %chin%
      c("merge", "retain_separate")) ||
    any(decisions$pass2_decision != decisions$final_decision)) {
  stop("A review decision has an invalid or inconsistent value.",
    call. = FALSE)
}
if (!all(grepl("^https://", decisions$pass2_search_url)) ||
    !all(grepl("^https://", decisions$pass2_source_1_url)) ||
    any(grepl("google.com/search", decisions$pass2_source_1_url,
      fixed = TRUE))) {
  stop("An outside-read source is missing or is only a search result.",
    call. = FALSE)
}
if (decisions[evidence_class == "exact_timing_units", .N] != 120L ||
    decisions[evidence_class == "same_units_different_timing", .N] != 11L ||
    decisions[evidence_class == "different_timing_or_units", .N] != 32L ||
    decisions[final_decision == "merge", .N] != 154L ||
    decisions[final_decision == "retain_separate", .N] != 9L ||
    members[final_decision == "merge", .N] != 308L ||
    members[final_decision == "retain_separate", .N] != 19L) {
  stop("The evidence-class or final-decision counts changed.", call. = FALSE)
}

member_group_decisions <- decisions[, .(
  candidate_group_id,
  expected_final_decision = final_decision,
  expected_final_reason_code = final_reason_code
)][members, on = "candidate_group_id"]
if (any(member_group_decisions$expected_final_decision !=
      member_group_decisions$final_decision) ||
    any(member_group_decisions$expected_final_reason_code !=
      member_group_decisions$final_reason_code)) {
  stop("A member decision disagrees with its group decision.", call. = FALSE)
}

member_development_groups <- unique(members[, .(
  candidate_group_id,
  current_development_id
)])
expected_anchor_episodes <- member_development_groups[
  episode,
  on = c(current_development_id = "development_id"),
  nomatch = 0L
]
expected_anchor_episodes[, anchor_sort_year := fcase(
  !is.na(pis_year), pis_year,
  !is.na(allocation_year), allocation_year,
  default = 9999L
)]
expected_anchors <- expected_anchor_episodes[
  order(candidate_group_id, anchor_sort_year, hud_id),
  .(
    expected_anchor_hud_id = first(hud_id),
    expected_development_id = first(current_development_id)
  ),
  by = candidate_group_id
]
members[expected_anchors, `:=`(
  expected_anchor_hud_id = i.expected_anchor_hud_id,
  expected_development_id = i.expected_development_id
), on = "candidate_group_id"]

if (members[
    final_decision == "merge",
    any(
      member_action != "merge_candidate_group" |
        name_adjudicated_development_id != expected_development_id |
        name_adjudicated_development_anchor_hud_id !=
          expected_anchor_hud_id
    )
  ] || members[
    final_decision == "retain_separate",
    any(
      member_action != "retain_current_development" |
        name_adjudicated_development_id != current_development_id |
        name_adjudicated_development_anchor_hud_id !=
          current_development_anchor_hud_id
    )
  ]) {
  stop("A member action does not implement its final decision.",
    call. = FALSE)
}

development_mapping <- unique(members[, .(
  current_development_id,
  name_adjudicated_development_id
)])
all_episode_ids <- episode[, .(
  hud_id,
  current_development_id = development_id,
  name_adjudicated_development_id = development_id
)]
all_episode_ids[development_mapping, name_adjudicated_development_id :=
  i.name_adjudicated_development_id,
  on = "current_development_id"
]
if (all_episode_ids[
    current_development_id %chin% development_mapping$current_development_id,
    .N
  ] != 336L ||
    uniqueN(all_episode_ids$name_adjudicated_development_id) != 54725L) {
  stop("The reviewed identifiers do not create the expected partition.",
    call. = FALSE)
}

setorder(decisions, review_index)
setorder(members, review_index, hud_id)
decisions[, c(
  "pass1_reviewed_on", "pass2_reviewed_on", "final_reviewed_on"
) := lapply(.SD, as.Date), .SDcols = c(
  "pass1_reviewed_on", "pass2_reviewed_on", "final_reviewed_on"
)]
members[, c("expected_anchor_hud_id", "expected_development_id") := NULL]
setindexv(decisions, NULL)
setindexv(members, NULL)
write_parquet(
  decisions,
  "../output/lihtc_name_variant_linkage_decisions_2024.parquet",
  compression = "zstd"
)
write_parquet(
  members,
  "../output/lihtc_name_variant_linkage_member_decisions_2024.parquet",
  compression = "zstd"
)

if (!identical(
  decisions,
  as.data.table(read_parquet(
    "../output/lihtc_name_variant_linkage_decisions_2024.parquet"
  ))
) || !identical(
  members,
  as.data.table(read_parquet(
    "../output/lihtc_name_variant_linkage_member_decisions_2024.parquet"
  ))
)) {
  stop("A validated review Parquet changed on round trip.", call. = FALSE)
}

cat(
  "Validated 163 name-variant blocks and 327 member decisions: ",
  "154 blocks merged and 9 retained as separate developments.\n",
  sep = ""
)
