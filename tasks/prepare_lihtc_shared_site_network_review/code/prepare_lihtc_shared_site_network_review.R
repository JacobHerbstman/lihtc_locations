# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/prepare_lihtc_shared_site_network_review/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
})

development <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_low_income_share_adjudicated.parquet"
))
episode <- as.data.table(read_parquet(
  "../input/lihtc_project_episode_2024_low_income_share_adjudicated.parquet"
))
site <- as.data.table(read_parquet(
  "../input/lihtc_development_site_2024_low_income_share_adjudicated.parquet"
))

if (nrow(development) != 53469L || nrow(episode) != 54902L ||
    nrow(site) != 131473L ||
    uniqueN(development$development_id) != nrow(development) ||
    uniqueN(episode$hud_id) != nrow(episode) ||
    uniqueN(site$development_site_id) != nrow(site) ||
    uniqueN(site, by = c("development_id", "site_key")) != nrow(site) ||
    anyNA(site$site_key) || any(site$site_key == "")) {
  stop("The final LIHTC inputs do not satisfy the shared-site contract.",
    call. = FALSE)
}

shared_site <- site[, .(
  n_developments_at_site = uniqueN(development_id),
  n_site_rows_at_site = .N
), by = site_key][n_developments_at_site > 1L]
setorder(shared_site, site_key)
shared_membership <- site[shared_site, on = "site_key", nomatch = 0L]
setorder(shared_membership, site_key, development_id)

if (nrow(shared_site) != 4284L || nrow(shared_membership) != 10034L ||
    uniqueN(shared_membership$development_id) != 5971L ||
    any(shared_membership[, .N, by = .(development_id, site_key)]$N != 1L)) {
  stop("The final shared-site counts or keys changed.", call. = FALSE)
}

network_development_ids <- sort(unique(shared_membership$development_id))
parent <- seq_along(network_development_ids)
names(parent) <- network_development_ids

find_root <- function(node) {
  root <- node
  while (parent[[root]] != root) {
    root <- parent[[root]]
  }
  while (parent[[node]] != node) {
    next_node <- parent[[node]]
    parent[[node]] <<- root
    node <- next_node
  }
  root
}

union_nodes <- function(first_node, second_node) {
  first_root <- find_root(first_node)
  second_root <- find_root(second_node)
  if (first_root != second_root) {
    parent[[second_root]] <<- first_root
  }
}

site_developments <- shared_membership[, .(
  development_ids = list(sort(development_id))
), by = site_key]
setorder(site_developments, site_key)
for (row in seq_len(nrow(site_developments))) {
  member_ids <- site_developments$development_ids[[row]]
  if (length(member_ids) > 1L) {
    for (member_id in member_ids[-1L]) {
      union_nodes(member_ids[1L], member_id)
    }
  }
}

network_map <- data.table(development_id = network_development_ids)
network_map[, network_root := vapply(
  development_id,
  find_root,
  integer(1L)
)]
network_map[shared_membership[, .(
  minimum_shared_site_key = min(site_key)
), by = development_id], minimum_shared_site_key :=
  i.minimum_shared_site_key, on = "development_id"]
component_keys <- network_map[, .(
  minimum_shared_site_key = min(minimum_shared_site_key)
), by = network_root]
setorder(component_keys, minimum_shared_site_key, network_root)
component_keys[, shared_site_network_id := sprintf("SSN_%06d", .I)]
network_map[component_keys, shared_site_network_id :=
  i.shared_site_network_id, on = "network_root"]
network_map[, c("network_root", "minimum_shared_site_key") := NULL]

if (uniqueN(network_map$shared_site_network_id) != 2160L) {
  stop("The shared-site connected-component count changed.", call. = FALSE)
}

shared_membership[network_map, shared_site_network_id :=
  i.shared_site_network_id, on = "development_id"]
