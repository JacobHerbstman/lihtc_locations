# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/audit_lihtc_geocoding_readiness/code")

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

collapse_text <- function(value) {
  value <- sort(unique(value[!is.na(value) & value != ""]))
  if (length(value) == 0L) NA_character_ else paste(value, collapse = "|")
}

normalize_zip5 <- function(value) {
  value <- str_to_upper(str_squish(value))
  fcase(
    str_detect(value, "^[0-9]{5}(-[0-9]{4})?$"),
    str_sub(value, 1L, 5L),
    str_detect(value, "^[0-9]{4}$"),
    paste0("0", value),
    str_detect(value, "^[0-9]{9}$"),
    str_sub(value, 1L, 5L),
    default = NA_character_
  )
}

episode <- as.data.table(read_parquet(
  "../input/lihtc_project_episode_2024_name_adjudicated.parquet"
))
site <- as.data.table(read_parquet(
  "../input/lihtc_development_site_2024_name_adjudicated.parquet"
))
multisite <- as.data.table(read_parquet(
  "../input/lihtc_multisite_2024_raw_text.parquet"
))

if (nrow(episode) != 55345L || nrow(site) != 134823L ||
    nrow(multisite) != 161715L ||
    uniqueN(episode$hud_id) != nrow(episode) ||
    uniqueN(site$development_site_id) != nrow(site) ||
    uniqueN(site, by = c("development_id", "site_key")) != nrow(site)) {
  stop("An audit input count or key changed.", call. = FALSE)
}
if (any(!site$development_id %chin% episode$development_id) ||
    any(!multisite$hud_id %chin% episode$hud_id)) {
  stop("A site or multi-address row has no project episode.",
    call. = FALSE)
}

in_scope_states <- c(state.abb, "DC")
site[, geographic_scope := fcase(
  site_state %chin% in_scope_states,
  "in_scope_50_states_dc",
  site_state %chin% c("PR", "VI", "GU", "AS", "MP"),
  "excluded_territory",
  default = "invalid_or_missing_state"
)]
if (site[geographic_scope == "in_scope_50_states_dc", .N] != 133862L ||
    site[geographic_scope == "excluded_territory", .N] != 961L ||
    site[geographic_scope == "invalid_or_missing_state", .N] != 0L) {
  stop("The 50-states-plus-DC scope count changed.", call. = FALSE)
}

uninformative_streets <- c(
  "N A", "NA", "NONE", "UNKNOWN", "UNAVAILABLE", "NOT AVAILABLE",
  "VARIOUS", "MULTIPLE", "MULTIPLE LOCATIONS", "SCATTERED",
  "SCATTERED SITE", "SCATTERED SITES", "TBD"
)
multisite[, `:=`(
  street_key = normalize_street(bin_add),
  site_key = make_site_key(proj_st, bin_add, bin_cty),
  development_id = episode$development_id[match(hud_id, episode$hud_id)],
  linkage_review_decision =
    episode$linkage_review_decision[match(hud_id, episode$hud_id)]
)]
multisite[, informative_site :=
  !is.na(street_key) & !street_key %chin% uninformative_streets]

development_evidence <- episode[, .(
  development_name_examples = collapse_text(project),
  state_id_examples = collapse_text(state_id),
  allocation_year_examples = collapse_text(as.character(allocation_year)),
  placed_in_service_year_examples = collapse_text(as.character(pis_year)),
  episode_unit_examples = collapse_text(as.character(episode_units))
), by = development_id]

primary_sources <- episode[!is.na(primary_site_key), .(
  development_id,
  hud_id,
  site_key = primary_site_key,
  source_type = "project_primary",
  raw_street = proj_add,
  raw_city = proj_cty,
  raw_state = proj_st,
  raw_zip = proj_zip,
  raw_bin = NA_character_
)]
multisite_sources <- multisite[
  informative_site == TRUE & linkage_review_decision != "reject",
  .(
    development_id,
    hud_id,
    site_key,
    source_type = "multi_address",
    raw_street = bin_add,
    raw_city = bin_cty,
    raw_state = proj_st,
    raw_zip = bin_zip,
    raw_bin = bin
  )
]
source_rows <- rbindlist(list(
  primary_sources,
  multisite_sources
), use.names = TRUE)
source_rows[, raw_zip5 := normalize_zip5(raw_zip)]
source_rows[, source_row_key := paste(
  source_type,
  fcoalesce(hud_id, ""),
  fcoalesce(raw_street, ""),
  fcoalesce(raw_city, ""),
  fcoalesce(raw_state, ""),
  fcoalesce(raw_zip, ""),
  fcoalesce(raw_bin, ""),
  sep = "|"
)]

