# setwd("tasks/audits/audit_lihtc_identical_address_sets/code")

library(arrow)
library(data.table)

valid_states <- c(state.abb, "DC")

development <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_address_round2_adjudicated.parquet"
))
site <- as.data.table(read_parquet(
  "../input/lihtc_development_site_2024_address_round2_adjudicated.parquet"
))
prior_pairs <- as.data.table(read_parquet(
  "../input/lihtc_cross_development_pairs_round2_adjudicated.parquet"
))

if (uniqueN(development$development_id) != nrow(development) ||
    uniqueN(site$development_site_id) != nrow(site) ||
    uniqueN(prior_pairs, by = c(
      "development_id_1", "development_id_2"
    )) != nrow(prior_pairs)) {
  stop("An input key is not unique.", call. = FALSE)
}
if (anyNA(site$development_id) || anyNA(site$site_key) ||
    any(site$site_key == "")) {
  stop("A development site lacks a usable key.", call. = FALSE)
}

analysis_site <- site[site_state %chin% valid_states]
if (!all(analysis_site$development_id %chin% development$development_id)) {
  stop("A site does not map to a final development.", call. = FALSE)
}

development_sites <- unique(analysis_site[, .(
  development_id,
  site_key
)])
setorder(development_sites, development_id, site_key)

development_sets <- development_sites[, .(
  n_addresses = .N,
  complete_address_set_key = paste(site_key, collapse = "\u001F"),
  address_examples = paste(head(site_key, 3L), collapse = "; ")
), by = development_id]

set_scope <- development_sets[, .(
  n_developments = .N
), by = complete_address_set_key][n_developments > 1L]
setorder(set_scope, complete_address_set_key)
set_scope[, identical_address_set_id := sprintf("IAS%04d", .I)]

members <- merge(
  development_sets,
  set_scope,
  by = "complete_address_set_key",
  all = FALSE,
  sort = FALSE
)
members[development, `:=`(
  development_name = i.development_name,
  development_name_key = i.development_name_key,
  development_state = i.development_state,
  development_city = i.development_city,
  n_project_episodes = i.n_project_episodes,
  first_pis_year = i.first_pis_year,
  last_pis_year = i.last_pis_year,
  episode_unit_count_max = i.episode_unit_count_max,
  n_units_development = i.n_units_development,
  n_development_sites = i.n_development_sites
), on = "development_id"]
if (anyNA(members$development_name) ||
    uniqueN(members, by = c(
      "identical_address_set_id", "development_id"
    )) != nrow(members)) {
  stop("Identical-set members violate the development join.", call. = FALSE)
}

pairs <- members[, {
  pair_matrix <- t(combn(sort(development_id), 2L))
  .(
    development_id_1 = pair_matrix[, 1L],
    development_id_2 = pair_matrix[, 2L]
  )
}, by = .(
  identical_address_set_id,
  complete_address_set_key,
  n_addresses,
  n_developments
)]

pairs[prior_pairs, `:=`(
  pair_audit_class = i.pair_audit_class,
  development_name_1 = i.development_name_1,
  development_name_2 = i.development_name_2,
  first_pis_year_1 = i.first_pis_year_1,
  first_pis_year_2 = i.first_pis_year_2,
  episode_unit_count_max_1 = i.episode_unit_count_max_1,
  episode_unit_count_max_2 = i.episode_unit_count_max_2,
  name_edit_similarity = i.name_edit_similarity,
  name_token_jaccard = i.name_token_jaccard,
  high_name_similarity = i.high_name_similarity,
  phase_or_component_name_signal = i.phase_or_component_name_signal,
  first_pis_year_gap = i.first_pis_year_gap,
  equal_nonmissing_unit_max = i.equal_nonmissing_unit_max
), on = .(development_id_1, development_id_2)]
if (anyNA(pairs$pair_audit_class)) {
  stop("A current identical-set pair is absent from the prior audit.",
    call. = FALSE)
}

pairs[, current_pair_status := fcase(
  pair_audit_class == "unresolved_identical_complete_address_set",
  "unresolved",
  pair_audit_class %chin% c(
    "round1_reviewed_distinct", "round2_reviewed_distinct"
  ),
  "reviewed_distinct",
  default = "unexpected_prior_class"
)]
if (any(pairs$current_pair_status == "unexpected_prior_class")) {
  stop("A current identical set has an unexpected prior pair class.",
    call. = FALSE)
}

groups <- members[, {
  pis_years <- first_pis_year[!is.na(first_pis_year)]
  unit_counts <- n_units_development[
    !is.na(n_units_development)
  ]
  names_sorted <- sort(unique(development_name))
  cities_sorted <- sort(unique(development_city))
  .(
    n_developments = .N,
    n_addresses = first(n_addresses),
    development_states = paste(
      sort(unique(development_state)), collapse = "/"
    ),
    development_cities = paste(head(cities_sorted, 5L), collapse = " / "),
    n_development_names = length(names_sorted),
    development_name_examples = paste(
      head(names_sorted, 3L), collapse = " | "
    ),
    first_pis_year_min = if (length(pis_years)) {
      min(pis_years)
    } else {
      NA_integer_
    },
    first_pis_year_max = if (length(pis_years)) {
      max(pis_years)
    } else {
      NA_integer_
    },
    n_missing_first_pis_year = sum(is.na(first_pis_year)),
    unit_count_min = if (length(unit_counts)) {
      min(unit_counts)
    } else {
      NA_real_
    },
    unit_count_max = if (length(unit_counts)) {
      max(unit_counts)
    } else {
      NA_real_
    },
    n_missing_unit_count = sum(is.na(n_units_development)),
    address_examples = first(address_examples)
  )
}, by = .(
  identical_address_set_id,
  complete_address_set_key
)]
groups[, first_pis_year_span :=
  first_pis_year_max - first_pis_year_min]
