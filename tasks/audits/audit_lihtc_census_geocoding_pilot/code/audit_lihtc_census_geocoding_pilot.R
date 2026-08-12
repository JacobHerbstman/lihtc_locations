# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/audit_lihtc_census_geocoding_pilot/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
})

result <- as.data.table(read_parquet("../input/lihtc_census_geocoding_pilot.parquet"))
manifest <- as.data.table(read_parquet("../input/lihtc_census_geocoding_pilot_manifest.parquet"))
raw_input <- fread(
  "../../../../data_raw/census_geocoder/2026-08-12/attempt_02/lihtc_census_geocoding_pilot_input.csv",
  header = FALSE,
  col.names = c(
    "census_batch_id", "query_street", "query_city", "query_state",
    "query_zip"
  ),
  colClasses = "character"
)
raw_response <- fread(
  "../../../../data_raw/census_geocoder/2026-08-12/attempt_02/lihtc_census_geocoding_pilot_response.csv",
  header = FALSE,
  col.names = c(
    "census_batch_id", "input_address", "match_status", "match_type",
    "matched_address", "coordinates", "tigerline", "side", "state_fips",
    "county_fips", "tract_code", "block_code"
  ),
  colClasses = "character",
  fill = TRUE
)
raw_metadata <- fread(
  "../../../../data_raw/census_geocoder/2026-08-12/attempt_02/lihtc_census_geocoding_pilot_retrieval.csv"
)
setorder(result, census_batch_id)
setorder(manifest, census_batch_id)
setorder(raw_input, census_batch_id)
setorder(raw_response, census_batch_id)

raw_columns <- c(
  "census_batch_id", "input_address", "match_status", "match_type",
  "matched_address", "coordinates", "tigerline", "side", "state_fips",
  "county_fips", "tract_code", "block_code"
)

if (nrow(result) != 457L || nrow(manifest) != 457L ||
    nrow(raw_input) != 457L || nrow(raw_response) != 457L ||
    nrow(raw_metadata) != 1L ||
    uniqueN(result$census_batch_id) != nrow(result) ||
    uniqueN(manifest$census_batch_id) != nrow(manifest) ||
    uniqueN(raw_input$census_batch_id) != nrow(raw_input) ||
    uniqueN(raw_response$census_batch_id) != nrow(raw_response) ||
    !setequal(result$census_batch_id, manifest$census_batch_id) ||
    !identical(
      raw_input,
      manifest[, .(
        census_batch_id,
        query_street,
        query_city,
        query_state,
        query_zip
      )]
    ) ||
    raw_metadata$input_md5 != unname(tools::md5sum(
      "../../../../data_raw/census_geocoder/2026-08-12/attempt_02/lihtc_census_geocoding_pilot_input.csv"
    )) ||
    !identical(result[, ..raw_columns], raw_response[, ..raw_columns]) ||
    raw_metadata$response_md5 != unname(tools::md5sum(
      "../../../../data_raw/census_geocoder/2026-08-12/attempt_02/lihtc_census_geocoding_pilot_response.csv"
    )) ||
    raw_metadata$response_bytes != file.info(
      "../../../../data_raw/census_geocoder/2026-08-12/attempt_02/lihtc_census_geocoding_pilot_response.csv"
    )$size ||
    result[matched == TRUE, any(!state_fips_agrees)] ||
    result[matched == TRUE, anyNA(census_longitude) | anyNA(census_latitude)]) {
  stop("The independently audited Census pilot contract failed.", call. = FALSE)
}