source_site <- source_rows[, .(
  source_site_type = fcase(
    any(source_type == "project_primary") &
      any(source_type == "multi_address"),
    "project_primary+multi_address",
    any(source_type == "project_primary"),
    "project_primary",
    default = "multi_address"
  ),
  source_n_project_episodes = uniqueN(hud_id),
  source_hud_ids = paste(sort(unique(hud_id)), collapse = "|"),
  source_n_bin_values = uniqueN(raw_bin, na.rm = TRUE),
  source_n_raw_streets = uniqueN(raw_street, na.rm = TRUE),
  source_n_raw_cities = uniqueN(raw_city, na.rm = TRUE),
  source_n_raw_states = uniqueN(raw_state, na.rm = TRUE),
  source_n_raw_zips = uniqueN(raw_zip, na.rm = TRUE),
  source_n_zip5_values = uniqueN(raw_zip5, na.rm = TRUE),
  source_n_unparsed_zips = uniqueN(
    raw_zip[!is.na(raw_zip) & is.na(raw_zip5)]
  ),
  source_n_rows = .N,
  source_n_distinct_rows = uniqueN(source_row_key),
  source_n_primary_rows = sum(source_type == "project_primary"),
  source_n_multisite_rows = sum(source_type == "multi_address"),
  source_street_examples = collapse_text(raw_street),
  source_city_examples = collapse_text(raw_city),
  source_zip_examples = collapse_text(raw_zip),
  source_zip5_examples = collapse_text(raw_zip5)
), by = .(development_id, site_key)]

if (uniqueN(source_site, by = c("development_id", "site_key")) !=
      nrow(source_site) ||
    !setequal(
      paste(source_site$development_id, source_site$site_key),
      paste(site$development_id, site$site_key)
    )) {
  stop("The final sites do not reconcile to their included source rows.",
    call. = FALSE)
}

site[source_site, `:=`(
  source_site_type = i.source_site_type,
  source_n_project_episodes = i.source_n_project_episodes,
  source_hud_ids = i.source_hud_ids,
  source_n_bin_values = i.source_n_bin_values,
  source_n_raw_streets = i.source_n_raw_streets,
  source_n_raw_cities = i.source_n_raw_cities,
  source_n_raw_states = i.source_n_raw_states,
  source_n_raw_zips = i.source_n_raw_zips,
  source_n_zip5_values = i.source_n_zip5_values,
  source_n_unparsed_zips = i.source_n_unparsed_zips,
  source_n_rows = i.source_n_rows,
  source_n_distinct_rows = i.source_n_distinct_rows,
  source_n_primary_rows = i.source_n_primary_rows,
  source_n_multisite_rows = i.source_n_multisite_rows,
  source_street_examples = i.source_street_examples,
  source_city_examples = i.source_city_examples,
  source_zip_examples = i.source_zip_examples,
  source_zip5_examples = i.source_zip5_examples
), on = c("development_id", "site_key")]

site[development_evidence, `:=`(
  development_name_examples = i.development_name_examples,
  state_id_examples = i.state_id_examples,
  allocation_year_examples = i.allocation_year_examples,
  placed_in_service_year_examples = i.placed_in_service_year_examples,
  episode_unit_examples = i.episode_unit_examples
), on = "development_id"]

if (anyNA(site$source_site_type) ||
    any(site$site_source != site$source_site_type) ||
    any(site$n_project_episodes != site$source_n_project_episodes) ||
    any(site$hud_ids != site$source_hud_ids) ||
    any(site$n_bin_values != site$source_n_bin_values)) {
  stop("A final site does not reproduce its source aggregation.",
    call. = FALSE)
}

site[, `:=`(
  query_street = str_to_upper(str_squish(site_street)),
  query_city = str_to_upper(str_squish(site_city)),
  query_state = str_to_upper(str_squish(site_state)),
  query_zip = normalize_zip5(site_zip),
  zip_format_action = fcase(
    is.na(site_zip) | str_squish(site_zip) == "",
    "missing",
    str_detect(str_squish(site_zip), "^[0-9]{5}$"),
    "retained_5_digit",
    str_detect(str_squish(site_zip), "^[0-9]{5}-[0-9]{4}$"),
    "dropped_zip4",
    str_detect(str_squish(site_zip), "^[0-9]{4}$"),
    "restored_leading_zero",
    str_detect(str_squish(site_zip), "^[0-9]{9}$"),
    "split_unhyphenated_zip9",
    default = "unparsed"
  )
)]
site[, `:=`(
  query_street_key = normalize_street(query_street),
  query_city_key = normalize_text(query_city),
  query_state_key = normalize_text(query_state),
  query_zip_key = fcoalesce(query_zip, "")
)]
site[, exact_address_key := paste(
  fcoalesce(query_street_key, ""),
  fcoalesce(query_city_key, ""),
  fcoalesce(query_state_key, ""),
  query_zip_key,
  sep = "|"
)]
site[, address_identity_key := paste(
  fcoalesce(query_street_key, ""),
  fcoalesce(query_city_key, ""),
  fcoalesce(query_state_key, ""),
  sep = "|"
)]
trailing_site_suffix_pattern <- paste0(
  "[[:space:]]+(APT|UNIT|UNITS|BLDG|STE|SUITE|FLOOR|FLOORS|FL|",
  "ROOM|RM|#)[[:space:]]*[A-Z0-9-]+.*$"
)
site[, has_trailing_site_suffix := str_detect(
  query_street_key,
  trailing_site_suffix_pattern
)]
site[, base_street_key := str_replace(
  query_street_key,
  trailing_site_suffix_pattern,
  ""
)]
site[, base_address_key := paste(
  fcoalesce(base_street_key, ""),
  fcoalesce(query_city_key, ""),
  fcoalesce(query_state_key, ""),
  sep = "|"
)]

