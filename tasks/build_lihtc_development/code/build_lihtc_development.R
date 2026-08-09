# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/build_lihtc_development/code")

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

valid_year <- function(value) {
  value <- suppressWarnings(as.integer(value))
  fifelse(value >= 1980L & value <= 2026L, value, NA_integer_)
}

first_text <- function(value) {
  value <- sort(unique(value[!is.na(value) & value != ""]))
  if (length(value) == 0L) NA_character_ else value[1]
}

property <- as.data.table(read_parquet(
  "../input/lihtc_property_2024_raw_text.parquet"
))
multisite <- as.data.table(read_parquet(
  "../input/lihtc_multisite_2024_raw_text.parquet"
))

if (nrow(property) != 55345L || uniqueN(property$hud_id) != nrow(property)) {
  stop("The property input must contain one row per published HUD ID.", call. = FALSE)
}
if (nrow(multisite) != 161715L) {
  stop("The multi-address input row count changed.", call. = FALSE)
}
if (any(!unique(multisite$hud_id) %chin% property$hud_id)) {
  stop("A multi-address HUD ID is absent from the property input.", call. = FALSE)
}

uninformative_streets <- c(
  "N A", "NA", "NONE", "UNKNOWN", "UNAVAILABLE", "NOT AVAILABLE",
  "VARIOUS", "MULTIPLE", "MULTIPLE LOCATIONS", "SCATTERED",
  "SCATTERED SITE", "SCATTERED SITES", "TBD"
)

episode <- copy(property)
episode[, source_property_row := .I]
episode[, `:=`(
  name_key = normalize_text(project),
  primary_street_key = normalize_street(proj_add),
  primary_site_key = make_site_key(proj_st, proj_add, proj_cty),
  pis_year = valid_year(yr_pis),
  allocation_year = valid_year(yr_alloc),
  episode_units = suppressWarnings(as.numeric(n_unitsr)),
  episode_low_income_units = suppressWarnings(as.numeric(li_unitr))
)]
episode[
  is.na(primary_street_key) | primary_street_key %chin% uninformative_streets,
  primary_site_key := NA_character_
]

multisite[, `:=`(
  street_key = normalize_street(bin_add),
  site_key = make_site_key(proj_st, bin_add, bin_cty)
)]
multisite[, informative_site :=
  !is.na(street_key) & !street_key %chin% uninformative_streets]

hud_multisite <- unique(multisite[
  informative_site == TRUE,
  .(hud_id, site_key)
])
multisite_sets <- hud_multisite[order(hud_id, site_key), .(
  n_multisites = .N,
  multisite_set = paste(site_key, collapse = "\u001F")
), by = hud_id]
multisite_sets[, property_row := match(hud_id, episode$hud_id)]
if (anyNA(multisite_sets$property_row)) {
  stop("A multi-address project failed the property-key match.", call. = FALSE)
}
multisite_sets[, name_key := episode$name_key[property_row]]

primary_edges <- episode[
  !is.na(name_key) & !is.na(primary_site_key),
  {
    ids <- sort(unique(hud_id))
    if (length(ids) < 2L) {
      NULL
    } else {
      pair_matrix <- combn(ids, 2L)
      .(hud_id_a = pair_matrix[1L, ], hud_id_b = pair_matrix[2L, ])
    }
  },
  by = .(name_key, primary_site_key)
]
if (nrow(primary_edges) > 0L) {
  primary_edges[, link_reason := "normalized_name_standardized_primary_address"]
}

multisite_edges <- multisite_sets[
  !is.na(name_key),
  {
    ids <- sort(unique(hud_id))
    if (length(ids) < 2L) {
      NULL
    } else {
      pair_matrix <- combn(ids, 2L)
      .(hud_id_a = pair_matrix[1L, ], hud_id_b = pair_matrix[2L, ])
    }
  },
  by = .(name_key, multisite_set)
]
if (nrow(multisite_edges) > 0L) {
  multisite_edges[, link_reason := "normalized_name_identical_multisite_set"]
}

link_edges <- rbindlist(list(
  primary_edges[, .(hud_id_a, hud_id_b, link_reason)],
  multisite_edges[, .(hud_id_a, hud_id_b, link_reason)]
), use.names = TRUE)
link_edges <- link_edges[, .(
  edge_evidence = paste(sort(unique(link_reason)), collapse = "+")
), by = .(hud_id_a, hud_id_b)]

parent <- seq_len(nrow(episode))
find_root <- function(row_number) {
  while (parent[row_number] != row_number) {
    row_number <- parent[row_number]
  }
  row_number
}

if (nrow(link_edges) > 0L) {
  link_edges[, `:=`(
    row_a = match(hud_id_a, episode$hud_id),
    row_b = match(hud_id_b, episode$hud_id)
  )]
  if (anyNA(link_edges[, .(row_a, row_b)])) {
    stop("A development-link edge contains an unknown HUD ID.", call. = FALSE)
  }

  for (edge_row in seq_len(nrow(link_edges))) {
    root_a <- find_root(link_edges$row_a[edge_row])
    root_b <- find_root(link_edges$row_b[edge_row])
    if (root_a != root_b) {
      parent[max(root_a, root_b)] <- min(root_a, root_b)
    }
  }
}

