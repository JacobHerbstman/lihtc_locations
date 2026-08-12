# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/audit_lihtc_geocoding_query_crosswalk/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
  library(stringr)
})

site <- as.data.table(read_parquet(
  "../input/lihtc_final_site_geocoding_readiness.parquet"
))
compound_questions <- as.data.table(read_parquet(
  "../input/lihtc_compound_address_questions.parquet"
))
compound_review <- as.data.table(read_parquet(
  "../input/lihtc_compound_address_question_reviews.parquet"
))
compound_members <- as.data.table(read_parquet(
  "../input/lihtc_compound_address_component_reviews.parquet"
))
components <- as.data.table(read_parquet(
  "../input/lihtc_site_address_component_2024_compound_adjudicated.parquet"
))
range_questions <- as.data.table(read_parquet(
  "../input/lihtc_range_address_questions.parquet"
))
range_review <- as.data.table(read_parquet(
  "../input/lihtc_range_address_reviews.parquet"
))
crosswalk <- as.data.table(read_parquet(
  "../input/lihtc_site_address_component_2024_geocoding_crosswalk.parquet"
))
queries <- as.data.table(read_parquet(
  "../input/lihtc_geocoding_queries_2024.parquet"
))

split_ids <- compound_review[
  final_action == "split_to_reviewed_components",
  development_site_id
]
unchanged <- site[!development_site_id %chin% split_ids]
unchanged[compound_review, `:=`(
  compound_address_question_id = i.compound_address_question_id,
  final_action = i.final_action,
  final_reason = i.final_reason,
  reviewed_on = i.reviewed_on
), on = "development_site_id"]

expected_unchanged <- unchanged[, .(
  development_site_address_component_id = paste0(
    development_site_id,
    "_ADDRESS_01"
  ),
  development_site_id,
  development_id,
  component_rank = 1L,
  source_site_key = site_key,
  source_site_street = site_street,
  source_site_city = site_city,
  source_site_state = site_state,
  source_site_zip = site_zip,
  component_street = site_street,
  component_city = site_city,
  component_state = site_state,
  component_zip = site_zip,
  address_component_action = fcase(
    final_action == "retain_one_fractional_address",
    "retained_reviewed_fractional_address",
    final_action == "defer_unresolved",
    "retained_blocked_compound_source_cell",
    default = "inherited_source_site_address"
  ),
  address_component_reason_code = fcoalesce(
    final_reason,
    "source_site_did_not_require_compound_address_review"
  ),
  compound_address_question_id,
  compound_address_reviewed_on = reviewed_on,
  parent_requires_site_review = requires_site_review,
  parent_address_readiness_status = address_readiness_status,
  parent_primary_review_reason = primary_review_reason,
  parent_downstream_unit_analysis_status = downstream_unit_analysis_status,
  parent_downstream_unit_analysis_eligible = downstream_unit_analysis_eligible,
  component_geocoding_status = fifelse(
    final_action == "defer_unresolved",
    "blocked_unresolved_compound_address",
    "pending_post_compound_readiness_review"
  ),
  submission_approval = "not_approved"
)]

expected_split <- site[compound_members, .(
  development_site_address_component_id = paste0(
    i.development_site_id,
    "_ADDRESS_",
    sprintf("%02d", i.reviewed_component_rank)
  ),
  development_site_id = i.development_site_id,
  development_id = i.development_id,
  component_rank = i.reviewed_component_rank,
  source_site_key = x.site_key,
  source_site_street = x.site_street,
  source_site_city = x.site_city,
  source_site_state = x.site_state,
  source_site_zip = x.site_zip,
  component_street = i.reviewed_component_street,
  component_city = i.reviewed_component_city,
  component_state = i.reviewed_component_state,
  component_zip = i.reviewed_component_zip,
  address_component_action = "split_to_two_read_component",
  address_component_reason_code = i.component_reason,
  compound_address_question_id = i.compound_address_question_id,
  compound_address_reviewed_on = i.reviewed_on,
  parent_requires_site_review = x.requires_site_review,
  parent_address_readiness_status = x.address_readiness_status,
  parent_primary_review_reason = x.primary_review_reason,
  parent_downstream_unit_analysis_status =
    x.downstream_unit_analysis_status,
  parent_downstream_unit_analysis_eligible =
    x.downstream_unit_analysis_eligible,
  component_geocoding_status = fifelse(
    i.collision_with_another_proposal |
      i.collision_with_existing_site |
      x.requires_site_review,
    "pending_collision_or_source_review",
    "pending_post_compound_readiness_review"
  ),
  submission_approval = "not_approved"
), on = "development_site_id"]
expected_components <- rbindlist(
  list(expected_unchanged, expected_split),
  use.names = TRUE
)
setorder(expected_components, development_site_address_component_id)
component_contract_columns <- names(expected_components)
observed_components <- components[, ..component_contract_columns]
setorder(observed_components, development_site_address_component_id)