if (anyNA(shared_membership$shared_site_network_id)) {
  stop("A shared-site row was not assigned to a network.", call. = FALSE)
}

network_site <- shared_membership[, .(
  n_developments_at_site = uniqueN(development_id),
  n_site_rows_at_site = .N,
  n_project_primary_rows = sum(site_source == "project_primary"),
  n_multi_address_rows = sum(site_source == "multi_address"),
  n_other_source_rows = sum(!site_source %chin% c("project_primary", "multi_address")),
  n_street_variants = uniqueN(site_street),
  n_city_variants = uniqueN(paste(site_state, site_city, sep = ":")),
  n_zip_variants = uniqueN(site_zip, na.rm = TRUE),
  site_street_examples = paste(head(sort(unique(site_street)), 3L), collapse = "|"),
  site_city_examples = paste(head(sort(unique(paste(
    site_state, site_city, sep = ":"
  ))), 3L), collapse = "|"),
  site_zip_examples = paste(head(sort(unique(site_zip[!is.na(site_zip)])), 3L),
    collapse = "|"),
  any_requires_site_review = any(requires_site_review),
  any_source_site_unresolved = any(source_site_unresolved_status != "none")
), by = .(shared_site_network_id, site_key)]
setorder(network_site, site_key)
network_site[, shared_site_key_question_id := sprintf("SSKQ_%06d", .I)]
network_site[, `:=`(
  site_key_priority_rank = fcase(
    n_developments_at_site >= 4L, 1L,
    n_multi_address_rows > 0L, 2L,
    default = 3L
  ),
  site_key_priority_stratum = fcase(
    n_developments_at_site >= 4L, "four_or_more_developments_at_exact_site_key",
    n_multi_address_rows > 0L, "shared_site_key_involves_multi_address_source",
    default = "shared_site_key_primary_or_other_source_only"
  ),
  site_key_review_status = "not_adjudicated",
  shared_geocoding_query_decision = "not_approved"
)]
network <- network_site[, .(
  n_shared_site_keys = .N,
  n_shared_site_rows = sum(n_site_rows_at_site),
  max_developments_at_one_site = max(n_developments_at_site)
), by = shared_site_network_id]
network[network_map[, .(
  shared_site_network_id,
  n_developments = .N
), by = shared_site_network_id], n_developments := i.n_developments,
on = "shared_site_network_id"]
network[shared_membership[, .(
  n_network_states = uniqueN(site_state),
  n_network_cities = uniqueN(paste(site_state, site_city, sep = ":")),
  network_states = paste(sort(unique(site_state)), collapse = "|"),
  network_city_examples = paste(head(sort(unique(paste(
    site_state, site_city, sep = ":"
  ))), 3L), collapse = "|")
), by = shared_site_network_id], `:=`(
  n_network_states = i.n_network_states,
  n_network_cities = i.n_network_cities,
  network_states = i.network_states,
  network_city_examples = i.network_city_examples
), on = "shared_site_network_id"]
network[, `:=`(
  priority_rank = fcase(
    n_developments >= 8L & n_shared_site_keys >= 10L, 1L,
    n_developments >= 5L | n_shared_site_keys >= 10L, 2L,
    default = 3L
  ),
  priority_stratum = fcase(
    n_developments >= 8L & n_shared_site_keys >= 10L,
    "repeated_address_set_network",
    n_developments >= 5L | n_shared_site_keys >= 10L,
    "large_shared_site_network",
    default = "small_shared_site_network"
  ),
  review_status = "not_adjudicated",
  shared_geocoding_query_decision = "not_approved"
)]
setorder(network, priority_rank, -n_shared_site_keys, -n_developments,
  shared_site_network_id)

