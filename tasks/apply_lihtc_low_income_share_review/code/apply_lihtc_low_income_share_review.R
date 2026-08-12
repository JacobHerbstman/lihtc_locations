# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/apply_lihtc_low_income_share_review/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
})

development <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_unit_scope_adjudicated.parquet"
))
episode <- as.data.table(read_parquet(
  "../input/lihtc_project_episode_2024_unit_scope_adjudicated.parquet"
))
site <- as.data.table(read_parquet(
  "../input/lihtc_development_site_2024_unit_scope_adjudicated.parquet"
))
wisconsin <- as.data.table(read_parquet(
  "../input/lihtc_wi_low_income_share_review.parquet"
))
other_states <- as.data.table(read_parquet(
  "../input/nonwi_low_income_share_review_validated.parquet"
))

if (nrow(development) != 53469L || nrow(episode) != 54902L ||
    nrow(site) != 131473L || nrow(wisconsin) != 197L ||
    nrow(other_states) != 78L ||
    uniqueN(development$development_id) != nrow(development) ||
    uniqueN(episode$hud_id) != nrow(episode) ||
    uniqueN(site$development_site_id) != nrow(site) ||
    uniqueN(wisconsin$development_id) != nrow(wisconsin) ||
    uniqueN(other_states$development_id) != nrow(other_states)) {
  stop("A low-income-share application input count or key changed.",
    call. = FALSE)
}

review_ids <- c(wisconsin$development_id, other_states$development_id)
expected_review_ids <- development[
  !is.na(n_units_development) & n_units_development > 0 &
    !is.na(li_units_development) & li_units_development >= 0 &
    li_units_development / n_units_development < 0.20,
  development_id
]
if (anyDuplicated(review_ids) || !setequal(review_ids, expected_review_ids)) {
  stop("The Wisconsin and other-state reviews do not partition the tail.",
    call. = FALSE)
}

wisconsin[, `:=`(
  low_income_share_review_scope = "wisconsin_sub_20_percent",
  low_income_share_review_action = fcase(
    review_action == "propose_direct_wheda_low_income_value",
    "replace_low_income_units",
    default = "unresolved_exclude_low_income_share"
  ),
  reviewed_low_income_units = fifelse(
    review_action == "propose_direct_wheda_low_income_value",
    as.numeric(proposed_low_income_units),
    NA_real_
  ),
  low_income_share_source_title = "WHEDA Monitored Housing Tax Credit Projects",
  low_income_share_source_type = "official_state_housing_agency",
  low_income_share_source_url = source_url,
  low_income_share_reviewed_on = as.IDate(reviewed_on),
  low_income_share_review_reason = review_reason
)]

other_states[, `:=`(
  low_income_share_review_scope = "other_state_sub_20_percent",
  low_income_share_review_action = final_action,
  reviewed_low_income_units = fifelse(
    final_action == "replace_low_income_units",
    as.numeric(replacement_low_income_units),
    fifelse(
      final_action == "retain_frozen_counts",
      as.numeric(frozen_low_income_units),
      NA_real_
    )
  ),
  low_income_share_source_title = source_1_title,
  low_income_share_source_type = source_1_type,
  low_income_share_source_url = source_1_url,
  low_income_share_reviewed_on = as.IDate(reviewer_2_reviewed_on),
  low_income_share_review_reason = classification
)]

review <- rbindlist(list(
  wisconsin[, .(
    development_id,
    low_income_share_review_scope,
    low_income_share_review_action,
    reviewed_low_income_units,
    low_income_share_source_title,
    low_income_share_source_type,
    low_income_share_source_url,
    low_income_share_reviewed_on,
    low_income_share_review_reason
  )],
  other_states[, .(
    development_id,
    low_income_share_review_scope,
    low_income_share_review_action,
    reviewed_low_income_units,
    low_income_share_source_title,
    low_income_share_source_type,
    low_income_share_source_url,
    low_income_share_reviewed_on,
    low_income_share_review_reason
  )]
), use.names = TRUE)
setkey(review, development_id)

if (any(review[
      low_income_share_review_action %chin% c(
        "replace_low_income_units", "retain_frozen_counts"
      ),
      is.na(reviewed_low_income_units) | reviewed_low_income_units <= 0
    ]) ||
    any(!review$low_income_share_review_action %chin% c(
      "replace_low_income_units", "retain_frozen_counts",
      "unresolved_exclude_low_income_share"
    ))) {
  stop("A reviewed low-income-unit action is not safe to apply.",
    call. = FALSE)
}

development[, pre_low_income_share_li_units_development :=
  li_units_development]