site[, flag_po_box := str_detect(
  query_street,
  "(^|[^A-Z])(P[.]?[[:space:]]*O[.]?|POST OFFICE)[[:space:]]*BOX([^A-Z]|$)|^BOX[[:space:]]+[0-9]"
)]
site[, flag_administrative_address := str_detect(
  query_street,
  "^(C/O|CARE OF|OFFICE|MANAGEMENT OFFICE)([^A-Z]|$)"
)]
site[, flag_scattered_or_unknown_label :=
  query_street_key %chin% uninformative_streets |
    str_detect(
      query_street,
      "^(MULTIPLE|VARIOUS|SCATTERED)[[:space:]]+(BUILDING[[:space:]]+)?(ADDRESS|ADDRESSES|LOCATIONS)([^A-Z]|$)"
    )]
site[, flag_building_label_only := str_detect(
  query_street,
  "^(TBD[[:space:]]+)?(BLDG|BUILDING)[[:space:]]+[A-Z0-9.-]+([[:space:]]+ADDRESS[[:space:]]+TBD)?$"
)]
site[, flag_parcel_or_legal_description := str_detect(
  query_street,
  "(^|[^A-Z])(VACANT PARCEL|PARCEL|TAX MAP|APN|LEGAL DESCRIPTION|PLAT NO[.]?|TOWNSHIP)([^A-Z]|$)|^LOT[[:space:]]+[A-Z0-9]"
)]
site[, flag_intersection := str_detect(
  query_street,
  "(^|[^A-Z])(INTERSECTION|CORNER OF)([^A-Z]|$)"
) | (
  !str_detect(query_street, "^[0-9]+[A-Z]?([^0-9A-Z]|$)") &
    str_detect(query_street, "[[:space:]](&|AND)[[:space:]]")
)]
site[, flag_multiple_addresses :=
  str_detect(query_street, ";") |
  str_detect(
    query_street,
    "^[0-9]+[A-Z]?([[:space:]]*,[[:space:]]*[0-9]+[A-Z]?)+"
  ) |
  str_detect(
    query_street,
    "^[0-9]+[A-Z]?[[:space:]]+(&|AND)[[:space:]]+[0-9]+[A-Z]?"
  ) |
  str_detect(query_street, "[0-9]+[[:space:]]*/[[:space:]]*[0-9]+") |
  str_detect(query_street, "[[:space:]][+][[:space:]]*[0-9]+") |
  str_detect(query_street, "&AMP;")
]
range_parts <- str_match(
  site$query_street,
  "^([0-9]+)[A-Z]?[[:space:]]*(-|–|TO)[[:space:]]*([0-9]+)"
)
site[, `:=`(
  range_start = as.integer(range_parts[, 2L]),
  range_end = as.integer(range_parts[, 4L])
)]
site[, flag_address_range := !is.na(range_start)]
site[, flag_range_end_below_start :=
  flag_address_range & range_end < range_start]
site[, flag_unit_or_building := str_detect(
  query_street,
  "(^|[^A-Z])(APT|APARTMENT|UNIT|BLDG|BUILDING|STE|SUITE|FLOOR|FLOORS|ROOM)([^A-Z]|$)|#[A-Z0-9]"
)]
site[, unit_building_position := fcase(
  flag_building_label_only,
  "building_label_only",
  str_detect(query_street, "^(BLDG|BUILDING|APT|APARTMENT|UNIT)([^A-Z]|$)"),
  "prefix_before_street_address",
  str_detect(
    query_street,
    "^[0-9]+[A-Z]?[^;]*(APT|APARTMENT|UNIT|STE|SUITE|FLOOR|FLOORS|ROOM|#)([^A-Z]|$)"
  ),
  "subpremise_after_street_address",
  str_detect(
    query_street,
    "^[0-9]+[A-Z]?[^;]*(BLDG|BUILDING)([^A-Z]|$)"
  ),
  "building_after_street_address",
  flag_unit_or_building,
  "other_unit_or_building_form",
  default = "none"
)]
site[, flag_malformed_text := str_detect(
  fcoalesce(query_street, ""),
  "&[A-Z]+;|&#[0-9]+;|<[^>]+>|^INVALID$"
) | str_detect(
  fcoalesce(query_city, ""),
  "&[A-Z]+;|&#[0-9]+;|<[^>]+>|^INVALID$"
)]
site[, flag_missing_structure_number := !str_detect(
  query_street,
  "^[0-9]+[A-Z]?([^0-9A-Z]|$)"
)]
site[, `:=`(
  flag_missing_city = is.na(query_city) | query_city == "",
  flag_missing_zip = is.na(site_zip) | str_squish(site_zip) == "",
  flag_invalid_zip = !is.na(site_zip) & str_squish(site_zip) != "" &
    is.na(query_zip),
  flag_placeholder_zip = query_zip %chin% c("00000", "11111", "99999"),
  flag_source_zip_conflict = source_n_zip5_values > 1L,
  flag_source_unparsed_zip = source_n_unparsed_zips > 0L,
  flag_source_state_conflict = source_n_raw_states > 1L,
  source_duplicate_row_count = source_n_rows - source_n_distinct_rows
)]