episode[, component_root := vapply(seq_len(.N), find_root, integer(1))]
episode[, anchor_sort_year := fcoalesce(pis_year, allocation_year, 9999L)]
anchors <- episode[
  order(component_root, anchor_sort_year, hud_id),
  .(development_anchor_hud_id = first(hud_id)),
  by = component_root
]
anchors[, development_id := paste0("DEV_", development_anchor_hud_id)]

episode[, development_row := match(component_root, anchors$component_root)]
if (anyNA(episode$development_row)) {
  stop("A property episode failed development assignment.", call. = FALSE)
}
episode[, `:=`(
  development_id = anchors$development_id[development_row],
  development_anchor_hud_id = anchors$development_anchor_hud_id[development_row]
)]

component_sizes <- episode[, .(n_project_episodes = .N), by = component_root]
episode[, n_project_episodes := component_sizes$n_project_episodes[
  match(component_root, component_sizes$component_root)
]]

if (nrow(link_edges) > 0L) {
  link_edges[, component_root := episode$component_root[
    match(hud_id_a, episode$hud_id)
  ]]
  component_evidence <- link_edges[, .(
    development_linkage_basis = paste(
      sort(unique(unlist(strsplit(edge_evidence, "+", fixed = TRUE)))),
      collapse = "+"
    )
  ), by = component_root]
  episode[, development_linkage_basis := component_evidence$development_linkage_basis[
    match(component_root, component_evidence$component_root)
  ]]
} else {
  episode[, development_linkage_basis := NA_character_]
}
episode[n_project_episodes == 1L, development_linkage_basis := "singleton_hud_id"]
episode[, `:=`(
  development_linkage_status = fifelse(
    n_project_episodes == 1L,
    "singleton",
    "provisional_linked"
  ),
  requires_linkage_review = n_project_episodes > 1L
)]

setorder(
  episode,
  development_id,
  anchor_sort_year,
  allocation_year,
  hud_id,
  na.last = TRUE
)
episode[, episode_number := seq_len(.N), by = development_id]
episode[, is_development_anchor := hud_id == development_anchor_hud_id]