development_member <- unique(shared_membership[, .(
  shared_site_network_id,
  development_id
)])
development_member[development, `:=`(
  development_name = i.development_name,
  development_state = i.development_state,
  development_city = i.development_city,
  n_project_episodes = i.n_project_episodes,
  n_development_sites = i.n_development_sites,
  n_units_development = i.n_units_development,
  li_units_development = i.li_units_development,
  first_pis_year = i.first_pis_year,
  last_pis_year = i.last_pis_year,
  development_linkage_status = i.development_linkage_status,
  source_site_review_scope = i.source_site_review_scope,
  source_site_unresolved_status = i.source_site_unresolved_status,
  singleton_identity_scope_action = i.singleton_identity_scope_action,
  singleton_identity_development_scope_status =
    i.singleton_identity_development_scope_status,
  unit_scope_review_status = i.unit_scope_review_status,
  low_income_share_analysis_status = i.low_income_share_analysis_status
), on = "development_id"]
development_member[network, `:=`(
  priority_rank = i.priority_rank,
  priority_stratum = i.priority_stratum,
  review_status = i.review_status,
  shared_geocoding_query_decision = i.shared_geocoding_query_decision
), on = "shared_site_network_id"]

site_member <- shared_membership[, .(
  shared_site_network_id,
  development_site_id,
  development_id,
  site_key,
  site_street,
  site_city,
  site_state,
  site_zip,
  site_source,
  hud_ids,
  n_project_episodes,
  n_bin_values,
  n_coordinate_pairs,
  latitude,
  longitude,
  requires_site_review,
  source_site_review_scope,
  source_site_unresolved_status,
  singleton_identity_scope_action,
  singleton_identity_scope_site_action,
  singleton_identity_development_scope_status
)]
site_member[shared_site, `:=`(
  n_developments_at_site = i.n_developments_at_site,
  n_site_rows_at_site = i.n_site_rows_at_site
), on = "site_key"]
site_member[network, `:=`(
  priority_rank = i.priority_rank,
  priority_stratum = i.priority_stratum,
  review_status = i.review_status,
  shared_geocoding_query_decision = i.shared_geocoding_query_decision
), on = "shared_site_network_id"]

all_site_member <- site[development_id %chin% network_map$development_id]
all_site_member[network_map, shared_site_network_id :=
  i.shared_site_network_id, on = "development_id"]
all_site_member[shared_site, is_shared_site_key := TRUE, on = "site_key"]
all_site_member[is.na(is_shared_site_key), is_shared_site_key := FALSE]
all_site_member[network, `:=`(
  priority_rank = i.priority_rank,
  priority_stratum = i.priority_stratum,
  review_status = i.review_status,
  shared_geocoding_query_decision = i.shared_geocoding_query_decision
), on = "shared_site_network_id"]

episode_member <- episode[development_id %chin% network_map$development_id]
episode_member[network_map, `:=`(
  shared_site_network_id = i.shared_site_network_id,
  priority_rank = NA_integer_,
  priority_stratum = NA_character_,
  review_status = NA_character_,
  shared_geocoding_query_decision = NA_character_
), on = "development_id"]
episode_member[network, `:=`(
  priority_rank = i.priority_rank,
  priority_stratum = i.priority_stratum,
  review_status = i.review_status,
  shared_geocoding_query_decision = i.shared_geocoding_query_decision
), on = "shared_site_network_id"]

