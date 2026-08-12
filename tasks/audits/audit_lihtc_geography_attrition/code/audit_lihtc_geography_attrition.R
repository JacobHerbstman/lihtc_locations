# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/audit_lihtc_geography_attrition/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
})

development <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_low_income_share_adjudicated.parquet"
))
site <- as.data.table(read_parquet(
  "../input/lihtc_development_site_2024_low_income_share_adjudicated.parquet"
))
component <- as.data.table(read_parquet(
  "../input/lihtc_site_address_component_2024_geocoding_crosswalk.parquet"
))
query <- as.data.table(read_parquet(
  "../input/lihtc_geocoding_queries_2024.parquet"
))

if (nrow(development) != 53469L || nrow(site) != 131473L ||
    nrow(component) != 137255L || nrow(query) != 83734L ||
    uniqueN(development$development_id) != nrow(development) ||
    uniqueN(site$development_site_id) != nrow(site) ||
    uniqueN(component$development_site_address_component_id) != nrow(component) ||
    uniqueN(query$geocoding_query_id) != nrow(query) ||
    any(!site$development_id %chin% development$development_id) ||
    any(!component$development_site_id %chin% site$development_site_id) ||
    any(!query$development_id %chin% development$development_id)) {
  stop("A geography-attrition input count or key changed.", call. = FALSE)
}

site_component <- component[, .(
  n_components = .N,
  n_ready_components = sum(crosswalk_query_status == "ready_for_local_geocoding_pilot"),
  n_blocked_components = sum(crosswalk_query_status != "ready_for_local_geocoding_pilot"),
  root_component_blocker = fcase(
    any(crosswalk_query_status == "blocked_baseline_address_issue"), "baseline_address_issue",
    any(crosswalk_query_status == "blocked_other_address_or_source_issue"), "other_address_or_source_issue",
    any(crosswalk_query_status == "blocked_unresolved_range_address"), "unresolved_range_address",
    any(crosswalk_query_status == "blocked_unresolved_compound_address"), "unresolved_compound_address",
    any(crosswalk_query_status == "excluded_nonphysical_range_description"), "nonphysical_range_description",
    default = "no_blocker"
  )
), by = development_site_id]

site[site_component, `:=`(
  n_components = i.n_components,
  n_ready_components = i.n_ready_components,
  n_blocked_components = i.n_blocked_components,
  root_component_blocker = i.root_component_blocker
), on = "development_site_id"]
site[is.na(n_components), `:=`(
  n_components = 0L,
  n_ready_components = 0L,
  n_blocked_components = 0L,
  root_component_blocker = "no_address_component"
)]
site[, site_geography_status := fcase(
  n_ready_components > 0L, "has_ready_query",
  default = "no_ready_query"
)]

development_site <- site[, .(
  n_source_sites = .N,
  n_sites_with_ready_query = sum(site_geography_status == "has_ready_query"),
  n_sites_without_ready_query = sum(site_geography_status == "no_ready_query"),
  n_address_components = sum(n_components),
  n_ready_address_components = sum(n_ready_components),
  n_blocked_address_components = sum(n_blocked_components),
  root_site_blocker = fcase(
    any(root_component_blocker == "other_address_or_source_issue"), "other_address_or_source_issue",
    any(root_component_blocker == "unresolved_range_address"), "unresolved_range_address",
    any(root_component_blocker == "unresolved_compound_address"), "unresolved_compound_address",
    any(root_component_blocker == "nonphysical_range_description"), "nonphysical_range_description",
    any(root_component_blocker == "baseline_address_issue"), "baseline_address_issue",
    any(root_component_blocker == "no_address_component"), "no_address_component",
    default = "no_blocker"
  )
), by = development_id]

development[development_site, `:=`(
  n_source_sites = i.n_source_sites,
  n_sites_with_ready_query = i.n_sites_with_ready_query,
  n_sites_without_ready_query = i.n_sites_without_ready_query,
  n_address_components = i.n_address_components,
  n_ready_address_components = i.n_ready_address_components,
  n_blocked_address_components = i.n_blocked_address_components,
  root_site_blocker = i.root_site_blocker
), on = "development_id"]
development[is.na(n_source_sites), `:=`(
  n_source_sites = 0L,
  n_sites_with_ready_query = 0L,
  n_sites_without_ready_query = 0L,
  n_address_components = 0L,
  n_ready_address_components = 0L,
  n_blocked_address_components = 0L,
  root_site_blocker = "no_source_site"
)]
development[, development_geography_status := fcase(
  n_sites_with_ready_query > 0L, "has_ready_query",
  n_source_sites == 0L, "no_source_site",
  default = "sites_but_no_ready_query"
)]
development[, `:=`(
  unit_size_group = cut(
    n_units_development,
    breaks = c(-Inf, 24, 49, 99, 199, Inf),
    labels = c("1_24", "25_49", "50_99", "100_199", "200_plus"),
    right = TRUE
  ),
  multisite_group = fcase(
    n_source_sites == 0L, "no_source_site",
    n_source_sites == 1L, "one_site",
    default = "multiple_sites"
  ),
  placed_in_service_group = fcase(
    is.na(first_pis_year), "missing",
    first_pis_year <= 1994L, "before_1995",
    first_pis_year <= 2004L, "1995_2004",
    first_pis_year <= 2014L, "2005_2014",
    default = "2015_plus"
  )
)]

if (uniqueN(query, by = "geocoding_query_id") != nrow(query) ||
    any(query$submission_approval != "not_approved") ||
    development[development_geography_status == "has_ready_query", .N] != 44621L ||
    development[development_geography_status == "sites_but_no_ready_query", .N] != 8051L ||
    development[development_geography_status == "no_source_site", .N] != 797L ||
    site[site_geography_status == "has_ready_query", .N] != 86419L ||
    component[crosswalk_query_status == "ready_for_local_geocoding_pilot", .N] != 89809L) {
  stop("The geography attrition flow contract failed.", call. = FALSE)
}

