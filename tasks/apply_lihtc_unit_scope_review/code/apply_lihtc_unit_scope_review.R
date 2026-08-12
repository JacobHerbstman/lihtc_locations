# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/apply_lihtc_unit_scope_review/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
})

development <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_singleton_identity_scope_adjudicated.parquet"
))
episode <- as.data.table(read_parquet(
  "../input/lihtc_project_episode_2024_singleton_identity_scope_adjudicated.parquet"
))
site <- as.data.table(read_parquet(
  "../input/lihtc_development_site_2024_singleton_identity_scope_adjudicated.parquet"
))
question_decisions <- as.data.table(read_parquet(
  "../input/lihtc_unit_scope_question_decisions.parquet"
))
member_decisions <- as.data.table(read_parquet(
  "../input/lihtc_unit_scope_member_decisions.parquet"
))

if (uniqueN(development$development_id) != nrow(development) ||
    uniqueN(episode$hud_id) != nrow(episode) ||
    uniqueN(site$development_site_id) != nrow(site) ||
    uniqueN(question_decisions$unit_scope_question_id) !=
      nrow(question_decisions) ||
    uniqueN(question_decisions$development_id) !=
      nrow(question_decisions) ||
    uniqueN(member_decisions$hud_id) != nrow(member_decisions) ||
    anyNA(development$singleton_identity_development_scope_status) ||
    anyNA(episode$singleton_identity_development_scope_status) ||
    anyNA(site$singleton_identity_development_scope_status) ||
    any(!episode$development_id %chin% development$development_id) ||
    any(!site$development_id %chin% development$development_id)) {
  stop("A corrected input key or physical-scope field is invalid.",
    call. = FALSE)
}

valid_states <- c(state.abb, "DC")
nonphysical_development_ids <- development[
  startsWith(
    singleton_identity_development_scope_status,
    "nonphysical_"
  ),
  development_id
]
territory_development_ids <- development[
  !startsWith(
    singleton_identity_development_scope_status,
    "nonphysical_"
  ) & !development_state %chin% valid_states,
  development_id
]
excluded_development_ids <- c(
  nonphysical_development_ids,
  territory_development_ids
)
physical_development <- development[
  !development_id %chin% excluded_development_ids
]
physical_episode <- episode[
  development_id %chin% physical_development$development_id
]
physical_site <- site[
  development_id %chin% physical_development$development_id
]
excluded_episode_evidence <- episode[
  development_id %chin% excluded_development_ids
]
excluded_episode_evidence[, unit_scope_exclusion_status := fcase(
  development_id %chin% nonphysical_development_ids,
  "nonphysical_development_scope",
  development_id %chin% territory_development_ids,
  "outside_50_states_and_dc"
)]

if (nrow(physical_development) != 53469L ||
    nrow(physical_episode) != 54902L ||
    nrow(physical_site) != 131473L ||
    nrow(excluded_episode_evidence) != 443L ||
    excluded_episode_evidence[
      unit_scope_exclusion_status == "nonphysical_development_scope",
      .N
    ] != 26L ||
    excluded_episode_evidence[
      unit_scope_exclusion_status == "outside_50_states_and_dc",
      .N
    ] != 417L ||
    anyNA(excluded_episode_evidence$unit_scope_exclusion_status) ||
    any(physical_development$development_id %chin%
      excluded_development_ids) ||
    any(!physical_development$development_state %chin% valid_states) ||
    any(startsWith(
      physical_development$singleton_identity_development_scope_status,
      "nonphysical_"
    )) ||
    length(intersect(
      physical_episode$hud_id,
      excluded_episode_evidence$hud_id
    )) > 0L ||
    uniqueN(c(
      physical_episode$hud_id,
      excluded_episode_evidence$hud_id
    )) != nrow(episode) ||
    !setequal(
      c(physical_episode$hud_id, excluded_episode_evidence$hud_id),
      episode$hud_id
    )) {
  stop(
    "The physical and excluded episode outputs are not an exact partition.",
    call. = FALSE
  )
}

if (any(question_decisions$development_id %chin%
      excluded_development_ids) ||
    any(!question_decisions$development_id %chin%
      physical_development$development_id) ||
    any(!member_decisions$hud_id %chin% physical_episode$hud_id) ||
    !setequal(
      member_decisions$unit_scope_question_id,
      question_decisions$unit_scope_question_id
    )) {
  stop("A unit-scope decision refers to an excluded or unknown row.",
    call. = FALSE)
}