character_component_columns <- setdiff(
  component_contract_columns,
  c("component_rank", "parent_requires_site_review",
    "parent_downstream_unit_analysis_eligible")
)
component_rows_exact <- nrow(expected_components) == nrow(components) &&
  all(vapply(
    character_component_columns,
    function(column) identical(
      fcoalesce(as.character(expected_components[[column]]), ""),
      fcoalesce(as.character(observed_components[[column]]), "")
    ),
    logical(1L)
  )) && identical(
    expected_components$component_rank,
    observed_components$component_rank
  ) && identical(
    expected_components$parent_requires_site_review,
    observed_components$parent_requires_site_review
  ) && identical(
    expected_components$parent_downstream_unit_analysis_eligible,
    observed_components$parent_downstream_unit_analysis_eligible
  )

range_pattern <- "^[0-9]+[A-Z]?[[:space:]]*(?:-|TO)[[:space:]]*[0-9]+"
independent_range_ids <- expected_components[
  str_detect(str_to_upper(str_squish(component_street)), range_pattern),
  development_site_address_component_id
]

expected_crosswalk <- copy(expected_components)
expected_crosswalk[range_review, `:=`(
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
  coordinate_readiness_status,
  latitude,
  longitude
)]
expected_crosswalk[site_evidence, `:=`(
  baseline_proposed_query_id = i.baseline_proposed_query_id,
  baseline_proposed_query_street = i.baseline_proposed_query_street,
  baseline_query_city = i.baseline_query_city,
  baseline_query_state = i.baseline_query_state,
  baseline_query_zip = i.baseline_query_zip,
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
  coordinate_readiness_status = i.coordinate_readiness_status,
  latitude = i.latitude,
  longitude = i.longitude
), on = "development_site_id"]

expected_crosswalk[, newly_reviewed_address :=
  address_component_action %chin% c(
    "split_to_two_read_component",
    "retained_reviewed_fractional_address"
  ) | range_address_final_action %chin% c(
    "retain_literal_range_query",
    "normalize_single_ordinal_address"
  )]
