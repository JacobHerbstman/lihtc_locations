# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/apply_lihtc_identical_address_set_review/code")

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

collapse_delimited <- function(value) {
  tokens <- unlist(strsplit(
    value[!is.na(value) & value != ""],
    "|",
    fixed = TRUE
  ))
  tokens <- sort(unique(tokens[tokens != ""]))
  if (length(tokens) == 0L) NA_character_ else paste(tokens, collapse = "|")
}

development_input <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_address_round2_adjudicated.parquet"
))
episode <- as.data.table(read_parquet(
  "../input/lihtc_project_episode_2024_address_round2_adjudicated.parquet"
))
current_site <- as.data.table(read_parquet(
  "../input/lihtc_development_site_2024_address_round2_adjudicated.parquet"
))
multisite <- as.data.table(read_parquet(
  "../input/lihtc_multisite_2024_raw_text.parquet"
))
reviews <- as.data.table(read_parquet(
  "../input/lihtc_identical_address_set_reviews.parquet"
))
members <- as.data.table(read_parquet(
  "../input/lihtc_identical_address_set_proposed_member_mapping.parquet"
))

if (nrow(development_input) != 54344L ||
    uniqueN(development_input$development_id) != nrow(development_input) ||
    nrow(episode) != 55345L || uniqueN(episode$hud_id) != nrow(episode) ||
    nrow(current_site) != 134232L ||
    uniqueN(current_site$development_site_id) != nrow(current_site) ||
    uniqueN(current_site, by = c("development_id", "site_key")) !=
      nrow(current_site) ||
    nrow(reviews) != 98L ||
    uniqueN(reviews$review_question_id) != nrow(reviews) ||
    nrow(members) != 199L ||
    uniqueN(members$development_id) != nrow(members) ||
    uniqueN(members$review_cluster_id) != 112L) {
  stop("An identical-address application input count or key changed.",
    call. = FALSE)
}
if (members[
      member_action == "merge_to_proposed_physical_development",
      .N
    ] != 172L ||
    members[
      member_action == "retain_current_development",
      .N
    ] != 27L ||
    members[
      member_action == "merge_to_proposed_physical_development",
      uniqueN(review_cluster_id)
    ] != 85L ||
    any(members$shared_geocoding_query_decision != "not_approved") ||
    any(reviews$shared_geocoding_query_decision != "not_approved") ||
    any(members$source_rows_changed) ||
    any(reviews$source_rows_changed)) {
  stop("The committed identical-address review contract changed.",
    call. = FALSE)
}
if (any(!members$development_id %chin% development_input$development_id) ||
    any(!members$proposed_physical_development_id %chin%
      development_input$development_id) ||
    !setequal(
      members$review_question_id,
      reviews$review_question_id
    )) {
  stop("A reviewed development or question is absent from the current data.",
    call. = FALSE)
}

mapping <- members[, .(
  current_development_id = development_id,
  review_question_id,
  review_cluster_id,
  member_action,
  adjudicated_development_id = proposed_physical_development_id,
  final_reason_code,
  address_set_assessment,
  shared_geocoding_query_decision
)]
mapping[reviews[, .(
  review_question_id,
  final_reviewed_on
)], final_reviewed_on := i.final_reviewed_on,
on = "review_question_id"]
mapping[development_input[, .(
  adjudicated_development_id = development_id,
  adjudicated_development_anchor_hud_id = development_anchor_hud_id
)], adjudicated_development_anchor_hud_id :=
  i.adjudicated_development_anchor_hud_id,
on = "adjudicated_development_id"]
if (uniqueN(mapping$current_development_id) != nrow(mapping) ||
    anyNA(mapping[, .(
      final_reason_code,
      address_set_assessment,
      final_reviewed_on,
      adjudicated_development_anchor_hud_id
    )])) {
  stop("A current development has an incomplete reviewed mapping.",
    call. = FALSE)
}

episode[, `:=`(
  pre_identical_address_set_review_development_id = development_id,
  identical_address_set_review_question_id = NA_character_,
  identical_address_set_review_cluster_id = NA_character_,
  identical_address_set_review_action = "not_applicable",
  identical_address_set_review_reason_code = NA_character_,
  identical_address_set_address_assessment = NA_character_,
  identical_address_set_reviewed_on = as.Date(NA),
  identical_address_set_shared_query_decision = "not_reviewed"
)]
episode[mapping, `:=`(
  development_id = i.adjudicated_development_id,
  development_anchor_hud_id =
    i.adjudicated_development_anchor_hud_id,
  identical_address_set_review_question_id = i.review_question_id,
  identical_address_set_review_cluster_id = i.review_cluster_id,
  identical_address_set_review_action = i.member_action,
  identical_address_set_review_reason_code = i.final_reason_code,
  identical_address_set_address_assessment = i.address_set_assessment,
  identical_address_set_reviewed_on = as.Date(i.final_reviewed_on),
  identical_address_set_shared_query_decision =
    i.shared_geocoding_query_decision
), on = c(
  pre_identical_address_set_review_development_id =
    "current_development_id"
)]
episode[identical_address_set_review_action ==
    "merge_to_proposed_physical_development", `:=`(
  development_linkage_status =
    "identical_address_set_adjudicated_linked",
  development_linkage_basis =
    "identical_complete_address_set_two_read_review",
  requires_linkage_review = FALSE
)]
episode[identical_address_set_review_action ==
    "retain_current_development", `:=`(
  development_linkage_status =
    "identical_address_set_reviewed_distinct",
  requires_linkage_review = FALSE
)]

