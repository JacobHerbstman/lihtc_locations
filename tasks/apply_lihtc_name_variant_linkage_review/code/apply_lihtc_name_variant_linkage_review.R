# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/apply_lihtc_name_variant_linkage_review/code")

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

development_input <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_adjudicated.parquet"
))
episode <- as.data.table(read_parquet(
  "../input/lihtc_project_episode_2024_adjudicated.parquet"
))
current_site <- as.data.table(read_parquet(
  "../input/lihtc_development_site_2024_adjudicated.parquet"
))
multisite <- as.data.table(read_parquet(
  "../input/lihtc_multisite_2024_raw_text.parquet"
))
decisions <- as.data.table(read_parquet(
  "../input/lihtc_name_variant_linkage_decisions_2024.parquet"
))
members <- as.data.table(read_parquet(
  "../input/lihtc_name_variant_linkage_member_decisions_2024.parquet"
))

if (uniqueN(development_input$development_id) != nrow(development_input) ||
    uniqueN(episode$hud_id) != nrow(episode) ||
    uniqueN(current_site$development_site_id) != nrow(current_site) ||
    uniqueN(current_site, by = c("development_id", "site_key")) !=
      nrow(current_site) ||
    uniqueN(decisions$candidate_group_id) != nrow(decisions) ||
    uniqueN(members$current_development_id) != nrow(members) ||
    uniqueN(members$hud_id) != nrow(members)) {
  stop("An input key is not unique.", call. = FALSE)
}
if (nrow(decisions) != 163L || nrow(members) != 327L ||
    decisions[final_decision == "merge", .N] != 154L ||
    decisions[final_decision == "retain_separate", .N] != 9L) {
  stop("The name-variant review counts changed.", call. = FALSE)
}
if (!all(members$hud_id %chin% episode$hud_id) ||
    any(!members$current_development_id %chin%
      development_input$development_id)) {
  stop("The member ledger contains an unknown episode or development.",
    call. = FALSE)
}

development_mapping <- unique(members[, .(
  current_development_id,
  candidate_group_id,
  final_decision,
  final_reason_code,
  name_adjudicated_development_id,
  name_adjudicated_development_anchor_hud_id
)])
if (uniqueN(development_mapping$current_development_id) !=
    nrow(development_mapping)) {
  stop("A current development has more than one reviewed mapping.",
    call. = FALSE)
}

episode[, `:=`(
  pre_name_review_development_id = development_id,
  name_variant_candidate_group_id = NA_character_,
  name_variant_review_decision = "not_applicable",
  name_variant_review_reason_code = NA_character_,
  name_variant_reviewed_on = as.Date(NA)
)]
episode[development_mapping, `:=`(
  development_id = i.name_adjudicated_development_id,
  development_anchor_hud_id =
    i.name_adjudicated_development_anchor_hud_id,
  name_variant_candidate_group_id = i.candidate_group_id,
  name_variant_review_decision = i.final_decision,
  name_variant_review_reason_code = i.final_reason_code
), on = c(
  pre_name_review_development_id = "current_development_id"
)]
episode[decisions, name_variant_reviewed_on := i.final_reviewed_on,
  on = c(name_variant_candidate_group_id = "candidate_group_id")]