zip_state_counts <- site[
  geographic_scope == "in_scope_50_states_dc" &
    !is.na(query_zip) & !flag_placeholder_zip,
  .N,
  by = .(query_zip, query_state)
]
zip_states <- zip_state_counts[,
  .(
    zip_n_states = uniqueN(query_state),
    zip_state_examples = collapse_text(query_state),
    zip_modal_state = fifelse(
      sum(N == max(N)) == 1L,
      query_state[which.max(N)],
      NA_character_
    )
  ),
  by = query_zip
]
site[zip_states, `:=`(
  zip_n_states = i.zip_n_states,
  zip_state_examples = i.zip_state_examples,
  zip_modal_state = i.zip_modal_state
), on = "query_zip"]
site[, flag_zip_state_internal_conflict :=
  !is.na(zip_n_states) & zip_n_states > 1L &
    !is.na(zip_modal_state) & query_state != zip_modal_state]
site[, flag_zip_state_internal_ambiguity :=
  !is.na(zip_n_states) & zip_n_states > 1L &
    is.na(zip_modal_state)]

address_identity_counts <- site[
  geographic_scope == "in_scope_50_states_dc",
  .(
    exact_address_n_sites = .N,
    exact_address_n_developments = uniqueN(development_id),
    exact_address_development_examples = collapse_text(development_id),
    exact_address_development_name_examples =
      collapse_text(development_name_examples),
    exact_address_state_id_examples = collapse_text(state_id_examples),
    exact_address_zip_examples = collapse_text(query_zip)
  ),
  by = address_identity_key
]
site[address_identity_counts, `:=`(
  exact_address_n_sites = i.exact_address_n_sites,
  exact_address_n_developments = i.exact_address_n_developments,
  exact_address_development_examples =
    i.exact_address_development_examples,
  exact_address_development_name_examples =
    i.exact_address_development_name_examples,
  exact_address_state_id_examples = i.exact_address_state_id_examples,
  exact_address_zip_examples = i.exact_address_zip_examples
), on = "address_identity_key"]
site[, flag_repeated_across_developments :=
  !is.na(exact_address_n_developments) &
    exact_address_n_developments > 1L]

base_address_counts <- site[
  geographic_scope == "in_scope_50_states_dc",
  .(
    base_address_n_sites = .N,
    base_address_n_site_keys = uniqueN(site_key)
  ),
  by = .(development_id, base_address_key)
]
site[base_address_counts, `:=`(
  base_address_n_sites = i.base_address_n_sites,
  base_address_n_site_keys = i.base_address_n_site_keys
), on = c("development_id", "base_address_key")]
site[, flag_base_address_collision :=
  !is.na(base_address_n_site_keys) & base_address_n_site_keys > 1L]

base_address_development_counts <- site[
  geographic_scope == "in_scope_50_states_dc",
  .(base_address_n_developments = uniqueN(development_id)),
  by = base_address_key
]
site[base_address_development_counts, base_address_n_developments :=
  i.base_address_n_developments, on = "base_address_key"]

shared_base_groups <- site[
  geographic_scope == "in_scope_50_states_dc" &
    flag_base_address_collision,
  .(
    has_suffix_variation = any(has_trailing_site_suffix),
    shared_base_n_zip_values = uniqueN(query_zip_key),
    flag_shared_base_zip_conflict = uniqueN(query_zip_key) > 1L,
    all_rows_explained_by_suffix = all(
      has_trailing_site_suffix | query_street_key == base_street_key
    ),
    has_other_address_problem = any(
      flag_source_zip_conflict | flag_source_state_conflict |
        flag_source_unparsed_zip | flag_zip_state_internal_conflict |
        flag_zip_state_internal_ambiguity | flag_placeholder_zip |
        flag_multiple_addresses | flag_po_box |
        flag_administrative_address |
        flag_scattered_or_unknown_label | flag_building_label_only |
        flag_parcel_or_legal_description | flag_intersection |
        flag_address_range | flag_missing_structure_number |
        flag_missing_city | flag_missing_zip | flag_invalid_zip |
        flag_malformed_text | flag_repeated_across_developments
    ),
    shared_query_street = first_text(base_street_key)
  ),
  by = .(development_id, base_address_key)
]
shared_base_groups[, within_development_shared_base_query :=
  has_suffix_variation & all_rows_explained_by_suffix &
    !flag_shared_base_zip_conflict & !has_other_address_problem]
site[shared_base_groups, `:=`(
  within_development_shared_base_query =
    i.within_development_shared_base_query,
  shared_query_street = i.shared_query_street,
  shared_base_n_zip_values = i.shared_base_n_zip_values,
  flag_shared_base_zip_conflict = i.flag_shared_base_zip_conflict
), on = c("development_id", "base_address_key")]
site[is.na(within_development_shared_base_query),
  within_development_shared_base_query := FALSE]
site[is.na(flag_shared_base_zip_conflict),
  flag_shared_base_zip_conflict := FALSE]
site[base_address_n_developments > 1L,
  within_development_shared_base_query := FALSE]

site[, proposed_query_street := fifelse(
  within_development_shared_base_query,
  shared_query_street,
  query_street
)]
site[, proposed_query_street_key := normalize_street(
  proposed_query_street
)]
site[, proposed_query_key := paste(
  fcoalesce(proposed_query_street_key, ""),
  fcoalesce(query_city_key, ""),
  fcoalesce(query_state_key, ""),
  query_zip_key,
  sep = "|"
)]