groups[, `:=`(
  timing_complete = n_missing_first_pis_year == 0L,
  unit_counts_complete = n_missing_unit_count == 0L,
  all_unit_counts_equal =
    n_missing_unit_count == 0L & unit_count_min == unit_count_max
)]

pair_summary <- pairs[, .(
  n_pairs = .N,
  n_unresolved_pairs = sum(current_pair_status == "unresolved"),
  n_reviewed_distinct_pairs = sum(
    current_pair_status == "reviewed_distinct"
  ),
  maximum_name_edit_similarity = max(
    name_edit_similarity, na.rm = TRUE
  ),
  any_high_name_similarity = any(high_name_similarity),
  any_phase_or_component_name_signal = any(
    phase_or_component_name_signal
  )
), by = identical_address_set_id]
groups[pair_summary, `:=`(
  n_pairs = i.n_pairs,
  n_unresolved_pairs = i.n_unresolved_pairs,
  n_reviewed_distinct_pairs = i.n_reviewed_distinct_pairs,
  maximum_name_edit_similarity = i.maximum_name_edit_similarity,
  any_high_name_similarity = i.any_high_name_similarity,
  any_phase_or_component_name_signal =
    i.any_phase_or_component_name_signal
), on = "identical_address_set_id"]

groups[, group_review_status := fcase(
  n_unresolved_pairs == n_pairs,
  "all_unresolved",
  n_unresolved_pairs == 0L,
  "all_reviewed_distinct",
  default = "mixed"
)]
groups[, observable_signature := fcase(
  n_addresses == 1L,
  "one address only",
  n_developments >= 4L,
  "many records / one address list",
  !timing_complete | !unit_counts_complete,
  "missing timing or units",
  timing_complete & first_pis_year_span >= 11L &
    all_unit_counts_equal,
  "long gap / same units",
  timing_complete & first_pis_year_span <= 2L &
    all_unit_counts_equal,
  "near timing / same units",
  timing_complete & first_pis_year_span <= 2L &
    unit_counts_complete & !all_unit_counts_equal,
  "near timing / different units",
  timing_complete & first_pis_year_span >= 3L &
    first_pis_year_span <= 10L,
  "medium timing gap",
  default = "other timing / unit pattern"
)]

focus_groups <- groups[
  n_addresses > 1L & n_unresolved_pairs > 0L
]
signature_summary <- focus_groups[, .(
  groups = .N,
  development_records = sum(n_developments),
  median_addresses = median(n_addresses),
  name_similar_groups = sum(any_high_name_similarity),
  phase_signal_groups = sum(any_phase_or_component_name_signal)
), by = observable_signature][order(-groups, observable_signature)]

example_groups <- focus_groups[
  order(observable_signature, -n_addresses, identical_address_set_id),
  head(.SD, 2L),
  by = observable_signature
]

current_pair_keys <- pairs[, .(
  development_id_1,
  development_id_2
)]
inherited_exact_not_current <- prior_pairs[
  pair_audit_class == "unresolved_identical_complete_address_set"
][!current_pair_keys, on = .(
  development_id_1,
  development_id_2
)]

setorder(groups, identical_address_set_id)
setorder(members, identical_address_set_id, development_id)
setorder(pairs, identical_address_set_id, development_id_1, development_id_2)

write_parquet(
  groups,
  "../output/lihtc_identical_address_set_groups.parquet"
)
write_parquet(
  members,
  "../output/lihtc_identical_address_set_members.parquet"
)
write_parquet(
  pairs,
  "../output/lihtc_identical_address_set_pairs.parquet"
)

format_count <- function(x) {
  format(x, big.mark = ",", scientific = FALSE, trim = TRUE)
}

scope_summary <- groups[, .(
  groups = .N,
  development_records = sum(n_developments),
  development_pairs = sum(n_pairs)
), by = .(
  address_scope = fifelse(
    n_addresses == 1L, "One address", "Multiple addresses"
  )
)][order(address_scope)]

