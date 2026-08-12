# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/audit_lihtc_final_geocoding_readiness/code")

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

development <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_unit_scope_adjudicated.parquet"
))
episode <- as.data.table(read_parquet(
  "../input/lihtc_project_episode_2024_unit_scope_adjudicated.parquet"
))
site <- as.data.table(read_parquet(
  "../input/lihtc_development_site_2024_unit_scope_adjudicated.parquet"
))

if (nrow(development) != 53469L || nrow(episode) != 54902L ||
    nrow(site) != 131473L ||
    uniqueN(development$development_id) != nrow(development) ||
    uniqueN(episode$hud_id) != nrow(episode) ||
    uniqueN(site$development_site_id) != nrow(site) ||
    uniqueN(site, by = c("development_id", "site_key")) != nrow(site) ||
    any(!episode$development_id %chin% development$development_id) ||
    any(!site$development_id %chin% development$development_id)) {
  stop("A final audit input count, key, or linkage changed.",
    call. = FALSE)
}

in_scope_states <- c(state.abb, "DC")
site[, geographic_scope := "in_scope_50_states_dc"]
if (any(!development$development_state %chin% in_scope_states) ||
    any(!site$site_state %chin% in_scope_states) ||
    any(!episode$proj_st %chin% in_scope_states) ||
    uniqueN(site$development_id) != 52672L) {
  stop("The final physical tables do not follow the 50-state-and-DC scope.",
    call. = FALSE)
}

uninformative_streets <- c(
  "N A", "NA", "NONE", "UNKNOWN", "UNAVAILABLE", "NOT AVAILABLE",
  "VARIOUS", "MULTIPLE", "MULTIPLE LOCATIONS", "SCATTERED",
  "SCATTERED SITE", "SCATTERED SITES", "TBD"
)
development_evidence <- development[, .(
  development_id,
  development_name_examples = development_name,
  n_units_physical_development = n_units_development,
  li_units_physical_development = li_units_development,
  downstream_unit_analysis_status,
  downstream_unit_analysis_eligible
)]
episode_evidence <- episode[, .(
  state_id_examples = collapse_text(state_id),
  allocation_year_examples = collapse_text(as.character(allocation_year)),
  placed_in_service_year_examples = collapse_text(as.character(pis_year)),
  episode_unit_examples = collapse_text(as.character(episode_units))
), by = development_id]

site[development_evidence, `:=`(
  development_name_examples = i.development_name_examples,
  audited_n_units_physical_development =
    i.n_units_physical_development,
  audited_li_units_physical_development =
    i.li_units_physical_development,
  audited_downstream_unit_analysis_status =
    i.downstream_unit_analysis_status,
  audited_downstream_unit_analysis_eligible =
    i.downstream_unit_analysis_eligible
), on = "development_id"]
site[episode_evidence, `:=`(
  state_id_examples = i.state_id_examples,
  allocation_year_examples = i.allocation_year_examples,
  placed_in_service_year_examples = i.placed_in_service_year_examples,
  episode_unit_examples = i.episode_unit_examples
), on = "development_id"]

if (anyNA(site$development_name_examples) ||
    anyNA(site$audited_downstream_unit_analysis_status) ||
    any(site$downstream_unit_analysis_status !=
      site$audited_downstream_unit_analysis_status) ||
    any(site$downstream_unit_analysis_eligible !=
      site$audited_downstream_unit_analysis_eligible)) {
  stop("The final development evidence did not join one-to-many safely.",
    call. = FALSE)
}
site[, c(
  "audited_n_units_physical_development",
  "audited_li_units_physical_development",
  "audited_downstream_unit_analysis_status",
  "audited_downstream_unit_analysis_eligible"
) := NULL]

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
  flag_source_site_inventory_review =
    source_site_geocoding_query_approval == "not_approved" |
      singleton_identity_scope_geocoding_query_approval ==
        "not_approved" |
      source_site_unresolved_status != "none" |
      str_detect(
        source_site_inventory_status,
        "incomplete|unresolved"
      )
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
      flag_source_site_inventory_review |
        flag_zip_state_internal_conflict |
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
site[, flag_upstream_site_review_pending :=
  requires_site_review & !within_development_shared_base_query &
    !flag_source_site_inventory_review]

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

site[, flag_deterministic_zip_format_repair :=
  zip_format_action %chin% c(
    "dropped_zip4",
    "restored_leading_zero",
    "split_unhyphenated_zip9"
  )]

