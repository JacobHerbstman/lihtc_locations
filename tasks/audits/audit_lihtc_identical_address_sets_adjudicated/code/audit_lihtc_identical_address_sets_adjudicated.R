# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/audit_lihtc_identical_address_sets_adjudicated/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
})

development_before <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_address_round2_adjudicated.parquet"
))
episode_before <- as.data.table(read_parquet(
  "../input/lihtc_project_episode_2024_address_round2_adjudicated.parquet"
))
site_before <- as.data.table(read_parquet(
  "../input/lihtc_development_site_2024_address_round2_adjudicated.parquet"
))
development <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_identical_address_adjudicated.parquet"
))
episode <- as.data.table(read_parquet(
  "../input/lihtc_project_episode_2024_identical_address_adjudicated.parquet"
))
site <- as.data.table(read_parquet(
  "../input/lihtc_development_site_2024_identical_address_adjudicated.parquet"
))
reviews <- as.data.table(read_parquet(
  "../input/lihtc_identical_address_set_reviews.parquet"
))
members <- as.data.table(read_parquet(
  "../input/lihtc_identical_address_set_proposed_member_mapping.parquet"
))
all_identical_members <- as.data.table(read_parquet(
  "../input/lihtc_identical_address_set_members.parquet"
))

if (nrow(development_before) != 54344L ||
    uniqueN(development_before$development_id) !=
      nrow(development_before) ||
    nrow(episode_before) != 55345L ||
    uniqueN(episode_before$hud_id) != nrow(episode_before) ||
    nrow(site_before) != 134232L ||
    uniqueN(site_before, by = c("development_id", "site_key")) !=
      nrow(site_before) ||
    nrow(development) != 54257L ||
    uniqueN(development$development_id) != nrow(development) ||
    nrow(episode) != 55345L ||
    uniqueN(episode$hud_id) != nrow(episode) ||
    nrow(site) != 133551L ||
    uniqueN(site$development_site_id) != nrow(site) ||
    uniqueN(site, by = c("development_id", "site_key")) != nrow(site)) {
  stop("An adjudicated table count or primary key changed.",
    call. = FALSE)
}

assignment <- development_before[, .(
  pre_development_id = development_id,
  expected_development_id = development_id
)]
assignment[members, expected_development_id :=
  i.proposed_physical_development_id,
on = c(pre_development_id = "development_id")]
if (uniqueN(assignment$expected_development_id) != nrow(development)) {
  stop("The reviewed assignment does not produce the output development count.",
    call. = FALSE)
}

expected_development_members <- assignment[, .(
  expected_pre_development_ids = paste(
    sort(pre_development_id),
    collapse = "|"
  )
), by = expected_development_id]
observed_development_members <- development[, .(
  expected_development_id = development_id,
  observed_pre_development_ids =
    pre_identical_address_set_review_development_ids
)]
expected_development_members[observed_development_members,
  observed_pre_development_ids := i.observed_pre_development_ids,
  on = "expected_development_id"]
if (anyNA(expected_development_members$observed_pre_development_ids) ||
    any(
      expected_development_members$expected_pre_development_ids !=
        expected_development_members$observed_pre_development_ids
    )) {
  stop("A development lineage does not match the committed assignment.",
    call. = FALSE)
}

expected_episode_assignment <- episode_before[, .(
  hud_id,
  pre_development_id = development_id,
  expected_development_id = development_id
)]
expected_episode_assignment[members, expected_development_id :=
  i.proposed_physical_development_id,
on = c(pre_development_id = "development_id")]
observed_episode_assignment <- episode[, .(
  hud_id,
  observed_pre_development_id =
    pre_identical_address_set_review_development_id,
  observed_development_id = development_id
)]
setorder(expected_episode_assignment, hud_id)
setorder(observed_episode_assignment, hud_id)
if (!identical(
      expected_episode_assignment$hud_id,
      observed_episode_assignment$hud_id
    ) ||
    !identical(
      expected_episode_assignment$pre_development_id,
      observed_episode_assignment$observed_pre_development_id
    ) ||
    !identical(
      expected_episode_assignment$expected_development_id,
      observed_episode_assignment$observed_development_id
    )) {
  stop("A project episode has an incorrect development assignment.",
    call. = FALSE)
}