development[review, `:=`(
  low_income_share_review_scope = i.low_income_share_review_scope,
  low_income_share_review_action = i.low_income_share_review_action,
  low_income_share_source_title = i.low_income_share_source_title,
  low_income_share_source_type = i.low_income_share_source_type,
  low_income_share_source_url = i.low_income_share_source_url,
  low_income_share_reviewed_on = i.low_income_share_reviewed_on,
  low_income_share_review_reason = i.low_income_share_review_reason
), on = "development_id"]
development[review[
  low_income_share_review_action == "replace_low_income_units"
], li_units_development := i.reviewed_low_income_units,
on = "development_id"]
development[is.na(low_income_share_review_scope), `:=`(
  low_income_share_review_scope = "not_in_review",
  low_income_share_review_action = "not_in_review",
  low_income_share_source_title = NA_character_,
  low_income_share_source_type = NA_character_,
  low_income_share_source_url = NA_character_,
  low_income_share_reviewed_on = as.IDate(NA),
  low_income_share_review_reason = "not_in_review"
)]
development[, low_income_share_analysis_status := fcase(
  low_income_share_review_action == "unresolved_exclude_low_income_share",
  "excluded_unresolved_sub_20_percent_count",
  is.na(n_units_development) | is.na(li_units_development),
  "excluded_incomplete_unit_counts",
  default = "eligible_reviewed_or_not_flagged"
)]
development[, low_income_share_analysis_eligible :=
  low_income_share_analysis_status == "eligible_reviewed_or_not_flagged"]

if (any(development[
      low_income_share_analysis_eligible == TRUE,
      n_units_development <= 0 | li_units_development < 0 |
        li_units_development > n_units_development
    ]) ||
    any(development[
      low_income_share_review_action == "unresolved_exclude_low_income_share",
      low_income_share_analysis_eligible
    ])) {
  stop("The development-level low-income-share eligibility contract failed.",
    call. = FALSE)
}

development_values <- development[, .(
  development_id,
  pre_low_income_share_li_units_development,
  reviewed_li_units_physical_development = li_units_development,
  low_income_share_review_scope,
  low_income_share_review_action,
  low_income_share_source_title,
  low_income_share_source_type,
  low_income_share_source_url,
  low_income_share_reviewed_on,
  low_income_share_review_reason,
  low_income_share_analysis_status,
  low_income_share_analysis_eligible
)]

episode[development_values, `:=`(
  pre_low_income_share_li_units_physical_development =
    i.pre_low_income_share_li_units_development,
  li_units_physical_development =
    i.reviewed_li_units_physical_development,
  low_income_share_review_scope = i.low_income_share_review_scope,
  low_income_share_review_action = i.low_income_share_review_action,
  low_income_share_source_title = i.low_income_share_source_title,
  low_income_share_source_type = i.low_income_share_source_type,
  low_income_share_source_url = i.low_income_share_source_url,
  low_income_share_reviewed_on = i.low_income_share_reviewed_on,
  low_income_share_review_reason = i.low_income_share_review_reason,
  low_income_share_analysis_status = i.low_income_share_analysis_status,
  low_income_share_analysis_eligible = i.low_income_share_analysis_eligible
), on = "development_id"]

site[development_values, `:=`(
  pre_low_income_share_li_units_physical_development =
    i.pre_low_income_share_li_units_development,
  li_units_physical_development =
    i.reviewed_li_units_physical_development,
  low_income_share_review_scope = i.low_income_share_review_scope,
  low_income_share_review_action = i.low_income_share_review_action,
  low_income_share_source_title = i.low_income_share_source_title,
  low_income_share_source_type = i.low_income_share_source_type,
  low_income_share_source_url = i.low_income_share_source_url,
  low_income_share_reviewed_on = i.low_income_share_reviewed_on,
  low_income_share_review_reason = i.low_income_share_review_reason,
  low_income_share_analysis_status = i.low_income_share_analysis_status,
  low_income_share_analysis_eligible = i.low_income_share_analysis_eligible
), on = "development_id"]

if (anyNA(episode$low_income_share_analysis_status) ||
    anyNA(site$low_income_share_analysis_status)) {
  stop("Development-level review fields did not join to episodes and sites.",
    call. = FALSE)
}

write_parquet(
  development,
  "../output/lihtc_development_2024_low_income_share_adjudicated.parquet",
  compression = "zstd"
)
write_parquet(
  episode,
  "../output/lihtc_project_episode_2024_low_income_share_adjudicated.parquet",
  compression = "zstd"
)
write_parquet(
  site,
  "../output/lihtc_development_site_2024_low_income_share_adjudicated.parquet",
  compression = "zstd"
)

if (nrow(read_parquet(
      "../output/lihtc_development_2024_low_income_share_adjudicated.parquet"
    )) != 53469L ||
    nrow(read_parquet(
      "../output/lihtc_project_episode_2024_low_income_share_adjudicated.parquet"
    )) != 54902L ||
    nrow(read_parquet(
      "../output/lihtc_development_site_2024_low_income_share_adjudicated.parquet"
    )) != 131473L) {
  stop("A low-income-share output row count changed on round trip.",
    call. = FALSE)
}