site[, address_readiness_status := fcase(
  flag_source_site_inventory_review,
  "requires_source_site_inventory_review",
  flag_multiple_addresses,
  "requires_address_split",
  within_development_shared_base_query,
  "ready_after_deterministic_format_repair",
  flag_po_box | flag_administrative_address |
    flag_scattered_or_unknown_label | flag_building_label_only |
    flag_parcel_or_legal_description | flag_intersection |
    flag_missing_structure_number | flag_missing_city,
  "not_safely_geocodable",
  flag_upstream_site_review_pending |
    flag_shared_base_zip_conflict |
    flag_zip_state_internal_conflict |
    flag_zip_state_internal_ambiguity | flag_placeholder_zip |
    flag_address_range | flag_unit_or_building |
    flag_missing_zip | flag_invalid_zip | flag_malformed_text,
  "requires_address_review",
  flag_repeated_across_developments | flag_base_address_collision,
  "requires_shared_address_review",
  flag_deterministic_zip_format_repair,
  "ready_after_deterministic_format_repair",
  default = "ready_as_written"
)]
site[, primary_review_reason := fcase(
  flag_source_site_inventory_review,
  "source_or_site_inventory_review",
  flag_multiple_addresses,
  "multiple_addresses_in_one_field",
  within_development_shared_base_query,
  "shared_base_query_within_development",
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
  flag_missing_structure_number,
  "missing_leading_structure_number",
  flag_missing_city,
  "missing_city",
  flag_upstream_site_review_pending,
  "upstream_site_review_pending",
  flag_shared_base_zip_conflict,
  "conflicting_zip_within_shared_base",
  flag_zip_state_internal_conflict,
  "zip_state_internal_outlier",
  flag_zip_state_internal_ambiguity,
  "zip_state_internal_ambiguity",
  flag_placeholder_zip,
  "placeholder_zip",
  flag_malformed_text,
  "malformed_text",
  flag_address_range,
  "address_range",
  flag_unit_or_building,
  "unit_building_or_floor_suffix",
  flag_missing_zip,
  "missing_zip",
  flag_invalid_zip,
  "invalid_zip",
  flag_repeated_across_developments,
  "same_address_multiple_developments",
  flag_base_address_collision,
  "base_address_collision_within_development",
  flag_deterministic_zip_format_repair,
  "deterministic_zip_format_repair",
  default = "ready_as_written"
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
  "ready_as_written",
  "ready_after_deterministic_format_repair"
)
proposed_queries <- site[
  address_readiness_status %chin% queryable_statuses,
  .(
    query_basis = fifelse(
      any(within_development_shared_base_query),
      "shared_base_within_development",
      fifelse(
        any(flag_deterministic_zip_format_repair),
        "listed_address_zip_format_repair",
        "listed_address"
      )
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
  within_development_shared_base_query &
    !is.na(proposed_query_id),
  "one_shared_base_query_not_approved",
  address_readiness_status ==
    "ready_after_deterministic_format_repair" &
    !is.na(proposed_query_id),
  "one_reformatted_query_not_approved",
  address_readiness_status == "ready_as_written" &
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

expected_address_status_counts <- data.table(
  address_readiness_status = c(
    "not_safely_geocodable",
    "ready_after_deterministic_format_repair",
    "ready_as_written",
    "requires_address_review",
    "requires_address_split",
    "requires_shared_address_review",
    "requires_source_site_inventory_review"
  ),
  expected_sites = c(
    6391L,
    13897L,
    69823L,
    28676L,
    5113L,
    7337L,
    236L
  )
)
observed_address_status_counts <- site[, .(
  observed_sites = .N
), by = address_readiness_status]
expected_address_status_counts[observed_address_status_counts,
  observed_sites := i.observed_sites,
  on = "address_readiness_status"]

if (anyNA(expected_address_status_counts$observed_sites) ||
    nrow(observed_address_status_counts) !=
      nrow(expected_address_status_counts) ||
    expected_address_status_counts[
      expected_sites != observed_sites,
      .N
    ] > 0L ||
    nrow(proposed_queries) != 77648L ||
    site[!is.na(proposed_query_id), .N] != 83720L ||
    proposed_queries[
      query_basis == "shared_base_within_development",
      .N
    ] != 1531L ||
    proposed_queries[
      query_basis == "shared_base_within_development",
      sum(n_sites)
    ] != 7603L ||
    site[flag_source_site_inventory_review == TRUE, .N] != 236L ||
    site[requires_site_review == TRUE, .N] != 1880L ||
    site[flag_upstream_site_review_pending == TRUE, .N] != 1233L ||
    site[
      downstream_unit_analysis_status ==
        "exclude_missing_both_unit_counts",
      .N
    ] != 1984L) {
  stop("A final geocoding-readiness category count changed.",
    call. = FALSE)
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
  requires_site_review,
  source_site_unresolved_status,
  source_site_inventory_status,
  source_site_geocoding_query_approval,
  singleton_identity_scope_site_action,
  singleton_identity_scope_site_decision_reason,
  singleton_identity_scope_geocoding_query_approval,
  exact_address_n_developments,
  exact_address_development_name_examples,
  downstream_unit_analysis_status,
  downstream_unit_analysis_eligible,
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
unit_analysis_counts <- site[, .N, by = downstream_unit_analysis_status][
  order(downstream_unit_analysis_status)
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
  "- The input is the final physical-development layer for the 50 states and District of Columbia.",
  "- Every proposed query is marked `not_approved`; this task does not create an upload-ready file.",
  "- A local audit can test internal coordinate plausibility and conflicts, but it cannot establish that a HUD coordinate matches a street address. That validation remains pending.",
  "",
  "## Input and scope counts",
  "",
  paste0("- Physical developments: ", format(nrow(development), big.mark = ","), "."),
  paste0("- Developments represented by at least one site: ", format(uniqueN(site$development_id), big.mark = ","), "."),
  paste0("- Developments without a retained site: ", format(nrow(development) - uniqueN(site$development_id), big.mark = ","), "."),
  paste0("- Final development sites: ", format(nrow(site), big.mark = ","), "."),
  paste0("- HUD project episodes: ", format(nrow(episode), big.mark = ","), "."),
  "",
  format_markdown_table(scope_counts),
  "",
  "### Analysis-sample handoff",
  "",
  "The unit-analysis eligibility flag is carried through for downstream work but does not affect address readiness. Sites belonging to the 400 developments missing both static unit measures remain in this audit.",
  "",
  format_markdown_table(unit_analysis_counts),
  "",
  "## Final site provenance",
  "",
  "The final site inventory is authoritative. It incorporates reviewed removals, retained unresolved rows, and official external replacements or additions. This audit does not attempt to reconstruct that adjudicated inventory from superseded raw address rows.",
  "",
  format_markdown_table(site_source_counts),
  "",
  paste0("- Sites retained with an explicit unresolved source or inventory review: ", format(site[flag_source_site_inventory_review == TRUE, .N], big.mark = ","), "."),
  paste0("- Sites carrying an upstream site-review flag: ", format(site[requires_site_review == TRUE, .N], big.mark = ","), "."),
  "",
  "## Address readiness within the 50 states and DC",
  "",
  format_markdown_table(address_status_counts),
  "",
  paste0("- Unique locally proposed queries: ", format(nrow(proposed_queries), big.mark = ","), "."),
  paste0("- Sites mapped to one proposed query: ", format(site[query_mapping_status %chin% c("one_listed_address_query_not_approved", "one_reformatted_query_not_approved", "one_shared_base_query_not_approved"), .N], big.mark = ","), "."),
  paste0("- Sites whose address field must be split into multiple query records: ", format(site[query_mapping_status == "requires_multiple_query_records", .N], big.mark = ","), "."),
  paste0("- Sites with no safe query pending review: ", format(site[query_mapping_status == "no_safe_query_pending_review", .N], big.mark = ","), "."),
  "",
  "Compound address cells are not split automatically. Ranges, intersections, missing fields, and ambiguous building text remain review records. Ready-after-repair means only a deterministic ZIP-format operation or the narrowly approved same-development base-address rule.",
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
  paste0("- Listed ZIP/state internal outliers: ", format(site[flag_zip_state_internal_conflict == TRUE, .N], big.mark = ","), "."),
  paste0("- Listed ZIP/state groups with no unique modal state: ", format(site[flag_zip_state_internal_ambiguity == TRUE, .N], big.mark = ","), "."),
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
  paste0("- Coordinates outside the broad region for their listed state: ", format(site[flag_coordinate_outside_broad_state_group == TRUE, .N], big.mark = ","), "."),
  paste0("- Exact coordinate pairs reused across different listed addresses: ", format(site[flag_coordinate_reused_across_addresses == TRUE, .N], big.mark = ","), "."),
  paste0("- Listed addresses associated with multiple HUD coordinate pairs: ", format(site[flag_address_coordinate_conflict == TRUE, .N], big.mark = ","), "."),
  "- These checks can falsify some HUD coordinates but cannot prove that an internally plausible coordinate corresponds to a listed street address. Exact address validation requires a later, separately approved reference or geocoding step.",
  "",
  "## Address and coordinate flags",
  "",
  format_markdown_table(flag_counts),
  "",
  "The site-level Parquet preserves every final input field, audit flag, internal conflict count, and one-query-or-review mapping. The proposed-query Parquet contains only ready addresses, but every query remains unapproved. The deterministic CSV sample supports human review of every primary reason category."
)

setorder(site, development_site_id)
setorder(proposed_queries, proposed_query_id)
write_parquet(
  site,
  "../output/lihtc_final_site_geocoding_readiness.parquet",
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
    "../output/lihtc_final_site_geocoding_readiness.parquet"
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