physical_development[, `:=`(
  pre_unit_scope_n_units_development = n_units_development,
  pre_unit_scope_li_units_development = li_units_development
)]
physical_development[question_decisions, `:=`(
  unit_scope_question_id = i.unit_scope_question_id,
  unit_scope_final_total_action = i.final_total_action,
  unit_scope_final_total_value = i.final_total_value,
  unit_scope_final_total_reason_code = i.final_total_reason_code,
  unit_scope_final_low_income_action = i.final_low_income_action,
  unit_scope_final_low_income_value = i.final_low_income_value,
  unit_scope_final_low_income_reason_code =
    i.final_low_income_reason_code,
  unit_scope_final_notes = i.final_notes,
  unit_scope_final_reviewed_on = i.final_reviewed_on
), on = "development_id"]
physical_development[, unit_scope_review_status := fifelse(
  is.na(unit_scope_question_id),
  "not_in_unit_scope_review",
  "reviewed"
)]
physical_development[!is.na(unit_scope_question_id), `:=`(
  n_units_development = unit_scope_final_total_value,
  li_units_development = unit_scope_final_low_income_value,
  unit_aggregation_status = fcase(
    !is.na(unit_scope_final_total_value) &
      !is.na(unit_scope_final_low_income_value),
    "resolved_unit_scope_review",
    !is.na(unit_scope_final_total_value) |
      !is.na(unit_scope_final_low_income_value),
    "partially_resolved_unit_scope_review",
    default = "reviewed_no_static_or_unavailable_value"
  ),
  unit_aggregation_rule = paste(
    unit_scope_final_total_action,
    unit_scope_final_low_income_action,
    sep = "|"
  )
)]

if (physical_development[
      !is.na(n_units_development) & n_units_development <= 0,
      .N
    ] > 0L ||
    physical_development[
      !is.na(li_units_development) & li_units_development < 0,
      .N
    ] > 0L ||
    physical_development[
      !is.na(n_units_development) & !is.na(li_units_development) &
        li_units_development > n_units_development,
      .N
    ] > 0L) {
  stop("An applied physical-development unit value is invalid.",
    call. = FALSE)
}

physical_development[, downstream_unit_analysis_status := fcase(
  !is.na(n_units_development) & !is.na(li_units_development),
  "eligible_total_and_low_income",
  !is.na(n_units_development),
  "eligible_total_only",
  !is.na(li_units_development),
  "eligible_low_income_only",
  default = "exclude_missing_both_unit_counts"
)]
physical_development[, downstream_unit_analysis_eligible :=
  downstream_unit_analysis_status !=
    "exclude_missing_both_unit_counts"]

if (physical_development[
      downstream_unit_analysis_status ==
        "exclude_missing_both_unit_counts",
      .N
    ] != 400L ||
    physical_development[
      downstream_unit_analysis_status ==
        "eligible_total_and_low_income",
      .N
    ] != 52919L ||
    physical_development[
      downstream_unit_analysis_status == "eligible_total_only",
      .N
    ] != 132L ||
    physical_development[
      downstream_unit_analysis_status == "eligible_low_income_only",
      .N
    ] != 18L ||
    anyNA(physical_development$downstream_unit_analysis_eligible)) {
  stop("The downstream unit-analysis partition is invalid.",
    call. = FALSE)
}

physical_episode[member_decisions, `:=`(
  unit_scope_question_id = i.unit_scope_question_id,
  unit_scope_final_total_member_role = i.final_total_member_role,
  unit_scope_final_total_value_source = i.final_total_value_source,
  unit_scope_final_total_member_reason_code =
    i.final_total_member_reason_code,
  unit_scope_final_low_income_member_role =
    i.final_low_income_member_role,
  unit_scope_final_low_income_value_source =
    i.final_low_income_value_source,
  unit_scope_final_low_income_member_reason_code =
    i.final_low_income_member_reason_code
), on = "hud_id"]

