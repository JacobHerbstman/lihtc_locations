# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/build_lihtc_geocoding_query_crosswalk/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
  library(stringr)
})

components <- as.data.table(read_parquet(
  "../input/lihtc_site_address_component_2024_compound_adjudicated.parquet"
))
range_review <- as.data.table(read_parquet(
  "../input/lihtc_range_address_reviews.parquet"
))
site <- as.data.table(read_parquet(
  "../input/lihtc_final_site_geocoding_readiness.parquet"
))

if (nrow(components) != 137255L ||
    uniqueN(components$development_site_address_component_id) !=
      nrow(components) ||
    nrow(range_review) != 8815L ||
    uniqueN(range_review$development_site_address_component_id) !=
      nrow(range_review) ||
    nrow(site) != 131473L ||
    uniqueN(site$development_site_id) != nrow(site)) {
  stop("A query-crosswalk input count or key changed.", call. = FALSE)
}

components[range_review, `:=`(
  range_address_question_id = i.range_address_question_id,
  range_address_final_action = i.final_action,
  range_address_final_query_street = i.final_query_street,
  range_address_final_reason = i.final_reason,
  range_address_reviewed_on = i.reviewed_on
), on = "development_site_address_component_id"]

site_evidence <- site[, .(
  development_site_id,
  baseline_proposed_query_id = proposed_query_id,
  baseline_proposed_query_street = proposed_query_street,
  baseline_query_city = query_city,
  baseline_query_state = query_state,
  baseline_query_zip = query_zip,
  baseline_address_readiness_status = address_readiness_status,
  flag_po_box,
  flag_administrative_address,
  flag_scattered_or_unknown_label,
  flag_building_label_only,
  flag_parcel_or_legal_description,
  flag_intersection,
  flag_unit_or_building,
  flag_malformed_text,
  flag_missing_structure_number,
  flag_missing_city,
  flag_missing_zip,
  flag_invalid_zip,
  flag_placeholder_zip,
  flag_source_site_inventory_review,
  flag_zip_state_internal_conflict,
  flag_zip_state_internal_ambiguity,
  flag_repeated_across_developments,
  flag_shared_base_zip_conflict,
  flag_upstream_site_review_pending,
  flag_deterministic_zip_format_repair,
  coordinate_readiness_status,
  latitude,
  longitude
)]
components[site_evidence, `:=`(
  baseline_proposed_query_id = i.baseline_proposed_query_id,
  baseline_proposed_query_street = i.baseline_proposed_query_street,
  baseline_query_city = i.baseline_query_city,
  baseline_query_state = i.baseline_query_state,
  baseline_query_zip = i.baseline_query_zip,
  baseline_address_readiness_status =
    i.baseline_address_readiness_status,
  flag_po_box = i.flag_po_box,
  flag_administrative_address = i.flag_administrative_address,
  flag_scattered_or_unknown_label = i.flag_scattered_or_unknown_label,
  flag_building_label_only = i.flag_building_label_only,
  flag_parcel_or_legal_description = i.flag_parcel_or_legal_description,
  flag_intersection = i.flag_intersection,
  flag_unit_or_building = i.flag_unit_or_building,
  flag_malformed_text = i.flag_malformed_text,
  flag_missing_structure_number = i.flag_missing_structure_number,
  flag_missing_city = i.flag_missing_city,
  flag_missing_zip = i.flag_missing_zip,
  flag_invalid_zip = i.flag_invalid_zip,
  flag_placeholder_zip = i.flag_placeholder_zip,
  flag_source_site_inventory_review =
    i.flag_source_site_inventory_review,
  flag_zip_state_internal_conflict = i.flag_zip_state_internal_conflict,
  flag_zip_state_internal_ambiguity =
    i.flag_zip_state_internal_ambiguity,
  flag_repeated_across_developments =
    i.flag_repeated_across_developments,
  flag_shared_base_zip_conflict = i.flag_shared_base_zip_conflict,
  flag_upstream_site_review_pending = i.flag_upstream_site_review_pending,
  flag_deterministic_zip_format_repair =
    i.flag_deterministic_zip_format_repair,
  coordinate_readiness_status = i.coordinate_readiness_status,
  latitude = i.latitude,
  longitude = i.longitude
), on = "development_site_id"]

if (components[, anyNA(baseline_address_readiness_status)] ||
    components[, anyNA(flag_po_box)]) {
  stop("Final readiness evidence did not join one-to-many safely.",
    call. = FALSE)
}