site[, coordinate_present := !is.na(latitude) & !is.na(longitude)]
site[, flag_coordinate_global_range := coordinate_present & (
  latitude < -90 | latitude > 90 | longitude < -180 | longitude > 180
)]
site[, flag_coordinate_outside_broad_state_group := coordinate_present &
  fcase(
    query_state == "AK",
    !(latitude >= 50 & latitude <= 72 &
        ((longitude >= -180 & longitude <= -129) |
          (longitude >= 170 & longitude <= 180))),
    query_state == "HI",
    !(latitude >= 18 & latitude <= 23 &
        longitude >= -161 & longitude <= -154),
    geographic_scope == "in_scope_50_states_dc",
    !(latitude >= 24 & latitude <= 50 &
        longitude >= -125 & longitude <= -66),
    default = FALSE
  )]
site[, coordinate_key := fifelse(
  coordinate_present,
  paste0(sprintf("%.7f", latitude), "|", sprintf("%.7f", longitude)),
  NA_character_
)]

address_coordinate_counts <- site[
  geographic_scope == "in_scope_50_states_dc" & coordinate_present,
  .(address_n_coordinate_pairs = uniqueN(coordinate_key)),
  by = address_identity_key
]
site[address_coordinate_counts, address_n_coordinate_pairs :=
  i.address_n_coordinate_pairs, on = "address_identity_key"]
site[, flag_address_coordinate_conflict :=
  !is.na(address_n_coordinate_pairs) & address_n_coordinate_pairs > 1L]

coordinate_address_counts <- site[
  geographic_scope == "in_scope_50_states_dc" & coordinate_present,
  .(coordinate_n_exact_addresses = uniqueN(address_identity_key)),
  by = coordinate_key
]
site[coordinate_address_counts, coordinate_n_exact_addresses :=
  i.coordinate_n_exact_addresses, on = "coordinate_key"]
site[, flag_coordinate_reused_across_addresses :=
  !is.na(coordinate_n_exact_addresses) &
    coordinate_n_exact_addresses > 1L]

site[, coordinate_readiness_status := fcase(
  geographic_scope != "in_scope_50_states_dc",
  "outside_research_scope",
  flag_coordinate_global_range |
    flag_coordinate_outside_broad_state_group |
    n_coordinate_pairs > 1L |
    flag_address_coordinate_conflict |
    flag_coordinate_reused_across_addresses,
  "requires_internal_coordinate_review",
  !coordinate_present,
  "missing_coordinate",
  default = "internally_plausible_external_address_validation_pending"
)]

site[, address_readiness_status := fcase(
  geographic_scope != "in_scope_50_states_dc",
  "outside_research_scope",
  flag_source_zip_conflict | flag_source_state_conflict |
    flag_source_unparsed_zip | flag_zip_state_internal_conflict |
    flag_zip_state_internal_ambiguity | flag_placeholder_zip,
  "requires_source_review",
  flag_multiple_addresses,
  "requires_address_split",
  within_development_shared_base_query,
  "provisionally_queryable_shared_base",
  flag_shared_base_zip_conflict,
  "requires_address_review",
  flag_po_box | flag_administrative_address |
    flag_scattered_or_unknown_label | flag_building_label_only |
    flag_parcel_or_legal_description | flag_intersection |
    flag_address_range | flag_unit_or_building |
    flag_missing_structure_number | flag_missing_city |
    flag_missing_zip | flag_invalid_zip | flag_malformed_text,
  "requires_address_review",
  flag_repeated_across_developments | flag_base_address_collision,
  "requires_repeated_address_review",
  default = "provisionally_queryable"
)]
site[, primary_review_reason := fcase(
  geographic_scope == "excluded_territory",
  "excluded_territory",
  geographic_scope == "invalid_or_missing_state",
  "invalid_or_missing_state",
  flag_source_state_conflict,
  "source_state_conflict",
  flag_source_zip_conflict,
  "source_zip_conflict",
  flag_source_unparsed_zip,
  "source_unparsed_zip",
  flag_placeholder_zip,
  "placeholder_zip",
  flag_zip_state_internal_conflict,
  "zip_state_internal_outlier",
  flag_zip_state_internal_ambiguity,
  "zip_state_internal_ambiguity",
  flag_multiple_addresses,
  "multiple_addresses_in_one_field",
  within_development_shared_base_query,
  "shared_base_query_within_development",
  flag_shared_base_zip_conflict,
  "conflicting_zip_within_shared_base",
  flag_po_box,
  "po_box",
  flag_administrative_address,
  "administrative_address",
  flag_scattered_or_unknown_label,
  "scattered_or_unknown_label",
  flag_building_label_only,
  "building_label_only",
  flag_parcel_or_legal_description,
  "parcel_or_legal_description",
  flag_intersection,
  "intersection",
  flag_malformed_text,
  "malformed_text",
  flag_address_range,
  "address_range",
  flag_unit_or_building,
  "unit_building_or_floor_suffix",
  flag_missing_structure_number,
  "missing_leading_structure_number",
  flag_missing_city,
  "missing_city",
  flag_missing_zip,
  "missing_zip",
  flag_invalid_zip,
  "invalid_zip",
  flag_repeated_across_developments,
  "same_address_multiple_developments",
  flag_base_address_collision,
  "base_address_collision_within_development",
  default = "provisionally_queryable"
)]

