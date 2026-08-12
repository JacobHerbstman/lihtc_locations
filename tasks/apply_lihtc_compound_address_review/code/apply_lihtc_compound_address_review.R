# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/apply_lihtc_compound_address_review/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
})

site <- as.data.table(read_parquet(
  "../input/lihtc_final_site_geocoding_readiness.parquet"
))
review <- as.data.table(read_parquet(
  "../input/lihtc_compound_address_question_reviews.parquet"
))
reviewed_components <- as.data.table(read_parquet(
  "../input/lihtc_compound_address_component_reviews.parquet"
))

if (nrow(site) != 131473L ||
    uniqueN(site$development_site_id) != nrow(site) ||
    nrow(review) != 5114L ||
    uniqueN(review$development_site_id) != nrow(review) ||
    nrow(reviewed_components) != 9091L ||
    uniqueN(reviewed_components$reviewed_component_id) !=
      nrow(reviewed_components)) {
  stop("An application input count or key changed.", call. = FALSE)
}

split_ids <- review[
  final_action == "split_to_reviewed_components",
  development_site_id
]
unchanged <- site[!development_site_id %chin% split_ids]
unchanged[review, `:=`(
  compound_address_question_id = i.compound_address_question_id,
  compound_address_final_action = i.final_action,
  compound_address_final_reason = i.final_reason,
  compound_address_reviewed_on = i.reviewed_on
), on = "development_site_id"]

unchanged_components <- unchanged[, .(
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
    compound_address_final_action == "retain_one_fractional_address",
    "retained_reviewed_fractional_address",
    compound_address_final_action == "defer_unresolved",
    "retained_blocked_compound_source_cell",
    default = "inherited_source_site_address"
  ),
  address_component_reason_code = fcoalesce(
    compound_address_final_reason,
    "source_site_did_not_require_compound_address_review"
  ),
  compound_address_question_id,
  compound_address_reviewed_on,
  parent_requires_site_review = requires_site_review,
  parent_address_readiness_status = address_readiness_status,
  parent_primary_review_reason = primary_review_reason,
  parent_downstream_unit_analysis_status = downstream_unit_analysis_status,
  parent_downstream_unit_analysis_eligible = downstream_unit_analysis_eligible,
  component_geocoding_status = fifelse(
    compound_address_final_action == "defer_unresolved",
    "blocked_unresolved_compound_address",
    "pending_post_compound_readiness_review"
  ),
  submission_approval = "not_approved"
)]

split_parent <- site[reviewed_components, .(
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

components <- rbindlist(
  list(unchanged_components, split_parent),
  use.names = TRUE
)
setorder(components, development_site_id, component_rank)

parent_counts <- components[, .N, by = development_site_id]
expected_split_counts <- reviewed_components[, .N,
  by = development_site_id]
parent_counts[expected_split_counts, expected_split_n := i.N,
  on = "development_site_id"]

if (nrow(components) != 137255L ||
    uniqueN(components$development_site_address_component_id) !=
      nrow(components) ||
    uniqueN(components$development_site_id) != nrow(site) ||
    any(!components$development_site_id %chin% site$development_site_id) ||
    parent_counts[development_site_id %chin% split_ids,
      any(N != expected_split_n)] ||
    parent_counts[!development_site_id %chin% split_ids,
      any(N != 1L)] ||
    components[
      address_component_action == "split_to_two_read_component",
      .N
    ] != 9091L ||
    components[
      address_component_action == "retained_reviewed_fractional_address",
      .N
    ] != 37L ||
    components[
      address_component_action == "retained_blocked_compound_source_cell",
      .N
    ] != 1768L ||
    any(components$submission_approval != "not_approved")) {
  stop("The compound-address application contract failed.", call. = FALSE)
}

write_parquet(
  components,
  "../output/lihtc_site_address_component_2024_compound_adjudicated.parquet",
  compression = "zstd"
)

if (!identical(
  components,
  as.data.table(read_parquet(
    "../output/lihtc_site_address_component_2024_compound_adjudicated.parquet"
  ))
)) {
  stop("The compound-address component Parquet changed on round trip.",
    call. = FALSE)
}

cat(
  "Built ", nrow(components), " address components for ",
  uniqueN(components$development_site_id),
  " unchanged source sites; none is approved.\n",
  sep = ""
)