development_unit_fields <- physical_development[, .(
  development_id,
  n_units_development,
  li_units_development,
  unit_scope_question_id,
  unit_scope_review_status,
  unit_scope_final_total_action,
  unit_scope_final_low_income_action,
  downstream_unit_analysis_status,
  downstream_unit_analysis_eligible
)]
if (uniqueN(development_unit_fields$development_id) !=
    nrow(development_unit_fields)) {
  stop("The development unit handoff is not unique.", call. = FALSE)
}

physical_episode[development_unit_fields, `:=`(
  n_units_physical_development = i.n_units_development,
  li_units_physical_development = i.li_units_development,
  unit_scope_question_id = i.unit_scope_question_id,
  unit_scope_review_status = i.unit_scope_review_status,
  unit_scope_final_total_action = i.unit_scope_final_total_action,
  unit_scope_final_low_income_action =
    i.unit_scope_final_low_income_action,
  downstream_unit_analysis_status =
    i.downstream_unit_analysis_status,
  downstream_unit_analysis_eligible =
    i.downstream_unit_analysis_eligible
), on = "development_id"]
physical_site[development_unit_fields, `:=`(
  n_units_physical_development = i.n_units_development,
  li_units_physical_development = i.li_units_development,
  unit_scope_question_id = i.unit_scope_question_id,
  unit_scope_review_status = i.unit_scope_review_status,
  unit_scope_final_total_action = i.unit_scope_final_total_action,
  unit_scope_final_low_income_action =
    i.unit_scope_final_low_income_action,
  downstream_unit_analysis_status =
    i.downstream_unit_analysis_status,
  downstream_unit_analysis_eligible =
    i.downstream_unit_analysis_eligible
), on = "development_id"]

if (anyNA(physical_episode$unit_scope_review_status) ||
    anyNA(physical_site$unit_scope_review_status) ||
    anyNA(physical_episode$downstream_unit_analysis_status) ||
    anyNA(physical_site$downstream_unit_analysis_status) ||
    any(physical_episode$development_id %chin%
      excluded_development_ids) ||
    any(physical_site$development_id %chin%
      excluded_development_ids) ||
    any(excluded_episode_evidence$development_id %chin%
      physical_development$development_id)) {
  stop("The final physical/nonphysical partition failed.", call. = FALSE)
}

setorder(physical_development, development_state, development_id)
setorder(physical_episode, development_id, episode_number, hud_id)
setorder(physical_site, development_id, site_number, development_site_id)
setorder(excluded_episode_evidence, development_id, episode_number, hud_id)

write_parquet(
  physical_development,
  "../output/lihtc_development_2024_unit_scope_adjudicated.parquet",
  compression = "zstd"
)
write_parquet(
  physical_episode,
  "../output/lihtc_project_episode_2024_unit_scope_adjudicated.parquet",
  compression = "zstd"
)
write_parquet(
  physical_site,
  "../output/lihtc_development_site_2024_unit_scope_adjudicated.parquet",
  compression = "zstd"
)
write_parquet(
  excluded_episode_evidence,
  "../output/lihtc_excluded_episode_2024_unit_scope_evidence.parquet",
  compression = "zstd"
)

development_round_trip <- as.data.table(read_parquet(
  "../output/lihtc_development_2024_unit_scope_adjudicated.parquet"
))
episode_round_trip <- as.data.table(read_parquet(
  "../output/lihtc_project_episode_2024_unit_scope_adjudicated.parquet"
))
site_round_trip <- as.data.table(read_parquet(
  "../output/lihtc_development_site_2024_unit_scope_adjudicated.parquet"
))
excluded_round_trip <- as.data.table(read_parquet(
  "../output/lihtc_excluded_episode_2024_unit_scope_evidence.parquet"
))
if (!isTRUE(all.equal(physical_development, development_round_trip)) ||
    !isTRUE(all.equal(physical_episode, episode_round_trip)) ||
    !isTRUE(all.equal(physical_site, site_round_trip)) ||
    !isTRUE(all.equal(excluded_episode_evidence, excluded_round_trip))) {
  stop("A final unit-scope Parquet round trip changed data.",
    call. = FALSE)
}

message(
  "Applied ", format(nrow(question_decisions), big.mark = ","),
  " unit-scope decisions to ",
  format(nrow(physical_development), big.mark = ","),
  " physical developments; preserved ",
  format(nrow(excluded_episode_evidence), big.mark = ","),
  " excluded episode rows as evidence."
)