components[, newly_reviewed_address :=
  address_component_action %chin% c(
    "split_to_two_read_component",
    "retained_reviewed_fractional_address"
  ) |
    range_address_final_action %chin% c(
      "retain_literal_range_query",
      "normalize_single_ordinal_address"
    )]
components[, unresolved_compound :=
  address_component_action == "retained_blocked_compound_source_cell"]
components[, unresolved_range :=
  range_address_final_action == "defer_manual"]
components[, excluded_range :=
  range_address_final_action == "exclude_nonphysical"]

components[, other_address_blocker :=
  parent_requires_site_review |
    component_geocoding_status == "pending_collision_or_source_review" |
    flag_po_box | flag_administrative_address |
    flag_scattered_or_unknown_label | flag_building_label_only |
    flag_parcel_or_legal_description | flag_intersection |
    flag_unit_or_building | flag_malformed_text |
    flag_missing_structure_number | flag_missing_city |
    flag_missing_zip | flag_invalid_zip | flag_placeholder_zip |
    flag_source_site_inventory_review |
    flag_zip_state_internal_conflict |
    flag_zip_state_internal_ambiguity |
    flag_repeated_across_developments |
    flag_shared_base_zip_conflict |
    flag_upstream_site_review_pending]
components[is.na(other_address_blocker), other_address_blocker := FALSE]

components[, crosswalk_query_basis := fcase(
  !is.na(baseline_proposed_query_id),
  "baseline_final_readiness_query",
  newly_reviewed_address & other_address_blocker,
  "reviewed_address_with_other_blocker",
  range_address_final_action == "normalize_single_ordinal_address",
  "reviewed_ordinal_street_normalization",
  range_address_final_action == "retain_literal_range_query",
  "reviewed_literal_range_without_expansion",
  address_component_action == "split_to_two_read_component",
  "reviewed_compound_address_component",
  address_component_action == "retained_reviewed_fractional_address",
  "reviewed_fractional_civic_address",
  unresolved_compound,
  "unresolved_compound_address",
  unresolved_range,
  "unresolved_range_address",
  excluded_range,
  "excluded_nonphysical_range_description",
  default = "baseline_address_not_ready"
)]

components[, crosswalk_query_street := fcase(
  !is.na(baseline_proposed_query_id),
  baseline_proposed_query_street,
  newly_reviewed_address & !other_address_blocker &
    range_address_final_action == "normalize_single_ordinal_address",
  range_address_final_query_street,
  newly_reviewed_address & !other_address_blocker &
    range_address_final_action == "retain_literal_range_query",
  component_street,
  newly_reviewed_address & !other_address_blocker,
  component_street,
  default = NA_character_
)]
components[, `:=`(
  crosswalk_query_city = fifelse(
    !is.na(crosswalk_query_street),
    str_to_upper(str_squish(component_city)),
    NA_character_
  ),
  crosswalk_query_state = fifelse(
    !is.na(crosswalk_query_street),
    str_to_upper(str_squish(component_state)),
    NA_character_
  ),
  crosswalk_query_zip = fifelse(
    !is.na(crosswalk_query_street),
    baseline_query_zip,
    NA_character_
  )
)]
components[, crosswalk_query_status := fcase(
  !is.na(crosswalk_query_street),
  "ready_for_local_geocoding_pilot",
  unresolved_compound,
  "blocked_unresolved_compound_address",
  unresolved_range,
  "blocked_unresolved_range_address",
  excluded_range,
  "excluded_nonphysical_range_description",
  newly_reviewed_address & other_address_blocker,
  "blocked_other_address_or_source_issue",
  default = "blocked_baseline_address_issue"
)]
components[, development_scoped_query_key := fifelse(
  !is.na(crosswalk_query_street),
  paste(
    development_id,
    str_to_upper(str_squish(crosswalk_query_street)),
    str_to_upper(str_squish(crosswalk_query_city)),
    str_to_upper(str_squish(crosswalk_query_state)),
    fcoalesce(crosswalk_query_zip, ""),
    sep = "|"
  ),
  NA_character_
)]

queries <- components[!is.na(development_scoped_query_key), .(
  query_basis = paste(sort(unique(crosswalk_query_basis)), collapse = "|"),
  query_street = sort(unique(crosswalk_query_street))[1L],
  query_city = sort(unique(crosswalk_query_city))[1L],
  query_state = sort(unique(crosswalk_query_state))[1L],
  query_zip = sort(unique(crosswalk_query_zip))[1L],
  n_address_components = .N,
  n_source_sites = uniqueN(development_site_id),
  n_components_with_coordinates = sum(!is.na(latitude) & !is.na(longitude)),
  coordinate_readiness_examples = paste(
    sort(unique(coordinate_readiness_status)),
    collapse = "|"
  )
), by = .(development_id, development_scoped_query_key)]
setorder(queries, query_state, query_city, query_street, query_zip,
  development_id)