development <- episode[, {
  anchor_row <- which(hud_id == development_anchor_hud_id)[1]
  total_units <- episode_units
  low_income_units <- episode_low_income_units

  if (.N == 1L) {
    unit_aggregation_status <- "resolved_single_episode"
    unit_aggregation_rule <- "single_episode_source"
    development_units <- total_units[1]
    development_low_income_units <- low_income_units[1]
    candidate_development_units <- total_units[1]
    candidate_development_low_income_units <- low_income_units[1]
  } else if (all(!is.na(total_units)) && all(total_units == 1)) {
    unit_aggregation_status <- "requires_review"
    unit_aggregation_rule <- "candidate_one_unit_fragments_sum"
    development_units <- NA_real_
    development_low_income_units <- NA_real_
    candidate_development_units <- sum(total_units)
    candidate_development_low_income_units <- if (all(!is.na(low_income_units))) {
      sum(low_income_units)
    } else {
      NA_real_
    }
  } else if (all(!is.na(total_units)) && uniqueN(total_units) == 1L) {
    unit_aggregation_status <- "requires_review"
    unit_aggregation_rule <- "candidate_repeated_equal_total_use_once"
    development_units <- NA_real_
    development_low_income_units <- NA_real_
    candidate_development_units <- total_units[1]
    candidate_development_low_income_units <- if (
      all(!is.na(low_income_units)) && uniqueN(low_income_units) == 1L
    ) {
      low_income_units[1]
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
    development_anchor_hud_id = development_anchor_hud_id[anchor_row],
    development_name = project[anchor_row],
    development_name_key = name_key[anchor_row],
    development_state = proj_st[anchor_row],
    development_city = proj_cty[anchor_row],
    development_linkage_status = development_linkage_status[1],
    development_linkage_basis = development_linkage_basis[1],
    requires_linkage_review = requires_linkage_review[1],
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
    any_resyndication_reported = any(resyndication_cd == "1", na.rm = TRUE),
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
    candidate_li_units_development = candidate_development_low_income_units
  )
}, by = development_id]

primary_site_sources <- episode[!is.na(primary_site_key), .(
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
)]

multisite[, development_id := episode$development_id[match(hud_id, episode$hud_id)]]
if (anyNA(multisite$development_id)) {
  stop("A multi-address row failed development assignment.", call. = FALSE)
}
multisite_sources <- multisite[informative_site == TRUE, .(
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
)]

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

development_site <- site_sources[, {
  coordinate_pairs <- unique(data.table(
    latitude = latitude_value[!is.na(latitude_value) & !is.na(longitude_value)],
    longitude = longitude_value[!is.na(latitude_value) & !is.na(longitude_value)]
  ))
  n_coordinate_pairs <- nrow(coordinate_pairs)

  .(
    site_street = first_text(raw_street),
    site_city = first_text(raw_city),
    site_state = first_text(raw_state),
    site_zip = first_text(raw_zip),
    site_source = fcase(
      any(source_type == "project_primary") & any(source_type == "multi_address"),
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
      coordinate_pairs$latitude[1]
    } else {
      NA_real_
    },
    longitude = if (n_coordinate_pairs == 1L) {
      coordinate_pairs$longitude[1]
    } else {
      NA_real_
    }
  )
}, by = .(development_id, site_key)]

setorder(development_site, development_id, site_key)
development_site[, site_number := seq_len(.N), by = development_id]
development_site[, development_site_id := paste0(
  development_id,
  "_SITE_",
  sprintf("%04d", site_number)
)]
development_site[, requires_site_review :=
  n_coordinate_pairs > 1L |
  str_detect(normalize_street(site_street), "\\b(UNIT|APT)\\b")]
setcolorder(development_site, c(
  "development_site_id", "development_id", "site_number", "site_key",
  "site_street", "site_city", "site_state", "site_zip", "site_source",
  "n_project_episodes", "hud_ids", "n_bin_values", "bin_example",
  "n_coordinate_pairs", "latitude", "longitude", "requires_site_review"
))

site_summary <- development_site[, .(
  n_development_sites = .N,
  n_sites_with_hud_coordinates = sum(!is.na(latitude) & !is.na(longitude)),
  n_sites_requiring_review = sum(requires_site_review)
), by = development_id]
development[, site_summary_row := match(development_id, site_summary$development_id)]
development[, `:=`(
  n_development_sites = fifelse(
    is.na(site_summary_row),
    0L,
    site_summary$n_development_sites[site_summary_row]
  ),
  n_sites_with_hud_coordinates = fifelse(
    is.na(site_summary_row),
    0L,
    site_summary$n_sites_with_hud_coordinates[site_summary_row]
  ),
  n_sites_requiring_review = fifelse(
    is.na(site_summary_row),
    0L,
    site_summary$n_sites_requiring_review[site_summary_row]
  )
)]
development[, site_summary_row := NULL]

episode[, c(
  "component_root", "anchor_sort_year", "development_row",
  "primary_street_key"
) := NULL]
setcolorder(episode, c(
  "development_id", "development_anchor_hud_id", "hud_id",
  "episode_number", "is_development_anchor", "development_linkage_status",
  "development_linkage_basis", "requires_linkage_review",
  "n_project_episodes", "source_property_row", "name_key",
  "primary_site_key", "pis_year", "allocation_year", "episode_units",
  "episode_low_income_units",
  setdiff(names(episode), c(
    "development_id", "development_anchor_hud_id", "hud_id",
    "episode_number", "is_development_anchor", "development_linkage_status",
    "development_linkage_basis", "requires_linkage_review",
    "n_project_episodes", "source_property_row", "name_key",
    "primary_site_key", "pis_year", "allocation_year", "episode_units",
    "episode_low_income_units"
  ))
))

if (uniqueN(development$development_id) != nrow(development)) {
  stop("Development IDs are not unique.", call. = FALSE)
}
if (nrow(episode) != nrow(property) || uniqueN(episode$hud_id) != nrow(episode)) {
  stop("The project-episode table lost or duplicated a property row.", call. = FALSE)
}
if (any(!episode$development_id %chin% development$development_id)) {
  stop("A project episode has no development record.", call. = FALSE)
}
if (uniqueN(development_site$development_site_id) != nrow(development_site) ||
    uniqueN(development_site, by = c("development_id", "site_key")) !=
      nrow(development_site)) {
  stop("Development-site keys are not unique.", call. = FALSE)
}
if (any(!development_site$development_id %chin% development$development_id)) {
  stop("A development site has no development record.", call. = FALSE)
}

write_parquet(
  development,
  "../output/lihtc_development_2024.parquet",
  compression = "zstd"
)
write_parquet(
  episode,
  "../output/lihtc_project_episode_2024.parquet",
  compression = "zstd"
)
write_parquet(
  development_site,
  "../output/lihtc_development_site_2024.parquet",
  compression = "zstd"
)

if (!identical(
  development,
  as.data.table(read_parquet("../output/lihtc_development_2024.parquet"))
)) {
  stop("The development Parquet round trip changed the table.", call. = FALSE)
}
if (!identical(
  episode,
  as.data.table(read_parquet("../output/lihtc_project_episode_2024.parquet"))
)) {
  stop("The project-episode Parquet round trip changed the table.", call. = FALSE)
}
if (!identical(
  development_site,
  as.data.table(read_parquet("../output/lihtc_development_site_2024.parquet"))
)) {
  stop("The development-site Parquet round trip changed the table.", call. = FALSE)
}

cat(
  "Built ", format(nrow(development), big.mark = ","), " developments, ",
  format(nrow(episode), big.mark = ","), " project episodes, and ",
  format(nrow(development_site), big.mark = ","), " development sites.\n",
  sep = ""
)