site[, review_reasons := apply(
  .SD,
  1L,
  function(value) {
    reasons <- names(value)[as.logical(value)]
    if (length(reasons) == 0L) NA_character_ else paste(reasons, collapse = "|")
  }
), .SDcols = patterns("^flag_")]

queryable_statuses <- c(
  "provisionally_queryable",
  "provisionally_queryable_shared_base"
)
proposed_queries <- site[
  address_readiness_status %chin% queryable_statuses,
  .(
    query_basis = fifelse(
      any(within_development_shared_base_query),
      "shared_base_within_development",
      "listed_address"
    ),
    query_street = first_text(proposed_query_street),
    query_city = first_text(query_city),
    query_state = first_text(query_state),
    query_zip = first_text(query_zip)
  ),
  by = proposed_query_key
]
setorder(
  proposed_queries,
  query_state,
  query_city,
  query_street,
  query_zip,
  na.last = TRUE
)
proposed_queries[, proposed_query_id := sprintf(
  "GQ_%06d",
  seq_len(.N)
)]
query_counts <- site[
  address_readiness_status %chin% queryable_statuses,
  .(
    n_sites = .N,
    n_developments = uniqueN(development_id),
    n_shared_base_sites = sum(within_development_shared_base_query),
    n_sites_with_coordinates = sum(coordinate_present),
    n_sites_missing_coordinates = sum(!coordinate_present)
  ),
  by = proposed_query_key
]
proposed_queries[query_counts, `:=`(
  n_sites = i.n_sites,
  n_developments = i.n_developments,
  n_shared_base_sites = i.n_shared_base_sites,
  n_sites_with_coordinates = i.n_sites_with_coordinates,
  n_sites_missing_coordinates = i.n_sites_missing_coordinates
), on = "proposed_query_key"]
proposed_queries[, submission_approval := "not_approved"]
setcolorder(proposed_queries, c(
  "proposed_query_id", "submission_approval", "query_basis",
  "query_street", "query_city", "query_state", "query_zip",
  "proposed_query_key", "n_sites", "n_developments",
  "n_shared_base_sites", "n_sites_with_coordinates",
  "n_sites_missing_coordinates"
))

site[
  address_readiness_status %chin% queryable_statuses,
  proposed_query_id := proposed_queries$proposed_query_id[
    match(proposed_query_key, proposed_queries$proposed_query_key)
  ]
]
site[, query_mapping_status := fcase(
  geographic_scope != "in_scope_50_states_dc",
  "outside_research_scope",
  address_readiness_status ==
    "provisionally_queryable_shared_base" &
    !is.na(proposed_query_id),
  "one_shared_base_query_not_approved",
  address_readiness_status == "provisionally_queryable" &
    !is.na(proposed_query_id),
  "one_listed_address_query_not_approved",
  address_readiness_status == "requires_address_split",
  "requires_multiple_query_records",
  default = "no_safe_query_pending_review"
)]
site[, submission_approval := "not_approved"]

if (uniqueN(proposed_queries$proposed_query_id) !=
      nrow(proposed_queries) ||
    uniqueN(proposed_queries$proposed_query_key) !=
      nrow(proposed_queries) ||
    site[address_readiness_status %chin% queryable_statuses,
      any(is.na(proposed_query_id))] ||
    site[!address_readiness_status %chin% queryable_statuses,
      any(!is.na(proposed_query_id))] ||
    proposed_queries[n_developments > 1L, .N] > 0L ||
    site[
      within_development_shared_base_query &
        flag_repeated_across_developments,
      .N
    ] > 0L ||
    any(proposed_queries$submission_approval != "not_approved") ||
    any(site$submission_approval != "not_approved")) {
  stop("The proposed-query safety contract failed.", call. = FALSE)
}

setorder(site, primary_review_reason, query_state, development_site_id)
manual_review_sample <- site[, {
  sample_rows <- unique(as.integer(round(seq(
    1,
    .N,
    length.out = min(.N, 20L)
  ))))
  .SD[sample_rows]
}, by = primary_review_reason]
manual_review_sample <- manual_review_sample[, .(
  primary_review_reason,
  development_site_id,
  development_id,
  development_name_examples,
  state_id_examples,
  allocation_year_examples,
  placed_in_service_year_examples,
  episode_unit_examples,
  site_source,
  site_street,
  site_city,
  site_state,
  site_zip,
  zip_format_action,
  query_zip,
  proposed_query_street,
  within_development_shared_base_query,
  base_address_n_developments,
  unit_building_position,
  source_street_examples,
  source_city_examples,
  source_zip_examples,
  source_zip5_examples,
  source_duplicate_row_count,
  exact_address_n_developments,
  exact_address_development_name_examples,
  address_readiness_status,
  coordinate_readiness_status,
  review_reasons,
  proposed_query_id,
  submission_approval
)]