queries[, geocoding_query_id := sprintf("LIHTC_GQ_%06d", seq_len(.N))]
queries[, submission_approval := "not_approved"]

components[queries, geocoding_query_id := i.geocoding_query_id,
  on = c("development_id", "development_scoped_query_key")]
components[, submission_approval := "not_approved"]
setcolorder(queries, c(
  "geocoding_query_id", "submission_approval", "development_id",
  "query_basis", "query_street", "query_city", "query_state",
  "query_zip", "development_scoped_query_key", "n_address_components",
  "n_source_sites", "n_components_with_coordinates",
  "coordinate_readiness_examples"
))
setorder(components, development_site_address_component_id)

expected_status_counts <- data.table(
  crosswalk_query_status = c(
    "blocked_baseline_address_issue",
    "blocked_other_address_or_source_issue",
    "blocked_unresolved_compound_address",
    "blocked_unresolved_range_address",
    "excluded_nonphysical_range_description",
    "ready_for_local_geocoding_pilot"
  ),
  expected_n = c(33877L, 3807L, 1768L, 7992L, 2L, 89809L)
)
observed_status_counts <- components[, .N, by = crosswalk_query_status]
expected_status_counts[observed_status_counts, observed_n := i.N,
  on = "crosswalk_query_status"]

if (nrow(components) != 137255L ||
    uniqueN(components$development_site_address_component_id) !=
      nrow(components) ||
    nrow(queries) != 83734L ||
    uniqueN(queries$geocoding_query_id) != nrow(queries) ||
    uniqueN(
      queries,
      by = c("development_id", "development_scoped_query_key")
    ) !=
      nrow(queries) ||
    components[crosswalk_query_status ==
      "ready_for_local_geocoding_pilot", anyNA(geocoding_query_id)] ||
    components[crosswalk_query_status !=
      "ready_for_local_geocoding_pilot", any(!is.na(geocoding_query_id))] ||
    anyNA(expected_status_counts$observed_n) ||
    any(expected_status_counts$expected_n !=
      expected_status_counts$observed_n) ||
    components[
      crosswalk_query_basis == "baseline_final_readiness_query",
      .N
    ] != 83720L ||
    components[
      crosswalk_query_basis == "reviewed_compound_address_component" &
        !is.na(geocoding_query_id),
      .N
    ] != 5289L ||
    components[
      crosswalk_query_basis == "reviewed_fractional_civic_address" &
        !is.na(geocoding_query_id),
      .N
    ] != 32L ||
    components[
      range_address_final_action == "retain_literal_range_query" &
        !is.na(geocoding_query_id),
      .N
    ] != 665L ||
    components[
      range_address_final_action ==
        "normalize_single_ordinal_address" &
        !is.na(geocoding_query_id),
      .N
    ] != 103L ||
    uniqueN(components[!is.na(geocoding_query_id)]$development_site_id) !=
      86419L ||
    uniqueN(components[!is.na(geocoding_query_id)]$development_id) !=
      44621L ||
    queries[n_source_sites < 1L, .N] > 0L ||
    any(queries$submission_approval != "not_approved") ||
    any(components$submission_approval != "not_approved")) {
  stop("The geocoding query crosswalk contract failed.", call. = FALSE)
}

write_parquet(
  components,
  "../output/lihtc_site_address_component_2024_geocoding_crosswalk.parquet",
  compression = "zstd"
)
write_parquet(
  queries,
  "../output/lihtc_geocoding_queries_2024.parquet",
  compression = "zstd"
)

if (!identical(
  components,
  as.data.table(read_parquet(
    "../output/lihtc_site_address_component_2024_geocoding_crosswalk.parquet"
  ))
) || !identical(
  queries,
  as.data.table(read_parquet(
    "../output/lihtc_geocoding_queries_2024.parquet"
  ))
)) {
  stop("A geocoding crosswalk Parquet changed on round trip.",
    call. = FALSE)
}

cat(
  "Mapped ",
  components[crosswalk_query_status ==
    "ready_for_local_geocoding_pilot", .N],
  " address components to ", nrow(queries),
  " local queries; all remain unapproved.\n",
  sep = ""
)
