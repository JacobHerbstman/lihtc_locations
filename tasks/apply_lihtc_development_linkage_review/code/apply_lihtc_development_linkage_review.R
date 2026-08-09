# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/apply_lihtc_development_linkage_review/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
})

development <- as.data.table(read_parquet(
  "../input/lihtc_development_2024.parquet"
))
episode <- as.data.table(read_parquet(
  "../input/lihtc_project_episode_2024.parquet"
))
site <- as.data.table(read_parquet(
  "../input/lihtc_development_site_2024.parquet"
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
    uniqueN(decisions$development_id) != nrow(decisions) ||
    uniqueN(members$hud_id) != nrow(members)) {
  stop("An input key is not unique.", call. = FALSE)
}
if (!setequal(
  decisions$development_id,
  development[n_project_episodes > 1L, development_id]
) || !setequal(
  members$hud_id,
  episode[n_project_episodes > 1L, hud_id]
)) {
  stop("The linkage review does not match the provisional build.", call. = FALSE)
}

episode[, `:=`(
  provisional_development_id = development_id,
  linkage_review_decision = "not_applicable_singleton",
  linkage_review_reason_code = NA_character_,
  linkage_reviewed_on = as.Date(NA)
)]
episode[members, `:=`(
  development_id = i.adjudicated_development_id,
  development_anchor_hud_id = i.adjudicated_development_anchor_hud_id,
  linkage_review_decision = i.final_decision,
  linkage_review_reason_code = i.final_reason_code
), on = "hud_id"]
episode[decisions, linkage_reviewed_on :=
  i.final_reviewed_on, on = c(provisional_development_id = "development_id")]

episode[linkage_review_decision == "accept", `:=`(
  development_linkage_status = "adjudicated_linked",
  requires_linkage_review = FALSE
)]
episode[linkage_review_decision == "reject", `:=`(
  episode_number = 1L,
  is_development_anchor = TRUE,
  development_linkage_status = "adjudicated_singleton_after_rejected_link",
  development_linkage_basis = "singleton_hud_id_after_rejected_linkage",
  requires_linkage_review = FALSE,
  n_project_episodes = 1L
)]

reviewed_episode_counts <- episode[
  linkage_review_decision %chin% c("accept", "reject"),
  .N,
  by = development_id
]
if (reviewed_episode_counts[N > 1L, .N] != 322L ||
    reviewed_episode_counts[N == 1L, .N] != 10L) {
  stop("The review did not produce the expected episode groups.", call. = FALSE)
}

development[, `:=`(
  provisional_development_id = development_id,
  linkage_review_decision = "not_applicable_singleton",
  linkage_review_reason_code = NA_character_,
  linkage_reviewed_on = as.Date(NA)
)]
development[decisions[final_decision == "accept"], `:=`(
  development_linkage_status = "adjudicated_linked",
  requires_linkage_review = FALSE,
  linkage_review_decision = i.final_decision,
  linkage_review_reason_code = i.final_reason_code,
  linkage_reviewed_on = i.final_reviewed_on
), on = "development_id"]

rejected_group_ids <- decisions[final_decision == "reject", development_id]
development <- development[!development_id %chin% rejected_group_ids]

rejected_developments <- episode[linkage_review_decision == "reject", {
  .(
    provisional_development_id = provisional_development_id,
    development_anchor_hud_id = hud_id,
    development_name = project,
    development_name_key = name_key,
    development_state = proj_st,
    development_city = proj_cty,
    development_linkage_status = development_linkage_status,
    development_linkage_basis = development_linkage_basis,
    requires_linkage_review = FALSE,
    linkage_review_decision = linkage_review_decision,
    linkage_review_reason_code = linkage_review_reason_code,
    linkage_reviewed_on = linkage_reviewed_on,
    n_project_episodes = 1L,
    first_pis_year = pis_year,
    last_pis_year = pis_year,
    any_resyndication_reported =
      !is.na(resyndication_cd) & resyndication_cd == "1",
    construction_type_codes = ifelse(is.na(type), "", type),
    episode_unit_count_max = episode_units,
    episode_unit_count_sum = episode_units,
    unit_aggregation_status = "resolved_single_episode",
    unit_aggregation_rule = "single_episode_source",
    n_units_development = episode_units,
    li_units_development = episode_low_income_units,
    candidate_n_units_development = episode_units,
    candidate_li_units_development = episode_low_income_units,
    n_development_sites = 0L,
    n_sites_with_hud_coordinates = 0L,
    n_sites_requiring_review = 0L
  )
}, by = development_id]

development <- rbindlist(
  list(development, rejected_developments),
  use.names = TRUE
)

site <- site[!development_id %chin% rejected_group_ids]
rejected_sites <- episode[
  linkage_review_decision == "reject" & !is.na(primary_site_key),
  .(
    development_site_id = paste0(development_id, "_SITE_0001"),
    development_id,
    site_number = 1L,
    site_key = primary_site_key,
    site_street = proj_add,
    site_city = proj_cty,
    site_state = proj_st,
    site_zip = proj_zip,
    site_source = "project_primary",
    n_project_episodes = 1L,
    hud_ids = hud_id,
    n_bin_values = 0L,
    bin_example = NA_character_,
    n_coordinate_pairs = 0L,
    latitude = NA_real_,
    longitude = NA_real_,
    requires_site_review = TRUE
  )
]
site <- rbindlist(list(site, rejected_sites), use.names = TRUE)

site_summary <- site[, .(
  n_development_sites = .N,
  n_sites_with_hud_coordinates = sum(!is.na(latitude) & !is.na(longitude)),
  n_sites_requiring_review = sum(requires_site_review)
), by = development_id]
development[, `:=`(
  n_development_sites = 0L,
  n_sites_with_hud_coordinates = 0L,
  n_sites_requiring_review = 0L
)]
development[site_summary, `:=`(
  n_development_sites = i.n_development_sites,
  n_sites_with_hud_coordinates = i.n_sites_with_hud_coordinates,
  n_sites_requiring_review = i.n_sites_requiring_review
), on = "development_id"]

setorder(development, development_id)
setorder(episode, development_id, episode_number, hud_id)
setorder(site, development_id, site_number, site_key)
setcolorder(development, c(
  "development_id", "provisional_development_id",
  "development_anchor_hud_id", "development_name", "development_name_key",
  "development_state", "development_city", "development_linkage_status",
  "development_linkage_basis", "requires_linkage_review",
  "linkage_review_decision", "linkage_review_reason_code",
  "linkage_reviewed_on", "n_project_episodes",
  setdiff(names(development), c(
    "development_id", "provisional_development_id",
    "development_anchor_hud_id", "development_name", "development_name_key",
    "development_state", "development_city", "development_linkage_status",
    "development_linkage_basis", "requires_linkage_review",
    "linkage_review_decision", "linkage_review_reason_code",
    "linkage_reviewed_on", "n_project_episodes"
  ))
))
setcolorder(episode, c(
  "development_id", "provisional_development_id",
  "development_anchor_hud_id", "hud_id", "episode_number",
  "is_development_anchor", "development_linkage_status",
  "development_linkage_basis", "requires_linkage_review",
  "linkage_review_decision", "linkage_review_reason_code",
  "linkage_reviewed_on", "n_project_episodes",
  setdiff(names(episode), c(
    "development_id", "provisional_development_id",
    "development_anchor_hud_id", "hud_id", "episode_number",
    "is_development_anchor", "development_linkage_status",
    "development_linkage_basis", "requires_linkage_review",
    "linkage_review_decision", "linkage_review_reason_code",
    "linkage_reviewed_on", "n_project_episodes"
  ))
))

if (nrow(development) != 54879L ||
    uniqueN(development$development_id) != nrow(development)) {
  stop("The adjudicated development count or key is wrong.", call. = FALSE)
}
if (nrow(episode) != 55345L || uniqueN(episode$hud_id) != nrow(episode)) {
  stop("The adjudicated episode table lost or duplicated a HUD row.",
    call. = FALSE)
}
if (nrow(site) != 135013L ||
    uniqueN(site$development_site_id) != nrow(site) ||
    uniqueN(site, by = c("development_id", "site_key")) != nrow(site)) {
  stop("The adjudicated site count or key is wrong.", call. = FALSE)
}
if (any(!episode$development_id %chin% development$development_id) ||
    any(!site$development_id %chin% development$development_id)) {
  stop("An adjudicated episode or site has no development.", call. = FALSE)
}
if (any(development$requires_linkage_review) ||
    any(episode$requires_linkage_review)) {
  stop("A provisional linkage review flag remains after adjudication.",
    call. = FALSE)
}

write_parquet(
  development,
  "../output/lihtc_development_2024_adjudicated.parquet",
  compression = "zstd"
)
write_parquet(
  episode,
  "../output/lihtc_project_episode_2024_adjudicated.parquet",
  compression = "zstd"
)
write_parquet(
  site,
  "../output/lihtc_development_site_2024_adjudicated.parquet",
  compression = "zstd"
)

if (!identical(
  development,
  as.data.table(read_parquet(
    "../output/lihtc_development_2024_adjudicated.parquet"
  ))
) || !identical(
  episode,
  as.data.table(read_parquet(
    "../output/lihtc_project_episode_2024_adjudicated.parquet"
  ))
) || !identical(
  site,
  as.data.table(read_parquet(
    "../output/lihtc_development_site_2024_adjudicated.parquet"
  ))
)) {
  stop("An adjudicated Parquet changed on round trip.", call. = FALSE)
}

cat(
  "Applied 325 linkage decisions to build 54,879 developments, 55,345 ",
  "project episodes, and 135,013 development sites.\n",
  sep = ""
)