episode[, anchor_sort_year := fcase(
  !is.na(pis_year), pis_year,
  !is.na(allocation_year), allocation_year,
  default = 9999L
)]
setorder(
  episode,
  development_id,
  anchor_sort_year,
  allocation_year,
  hud_id,
  na.last = TRUE
)
episode[, `:=`(
  episode_number = seq_len(.N),
  n_project_episodes = .N
), by = development_id]
episode[, is_development_anchor := hud_id == development_anchor_hud_id]
if (episode[is_development_anchor == TRUE, .N] !=
      uniqueN(episode$development_id)) {
  stop("An adjudicated episode group has an invalid anchor.",
    call. = FALSE)
}

development <- copy(development_input)
development[, `:=`(
  current_development_id = development_id,
  pre_identical_address_set_review_development_ids = development_id,
  identical_address_set_review_question_ids = NA_character_,
  identical_address_set_review_cluster_id = NA_character_,
  identical_address_set_review_action = "not_applicable",
  identical_address_set_review_reason_codes = NA_character_,
  identical_address_set_address_assessments = NA_character_,
  identical_address_set_reviewed_on = as.Date(NA),
  identical_address_set_shared_query_decision = "not_reviewed"
)]
development[mapping, `:=`(
  development_id = i.adjudicated_development_id,
  development_anchor_hud_id =
    i.adjudicated_development_anchor_hud_id,
  identical_address_set_review_question_ids = i.review_question_id,
  identical_address_set_review_cluster_id = i.review_cluster_id,
  identical_address_set_review_action = i.member_action,
  identical_address_set_review_reason_codes = i.final_reason_code,
  identical_address_set_address_assessments = i.address_set_assessment,
  identical_address_set_reviewed_on = as.Date(i.final_reviewed_on),
  identical_address_set_shared_query_decision =
    i.shared_geocoding_query_decision
), on = c(current_development_id = "current_development_id")]
development[identical_address_set_review_action ==
    "merge_to_proposed_physical_development", `:=`(
  development_linkage_status =
    "identical_address_set_adjudicated_linked",
  development_linkage_basis =
    "identical_complete_address_set_two_read_review",
  requires_linkage_review = FALSE
)]
development[identical_address_set_review_action ==
    "retain_current_development", `:=`(
  development_linkage_status =
    "identical_address_set_reviewed_distinct",
  requires_linkage_review = FALSE
)]

merged_members <- development[
  identical_address_set_review_action ==
    "merge_to_proposed_physical_development"
]
merged_development <- merged_members[
  current_development_id == development_id
]
if (nrow(merged_development) != 85L ||
    uniqueN(merged_development$development_id) !=
      nrow(merged_development)) {
  stop("A multi-member cluster does not have exactly one anchor row.",
    call. = FALSE)
}

