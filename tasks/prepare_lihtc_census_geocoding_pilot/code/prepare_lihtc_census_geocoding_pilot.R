# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/prepare_lihtc_census_geocoding_pilot/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
})

stable_hash <- function(value) {
  vapply(value, function(one_value) {
    hash <- 0
    for (character_code in utf8ToInt(one_value)) {
      hash <- (hash * 31 + character_code) %% 2147483647
    }
    hash
  }, numeric(1L))
}

development <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_unit_scope_adjudicated.parquet"
))
site <- as.data.table(read_parquet(
  "../input/lihtc_development_site_2024_unit_scope_adjudicated.parquet"
))
component <- as.data.table(read_parquet(
  "../input/lihtc_site_address_component_2024_geocoding_crosswalk.parquet"
))
query <- as.data.table(read_parquet("../input/lihtc_geocoding_queries_2024.parquet"))

if (nrow(development) != 53469L || nrow(site) != 131473L ||
    nrow(component) != 137255L || nrow(query) != 83734L || uniqueN(development$development_id) != nrow(development) ||
    uniqueN(site$development_site_id) != nrow(site) || uniqueN(query$geocoding_query_id) != nrow(query) ||
    uniqueN(component$development_site_address_component_id) != nrow(component) ||
    any(query$submission_approval != "not_approved")) {
  stop("A pilot-preparation input count or approval changed.", call. = FALSE)
}

site_count <- site[, .(n_source_sites = .N), by = development_id]
development[site_count, n_source_sites := i.n_source_sites, on = "development_id"]
if (anyNA(development$n_source_sites)) {
  development[is.na(n_source_sites), n_source_sites := 0L]
}
query[development, `:=`(
  development_state = i.development_state,
  n_source_sites = i.n_source_sites
), on = "development_id"]
if (anyNA(query$development_state) || anyNA(query$n_source_sites)) {
  stop("Development attributes did not join safely to pilot queries.", call. = FALSE)
}

query_coordinate <- component[!is.na(geocoding_query_id), .(
  has_hud_coordinate = any(!is.na(latitude) & !is.na(longitude)),
  representative_hud_longitude = {
    value <- longitude[!is.na(latitude) & !is.na(longitude)]
    if (length(value) == 0L) NA_real_ else value[1L]
  },
  representative_hud_latitude = {
    value <- latitude[!is.na(latitude) & !is.na(longitude)]
    if (length(value) == 0L) NA_real_ else value[1L]
  },
  coordinate_readiness_examples = paste(sort(unique(coordinate_readiness_status)), collapse = "|")
), by = geocoding_query_id]
query[query_coordinate, `:=`(
  has_hud_coordinate = i.has_hud_coordinate,
  representative_hud_longitude = i.representative_hud_longitude,
  representative_hud_latitude = i.representative_hud_latitude,
  coordinate_readiness_examples = i.coordinate_readiness_examples
), on = "geocoding_query_id"]
if (anyNA(query$has_hud_coordinate)) {
  stop("Coordinate evidence did not join one-to-one to pilot queries.", call. = FALSE)
}

query[, `:=`(
  address_basis_group = fifelse(
    query_basis == "baseline_final_readiness_query",
    "baseline",
    "reviewed"
  ),
  multisite_group = fifelse(n_source_sites == 1L, "one_site", "multiple_sites"),
  hud_coordinate_group = fifelse(has_hud_coordinate, "has_hud_coordinate", "no_hud_coordinate")
)]
query[, pilot_hash := stable_hash(paste(
  "lihtc_census_pilot_2026_08_12", geocoding_query_id, sep = "|"
))]
setorder(query, development_state, address_basis_group, multisite_group,
  hud_coordinate_group, pilot_hash, geocoding_query_id)
query[, stratum_rank := seq_len(.N), by = .(
  development_state, address_basis_group, multisite_group, hud_coordinate_group
)]

# Each nonempty state-by-basis-by-multisite-by-coordinate stratum contributes
# at most two queries. With eight possible strata, this is below the 24-query
# state cap without a second, less transparent fill rule.
query[, pilot_selected := stratum_rank <= 2L]

pilot <- query[pilot_selected == TRUE]
setorder(pilot, development_state, address_basis_group, multisite_group,
  hud_coordinate_group, pilot_hash, geocoding_query_id)
pilot[, census_batch_id := sprintf("LIHTC_CENSUS_%04d", seq_len(.N))]

if (nrow(pilot) > 1224L || nrow(pilot) > 10000L ||
    uniqueN(pilot$census_batch_id) != nrow(pilot) ||
    anyNA(pilot$query_street) || anyNA(pilot$query_state) ||
    any(pilot$query_street == "") || any(pilot$query_state == "") ||
    any(pilot$development_state != pilot$query_state)) {
  stop("The Census pilot sample or required address fields are unsafe.", call. = FALSE)
}
if (any(pilot[, .N, by = development_state]$N > 24L) ||
    any(pilot[, .N, by = .(
      development_state, address_basis_group, multisite_group, hud_coordinate_group
    )]$N > 2L)) {
  stop("The pilot stratification contract failed.", call. = FALSE)
}

census_input <- pilot[, .(
  unique_id = census_batch_id,
  street = query_street,
  city = query_city,
  state = query_state,
  zip = query_zip
)]
fwrite(census_input, "../output/lihtc_census_geocoding_pilot_input.csv", na = "",
  col.names = FALSE)

manifest <- pilot[, .(
  census_batch_id,
  geocoding_query_id,
  development_id,
  development_state,
  address_basis_group,
  multisite_group,
  query_basis,
  query_street,
  query_city,
  query_state,
  query_zip,
  n_source_sites,
  n_address_components,
  n_components_with_coordinates,
  coordinate_readiness_examples,
  has_hud_coordinate,
  representative_hud_longitude,
  representative_hud_latitude,
  pilot_hash
)]
write_parquet(manifest, "../output/lihtc_census_geocoding_pilot_manifest.parquet", compression = "zstd")

writeLines(c(
  "# Census geocoding pilot: safety check",
  "",
  sprintf("The frozen pilot contains %s queries, below the Census 10,000-record batch limit.", format(nrow(pilot), big.mark = ",")),
  "It uses a deterministic integer hash of the frozen query ID and is stratified by state, baseline-versus-reviewed address basis, one-versus-multiple source sites, and HUD-coordinate availability. Each nonempty stratum contributes up to two queries; each state contributes at most 24.",
  "",
  "No external request is made by this task. The headerless CSV has the Census batch schema: unique ID, street address, city, state, ZIP. Census requires a structure address and unique ID; city and ZIP may be blank, but street is required.",
  "",
  "The downstream submission uses benchmark `Public_AR_Census2020` and vintage `Census2020_Census2020`, retains the unmodified response, and validates returned IDs before any tract assignment. It uses the Census `geographies/addressbatch` endpoint, not an undocumented third-party service."
), "../output/pilot_safety_check.md")

if (!identical(manifest, as.data.table(read_parquet("../output/lihtc_census_geocoding_pilot_manifest.parquet")))) {
  stop("The pilot manifest Parquet changed on round trip.", call. = FALSE)
}
