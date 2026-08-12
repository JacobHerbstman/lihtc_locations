# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/audit_lihtc_low_income_share_application/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
})

development_before <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_unit_scope_adjudicated.parquet"
))
episode_before <- as.data.table(read_parquet(
  "../input/lihtc_project_episode_2024_unit_scope_adjudicated.parquet"
))
site_before <- as.data.table(read_parquet(
  "../input/lihtc_development_site_2024_unit_scope_adjudicated.parquet"
))
wisconsin <- as.data.table(read_parquet(
  "../input/lihtc_wi_low_income_share_review.parquet"
))
other_states <- as.data.table(read_parquet(
  "../input/nonwi_low_income_share_review_validated.parquet"
))
development_after <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_low_income_share_adjudicated.parquet"
))
episode_after <- as.data.table(read_parquet(
  "../input/lihtc_project_episode_2024_low_income_share_adjudicated.parquet"
))
site_after <- as.data.table(read_parquet(
  "../input/lihtc_development_site_2024_low_income_share_adjudicated.parquet"
))

setorder(development_before, development_id)
setorder(development_after, development_id)
setorder(episode_before, hud_id)
setorder(episode_after, hud_id)
setorder(site_before, development_site_id)
setorder(site_after, development_site_id)

expected <- rbindlist(list(
  wisconsin[, .(
    development_id,
    expected_action = fifelse(
      review_action == "propose_direct_wheda_low_income_value",
      "replace_low_income_units",
      "unresolved_exclude_low_income_share"
    ),
    expected_low_income_units = fifelse(
      review_action == "propose_direct_wheda_low_income_value",
      as.numeric(proposed_low_income_units),
      NA_real_
    )
  )],
  other_states[, .(
    development_id,
    expected_action = final_action,
    expected_low_income_units = fifelse(
      final_action == "replace_low_income_units",
      as.numeric(replacement_low_income_units),
      fifelse(
        final_action == "retain_frozen_counts",
        as.numeric(frozen_low_income_units),
        NA_real_
      )
    )
  )]
), use.names = TRUE)
setkey(expected, development_id)

changed_ids <- expected[expected_action == "replace_low_income_units",
  development_id]
retained_ids <- expected[expected_action == "retain_frozen_counts",
  development_id]
unresolved_ids <- expected[
  expected_action == "unresolved_exclude_low_income_share",
  development_id
]

expected_values <- development_before[, .(
  development_id,
  expected_low_income_units = li_units_development
)]
expected_values[expected[expected_action == "replace_low_income_units"],
  expected_low_income_units := i.expected_low_income_units,
  on = "development_id"]
setorder(expected_values, development_id)

unchanged_development_columns <- setdiff(
  names(development_before), "li_units_development"
)
unchanged_episode_columns <- setdiff(
  names(episode_before), "li_units_physical_development"
)
unchanged_site_columns <- setdiff(
  names(site_before), "li_units_physical_development"
)
episode_expected_low_income_units <- development_after$li_units_development[
  match(episode_after$development_id, development_after$development_id)
]
site_expected_low_income_units <- development_after$li_units_development[
  match(site_after$development_id, development_after$development_id)
]

checks <- data.table(
  check = c(
    "development_rows_and_keys_preserved",
    "episode_rows_and_keys_preserved",
    "site_rows_and_keys_preserved",
    "development_source_columns_preserved",
    "episode_source_columns_preserved",
    "site_source_columns_preserved",
    "review_partition_exact",
    "review_action_counts_exact",
    "replacement_values_exact",
    "nonreplacement_values_preserved",
    "episode_physical_values_match_development",
    "site_physical_values_match_development",
    "raw_episode_low_income_values_preserved",
    "unresolved_values_excluded",
    "retained_nominal_set_asides_eligible",
    "incomplete_counts_excluded",
    "eligible_values_numerically_valid",
    "analysis_status_counts_exact"
  ),
  passed = c(
    nrow(development_before) == 53469L &&
      nrow(development_after) == 53469L &&
      identical(development_before$development_id,
        development_after$development_id),
    nrow(episode_before) == 54902L &&
      nrow(episode_after) == 54902L &&
      identical(episode_before$hud_id, episode_after$hud_id),
    nrow(site_before) == 131473L && nrow(site_after) == 131473L &&
      identical(site_before$development_site_id,
        site_after$development_site_id),
    identical(
      development_before[, ..unchanged_development_columns],
      development_after[, ..unchanged_development_columns]
    ),
    identical(
      episode_before[, ..unchanged_episode_columns],
      episode_after[, ..unchanged_episode_columns]
    ),
    identical(
      site_before[, ..unchanged_site_columns],
      site_after[, ..unchanged_site_columns]
    ),
    nrow(expected) == 275L && uniqueN(expected$development_id) == 275L &&
      setequal(expected$development_id, development_before[
        !is.na(n_units_development) & n_units_development > 0 &
          !is.na(li_units_development) &
          li_units_development / n_units_development < 0.20,
        development_id
      ]),
    length(changed_ids) == 176L && length(retained_ids) == 11L &&
      length(unresolved_ids) == 88L,
    identical(
      development_after$li_units_development,
      expected_values$expected_low_income_units
    ),
    development_after[
      !development_id %chin% changed_ids,
      identical(
        li_units_development,
        development_before[
          !development_id %chin% changed_ids,
          li_units_development
        ]
      )
    ],
    identical(
      episode_after$li_units_physical_development,
      episode_expected_low_income_units
    ),
    identical(
      site_after$li_units_physical_development,
      site_expected_low_income_units
    ),
    identical(episode_before[, .(hud_id, episode_low_income_units,
      li_unitr, li_units)], episode_after[, .(hud_id,
      episode_low_income_units, li_unitr, li_units)]),
    development_after[development_id %chin% unresolved_ids,
      all(!low_income_share_analysis_eligible &
        low_income_share_analysis_status ==
          "excluded_unresolved_sub_20_percent_count")],
    development_after[development_id %chin% retained_ids,
      all(low_income_share_analysis_eligible &
        low_income_share_review_action == "retain_frozen_counts")],
    development_after[
      is.na(n_units_development) | is.na(li_units_development),
      all(!low_income_share_analysis_eligible &
        low_income_share_analysis_status ==
          "excluded_incomplete_unit_counts")
    ],
    development_after[low_income_share_analysis_eligible == TRUE,
      all(n_units_development > 0 & li_units_development >= 0 &
        li_units_development <= n_units_development)],
    development_after[
      low_income_share_analysis_status ==
        "eligible_reviewed_or_not_flagged", .N
    ] == 52831L &&
      development_after[
        low_income_share_analysis_status ==
          "excluded_incomplete_unit_counts", .N
      ] == 550L &&
      development_after[
        low_income_share_analysis_status ==
          "excluded_unresolved_sub_20_percent_count", .N
      ] == 88L
  )
)

if (anyNA(checks$passed)) {
  stop(paste(
    "Low-income-share application audit returned an undefined check:",
    paste(checks[is.na(passed), check], collapse = ", ")
  ), call. = FALSE)
}
if (any(!checks$passed)) {
  stop(paste(
    "Low-income-share application audit failed:",
    paste(checks[passed == FALSE, check], collapse = ", ")
  ), call. = FALSE)
}

checks[, audit_status := "pass"]
write_parquet(
  checks,
  "../output/lihtc_low_income_share_application_audit.parquet",
  compression = "zstd"
)

if (!identical(checks, as.data.table(read_parquet(
      "../output/lihtc_low_income_share_application_audit.parquet"
    )))) {
  stop("The audit Parquet changed on round trip.", call. = FALSE)
}