site_flag_columns <- grep("^flag_", names(site), value = TRUE)
flag_counts <- data.table(
  flag = site_flag_columns,
  sites = vapply(
    site[geographic_scope == "in_scope_50_states_dc", ..site_flag_columns],
    sum,
    integer(1L),
    na.rm = TRUE
  )
)[order(-sites, flag)]
scope_counts <- site[, .N, by = geographic_scope][order(geographic_scope)]
address_status_counts <- site[
  geographic_scope == "in_scope_50_states_dc",
  .N,
  by = address_readiness_status
][order(address_readiness_status)]
coordinate_status_counts <- site[
  geographic_scope == "in_scope_50_states_dc",
  .N,
  by = coordinate_readiness_status
][order(coordinate_readiness_status)]
primary_reason_counts <- site[
  geographic_scope == "in_scope_50_states_dc",
  .N,
  by = primary_review_reason
][order(-N, primary_review_reason)]
zip_action_counts <- site[
  geographic_scope == "in_scope_50_states_dc",
  .N,
  by = zip_format_action
][order(zip_format_action)]
unit_position_counts <- site[
  geographic_scope == "in_scope_50_states_dc" &
    unit_building_position != "none",
  .N,
  by = unit_building_position
][order(unit_building_position)]
site_source_counts <- site[
  geographic_scope == "in_scope_50_states_dc",
  .N,
  by = site_source
][order(site_source)]
excluded_territory_counts <- site[
  geographic_scope == "excluded_territory",
  .N,
  by = site_state
][order(site_state)]
query_basis_counts <- proposed_queries[, .(
  queries = .N,
  mapped_sites = sum(n_sites)
), by = query_basis][order(query_basis)]
shared_base_zip_conflict_summary <- site[
  flag_shared_base_zip_conflict == TRUE,
  .(
    groups = uniqueN(paste(development_id, base_address_key, sep = "|")),
    sites = .N
  )
]

format_markdown_table <- function(table) {
  header <- paste0("| ", paste(names(table), collapse = " | "), " |")
  divider <- paste0(
    "| ",
    paste(rep("---", ncol(table)), collapse = " | "),
    " |"
  )
  rows <- apply(table, 1L, function(row) {
    paste0("| ", paste(row, collapse = " | "), " |")
  })
  c(header, divider, rows)
}