merged_summary <- merged_members[, .(
  pre_identical_address_set_review_development_ids = paste(
    sort(current_development_id),
    collapse = "|"
  ),
  identical_address_set_review_question_ids = collapse_delimited(
    identical_address_set_review_question_ids
  ),
  identical_address_set_review_reason_codes = collapse_delimited(
    identical_address_set_review_reason_codes
  ),
  identical_address_set_address_assessments = collapse_delimited(
    identical_address_set_address_assessments
  ),
  pre_cross_address_round2_development_ids = collapse_delimited(
    pre_cross_address_round2_development_ids
  ),
  pre_cross_address_review_development_ids = collapse_delimited(
    pre_cross_address_review_development_ids
  ),
  pre_name_review_development_ids = collapse_delimited(
    pre_name_review_development_ids
  ),
  cross_address_round2_identity_question_ids = collapse_delimited(
    cross_address_round2_identity_question_ids
  ),
  cross_address_round2_review_reason_codes = collapse_delimited(
    cross_address_round2_review_reason_codes
  ),
  cross_address_round2_overlap_classes = collapse_delimited(
    cross_address_round2_overlap_classes
  ),
  cross_address_identity_question_id = collapse_delimited(
    cross_address_identity_question_id
  ),
  cross_address_review_decision = collapse_delimited(
    cross_address_review_decision
  ),
  cross_address_review_reason_code = collapse_delimited(
    cross_address_review_reason_code
  ),
  cross_address_overlap_class = collapse_delimited(
    cross_address_overlap_class
  ),
  cross_address_shared_query_decision = collapse_delimited(
    cross_address_shared_query_decision
  )
), by = development_id]
episode_summary <- episode[
  development_id %chin% merged_development$development_id,
  .(
    n_project_episodes = .N,
    first_pis_year = if (all(is.na(pis_year))) {
      NA_integer_
    } else {
      min(pis_year, na.rm = TRUE)
    },
    last_pis_year = if (all(is.na(pis_year))) {
      NA_integer_
    } else {
      max(pis_year, na.rm = TRUE)
    },
    any_resyndication_reported = any(
      resyndication_cd == "1",
      na.rm = TRUE
    ),
    construction_type_codes = paste(
      sort(unique(type[!is.na(type)])),
      collapse = "|"
    ),
    episode_unit_count_max = if (all(is.na(episode_units))) {
      NA_real_
    } else {
      max(episode_units, na.rm = TRUE)
    },
    episode_unit_count_sum = if (all(is.na(episode_units))) {
      NA_real_
    } else {
      sum(episode_units, na.rm = TRUE)
    }
  ),
  by = development_id
]
if (nrow(episode_summary) != 85L) {
  stop("A merged development is missing its episode summary.",
    call. = FALSE)
}

merged_fields <- setdiff(names(merged_summary), "development_id")
merged_development[merged_summary,
  (merged_fields) := mget(paste0("i.", merged_fields)),
  on = "development_id"]
merged_development[episode_summary, `:=`(
  n_project_episodes = i.n_project_episodes,
  first_pis_year = i.first_pis_year,
  last_pis_year = i.last_pis_year,
  any_resyndication_reported = i.any_resyndication_reported,
  construction_type_codes = i.construction_type_codes,
  episode_unit_count_max = i.episode_unit_count_max,
  episode_unit_count_sum = i.episode_unit_count_sum
), on = "development_id"]
merged_development[, `:=`(
  unit_aggregation_status = "requires_review",
  unit_aggregation_rule =
    "identical_address_set_identity_merge_requires_unit_review",
  n_units_development = NA_real_,
  li_units_development = NA_real_,
  candidate_n_units_development = NA_real_,
  candidate_li_units_development = NA_real_
)]

development <- rbindlist(list(
  development[
    identical_address_set_review_action !=
      "merge_to_proposed_physical_development"
  ],
  merged_development
), use.names = TRUE)

uninformative_streets <- c(
  "N A", "NA", "NONE", "UNKNOWN", "UNAVAILABLE", "NOT AVAILABLE",
  "VARIOUS", "MULTIPLE", "MULTIPLE LOCATIONS", "SCATTERED",
  "SCATTERED SITE", "SCATTERED SITES", "TBD"
)
multisite[, `:=`(
  street_key = normalize_street(bin_add),
  site_key = make_site_key(proj_st, bin_add, bin_cty)
)]
multisite[, informative_site :=
  !is.na(street_key) & !street_key %chin% uninformative_streets]