allowed_episode_changes <- c(
  "development_id",
  "development_anchor_hud_id",
  "development_linkage_status",
  "development_linkage_basis",
  "requires_linkage_review",
  "episode_number",
  "n_project_episodes",
  "is_development_anchor"
)
protected_episode_fields <- setdiff(
  intersect(names(episode_before), names(episode)),
  allowed_episode_changes
)
setorder(episode_before, hud_id)
setorder(episode, hud_id)
changed_protected_fields <- protected_episode_fields[
  !vapply(protected_episode_fields, function(field) {
    isTRUE(all.equal(
      episode_before[[field]],
      episode[[field]],
      check.attributes = FALSE
    ))
  }, logical(1L))
]
if (length(changed_protected_fields) > 0L) {
  stop(
    paste0(
      "Protected episode fields changed: ",
      paste(changed_protected_fields, collapse = ", "),
      "."
    ),
    call. = FALSE
  )
}

expected_site_keys <- site_before[, .(
  pre_development_id = development_id,
  development_id,
  site_key
)]
expected_site_keys[assignment, development_id :=
  i.expected_development_id,
on = "pre_development_id"]
expected_site_keys <- unique(expected_site_keys[, .(
  development_id,
  site_key
)])
observed_site_keys <- site[, .(development_id, site_key)]
setorder(expected_site_keys, development_id, site_key)
setorder(observed_site_keys, development_id, site_key)
if (!identical(expected_site_keys, observed_site_keys)) {
  stop("A development/site key was lost or invented.", call. = FALSE)
}

site_hud_ids_expected <- copy(site_before[, .(
  pre_development_id = development_id,
  development_id,
  site_key,
  hud_ids
)])
site_hud_ids_expected[assignment, development_id :=
  i.expected_development_id,
on = "pre_development_id"]
site_hud_ids_expected <- site_hud_ids_expected[, {
  hud_id_tokens <- unlist(strsplit(
    hud_ids[!is.na(hud_ids) & hud_ids != ""],
    "|",
    fixed = TRUE
  ))
  hud_id_tokens <- sort(unique(hud_id_tokens[hud_id_tokens != ""]))
  .(expected_hud_ids = paste(hud_id_tokens, collapse = "|"))
}, by = .(development_id, site_key)]
site_hud_ids_observed <- site[, .(
  development_id,
  site_key,
  observed_hud_ids = hud_ids
)]
site_hud_ids_expected[site_hud_ids_observed,
  observed_hud_ids := i.observed_hud_ids,
  on = c("development_id", "site_key")]
if (anyNA(site_hud_ids_expected$observed_hud_ids) ||
    any(
      site_hud_ids_expected$expected_hud_ids !=
        site_hud_ids_expected$observed_hud_ids
    )) {
  stop("A site does not preserve its contributing HUD IDs.",
    call. = FALSE)
}

episode_summary <- episode[, .(
  expected_episode_count = .N,
  expected_first_pis_year = if (all(is.na(pis_year))) {
    NA_integer_
  } else {
    min(pis_year, na.rm = TRUE)
  },
  expected_last_pis_year = if (all(is.na(pis_year))) {
    NA_integer_
  } else {
    max(pis_year, na.rm = TRUE)
  }
), by = development_id]
episode_summary[development[, .(
  development_id,
  observed_episode_count = n_project_episodes,
  observed_first_pis_year = first_pis_year,
  observed_last_pis_year = last_pis_year
)], `:=`(
  observed_episode_count = i.observed_episode_count,
  observed_first_pis_year = i.observed_first_pis_year,
  observed_last_pis_year = i.observed_last_pis_year
), on = "development_id"]
if (anyNA(episode_summary$observed_episode_count) ||
    any(
      episode_summary$expected_episode_count !=
        episode_summary$observed_episode_count
    ) ||
    !isTRUE(all.equal(
      episode_summary$expected_first_pis_year,
      episode_summary$observed_first_pis_year,
      check.attributes = FALSE
    )) ||
    !isTRUE(all.equal(
      episode_summary$expected_last_pis_year,
      episode_summary$observed_last_pis_year,
      check.attributes = FALSE
    ))) {
  stop("A development episode summary is inconsistent.",
    call. = FALSE)
}