audit <- rbindlist(list(
  result[, .(n = .N), by = match_status][, `:=`(measure = "match_status", group = match_status)][, match_status := NULL],
  result[, .(n = .N), by = .(group = fifelse(matched, match_type, "not_matched"))][, measure := "match_type"],
  result[, .(n = .N), by = .(group = fifelse(matched, as.character(state_fips_agrees), "not_matched"))][, measure := "state_fips_agreement"],
  result[matched & has_hud_coordinate, .(
    n = .N,
    mean_value = mean(hud_distance_meters),
    median_value = median(hud_distance_meters),
    p90_value = quantile(hud_distance_meters, 0.9),
    share_within_100m = mean(hud_distance_meters <= 100),
    share_within_1000m = mean(hud_distance_meters <= 1000)
  )][, `:=`(measure = "hud_coordinate_distance_meters", group = "matched_with_hud_coordinate")],
  result[, .(
    n = .N,
    match_rate = mean(matched),
    exact_match_rate_among_matches = mean(exact_match[matched])
  ), by = .(group = address_basis_group)][,
    measure := "match_rate_and_exact_rate_by_address_basis"],
  result[, .(
    n = .N,
    match_rate = mean(matched),
    exact_match_rate_among_matches = mean(exact_match[matched])
  ), by = .(group = multisite_group)][,
    measure := "match_rate_and_exact_rate_by_multisite_status"],
  result[, .(
    n = .N,
    match_rate = mean(matched),
    exact_match_rate_among_matches = mean(exact_match[matched])
  ), by = .(group = fifelse(
    has_hud_coordinate,
    "has_hud_coordinate",
    "no_hud_coordinate"
  ))][, measure := "match_rate_and_exact_rate_by_hud_coordinate"]
), use.names = TRUE, fill = TRUE)
setorder(audit, measure, group)
write_parquet(audit, "../output/lihtc_census_geocoding_pilot_audit.parquet", compression = "zstd")

result[, pilot_review_status := fcase(
  match_status == "No_Match", "unmatched_requires_address_review",
  match_status == "Tie", "tie_requires_candidate_review",
  match_type == "Non_Exact", "nonexact_match_requires_manual_review",
  exact_match & has_hud_coordinate & hud_distance_meters > 1000,
  "exact_match_large_hud_distance_review",
  default = "no_additional_pilot_flag"
)]
review_queue <- result[
  pilot_review_status != "no_additional_pilot_flag",
  .(
    census_batch_id,
    geocoding_query_id,
    development_id,
    query_street,
    query_city,
    query_state,
    query_zip,
    query_basis,
    address_basis_group,
    multisite_group,
    match_status,
    match_type,
    matched_address,
    census_longitude,
    census_latitude,
    has_hud_coordinate,
    representative_hud_longitude,
    representative_hud_latitude,
    hud_distance_meters,
    pilot_review_status,
    manual_review_decision = "not_reviewed"
  )
]
setorder(review_queue, pilot_review_status, census_batch_id)
expected_review_ids <- result[
  pilot_review_status != "no_additional_pilot_flag",
  census_batch_id
]
if (nrow(review_queue) != 227L ||
    uniqueN(review_queue$census_batch_id) != nrow(review_queue) ||
    !setequal(review_queue$census_batch_id, expected_review_ids) ||
    any(review_queue$manual_review_decision != "not_reviewed")) {
  stop("The conservative Census pilot review queue is incomplete.",
    call. = FALSE)
}
write_parquet(
  review_queue,
  "../output/lihtc_census_geocoding_pilot_review_queue.parquet",
  compression = "zstd"
)
if (!identical(
  review_queue,
  as.data.table(read_parquet(
    "../output/lihtc_census_geocoding_pilot_review_queue.parquet"
  ))
)) {
  stop("The Census pilot review queue changed on Parquet round trip.",
    call. = FALSE)
}

match_rate <- mean(result$matched)
exact_rate <- mean(result$exact_match[result$matched])
distance <- audit[measure == "hud_coordinate_distance_meters"]
writeLines(c(
  "# Census geocoding pilot audit",
  "",
  sprintf("- Returned IDs: %s of %s, unique and complete.", nrow(result), nrow(manifest)),
  sprintf("- Match rate: %.1f%%; exact-match rate among matches: %.1f%%.", 100 * match_rate, 100 * exact_rate),
  sprintf("- Matched state-FIPS disagreements: %s.", result[matched & !state_fips_agrees, .N]),
  sprintf("- HUD-coordinate comparisons: %s matched queries; median distance %.0f m; 90th percentile %.0f m.", distance$n, distance$median_value, distance$p90_value),
  sprintf("- Conservative manual-review queue: %s queries; no decision has been made.", nrow(review_queue)),
  "",
  "This audit does not approve any query for full submission or tract assignment."
), "../output/census_geocoding_pilot_summary.md")

if (!isTRUE(all.equal(audit, as.data.table(read_parquet(
  "../output/lihtc_census_geocoding_pilot_audit.parquet"
)), check.attributes = FALSE))) {
  stop("The independent Census pilot audit changed on Parquet round trip.", call. = FALSE)
}