expected_crosswalk[, other_address_blocker :=
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
expected_crosswalk[is.na(other_address_blocker),
  other_address_blocker := FALSE]
expected_crosswalk[, expected_query_street := fcase(
  !is.na(baseline_proposed_query_id),
  baseline_proposed_query_street,
  newly_reviewed_address & !other_address_blocker &
    range_address_final_action == "normalize_single_ordinal_address",
  range_address_final_query_street,
  newly_reviewed_address & !other_address_blocker,
  component_street,
  default = NA_character_
)]
expected_crosswalk[, `:=`(
  expected_query_city = fifelse(
    !is.na(expected_query_street),
    str_to_upper(str_squish(component_city)),
    NA_character_
  ),
  expected_query_state = fifelse(
    !is.na(expected_query_street),
    str_to_upper(str_squish(component_state)),
    NA_character_
  ),
  expected_query_zip = fifelse(
    !is.na(expected_query_street),
    baseline_query_zip,
    NA_character_
  )
)]
expected_crosswalk[, expected_development_scoped_query_key := fifelse(
  !is.na(expected_query_street),
  paste(
    development_id,
    str_to_upper(str_squish(expected_query_street)),
    str_to_upper(str_squish(expected_query_city)),
    str_to_upper(str_squish(expected_query_state)),
    fcoalesce(expected_query_zip, ""),
    sep = "|"
  ),
  NA_character_
)]
setorder(expected_crosswalk, development_site_address_component_id)
setorder(crosswalk, development_site_address_component_id)

query_fields_exact <- identical(
  fcoalesce(expected_crosswalk$expected_query_street, ""),
  fcoalesce(crosswalk$crosswalk_query_street, "")
) && identical(
  fcoalesce(expected_crosswalk$expected_query_city, ""),
  fcoalesce(crosswalk$crosswalk_query_city, "")
) && identical(
  fcoalesce(expected_crosswalk$expected_query_state, ""),
  fcoalesce(crosswalk$crosswalk_query_state, "")
) && identical(
  fcoalesce(expected_crosswalk$expected_query_zip, ""),
  fcoalesce(crosswalk$crosswalk_query_zip, "")
) && identical(
  fcoalesce(expected_crosswalk$expected_development_scoped_query_key, ""),
  fcoalesce(crosswalk$development_scoped_query_key, "")
)

expected_queries <- expected_crosswalk[
  !is.na(expected_development_scoped_query_key),
  .(
    query_street = sort(unique(expected_query_street))[1L],
    query_city = sort(unique(expected_query_city))[1L],
    query_state = sort(unique(expected_query_state))[1L],
    query_zip = sort(unique(expected_query_zip))[1L],
    n_address_components = .N,
    n_source_sites = uniqueN(development_site_id),
    n_components_with_coordinates = sum(!is.na(latitude) & !is.na(longitude)),
    coordinate_readiness_examples = paste(
      sort(unique(coordinate_readiness_status)),
      collapse = "|"
    )
  ),
  by = .(
    development_id,
    development_scoped_query_key =
      expected_development_scoped_query_key
  )
]
setorder(expected_queries, query_state, query_city, query_street, query_zip,
  development_id)
expected_queries[, geocoding_query_id := sprintf(
  "LIHTC_GQ_%06d",
  seq_len(.N)
)]
setorder(expected_queries, geocoding_query_id)
setorder(queries, geocoding_query_id)

query_contract_columns <- c(
  "geocoding_query_id", "development_id", "query_street", "query_city",
  "query_state", "query_zip", "development_scoped_query_key",
  "n_address_components", "n_source_sites",
  "n_components_with_coordinates", "coordinate_readiness_examples"
)
observed_queries <- queries[, ..query_contract_columns]
expected_query_contract <- expected_queries[, ..query_contract_columns]
query_character_columns <- setdiff(
  query_contract_columns,
  c("n_address_components", "n_source_sites",
    "n_components_with_coordinates")
)
query_groups_exact <- nrow(expected_queries) == nrow(queries) &&
  all(vapply(
    query_character_columns,
    function(column) identical(
      fcoalesce(as.character(expected_query_contract[[column]]), ""),
      fcoalesce(as.character(observed_queries[[column]]), "")
    ),
    logical(1L)
  )) && identical(
    expected_query_contract$n_address_components,
    observed_queries$n_address_components
  ) && identical(
    expected_query_contract$n_source_sites,
    observed_queries$n_source_sites
  ) && identical(
    expected_query_contract$n_components_with_coordinates,
    observed_queries$n_components_with_coordinates
  )

checks <- data.table(
  check_name = c(
    "final_site_input_count_and_key",
    "compound_question_exact_coverage",
    "compound_review_exact_coverage",
    "compound_two_read_split_count",
    "compound_reviewed_component_count_and_key",
    "source_site_complete_component_partition",
    "compound_component_rows_independently_reconstructed",
    "component_multiplicity_only_for_reviewed_splits",
    "unresolved_compounds_remain_one_blocked_component",
    "fractional_addresses_remain_one_component",
    "range_question_exact_component_set",
    "range_review_exact_coverage",
    "range_endpoint_expansion_never_applied",
    "literal_range_query_preserves_source_text",
    "ordinal_query_matches_prepared_single_address",
    "unresolved_and_nonphysical_ranges_have_no_query",
    "baseline_ready_query_fields_preserved",
    "new_ready_components_have_review_support",
    "new_ready_components_have_no_other_blocker",
    "crosswalk_query_fields_independently_reconstructed",
    "crosswalk_ready_mapping_complete_and_disjoint",
    "query_ids_and_development_keys_unique",
    "query_groups_independently_reconstructed",
    "queries_never_group_developments",
    "query_groups_preserve_one_literal_address",
    "source_site_and_unit_flags_preserved",
    "final_component_status_counts_exact",
    "final_ready_component_basis_counts_exact",
    "final_query_and_ready_site_counts_exact",
    "all_submission_approvals_remain_not_approved"
  ),
  passed = c(
    nrow(site) == 131473L && uniqueN(site$development_site_id) == nrow(site),
    nrow(compound_questions) == 5114L &&
      uniqueN(compound_questions$development_site_id) == nrow(compound_questions),
    nrow(compound_review) == 5114L &&
      setequal(compound_review$compound_address_question_id,
        compound_questions$compound_address_question_id),
    compound_review[final_action == "split_to_reviewed_components", .N] ==
      3309L,
    nrow(compound_members) == 9091L &&
      uniqueN(compound_members$reviewed_component_id) == nrow(compound_members),
    nrow(components) == 137255L &&
      uniqueN(components$development_site_id) == nrow(site),
    component_rows_exact,
    components[, .N, by = development_site_id][
      development_site_id %chin% split_ids,
      all(N > 1L)
    ] && components[, .N, by = development_site_id][
      !development_site_id %chin% split_ids,
      all(N == 1L)
    ],
    components[
      address_component_action == "retained_blocked_compound_source_cell",
      .N
    ] == 1768L,
    components[
      address_component_action == "retained_reviewed_fractional_address",
      .N
    ] == 37L,
    nrow(range_questions) == 8815L &&
      setequal(
        range_questions$development_site_address_component_id,
        independent_range_ids
      ),
    nrow(range_review) == 8815L &&
      setequal(range_review$range_address_question_id,
        range_questions$range_address_question_id),
    !any(range_review$endpoint_expansion_applied),
    range_review[
      final_action == "retain_literal_range_query",
      all(final_query_street == source_component_street)
    ],
    range_review[
      final_action == "normalize_single_ordinal_address",
      all(final_query_street == ordinal_single_address_proposal)
    ],
    crosswalk[
      range_address_final_action %chin% c(
        "defer_manual", "exclude_nonphysical"
      ),
      all(is.na(geocoding_query_id))
    ],
    crosswalk[!is.na(baseline_proposed_query_id), all(
      crosswalk_query_street == baseline_proposed_query_street &
        crosswalk_query_city == baseline_query_city &
        crosswalk_query_state == baseline_query_state &
        fcoalesce(crosswalk_query_zip, "") ==
          fcoalesce(baseline_query_zip, "")
    )],
    expected_crosswalk[
      is.na(baseline_proposed_query_id) &
        !is.na(expected_query_street),
      all(newly_reviewed_address)
    ],
    expected_crosswalk[
      is.na(baseline_proposed_query_id) &
        !is.na(expected_query_street),
      all(!other_address_blocker)
    ],
    query_fields_exact,
    crosswalk[
      crosswalk_query_status == "ready_for_local_geocoding_pilot",
      all(!is.na(geocoding_query_id))
    ] && crosswalk[
      crosswalk_query_status != "ready_for_local_geocoding_pilot",
      all(is.na(geocoding_query_id))
    ],
    uniqueN(queries$geocoding_query_id) == nrow(queries) &&
      uniqueN(
        queries,
        by = c("development_id", "development_scoped_query_key")
      ) ==
        nrow(queries),
    query_groups_exact,
    queries[, all(n_source_sites >= 1L)] &&
      crosswalk[!is.na(geocoding_query_id),
        uniqueN(development_id), by = geocoding_query_id][V1 > 1L, .N] == 0L,
    crosswalk[!is.na(geocoding_query_id), .(
      n_streets = uniqueN(crosswalk_query_street),
      n_cities = uniqueN(crosswalk_query_city),
      n_states = uniqueN(crosswalk_query_state),
      n_zips = uniqueN(crosswalk_query_zip)
    ), by = geocoding_query_id][
      n_streets > 1L | n_cities > 1L | n_states > 1L | n_zips > 1L,
      .N
    ] == 0L,
    identical(
      expected_components$parent_downstream_unit_analysis_status,
      components$parent_downstream_unit_analysis_status
    ) && identical(
      expected_components$parent_downstream_unit_analysis_eligible,
      components$parent_downstream_unit_analysis_eligible
    ),
    crosswalk[crosswalk_query_status == "ready_for_local_geocoding_pilot", .N] ==
      89809L && nrow(crosswalk) == 137255L,
    crosswalk[crosswalk_query_basis == "baseline_final_readiness_query", .N] ==
      83720L && crosswalk[
        crosswalk_query_basis == "reviewed_compound_address_component" &
          !is.na(geocoding_query_id),
        .N
      ] == 5289L && crosswalk[
        range_address_final_action == "retain_literal_range_query" &
          !is.na(geocoding_query_id),
        .N
      ] == 665L && crosswalk[
        range_address_final_action == "normalize_single_ordinal_address" &
          !is.na(geocoding_query_id),
        .N
      ] == 103L,
    nrow(queries) == 83734L &&
      uniqueN(crosswalk[!is.na(geocoding_query_id)]$development_site_id) ==
        86419L &&
      uniqueN(crosswalk[!is.na(geocoding_query_id)]$development_id) == 44621L,
    all(crosswalk$submission_approval == "not_approved") &&
      all(queries$submission_approval == "not_approved") &&
      all(compound_questions$submission_approval == "not_approved") &&
      all(compound_review$submission_approval == "not_approved") &&
      all(range_questions$submission_approval == "not_approved") &&
      all(range_review$submission_approval == "not_approved")
  )
)
checks[, audit_status := fifelse(passed, "pass", "fail")]

if (nrow(checks) != 30L || any(!checks$passed)) {
  print(checks[passed == FALSE])
  stop("The independent geocoding-query crosswalk audit failed.",
    call. = FALSE)
}

write_parquet(
  checks,
  "../output/lihtc_geocoding_query_crosswalk_audit.parquet",
  compression = "zstd"
)

if (!identical(
  checks,
  as.data.table(read_parquet(
    "../output/lihtc_geocoding_query_crosswalk_audit.parquet"
  ))
)) {
  stop("The crosswalk audit Parquet changed on round trip.",
    call. = FALSE)
}

cat(
  "All ", nrow(checks),
  " independent geocoding-query crosswalk checks passed.\n",
  sep = ""
)