merged_current_developments <- mapping[
  member_action == "merge_to_proposed_physical_development",
  current_development_id
]
primary_site_sources <- episode[
  pre_identical_address_set_review_development_id %chin%
    merged_current_developments & !is.na(primary_site_key),
  .(
    development_id,
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
  development_id = episode$development_id[match(hud_id, episode$hud_id)],
  pre_identical_address_set_review_development_id =
    episode$pre_identical_address_set_review_development_id[
      match(hud_id, episode$hud_id)
    ]
)]
if (anyNA(multisite$development_id)) {
  stop("A multi-address row failed development assignment.",
    call. = FALSE)
}
multisite_sources <- multisite[
  pre_identical_address_set_review_development_id %chin%
    merged_current_developments & informative_site == TRUE,
  .(
    development_id,
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

site_sources <- unique(rbindlist(list(
  primary_site_sources,
  multisite_sources
), use.names = TRUE))
site_sources[, `:=`(
  latitude_value = suppressWarnings(as.numeric(latitude_raw)),
  longitude_value = suppressWarnings(as.numeric(longitude_raw))
)]
site_sources[
  latitude_value < -90 | latitude_value > 90 |
    longitude_value < -180 | longitude_value > 180,
  `:=`(latitude_value = NA_real_, longitude_value = NA_real_)
]

merged_site <- site_sources[, {
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

setorder(merged_site, development_id, site_key)
merged_site[, site_number := seq_len(.N), by = development_id]
merged_site[, development_site_id := paste0(
  development_id,
  "_SITE_",
  sprintf("%04d", site_number)
)]
merged_site[, requires_site_review :=
  n_coordinate_pairs > 1L |
    str_detect(normalize_street(site_street), "\\b(UNIT|APT)\\b")]
setcolorder(merged_site, names(current_site))

site <- rbindlist(list(
  current_site[!development_id %chin% merged_current_developments],
  merged_site
), use.names = TRUE)
setorder(site, development_id, site_key)

expected_site_keys <- copy(current_site[, .(development_id, site_key)])
expected_site_keys[mapping, development_id := i.adjudicated_development_id,
  on = c(development_id = "current_development_id")]
expected_site_keys <- unique(expected_site_keys)
observed_site_keys <- site[, .(development_id, site_key)]
setorder(expected_site_keys, development_id, site_key)
setorder(observed_site_keys, development_id, site_key)
if (!identical(expected_site_keys, observed_site_keys)) {
  stop("A source site key was lost or invented during application.",
    call. = FALSE)
}

site_summary <- site[, .(
  n_development_sites = .N,
  n_sites_with_hud_coordinates = sum(
    !is.na(latitude) & !is.na(longitude)
  ),
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

development[, current_development_id := NULL]
episode[, anchor_sort_year := NULL]
setorder(development, development_id)
setorder(episode, development_id, episode_number, hud_id)
setorder(site, development_id, site_number, site_key)

development_front <- c(
  "development_id",
  "pre_identical_address_set_review_development_ids",
  "identical_address_set_review_question_ids",
  "identical_address_set_review_cluster_id",
  "identical_address_set_review_action",
  "identical_address_set_review_reason_codes",
  "identical_address_set_address_assessments",
  "identical_address_set_reviewed_on",
  "identical_address_set_shared_query_decision"
)
episode_front <- c(
  "development_id",
  "pre_identical_address_set_review_development_id",
  "identical_address_set_review_question_id",
  "identical_address_set_review_cluster_id",
  "identical_address_set_review_action",
  "identical_address_set_review_reason_code",
  "identical_address_set_address_assessment",
  "identical_address_set_reviewed_on",
  "identical_address_set_shared_query_decision"
)
setcolorder(development, c(
  development_front,
  setdiff(names(development), development_front)
))
setcolorder(episode, c(
  episode_front,
  setdiff(names(episode), episode_front)
))

if (nrow(development) != 54257L ||
    uniqueN(development$development_id) != nrow(development) ||
    nrow(episode) != 55345L || uniqueN(episode$hud_id) != nrow(episode) ||
    nrow(site) != 133551L ||
    nrow(site) != nrow(expected_site_keys) ||
    uniqueN(site$development_site_id) != nrow(site) ||
    uniqueN(site, by = c("development_id", "site_key")) != nrow(site) ||
    any(!episode$development_id %chin% development$development_id) ||
    any(!site$development_id %chin% development$development_id) ||
    development[
      identical_address_set_review_action ==
        "merge_to_proposed_physical_development",
      .N
    ] != 85L ||
    development[
      identical_address_set_review_action ==
        "retain_current_development",
      .N
    ] != 27L ||
    development[
      identical_address_set_review_action ==
        "merge_to_proposed_physical_development",
      any(!is.na(n_units_development) | !is.na(li_units_development))
    ] ||
    episode[
      identical_address_set_review_action != "not_applicable",
      any(
        identical_address_set_shared_query_decision != "not_approved"
      )
    ]) {
  stop("An identical-address review decision was applied inconsistently.",
    call. = FALSE)
}

write_parquet(
  development,
  "../output/lihtc_development_2024_identical_address_adjudicated.parquet",
  compression = "zstd"
)
write_parquet(
  episode,
  "../output/lihtc_project_episode_2024_identical_address_adjudicated.parquet",
  compression = "zstd"
)
write_parquet(
  site,
  "../output/lihtc_development_site_2024_identical_address_adjudicated.parquet",
  compression = "zstd"
)

development_round_trip <- as.data.table(read_parquet(
  "../output/lihtc_development_2024_identical_address_adjudicated.parquet"
))
episode_round_trip <- as.data.table(read_parquet(
  "../output/lihtc_project_episode_2024_identical_address_adjudicated.parquet"
))
site_round_trip <- as.data.table(read_parquet(
  "../output/lihtc_development_site_2024_identical_address_adjudicated.parquet"
))
if (!isTRUE(all.equal(development, development_round_trip)) ||
    !isTRUE(all.equal(episode, episode_round_trip)) ||
    !isTRUE(all.equal(site, site_round_trip))) {
  stop("An applied identical-address Parquet changed on round trip.",
    call. = FALSE)
}

cat(
  "Applied 98 reviewed identical address sets to build ",
  format(nrow(development), big.mark = ","),
  " developments, ",
  format(nrow(episode), big.mark = ","),
  " project episodes, and ",
  format(nrow(site), big.mark = ","),
  " development sites; no query approved.\n",
  sep = ""
)
