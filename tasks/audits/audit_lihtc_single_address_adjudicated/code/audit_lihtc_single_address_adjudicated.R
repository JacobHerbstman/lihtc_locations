# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/audit_lihtc_single_address_adjudicated/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
  library(stringr)
})

normalize_text <- function(value) {
  value <- iconv(value, from = "", to = "ASCII//TRANSLIT", sub = "")
  value <- str_to_upper(str_squish(value))
  value <- str_replace_all(value, "[^A-Z0-9]+", " ")
  value <- str_squish(value)
  value[value == ""] <- NA_character_
  value
}

normalize_street <- function(value) {
  value <- normalize_text(value)
  replacements <- c(
    "NORTHEAST" = "NE",
    "NORTHWEST" = "NW",
    "SOUTHEAST" = "SE",
    "SOUTHWEST" = "SW",
    "NORTH" = "N",
    "SOUTH" = "S",
    "EAST" = "E",
    "WEST" = "W",
    "STREET" = "ST",
    "AVENUE" = "AVE",
    "BOULEVARD" = "BLVD",
    "CIRCLE" = "CIR",
    "COURT" = "CT",
    "DRIVE" = "DR",
    "EXPRESSWAY" = "EXPY",
    "HIGHWAY" = "HWY",
    "LANE" = "LN",
    "PARKWAY" = "PKWY",
    "PLACE" = "PL",
    "PLAZA" = "PLZ",
    "ROAD" = "RD",
    "TERRACE" = "TER",
    "TRAIL" = "TRL",
    "TURNPIKE" = "TPKE",
    "APARTMENT" = "APT",
    "BUILDING" = "BLDG"
  )
  for (term in names(replacements)) {
    value <- str_replace_all(
      value,
      paste0("\\b", term, "\\b"),
      replacements[[term]]
    )
  }
  str_squish(value)
}

make_site_key <- function(state, street, city) {
  paste(
    fcoalesce(normalize_text(state), ""),
    fcoalesce(normalize_street(street), ""),
    fcoalesce(normalize_text(city), ""),
    sep = "|"
  )
}

first_text <- function(value) {
  value <- sort(unique(value[!is.na(value) & value != ""]))
  if (length(value) == 0L) NA_character_ else value[1L]
}

development_before <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_identical_address_adjudicated.parquet"
))
episode_before <- as.data.table(read_parquet(
  "../input/lihtc_project_episode_2024_identical_address_adjudicated.parquet"
))
site_before <- as.data.table(read_parquet(
  "../input/lihtc_development_site_2024_identical_address_adjudicated.parquet"
))
development <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_single_address_adjudicated.parquet"
))
episode <- as.data.table(read_parquet(
  "../input/lihtc_project_episode_2024_single_address_adjudicated.parquet"
))
site <- as.data.table(read_parquet(
  "../input/lihtc_development_site_2024_single_address_adjudicated.parquet"
))
multisite <- as.data.table(read_parquet(
  "../input/lihtc_multisite_2024_raw_text.parquet"
))
reviews <- as.data.table(read_parquet(
  "../input/lihtc_single_address_question_reviews.parquet"
))
members <- as.data.table(read_parquet(
  "../input/lihtc_single_address_member_partitions.parquet"
))

if (nrow(development_before) != 54257L ||
    uniqueN(development_before$development_id) !=
      nrow(development_before) ||
    nrow(episode_before) != 55345L ||
    uniqueN(episode_before$hud_id) != nrow(episode_before) ||
    nrow(site_before) != 133551L ||
    uniqueN(site_before, by = c("development_id", "site_key")) !=
      nrow(site_before) ||
    nrow(development) != 54030L ||
    uniqueN(development$development_id) != nrow(development) ||
    nrow(episode) != 55345L || uniqueN(episode$hud_id) != nrow(episode) ||
    nrow(site) != 133324L ||
    uniqueN(site$development_site_id) != nrow(site) ||
    uniqueN(site, by = c("development_id", "site_key")) != nrow(site) ||
    nrow(reviews) != 1149L || nrow(members) != 2463L) {
  stop("An applied single-address table count or primary key changed.",
    call. = FALSE)
}