excluded_set_ids <- c("IAS0670", "IAS0687")
excluded_development_ids <- all_identical_members[
  identical_address_set_id %chin% excluded_set_ids,
  development_id
]
if (length(excluded_development_ids) != 16L ||
    any(excluded_development_ids %chin% members$development_id) ||
    development[
      development_id %chin% excluded_development_ids,
      any(identical_address_set_review_action != "not_applicable")
    ] ||
    uniqueN(
      site[development_id %chin% excluded_development_ids],
      by = c("development_id", "site_key")
    ) != site_before[
      development_id %chin% excluded_development_ids,
      uniqueN(.SD, by = c("development_id", "site_key"))
    ]) {
  stop("An excluded portfolio cross-listing was changed.",
    call. = FALSE)
}

merged_developments <- development[
  identical_address_set_review_action ==
    "merge_to_proposed_physical_development"
]
retained_developments <- development[
  identical_address_set_review_action ==
    "retain_current_development"
]
if (nrow(merged_developments) != 85L ||
    nrow(retained_developments) != 27L ||
    merged_developments[,
      any(
        !is.na(n_units_development) |
          !is.na(li_units_development) |
          !is.na(candidate_n_units_development) |
          !is.na(candidate_li_units_development)
      )
    ] ||
    any(
      development[
        identical_address_set_review_action != "not_applicable",
        identical_address_set_shared_query_decision
      ] != "not_approved"
    ) ||
    any(!episode$development_id %chin% development$development_id) ||
    any(!site$development_id %chin% development$development_id) ||
    episode[is_development_anchor == TRUE, .N] != nrow(development)) {
  stop("An application safeguard failed.", call. = FALSE)
}

assessment_summary <- reviews[, .(groups = .N),
  by = address_set_assessment
][order(-groups, address_set_assessment)]
assessment_rows <- sprintf(
  "| %s | %s |",
  assessment_summary$address_set_assessment,
  assessment_summary$groups
)

writeLines(c(
  "# LIHTC Identical Address-Set Application Audit",
  "",
  "## Applied identity decisions",
  "",
  "- Reviewed identical multi-address groups: 98.",
  "- Groups merged as one physical development: 85.",
  "- Groups retained as distinct physical developments: 13.",
  "- Reviewed development records before application: 199.",
  "- Reviewed physical developments after application: 112.",
  "",
  "## Output reconciliation",
  "",
  "- Physical developments: 54,257 (87 fewer).",
  "- HUD project episodes: 55,345 (none removed).",
  "- Development sites: 133,551 (681 duplicate mapped keys collapsed).",
  "- Protected project-episode fields changed: 0.",
  "- Source development/site keys lost or invented: 0.",
  "- Shared geocoding queries approved: 0.",
  "- Newly merged development unit totals resolved: 0.",
  "",
  "## Address-set assessments",
  "",
  "| Assessment | Groups |",
  "| --- | ---: |",
  assessment_rows,
  "",
  paste0(
    "The Massachusetts eight-address and Baltimore 53-address portfolio ",
    "cross-listings remain unchanged and outside this application. Copied, ",
    "administrative, and contaminated address sets remain blocked for later ",
    "site-level correction."
  )
), "../output/audit_summary.md")