summary_lines <- c(
  "# LIHTC Identical Complete Address-Set Audit",
  "",
  "## Scope",
  "",
  paste0(
    "This audit recomputes complete standardized address sets from the current ",
    "round-two development-site file. It includes the 50 states and DC only. ",
    "It does not change a linkage decision or approve a geocoding query."
  ),
  "",
  sprintf(
    "- Current identical address-set groups: %s.",
    format_count(nrow(groups))
  ),
  sprintf(
    "- Development records in those groups: %s.",
    format_count(nrow(members))
  ),
  sprintf(
    "- Development pairs in those groups: %s.",
    format_count(nrow(pairs))
  ),
  sprintf(
    "- Site rows excluded because they are outside the 50 states and DC: %s.",
    format_count(nrow(site) - nrow(analysis_site))
  ),
  "",
  "| Complete address-list size | Groups | Development records | Pairs |",
  "| --- | ---: | ---: | ---: |",
  sprintf(
    "| %s | %s | %s | %s |",
    scope_summary$address_scope,
    format_count(scope_summary$groups),
    format_count(scope_summary$development_records),
    format_count(scope_summary$development_pairs)
  ),
  "",
  "## Current versus inherited labels",
  "",
  sprintf(
    paste0(
      "The earlier pair audit contains %s pairs with the inherited label ",
      "`unresolved_identical_complete_address_set`. Recomputing the complete ",
      "sets after round-two merges finds %s current exact-set pairs: %s remain ",
      "unresolved, %s were reviewed as distinct, and %s inherited-label pairs ",
      "are no longer current exact-set matches."
    ),
    format_count(prior_pairs[
      pair_audit_class == "unresolved_identical_complete_address_set", .N
    ]),
    format_count(nrow(pairs)),
    format_count(pairs[current_pair_status == "unresolved", .N]),
    format_count(pairs[current_pair_status == "reviewed_distinct", .N]),
    format_count(nrow(inherited_exact_not_current))
  ),
  "",
  "The current complete-set calculation, rather than the inherited label, is the appropriate scope for this review.",
  "",
  "## Unresolved multi-address groups",
  "",
  sprintf(
    paste0(
      "There are %s unresolved groups in which multiple development records ",
      "carry the same list of two or more addresses. The labels below describe ",
      "observed timing and unit-count patterns; they are not identity decisions."
    ),
    format_count(nrow(focus_groups))
  ),
  "",
  "| Observable signature | Groups | Development records | Median addresses | High-name-similarity groups | Phase-signal groups |",
  "| --- | ---: | ---: | ---: | ---: | ---: |",
  sprintf(
    "| %s | %s | %s | %s | %s | %s |",
    signature_summary$observable_signature,
    format_count(signature_summary$groups),
    format_count(signature_summary$development_records),
    format_count(signature_summary$median_addresses),
    format_count(signature_summary$name_similar_groups),
    format_count(signature_summary$phase_signal_groups)
  ),
  "",
  "## Representative records",
  "",
  "These examples are selected mechanically: the two largest address lists in each observable signature.",
  "",
  "| Signature | State | Addresses | Records | First-year span | Development-unit range | Name examples |",
  "| --- | --- | ---: | ---: | ---: | ---: | --- |",
  sprintf(
    "| %s | %s | %s | %s | %s | %s | %s |",
    example_groups$observable_signature,
    example_groups$development_states,
    format_count(example_groups$n_addresses),
    format_count(example_groups$n_developments),
    ifelse(
      is.na(example_groups$first_pis_year_span),
      "NA",
      ifelse(
        example_groups$timing_complete,
        format_count(example_groups$first_pis_year_span),
        paste0(
          format_count(example_groups$first_pis_year_span),
          " (incomplete)"
        )
      )
    ),
    ifelse(
      is.na(example_groups$unit_count_min),
      "NA",
      paste0(
        format_count(example_groups$unit_count_min),
        "-",
        format_count(example_groups$unit_count_max),
        ifelse(example_groups$unit_counts_complete, "", " (incomplete)")
      )
    ),
    gsub("\\|", "/", example_groups$development_name_examples)
  ),
  "",
  "## Interpretation boundary",
  "",
  paste0(
    "An identical address list is evidence about how HUD represented the records, ",
    "not by itself evidence that the records are one physical development. A ",
    "near-timing, same-unit pair may be an alternate label or duplicate; a ",
    "long-gap, same-unit pair may be a later financing episode; a many-record ",
    "group may reflect a portfolio-wide address list copied across distinct ",
    "properties. Each interpretation still requires record-level review and, ",
    "before adjudication, outside evidence."
  )
)
writeLines(summary_lines, "../output/audit_summary.md")

groups_check <- as.data.table(read_parquet(
  "../output/lihtc_identical_address_set_groups.parquet"
))
members_check <- as.data.table(read_parquet(
  "../output/lihtc_identical_address_set_members.parquet"
))
pairs_check <- as.data.table(read_parquet(
  "../output/lihtc_identical_address_set_pairs.parquet"
))
if (nrow(groups_check) != nrow(groups) ||
    nrow(members_check) != nrow(members) ||
    nrow(pairs_check) != nrow(pairs) ||
    uniqueN(groups_check$identical_address_set_id) != nrow(groups_check) ||
    uniqueN(members_check, by = c(
      "identical_address_set_id", "development_id"
    )) != nrow(members_check) ||
    uniqueN(pairs_check, by = c(
      "development_id_1", "development_id_2"
    )) != nrow(pairs_check)) {
  stop("An identical-set output failed its Parquet round trip.",
    call. = FALSE)
}