episode[name_variant_review_decision == "merge", `:=`(
  development_linkage_status = "name_adjudicated_linked",
  development_linkage_basis =
    "same_state_id_standardized_primary_address_manual_name_review",
  requires_linkage_review = FALSE
)]
episode[name_variant_review_decision == "retain_separate", `:=`(
  development_linkage_status =
    "name_reviewed_separate_same_state_id_address",
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
  stop("The reviewed episode groups do not have one anchor each.",
    call. = FALSE)
}

development <- episode[, {
  anchor_row <- which(hud_id == development_anchor_hud_id)[1L]
  total_units <- episode_units
  low_income_units <- episode_low_income_units
  second_pass_reason <- unique(
    name_variant_review_reason_code[
      name_variant_review_decision == "merge"
    ]
  )

  if (.N == 1L) {
    unit_aggregation_status <- "resolved_single_episode"
    unit_aggregation_rule <- "single_episode_source"
    development_units <- total_units[1L]
    development_low_income_units <- low_income_units[1L]
    candidate_development_units <- total_units[1L]
    candidate_development_low_income_units <- low_income_units[1L]
  } else if (length(second_pass_reason) == 1L &&
      second_pass_reason == "duplicate_reporting_name_variant" &&
      all(!is.na(total_units)) && uniqueN(total_units) == 1L) {
    unit_aggregation_status <- "requires_review"
    unit_aggregation_rule <- "candidate_duplicate_records_use_once"
    development_units <- NA_real_
    development_low_income_units <- NA_real_
    candidate_development_units <- total_units[1L]
    candidate_development_low_income_units <- if (
      all(!is.na(low_income_units)) && uniqueN(low_income_units) == 1L
    ) {
      low_income_units[1L]
    } else {
      NA_real_
    }
  } else if (length(second_pass_reason) == 1L &&
      second_pass_reason == "single_building_split_financing_applications" &&
      all(!is.na(total_units))) {
    unit_aggregation_status <- "requires_review"
    unit_aggregation_rule <- "candidate_financing_components_sum"
    development_units <- NA_real_
    development_low_income_units <- NA_real_
    candidate_development_units <- sum(total_units)
    candidate_development_low_income_units <- if (
      all(!is.na(low_income_units))
    ) {
      sum(low_income_units)
    } else {
      NA_real_
    }
  } else if (all(!is.na(total_units)) && all(total_units == 1)) {
    unit_aggregation_status <- "requires_review"
    unit_aggregation_rule <- "candidate_one_unit_fragments_sum"
    development_units <- NA_real_
    development_low_income_units <- NA_real_
    candidate_development_units <- sum(total_units)
    candidate_development_low_income_units <- if (
      all(!is.na(low_income_units))
    ) {
      sum(low_income_units)
    } else {
      NA_real_
    }
  } else if (all(!is.na(total_units)) && uniqueN(total_units) == 1L) {
    unit_aggregation_status <- "requires_review"
    unit_aggregation_rule <- "candidate_repeated_equal_total_use_once"
    development_units <- NA_real_
    development_low_income_units <- NA_real_
    candidate_development_units <- total_units[1L]
    candidate_development_low_income_units <- if (
      all(!is.na(low_income_units)) && uniqueN(low_income_units) == 1L
    ) {
      low_income_units[1L]
    } else {
      NA_real_
    }
  } else {
    unit_aggregation_status <- "requires_review"
    unit_aggregation_rule <- "unresolved_component_or_changed_totals"
    development_units <- NA_real_
    development_low_income_units <- NA_real_
    candidate_development_units <- NA_real_
    candidate_development_low_income_units <- NA_real_
  }

  .(
    pre_name_review_development_ids = paste(
      sort(unique(pre_name_review_development_id)),
      collapse = "|"
    ),
    provisional_development_id = provisional_development_id[anchor_row],
    development_anchor_hud_id = development_anchor_hud_id[anchor_row],
    development_name = project[anchor_row],
    development_name_key = name_key[anchor_row],
    development_state = proj_st[anchor_row],
    development_city = proj_cty[anchor_row],
    development_linkage_status = development_linkage_status[anchor_row],
    development_linkage_basis = development_linkage_basis[anchor_row],
    requires_linkage_review = any(requires_linkage_review),
    linkage_review_decision = linkage_review_decision[anchor_row],
    linkage_review_reason_code = linkage_review_reason_code[anchor_row],
    linkage_reviewed_on = linkage_reviewed_on[anchor_row],
    name_variant_candidate_group_id =
      name_variant_candidate_group_id[anchor_row],
    name_variant_review_decision =
      name_variant_review_decision[anchor_row],
    name_variant_review_reason_code =
      name_variant_review_reason_code[anchor_row],
    name_variant_reviewed_on = name_variant_reviewed_on[anchor_row],
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
    episode_unit_count_max = if (all(is.na(total_units))) {
      NA_real_
    } else {
      max(total_units, na.rm = TRUE)
    },
    episode_unit_count_sum = if (all(is.na(total_units))) {
      NA_real_
    } else {
      sum(total_units, na.rm = TRUE)
    },
    unit_aggregation_status = unit_aggregation_status,
    unit_aggregation_rule = unit_aggregation_rule,
    n_units_development = development_units,
    li_units_development = development_low_income_units,
    candidate_n_units_development = candidate_development_units,
    candidate_li_units_development =
      candidate_development_low_income_units
  )
}, by = development_id]

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

reviewed_current_developments <- development_mapping$current_development_id

primary_site_sources <- episode[
  pre_name_review_development_id %chin% reviewed_current_developments &
    !is.na(primary_site_key),
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
  development_id = episode$development_id[
    match(hud_id, episode$hud_id)
  ],
  pre_name_review_development_id =
    episode$pre_name_review_development_id[
      match(hud_id, episode$hud_id)
    ]
)]
if (anyNA(multisite$development_id)) {
  stop("A multi-address row failed development assignment.", call. = FALSE)
}
multisite_sources <- multisite[
  pre_name_review_development_id %chin% reviewed_current_developments &
    informative_site == TRUE,
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

reviewed_site <- site_sources[, {
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

setorder(reviewed_site, development_id, site_key)
reviewed_site[, site_number := seq_len(.N), by = development_id]
reviewed_site[, development_site_id := paste0(
  development_id,
  "_SITE_",
  sprintf("%04d", site_number)
)]
reviewed_site[, requires_site_review :=
  n_coordinate_pairs > 1L |
  str_detect(normalize_street(site_street), "\\b(UNIT|APT)\\b")]
setcolorder(reviewed_site, c(
  "development_site_id", "development_id", "site_number", "site_key",
  "site_street", "site_city", "site_state", "site_zip", "site_source",
  "n_project_episodes", "hud_ids", "n_bin_values", "bin_example",
  "n_coordinate_pairs", "latitude", "longitude", "requires_site_review"
))

site <- rbindlist(list(
  current_site[!development_id %chin% reviewed_current_developments],
  reviewed_site
), use.names = TRUE)
setorder(site, development_id, site_key)

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

episode[, anchor_sort_year := NULL]
setorder(development, development_id)
setorder(episode, development_id, episode_number, hud_id)
setcolorder(development, c(
  "development_id", "pre_name_review_development_ids",
  "provisional_development_id", "development_anchor_hud_id",
  "development_name", "development_name_key", "development_state",
  "development_city", "development_linkage_status",
  "development_linkage_basis", "requires_linkage_review",
  "linkage_review_decision", "linkage_review_reason_code",
  "linkage_reviewed_on", "name_variant_candidate_group_id",
  "name_variant_review_decision", "name_variant_review_reason_code",
  "name_variant_reviewed_on", "n_project_episodes",
  setdiff(names(development), c(
    "development_id", "pre_name_review_development_ids",
    "provisional_development_id", "development_anchor_hud_id",
    "development_name", "development_name_key", "development_state",
    "development_city", "development_linkage_status",
    "development_linkage_basis", "requires_linkage_review",
    "linkage_review_decision", "linkage_review_reason_code",
    "linkage_reviewed_on", "name_variant_candidate_group_id",
    "name_variant_review_decision", "name_variant_review_reason_code",
    "name_variant_reviewed_on", "n_project_episodes"
  ))
))
setcolorder(episode, c(
  "development_id", "pre_name_review_development_id",
  "provisional_development_id", "development_anchor_hud_id", "hud_id",
  "episode_number", "is_development_anchor", "development_linkage_status",
  "development_linkage_basis", "requires_linkage_review",
  "linkage_review_decision", "linkage_review_reason_code",
  "linkage_reviewed_on", "name_variant_candidate_group_id",
  "name_variant_review_decision", "name_variant_review_reason_code",
  "name_variant_reviewed_on", "n_project_episodes",
  setdiff(names(episode), c(
    "development_id", "pre_name_review_development_id",
    "provisional_development_id", "development_anchor_hud_id", "hud_id",
    "episode_number", "is_development_anchor", "development_linkage_status",
    "development_linkage_basis", "requires_linkage_review",
    "linkage_review_decision", "linkage_review_reason_code",
    "linkage_reviewed_on", "name_variant_candidate_group_id",
    "name_variant_review_decision", "name_variant_review_reason_code",
    "name_variant_reviewed_on", "n_project_episodes"
  ))
))

if (nrow(development) != 54725L ||
    uniqueN(development$development_id) != nrow(development)) {
  stop("The name-adjudicated development count or key is wrong.",
    call. = FALSE)
}
if (nrow(episode) != 55345L || uniqueN(episode$hud_id) != nrow(episode)) {
  stop("The name-adjudicated episode table lost or duplicated a HUD row.",
    call. = FALSE)
}
if (nrow(site) != 134823L ||
    uniqueN(site$development_site_id) != nrow(site) ||
    uniqueN(site, by = c("development_id", "site_key")) != nrow(site)) {
  stop("The name-adjudicated site count or key is wrong.", call. = FALSE)
}
if (any(!episode$development_id %chin% development$development_id) ||
    any(!site$development_id %chin% development$development_id)) {
  stop("An episode or site points to an unknown development.",
    call. = FALSE)
}
if (development[name_variant_review_decision == "merge", .N] != 154L ||
    development[name_variant_review_decision == "retain_separate", .N] !=
      19L ||
    any(development[
      name_variant_review_decision == "merge",
      !is.na(n_units_development) | !is.na(li_units_development)
    ])) {
  stop("The group decisions or unresolved unit contract was not applied.",
    call. = FALSE)
}

write_parquet(
  development,
  "../output/lihtc_development_2024_name_adjudicated.parquet",
  compression = "zstd"
)
write_parquet(
  episode,
  "../output/lihtc_project_episode_2024_name_adjudicated.parquet",
  compression = "zstd"
)
write_parquet(
  site,
  "../output/lihtc_development_site_2024_name_adjudicated.parquet",
  compression = "zstd"
)

if (!identical(
  development,
  as.data.table(read_parquet(
    "../output/lihtc_development_2024_name_adjudicated.parquet"
  ))
) || !identical(
  episode,
  as.data.table(read_parquet(
    "../output/lihtc_project_episode_2024_name_adjudicated.parquet"
  ))
) || !identical(
  site,
  as.data.table(read_parquet(
    "../output/lihtc_development_site_2024_name_adjudicated.parquet"
  ))
)) {
  stop("A name-adjudicated Parquet changed on round trip.", call. = FALSE)
}

cat(
  "Applied 163 name-variant decisions to build 54,725 developments, ",
  "55,345 project episodes, and ",
  format(nrow(site), big.mark = ","),
  " development sites.\n",
  sep = ""
)
