# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/submit_lihtc_census_geocoding_pilot/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
})

manifest <- as.data.table(read_parquet("../input/lihtc_census_geocoding_pilot_manifest.parquet"))
response <- fread(
  "../../../data_raw/census_geocoder/2026-08-12/attempt_02/lihtc_census_geocoding_pilot_response.csv",
  header = FALSE,
  col.names = c(
    "census_batch_id", "input_address", "match_status", "match_type",
    "matched_address", "coordinates", "tigerline", "side", "state_fips",
    "county_fips", "tract_code", "block_code"
  ),
  colClasses = "character",
  fill = TRUE
)
metadata <- fread("../../../data_raw/census_geocoder/2026-08-12/attempt_02/lihtc_census_geocoding_pilot_retrieval.csv")
attempt_one_input <- "../../../data_raw/census_geocoder/2026-08-12/attempt_01/lihtc_census_geocoding_pilot_input.csv"
attempt_one_response <- "../../../data_raw/census_geocoder/2026-08-12/attempt_01/lihtc_census_geocoding_pilot_response.csv"
attempt_one_metadata <- fread("../../../data_raw/census_geocoder/2026-08-12/attempt_01/lihtc_census_geocoding_pilot_retrieval.csv")
attempt_two_input <- "../../../data_raw/census_geocoder/2026-08-12/attempt_02/lihtc_census_geocoding_pilot_input.csv"
attempt_two_response <- "../../../data_raw/census_geocoder/2026-08-12/attempt_02/lihtc_census_geocoding_pilot_response.csv"
attempt_two_submitted <- fread(
  attempt_two_input,
  header = FALSE,
  col.names = c(
    "census_batch_id", "query_street", "query_city", "query_state",
    "query_zip"
  ),
  colClasses = "character"
)
attempt_one_result <- fread(attempt_one_response, header = FALSE, fill = TRUE,
  colClasses = "character")

state_fips <- data.table(
  query_state = c(state.abb, "DC"),
  expected_state_fips = c(sprintf("%02d", c(
    1, 2, 4, 5, 6, 8, 9, 10, 12, 13, 15, 16, 17, 18, 19, 20, 21,
    22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37,
    38, 39, 40, 41, 42, 44, 45, 46, 47, 48, 49, 50, 51, 53, 54, 55,
    56
  )), "11")
)

if (nrow(manifest) != 457L || uniqueN(manifest$census_batch_id) != nrow(manifest) ||
    nrow(attempt_one_metadata) != 1L ||
    attempt_one_metadata$benchmark != "Public_AR_Census2020" ||
    attempt_one_metadata$vintage != "Census2020_Census2020" ||
    attempt_one_metadata$input_md5 != unname(tools::md5sum(attempt_one_input)) ||
    attempt_one_metadata$response_md5 != unname(tools::md5sum(attempt_one_response)) ||
    attempt_one_metadata$response_bytes != file.info(attempt_one_response)$size ||
    nrow(attempt_one_result) != 458L ||
    !setequal(attempt_one_result[[1L]], c(manifest$census_batch_id, "unique_id")) ||
    nrow(metadata) != 1L || metadata$benchmark != "Public_AR_Census2020" ||
    metadata$vintage != "Census2020_Census2020" ||
    metadata$input_md5 != unname(tools::md5sum(attempt_two_input)) ||
    metadata$input_md5 != unname(tools::md5sum(
      "../input/lihtc_census_geocoding_pilot_input.csv"
    )) ||
    metadata$response_md5 != unname(tools::md5sum(attempt_two_response)) ||
    metadata$response_bytes != file.info(attempt_two_response)$size ||
    !identical(
      attempt_two_submitted,
      manifest[, .(
        census_batch_id,
        query_street,
        query_city,
        query_state,
        query_zip
      )]
    ) ||
    nrow(response) != nrow(manifest) ||
    uniqueN(response$census_batch_id) != nrow(response) ||
    !setequal(response$census_batch_id, manifest$census_batch_id)) {
  stop("The Census response metadata or identifier contract failed.", call. = FALSE)
}

response[manifest, `:=`(
  geocoding_query_id = i.geocoding_query_id,
  development_id = i.development_id,
  query_state = i.query_state,
  query_street = i.query_street,
  query_city = i.query_city,
  query_zip = i.query_zip,
  query_basis = i.query_basis,
  address_basis_group = i.address_basis_group,
  multisite_group = i.multisite_group,
  has_hud_coordinate = i.has_hud_coordinate,
  representative_hud_longitude = i.representative_hud_longitude,
  representative_hud_latitude = i.representative_hud_latitude
), on = "census_batch_id"]
response[state_fips, expected_state_fips := i.expected_state_fips, on = "query_state"]
if (anyNA(response$geocoding_query_id) || anyNA(response$expected_state_fips)) {
  stop("The Census response did not join safely to pilot evidence.", call. = FALSE)
}

coordinate_parts <- tstrsplit(response$coordinates, ",", fixed = TRUE)
response[, `:=`(
  census_longitude = as.numeric(coordinate_parts[[1L]]),
  census_latitude = as.numeric(coordinate_parts[[2L]]),
  matched = match_status == "Match",
  exact_match = match_type == "Exact",
  state_fips_agrees = !is.na(state_fips) & state_fips == expected_state_fips
)]
response[, hud_distance_meters := NA_real_]
distance_rows <- response[
  matched & has_hud_coordinate & !is.na(census_longitude) & !is.na(census_latitude),
  which = TRUE
]
response[distance_rows, hud_distance_meters := {
  radians <- pi / 180
  longitude_difference <- (census_longitude - representative_hud_longitude) * radians
  latitude_difference <- (census_latitude - representative_hud_latitude) * radians
  a <- sin(latitude_difference / 2)^2 +
    cos(representative_hud_latitude * radians) * cos(census_latitude * radians) *
    sin(longitude_difference / 2)^2
  6371008.8 * 2 * atan2(sqrt(a), sqrt(1 - a))
}]

if (response[matched == TRUE, .N] == 0L ||
    response[matched == TRUE, anyNA(census_longitude) | anyNA(census_latitude)] ||
    response[matched == TRUE, anyNA(state_fips)] ||
    response[matched == TRUE, any(!state_fips_agrees)]) {
  stop("The Census response has no usable matches or a state disagreement.", call. = FALSE)
}

setorder(response, census_batch_id)
write_parquet(response, "../output/lihtc_census_geocoding_pilot.parquet", compression = "zstd")
if (!identical(response, as.data.table(read_parquet(
  "../output/lihtc_census_geocoding_pilot.parquet"
)))) {
  stop("The parsed Census response changed on Parquet round trip.", call. = FALSE)
}