if (nrow(network) != 2160L || nrow(development_member) != 5971L ||
    nrow(network_site) != 4284L || nrow(site_member) != 10034L ||
    nrow(all_site_member) != 28511L ||
    nrow(episode_member) != 6264L ||
    uniqueN(development_member, by = c(
      "shared_site_network_id", "development_id"
    )) != nrow(development_member) ||
    uniqueN(site_member$development_site_id) != nrow(site_member) ||
    uniqueN(network_site$site_key) != nrow(network_site) ||
    uniqueN(network_site$shared_site_key_question_id) != nrow(network_site) ||
    uniqueN(all_site_member$development_site_id) != nrow(all_site_member) ||
    uniqueN(episode_member$hud_id) != nrow(episode_member) ||
    all_site_member[is_shared_site_key == TRUE, .N] != 10034L ||
    any(!site_member$development_site_id %chin%
      all_site_member$development_site_id) ||
    any(!episode_member$development_id %chin%
      development_member$development_id) ||
    anyNA(development_member$development_name) ||
    anyNA(site_member$priority_stratum) ||
    anyNA(all_site_member$priority_stratum) ||
    anyNA(episode_member$priority_stratum) ||
    any(network_site$site_key_review_status != "not_adjudicated") ||
    any(network_site$shared_geocoding_query_decision != "not_approved") ||
    !setequal(network_site$site_key, site_member$site_key) ||
    network_site[, sum(n_site_rows_at_site)] != nrow(site_member) ||
    any(network$shared_geocoding_query_decision != "not_approved")) {
  stop("The shared-site review outputs are incomplete or not one-to-one.",
    call. = FALSE)
}

write_parquet(network,
  "../output/lihtc_shared_site_network_questions.parquet",
  compression = "zstd"
)
write_parquet(network_site,
  "../output/lihtc_shared_site_network_site_key_questions.parquet",
  compression = "zstd"
)
write_parquet(development_member,
  "../output/lihtc_shared_site_network_development_members.parquet",
  compression = "zstd"
)
write_parquet(site_member,
  "../output/lihtc_shared_site_network_site_members.parquet",
  compression = "zstd"
)
write_parquet(all_site_member,
  "../output/lihtc_shared_site_network_all_site_members.parquet",
  compression = "zstd"
)
write_parquet(episode_member,
  "../output/lihtc_shared_site_network_episode_members.parquet",
  compression = "zstd"
)

summary_lines <- c(
  "# LIHTC Shared-Site Network Review Preparation",
  "",
  "This task prepares connected components of final developments linked by an exact standardized site key.",
  "It makes no identity, site, or geocoding decision.",
  "",
  sprintf("- Shared standardized site keys: %s.",
    format(nrow(shared_site), big.mark = ",")),
  sprintf("- Exact site-key review questions: %s.",
    format(nrow(network_site), big.mark = ",")),
  sprintf("- Shared final site rows: %s.",
    format(nrow(shared_membership), big.mark = ",")),
  sprintf("- Development members: %s.",
    format(nrow(development_member), big.mark = ",")),
  sprintf("- All final site rows for network developments: %s (%s shared-key rows).",
    format(nrow(all_site_member), big.mark = ","),
    format(all_site_member[is_shared_site_key == TRUE, .N], big.mark = ",")),
  sprintf("- Final project episodes for network developments: %s.",
    format(nrow(episode_member), big.mark = ",")),
  sprintf("- Connected review networks: %s.",
    format(nrow(network), big.mark = ",")),
  "",
  "Every prepared network has `review_status = not_adjudicated` and `shared_geocoding_query_decision = not_approved`."
)
writeLines(summary_lines, "../output/preparation_summary.md")

if (!identical(network, as.data.table(read_parquet(
      "../output/lihtc_shared_site_network_questions.parquet"
    ))) ||
    !identical(network_site, as.data.table(read_parquet(
      "../output/lihtc_shared_site_network_site_key_questions.parquet"
    ))) ||
    !identical(development_member, as.data.table(read_parquet(
      "../output/lihtc_shared_site_network_development_members.parquet"
    ))) ||
    !identical(site_member, as.data.table(read_parquet(
      "../output/lihtc_shared_site_network_site_members.parquet"
    ))) ||
    !identical(all_site_member, as.data.table(read_parquet(
      "../output/lihtc_shared_site_network_all_site_members.parquet"
    ))) ||
    !identical(episode_member, as.data.table(read_parquet(
      "../output/lihtc_shared_site_network_episode_members.parquet"
    )))) {
  stop("A shared-site review output changed on Parquet round trip.",
    call. = FALSE)
}