summary_lines <- c(
  "# LIHTC Geocoding Readiness Audit",
  "",
  "## Safety contract",
  "",
  "- This audit is entirely local. It calls no geocoder and transmits no address or coordinate.",
  "- No source or production row is changed.",
  "- The research scope is the 50 states plus the District of Columbia.",
  "- Puerto Rico and the other territories remain in the input and are reported as explicitly excluded records.",
  "- Every proposed query is marked `not_approved`; this task does not create an upload-ready file.",
  "- A local audit can test internal coordinate plausibility and conflicts, but it cannot establish that a HUD coordinate matches a street address. That validation remains pending.",
  "",
  "## Input and scope counts",
  "",
  paste0("- Final development sites: ", format(nrow(site), big.mark = ","), "."),
  paste0("- HUD project episodes: ", format(nrow(episode), big.mark = ","), "."),
  paste0("- Raw multi-address rows: ", format(nrow(multisite), big.mark = ","), "."),
  paste0("- Included informative multi-address rows: ", format(nrow(multisite_sources), big.mark = ","), "."),
  paste0("- Uninformative multi-address rows excluded by the site producer: ", format(multisite[informative_site == FALSE, .N], big.mark = ","), "."),
  paste0("- Multi-address rows excluded for rejected coarse portfolio links: ", format(multisite[informative_site == TRUE & linkage_review_decision == "reject", .N], big.mark = ","), "."),
  paste0("- Exact duplicate raw multi-address rows: ", format(nrow(multisite) - uniqueN(multisite), big.mark = ","), "."),
  paste0("- Final sites fed by at least one repeated address/BIN source record: ", format(site[source_duplicate_row_count > 0L, .N], big.mark = ","), "."),
  "",
  format_markdown_table(scope_counts),
  "",
  "### Explicit territory exclusions",
  "",
  format_markdown_table(excluded_territory_counts),
  "",
  "## Multi-address row behavior",
  "",
  "The upstream site producer does not split text inside an address cell. Each informative multi-address row maps to exactly one normalized development/site key; repeated address/BIN records collapse to that same key. Compound cells, ranges, building-only labels, and base-address collisions remain explicit review records rather than being silently expanded or discarded.",
  "",
  format_markdown_table(site_source_counts),
  "",
  paste0("- In-scope address cells containing multiple proposed street addresses: ", format(site[geographic_scope == "in_scope_50_states_dc" & flag_multiple_addresses, .N], big.mark = ","), "."),
  paste0("- In-scope range or hyphenated-number cells requiring interpretation: ", format(site[geographic_scope == "in_scope_50_states_dc" & flag_address_range, .N], big.mark = ","), "."),
  paste0("- In-scope building-only labels without a street address: ", format(site[geographic_scope == "in_scope_50_states_dc" & flag_building_label_only, .N], big.mark = ","), "."),
  "",
  "## Address readiness within the 50 states and DC",
  "",
  format_markdown_table(address_status_counts),
  "",
  paste0("- Unique locally proposed queries: ", format(nrow(proposed_queries), big.mark = ","), "."),
  paste0("- Sites mapped to one proposed query: ", format(site[query_mapping_status %chin% c("one_listed_address_query_not_approved", "one_shared_base_query_not_approved"), .N], big.mark = ","), "."),
  paste0("- Sites whose address field must be split into multiple query records: ", format(site[query_mapping_status == "requires_multiple_query_records", .N], big.mark = ","), "."),
  paste0("- In-scope sites with no safe query pending review: ", format(site[query_mapping_status == "no_safe_query_pending_review", .N], big.mark = ","), "."),
  "",
  "### Approved same-development sharing rule",
  "",
  "Site rows within one established development may share a base-street query when every difference is explained by a trailing building, unit, apartment, suite, floor, or room suffix, every row has the same normalized city, state, and ZIP, and no other address problem is present. Original site addresses remain unchanged. A base address used by more than one development is never cleared by this rule.",
  "",
  format_markdown_table(query_basis_counts),
  "",
  paste0(
    "- Same-development base-address groups with conflicting normalized ZIP values remain blocked: ",
    format(shared_base_zip_conflict_summary$groups, big.mark = ","),
    " groups covering ",
    format(shared_base_zip_conflict_summary$sites, big.mark = ","),
    " sites."
  ),
  "",
  "### Primary address disposition",
  "",
  format_markdown_table(primary_reason_counts),
  "",
  "### ZIP formatting",
  "",
  "The proposed ZIP field restores a leading zero to four-digit cells and splits unhyphenated nine-digit ZIP+4 cells. The raw `site_zip` is preserved. These are format-only proposals, not claims that the ZIP belongs to the listed street or city.",
  "",
  format_markdown_table(zip_action_counts),
  "",
  paste0("- Source-site groups with conflicting normalized ZIP5 values: ", format(site[geographic_scope == "in_scope_50_states_dc" & flag_source_zip_conflict, .N], big.mark = ","), "."),
  paste0("- Listed ZIP/state internal outliers: ", format(site[geographic_scope == "in_scope_50_states_dc" & flag_zip_state_internal_conflict, .N], big.mark = ","), "."),
  paste0("- Listed ZIP/state groups with no unique modal state: ", format(site[geographic_scope == "in_scope_50_states_dc" & flag_zip_state_internal_ambiguity, .N], big.mark = ","), "."),
  "- City/state/ZIP consistency is internally screened but not proven against an authoritative postal locality file. That exact external validation remains pending.",
  "",
  "### Unit and building text",
  "",
  "Unit, apartment, suite, room, floor, and building text is retained exactly in `site_street`. For the approved same-development cases, only the separate proposed query uses the normalized base street.",
  "",
  format_markdown_table(unit_position_counts),
  "",
  "Cross-development address repeats remain blocked for review. Irregular within-development base collisions also remain blocked. The output supplies development names, state IDs, years, unit counts, ZIP variants, and coordinate evidence, but it does not automatically call a repeated address a duplicate, campus, or separate building.",
  "",
  "## Coordinate readiness within the 50 states and DC",
  "",
  format_markdown_table(coordinate_status_counts),
  "",
  paste0("- Coordinates outside the broad region for their listed state: ", format(site[geographic_scope == "in_scope_50_states_dc" & flag_coordinate_outside_broad_state_group, .N], big.mark = ","), "."),
  paste0("- Exact coordinate pairs reused across different listed addresses: ", format(site[geographic_scope == "in_scope_50_states_dc" & flag_coordinate_reused_across_addresses, .N], big.mark = ","), "."),
  paste0("- Listed addresses associated with multiple HUD coordinate pairs: ", format(site[geographic_scope == "in_scope_50_states_dc" & flag_address_coordinate_conflict, .N], big.mark = ","), "."),
  "- These checks can falsify some HUD coordinates but cannot prove that an internally plausible coordinate corresponds to a listed street address. Exact address validation requires a later, separately approved reference or geocoding step.",
  "",
  "## Address and coordinate flags",
  "",
  format_markdown_table(flag_counts),
  "",
  "The site-level Parquet preserves all flags, source examples, internal conflict counts, and the one-query-or-review mapping. The proposed-query Parquet contains only provisionally queryable addresses, but every row remains unapproved. The deterministic CSV sample supports human review of every primary reason category."
)

setorder(site, development_site_id)
setorder(proposed_queries, proposed_query_id)
write_parquet(
  site,
  "../output/lihtc_site_geocoding_readiness.parquet",
  compression = "zstd"
)
write_parquet(
  proposed_queries,
  "../output/proposed_address_queries.parquet",
  compression = "zstd"
)
fwrite(manual_review_sample, "../output/manual_review_sample.csv", na = "")
writeLines(summary_lines, "../output/audit_summary.md")

if (!identical(
  site,
  as.data.table(read_parquet(
    "../output/lihtc_site_geocoding_readiness.parquet"
  ))
) || !identical(
  proposed_queries,
  as.data.table(read_parquet(
    "../output/proposed_address_queries.parquet"
  ))
)) {
  stop("A geocoding-readiness Parquet changed on round trip.",
    call. = FALSE)
}

cat(
  "Audited ", format(nrow(site), big.mark = ","),
  " development sites locally; ",
  format(nrow(proposed_queries), big.mark = ","),
  " unique address queries remain explicitly unapproved.\n",
  sep = ""
)