assignment <- development_before[, .(
  pre_development_id = development_id,
  expected_development_id = development_id
)]
assignment[members, expected_development_id :=
  i.adjudicated_development_id,
on = c(pre_development_id = "development_id")]
if (uniqueN(assignment$expected_development_id) != nrow(development)) {
  stop("The committed partition does not produce the output development count.",
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
    pre_single_address_review_development_ids
)]
expected_development_members[observed_development_members,
  observed_pre_development_ids := i.observed_pre_development_ids,
  on = "expected_development_id"]
if (anyNA(expected_development_members$observed_pre_development_ids) ||
    any(
      expected_development_members$expected_pre_development_ids !=
        expected_development_members$observed_pre_development_ids
    )) {
  stop("A development lineage does not match the committed partition.",
    call. = FALSE)
}

expected_episode_assignment <- episode_before[, .(
  hud_id,
  pre_development_id = development_id,
  expected_development_id = development_id
)]
expected_episode_assignment[members, expected_development_id :=
  i.adjudicated_development_id,
on = c(pre_development_id = "development_id")]
observed_episode_assignment <- episode[, .(
  hud_id,
  observed_pre_development_id =
    pre_single_address_review_development_id,
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

unreviewed_ids <- development_before[
  !development_id %chin% members$development_id,
  development_id
]
unreviewed_development_before <- development_before[
  development_id %chin% unreviewed_ids
]
unreviewed_development <- development[
  development_id %chin% unreviewed_ids,
  names(development_before),
  with = FALSE
]
setorder(unreviewed_development_before, development_id)
setorder(unreviewed_development, development_id)
if (!identical(unreviewed_development_before, unreviewed_development)) {
  stop("A development outside the review changed.", call. = FALSE)
}

retained_ids <- members[
  member_action == "retain_current_development",
  development_id
]
allowed_retained_development_changes <- c(
  "development_linkage_status",
  "development_linkage_basis",
  "requires_linkage_review"
)
protected_retained_fields <- setdiff(
  names(development_before),
  allowed_retained_development_changes
)
retained_before <- development_before[
  development_id %chin% retained_ids,
  protected_retained_fields,
  with = FALSE
]
retained_after <- development[
  development_id %chin% retained_ids,
  protected_retained_fields,
  with = FALSE
]
setorder(retained_before, development_id)
setorder(retained_after, development_id)
if (!identical(retained_before, retained_after)) {
  stop("A protected retained-development field changed.", call. = FALSE)
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
  stop("A site does not preserve its contributing HUD identifiers.",
    call. = FALSE)
}

merged_current_developments <- members[
  member_action == "merge_to_review_cluster",
  development_id
]
unchanged_site_before <- site_before[
  !development_id %chin% merged_current_developments
]
unchanged_site <- site[
  development_id %chin% unchanged_site_before$development_id
]
setorder(unchanged_site_before, development_site_id)
setorder(unchanged_site, development_site_id)
if (!identical(unchanged_site_before, unchanged_site)) {
  stop("A site outside a merged cluster changed.", call. = FALSE)
}

uninformative_streets <- c(
  "N A", "NA", "NONE", "UNKNOWN", "UNAVAILABLE", "NOT AVAILABLE",
  "VARIOUS", "MULTIPLE", "MULTIPLE LOCATIONS", "SCATTERED",
  "SCATTERED SITE", "SCATTERED SITES", "TBD"
)
source_episode <- copy(episode_before)
source_episode[, expected_development_id := development_id]
source_episode[members, expected_development_id :=
  i.adjudicated_development_id,
on = "development_id"]

expected_primary_sources <- source_episode[
  development_id %chin% merged_current_developments &
    !is.na(primary_site_key),
  .(
    development_id = expected_development_id,
    hud_id,
    site_key = primary_site_key,
    source_type = "project_primary",
    raw_street = proj_add,
    raw_city = proj_cty,
    raw_state = proj_st,
    raw_zip = proj_zip,
    raw_bin = NA_character_,
    latitude_raw = latitude,
    longitude_raw = longitude
  )
]

multisite[, `:=`(
  street_key = normalize_street(bin_add),
  site_key = make_site_key(proj_st, bin_add, bin_cty),
  source_development_id =
    source_episode$development_id[match(hud_id, source_episode$hud_id)],
  expected_development_id =
    source_episode$expected_development_id[
      match(hud_id, source_episode$hud_id)
    ]
)]
if (anyNA(multisite$source_development_id) ||
    anyNA(multisite$expected_development_id)) {
  stop("A raw multisite row does not map to one project episode.",
    call. = FALSE)
}
multisite[, informative_site :=
  !is.na(street_key) & !street_key %chin% uninformative_streets]
expected_multisite_sources <- multisite[
  source_development_id %chin% merged_current_developments &
    informative_site == TRUE,
  .(
    development_id = expected_development_id,
    hud_id,
    site_key,
    source_type = "multi_address",
    raw_street = bin_add,
    raw_city = bin_cty,
    raw_state = proj_st,
    raw_zip = bin_zip,
    raw_bin = bin,
    latitude_raw = NA_character_,
    longitude_raw = NA_character_
  )
]

expected_site_sources <- unique(rbindlist(list(
  expected_primary_sources,
  expected_multisite_sources
), use.names = TRUE))
expected_site_sources[, `:=`(
  latitude_value = suppressWarnings(as.numeric(latitude_raw)),
  longitude_value = suppressWarnings(as.numeric(longitude_raw))
)]
expected_site_sources[
  latitude_value < -90 | latitude_value > 90 |
    longitude_value < -180 | longitude_value > 180,
  `:=`(latitude_value = NA_real_, longitude_value = NA_real_)
]

expected_merged_site <- expected_site_sources[, {
  coordinate_pairs <- unique(data.table(
    latitude = latitude_value[
      !is.na(latitude_value) & !is.na(longitude_value)
    ],
    longitude = longitude_value[
      !is.na(latitude_value) & !is.na(longitude_value)
    ]
  ))
  n_coordinate_pairs <- nrow(coordinate_pairs)

  .(
    site_street = first_text(raw_street),
    site_city = first_text(raw_city),
    site_state = first_text(raw_state),
    site_zip = first_text(raw_zip),
    site_source = fcase(
      any(source_type == "project_primary") &
        any(source_type == "multi_address"),
      "project_primary+multi_address",
      any(source_type == "project_primary"),
      "project_primary",
      default = "multi_address"
    ),
    n_project_episodes = uniqueN(hud_id),
    hud_ids = paste(sort(unique(hud_id)), collapse = "|"),
    n_bin_values = uniqueN(raw_bin, na.rm = TRUE),
    bin_example = first_text(raw_bin),
    n_coordinate_pairs = n_coordinate_pairs,
    latitude = if (n_coordinate_pairs == 1L) {
      coordinate_pairs$latitude[1L]
    } else {
      NA_real_
    },
    longitude = if (n_coordinate_pairs == 1L) {
      coordinate_pairs$longitude[1L]
    } else {
      NA_real_
    }
  )
}, by = .(development_id, site_key)]
setorder(expected_merged_site, development_id, site_key)
expected_merged_site[, site_number := seq_len(.N), by = development_id]
expected_merged_site[, development_site_id := paste0(
  development_id,
  "_SITE_",
  sprintf("%04d", site_number)
)]
expected_merged_site[, requires_site_review :=
  n_coordinate_pairs > 1L |
    str_detect(normalize_street(site_street), "\\b(UNIT|APT)\\b")]
setcolorder(expected_merged_site, names(site_before))

observed_merged_site <- site[
  development_id %chin% members[
    member_action == "merge_to_review_cluster",
    unique(adjudicated_development_id)
  ]
]
setorder(expected_merged_site, development_site_id)
setorder(observed_merged_site, development_site_id)
if (!identical(expected_merged_site, observed_merged_site)) {
  stop("A reconstructed merged-site field differs from its raw sources.",
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

site_summary <- site[, .(
  expected_site_count = .N,
  expected_coordinate_site_count = sum(
    !is.na(latitude) & !is.na(longitude)
  ),
  expected_review_site_count = sum(requires_site_review)
), by = development_id]
site_summary[development[, .(
  development_id,
  observed_site_count = n_development_sites,
  observed_coordinate_site_count = n_sites_with_hud_coordinates,
  observed_review_site_count = n_sites_requiring_review
)], `:=`(
  observed_site_count = i.observed_site_count,
  observed_coordinate_site_count = i.observed_coordinate_site_count,
  observed_review_site_count = i.observed_review_site_count
), on = "development_id"]
if (anyNA(site_summary$observed_site_count) ||
    any(site_summary$expected_site_count != site_summary$observed_site_count) ||
    any(
      site_summary$expected_coordinate_site_count !=
        site_summary$observed_coordinate_site_count
    ) ||
    any(
      site_summary$expected_review_site_count !=
        site_summary$observed_review_site_count
    )) {
  stop("A development site summary is inconsistent.", call. = FALSE)
}

merged_developments <- development[
  single_address_review_action == "merge_to_review_cluster"
]
retained_developments <- development[
  single_address_review_action == "retain_current_development"
]
reviewed_episodes <- episode[
  single_address_review_action != "not_applicable"
]
territory_ids <- development_before[
  !development_state %chin% c(state.abb, "DC"),
  development_id
]
if (nrow(merged_developments) != 215L ||
    nrow(retained_developments) != 2021L ||
    nrow(reviewed_episodes) != 2472L ||
    merged_developments[,
      any(
        !is.na(n_units_development) |
          !is.na(li_units_development) |
          !is.na(candidate_n_units_development) |
          !is.na(candidate_li_units_development)
      )
    ] ||
    development[unit_aggregation_status == "requires_review", .N] != 1052L ||
    any(
      reviewed_episodes$single_address_review_shared_query_decision !=
        "not_approved"
    ) ||
    any(reviews$source_rows_changed) || any(members$source_rows_changed) ||
    any(members$development_id %chin% territory_ids) ||
    any(!episode$development_id %chin% development$development_id) ||
    any(!site$development_id %chin% development$development_id) ||
    episode[is_development_anchor == TRUE, .N] != nrow(development)) {
  stop("A single-address application safeguard failed.", call. = FALSE)
}

decision_summary <- reviews[, .(
  questions = .N,
  reviewed_records = sum(n_members),
  physical_developments = sum(n_clusters)
), by = final_identity_decision][order(final_identity_decision)]
decision_rows <- sprintf(
  "| %s | %s | %s | %s |",
  decision_summary$final_identity_decision,
  decision_summary$questions,
  decision_summary$reviewed_records,
  decision_summary$physical_developments
)

writeLines(c(
  "# LIHTC Single-Address Application Audit",
  "",
  "## Applied identity decisions",
  "",
  "| Decision | Questions | Reviewed records | Physical developments |",
  "| --- | ---: | ---: | ---: |",
  decision_rows,
  "",
  "- Reviewed development records: 2,463.",
  "- Reviewed physical-development clusters: 2,236.",
  "- Multi-member clusters: 215.",
  "- Reviewed singleton developments: 2,021.",
  "",
  "## Output reconciliation",
  "",
  "- Physical developments: 54,030 (227 fewer).",
  "- HUD project episodes: 55,345 (none removed).",
  "- Development sites: 133,324 (227 duplicate mapped keys collapsed).",
  "- Protected project-episode fields changed: 0.",
  "- Unreviewed development records changed: 0.",
  "- Protected retained-development fields changed: 0.",
  "- Source development/site keys lost or invented: 0.",
  "- Reconstructed merged-site fields differing from raw sources: 0.",
  "- Unmerged site records changed: 0.",
  "- Territory developments reviewed or changed: 0.",
  "- Shared geocoding queries approved: 0.",
  "- Source rows changed: 0.",
  "",
  "## Unit safeguard",
  "",
  "- Developments requiring unit-scope review: 1,052.",
  "- Newly merged developments with unit totals deliberately unresolved: 215.",
  "- Newly merged development unit totals resolved by this task: 0.",
  "",
  paste0(
    "The member ledger, rather than a matching rule, determines every applied ",
    "identity. Every HUD episode and source address remains traceable. The ",
    "application makes no address repair and no geocoding decision."
  )
), "../output/audit_summary.md")