flow <- rbindlist(list(
  data.table(level = "development", measure = "all", group = "all", n = nrow(development)),
  development[, .(n = .N), by = .(group = development_geography_status)][, `:=`(level = "development", measure = "geography_status")],
  data.table(level = "site", measure = "all", group = "all", n = nrow(site)),
  site[, .(n = .N), by = .(group = site_geography_status)][, `:=`(level = "site", measure = "geography_status")],
  data.table(level = "address_component", measure = "all", group = "all", n = nrow(component)),
  component[, .(n = .N), by = .(group = crosswalk_query_status)][, `:=`(level = "address_component", measure = "query_status")],
  data.table(level = "query", measure = "ready_unique_query", group = "all", n = nrow(query)),
  data.table(level = "query", measure = "unique_development_with_ready_query", group = "all", n = uniqueN(query$development_id)),
  query[, .(n = .N), by = .(group = submission_approval)][, `:=`(level = "query", measure = "submission_approval")]
), use.names = TRUE, fill = TRUE)

blockers <- development[development_geography_status != "has_ready_query",
  .(n = .N), by = .(group = root_site_blocker)]
blockers[, `:=`(level = "development", measure = "root_blocker")]

by_development_group <- function(column) {
  development[, .(
    n_developments = .N,
    n_with_ready_query = sum(development_geography_status == "has_ready_query"),
    share_with_ready_query = mean(development_geography_status == "has_ready_query"),
    mean_units = mean(n_units_development, na.rm = TRUE),
    median_units = median(n_units_development, na.rm = TRUE),
    share_multisite = mean(multisite_group == "multiple_sites")
  ), by = column]
}

state <- by_development_group("development_state")
setnames(state, "development_state", "group")
state[, `:=`(level = "development", measure = "by_state")]
year <- by_development_group("placed_in_service_group")
setnames(year, "placed_in_service_group", "group")
year[, `:=`(level = "development", measure = "by_pis_group")]
units <- by_development_group("unit_size_group")
setnames(units, "unit_size_group", "group")
units[, `:=`(level = "development", measure = "by_unit_size")]
multisite <- by_development_group("multisite_group")
setnames(multisite, "multisite_group", "group")
multisite[, `:=`(level = "development", measure = "by_multisite")]

comparability <- development[, .(
  n_developments = .N,
  mean_units = mean(n_units_development, na.rm = TRUE),
  median_units = median(n_units_development, na.rm = TRUE),
  mean_first_pis_year = mean(first_pis_year, na.rm = TRUE),
  share_multisite = mean(multisite_group == "multiple_sites"),
  share_unit_analysis_eligible = mean(downstream_unit_analysis_eligible),
  share_low_income_share_analysis_eligible =
    mean(low_income_share_analysis_eligible)
), by = .(group = development_geography_status)]
comparability[, `:=`(level = "development", measure = "included_blocked_comparability")]

audit <- rbindlist(list(flow, blockers, state, year, units, multisite, comparability),
  use.names = TRUE, fill = TRUE)
audit[, `:=`(
  n = as.integer(n),
  n_developments = as.integer(n_developments),
  n_with_ready_query = as.integer(n_with_ready_query),
  n_units = as.integer(NA)
)]
setcolorder(audit, c(
  "level", "measure", "group", "n", "n_developments", "n_with_ready_query",
  "share_with_ready_query", "mean_units", "median_units", "mean_first_pis_year",
  "share_multisite", "share_unit_analysis_eligible",
  "share_low_income_share_analysis_eligible", "n_units"
))
setorder(audit, level, measure, group)
write_parquet(audit, "../output/lihtc_geography_attrition.parquet", compression = "zstd")

summary_lines <- c(
  "# LIHTC geography attrition",
  "",
  "This audit is read-only. A ready query is an approved local string, not a geocode or tract assignment.",
  "",
  "## Non-overlapping flow",
  "",
  sprintf("- Developments: %s total; %s with at least one ready query; %s with sites but no ready query; %s with no source site.",
    format(nrow(development), big.mark = ","),
    format(development[development_geography_status == "has_ready_query", .N], big.mark = ","),
    format(development[development_geography_status == "sites_but_no_ready_query", .N], big.mark = ","),
    format(development[development_geography_status == "no_source_site", .N], big.mark = ",")),
  sprintf("- Sites: %s total; %s with a ready component query.", format(nrow(site), big.mark = ","), format(site[site_geography_status == "has_ready_query", .N], big.mark = ",")),
  sprintf("- Address components: %s total; %s ready; %s blocked or excluded.", format(nrow(component), big.mark = ","), format(component[crosswalk_query_status == "ready_for_local_geocoding_pilot", .N], big.mark = ","), format(component[crosswalk_query_status != "ready_for_local_geocoding_pilot", .N], big.mark = ",")),
  sprintf("- Unique development-scoped queries: %s. This task makes no submission; the separate pilot task samples 457 queries.", format(nrow(query), big.mark = ",")),
  "",
  "Root blockers use this mutually exclusive priority: other address/source issue, unresolved range, unresolved compound, nonphysical range description, baseline address issue, no address component, then no source site.",
  "",
  "The Parquet output contains the full flow, root blockers, state/year/unit-size/multisite coverage, and included-versus-blocked comparison rows."
)
writeLines(summary_lines, "../output/geography_attrition_summary.md")

if (!identical(audit, as.data.table(read_parquet("../output/lihtc_geography_attrition.parquet")))) {
  stop("The geography attrition Parquet changed on round trip.", call. = FALSE)
}
