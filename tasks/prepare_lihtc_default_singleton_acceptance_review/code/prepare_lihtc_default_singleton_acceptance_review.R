# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/prepare_lihtc_default_singleton_acceptance_review/code")

suppressPackageStartupMessages({ library(arrow); library(data.table) })

routing <- as.data.table(read_parquet("../input/lihtc_acceptance_review_routing.parquet"))
development <- as.data.table(read_parquet("../input/lihtc_development_2024_low_income_share_adjudicated.parquet"))
episode <- as.data.table(read_parquet("../input/lihtc_project_episode_2024_low_income_share_adjudicated.parquet"))
site <- as.data.table(read_parquet("../input/lihtc_development_site_2024_low_income_share_adjudicated.parquet"))

if (nrow(routing) != 53469L || nrow(development) != 53469L ||
    nrow(episode) != 54902L || nrow(site) != 131473L ||
    uniqueN(routing$development_id) != nrow(routing) ||
    uniqueN(development$development_id) != nrow(development) ||
    uniqueN(episode$hud_id) != nrow(episode) ||
    uniqueN(site$development_site_id) != nrow(site) ||
    uniqueN(site, by = c("development_id", "site_key")) != nrow(site) ||
    !setequal(routing$development_id, development$development_id) ||
    any(!episode$development_id %chin% development$development_id) ||
    any(!site$development_id %chin% development$development_id)) {
  stop("A canonical-routing or final-input key contract failed.", call. = FALSE)
}

default_routes <- c(
  "default_singleton_one_primary_site",
  "default_singleton_one_nonprimary_site",
  "default_singleton_multisite"
)
expected_route_counts <- data.table(
  routing_status = c(
    "site_exception_or_flag", "no_retained_site", "shared_site_network",
    "explicit_identity_review_nonblocked", default_routes
  ),
  N = c(211L, 797L, 5928L, 913L, 28701L, 9214L, 7705L)
)
actual_route_counts <- routing[, .N, by = routing_status]
setorder(expected_route_counts, routing_status)
setorder(actual_route_counts, routing_status)
if (!identical(actual_route_counts, expected_route_counts)) {
  stop("The full canonical routing partition changed.", call. = FALSE)
}
question <- copy(routing[routing_status %chin% default_routes])
if (nrow(question) != 45620L || uniqueN(question$development_id) != nrow(question) ||
    question[development_id == "DEV_MAB20191004", .N] != 1L ||
    question[development_id == "DEV_MAB20191004", routing_status] != "default_singleton_one_nonprimary_site") {
  stop("The canonical default-route universe changed or omitted Mechanic Mill.", call. = FALSE)
}
question[development, development_name_key := i.development_name_key, on = "development_id"]
if (anyNA(question$development_name_key)) stop("A routed default development lacks its normalized name key.", call. = FALSE)

development[routing, routing_status := i.routing_status, on = "development_id"]
if (anyNA(development$routing_status)) stop("A final development lacks its canonical route.", call. = FALSE)

full_site_summary <- site[, .(
  site_set = paste(sort(site_key), collapse = " | "),
  n_sites_with_resolved_source_evidence = sum(source_site_review_scope == "reviewed_source_exception"),
  resolved_source_site_actions = paste(sort(unique(source_site_operative_action[source_site_review_scope == "reviewed_source_exception"])), collapse = " | "),
  resolved_source_site_status = paste(sort(unique(source_site_decision_status[source_site_review_scope == "reviewed_source_exception"])), collapse = " | ")
), by = development_id]
if (uniqueN(full_site_summary$development_id) != nrow(full_site_summary)) stop("Full site summary is not one row per development.", call. = FALSE)
question[full_site_summary, `:=`(
  site_set = i.site_set,
  n_sites_with_resolved_source_evidence = i.n_sites_with_resolved_source_evidence,
  resolved_source_site_actions = i.resolved_source_site_actions,
  resolved_source_site_status = i.resolved_source_site_status
), on = "development_id"]
question[is.na(n_sites_with_resolved_source_evidence), `:=`(
  n_sites_with_resolved_source_evidence = 0L,
  resolved_source_site_actions = NA_character_,
  resolved_source_site_status = NA_character_
)]
question[, resolved_site_evidence_status := fifelse(
  n_sites_with_resolved_source_evidence > 0L,
  "resolved_source_site_evidence_annotated",
  "no_resolved_source_site_evidence"
)]

name_group <- development[!is.na(development_name_key) & development_name_key != "", .(
  n_same_normalized_name_state = .N,
  n_nondefault_normalized_name_state = sum(!routing_status %chin% default_routes)
), by = .(development_name_key, development_state)]
if (uniqueN(name_group, by = c("development_name_key", "development_state")) != nrow(name_group)) stop("Full name-state groups are not unique.", call. = FALSE)
question[name_group, `:=`(
  n_same_normalized_name_state = i.n_same_normalized_name_state,
  n_nondefault_normalized_name_state = i.n_nondefault_normalized_name_state
), on = c("development_name_key", "development_state")]
question[is.na(n_same_normalized_name_state), n_same_normalized_name_state := 1L]
question[is.na(n_nondefault_normalized_name_state), n_nondefault_normalized_name_state := 0L]

state_id_normalized <- toupper(trimws(episode$state_id))
valid_state_id <- !is.na(state_id_normalized) & state_id_normalized != "" &
  !grepl("99-99|UNKNOWN|N/A|^9{6,}$", state_id_normalized)
episode_map <- unique(episode[valid_state_id,
  .(development_id, state_id_key = state_id_normalized[valid_state_id], proj_st = toupper(trimws(proj_st)))
])
if (uniqueN(episode_map, by = c("development_id", "state_id_key", "proj_st")) != nrow(episode_map)) {
  stop("State-ID map is not unique at its declared key.", call. = FALSE)
}
episode_map[routing, route_for_state_id := i.routing_status, on = "development_id"]
if (anyNA(episode_map$route_for_state_id)) stop("A state-ID member lacks its canonical route.", call. = FALSE)
state_id_group <- episode_map[, .(
  n_same_nonplaceholder_state_id = uniqueN(development_id),
  n_nondefault_nonplaceholder_state_id = uniqueN(development_id[!route_for_state_id %chin% default_routes])
), by = .(state_id_key, proj_st)]
episode_map[state_id_group, `:=`(
  n_same_nonplaceholder_state_id = i.n_same_nonplaceholder_state_id,
  n_nondefault_nonplaceholder_state_id = i.n_nondefault_nonplaceholder_state_id
), on = c("state_id_key", "proj_st")]
state_id_signal <- episode_map[development_id %chin% question$development_id, .(
  n_same_nonplaceholder_state_id = max(n_same_nonplaceholder_state_id),
  n_nondefault_nonplaceholder_state_id = max(n_nondefault_nonplaceholder_state_id)
), by = development_id]
if (uniqueN(state_id_signal$development_id) != nrow(state_id_signal)) stop("State-ID signal is not one row per development.", call. = FALSE)
question[state_id_signal, `:=`(
  n_same_nonplaceholder_state_id = i.n_same_nonplaceholder_state_id,
  n_nondefault_nonplaceholder_state_id = i.n_nondefault_nonplaceholder_state_id
), on = "development_id"]
question[is.na(n_same_nonplaceholder_state_id), `:=`(n_same_nonplaceholder_state_id = 1L, n_nondefault_nonplaceholder_state_id = 0L)]

primary_map <- unique(episode[!is.na(primary_site_key) & primary_site_key != "", .(development_id, primary_site_key)])
if (uniqueN(primary_map, by = c("development_id", "primary_site_key")) != nrow(primary_map)) {
  stop("Primary-address map is not unique at its declared key.", call. = FALSE)
}
primary_map[routing, route_for_primary_address := i.routing_status, on = "development_id"]
if (anyNA(primary_map$route_for_primary_address)) stop("A primary-address member lacks its canonical route.", call. = FALSE)
primary_group <- primary_map[, .(
  n_same_primary_address = uniqueN(development_id),
  n_nondefault_primary_address = uniqueN(development_id[!route_for_primary_address %chin% default_routes])
), by = primary_site_key]
primary_map[primary_group, `:=`(
  n_same_primary_address = i.n_same_primary_address,
  n_nondefault_primary_address = i.n_nondefault_primary_address
), on = "primary_site_key"]
primary_signal <- primary_map[development_id %chin% question$development_id, .(
  n_same_primary_address = max(n_same_primary_address),
  n_nondefault_primary_address = max(n_nondefault_primary_address)
), by = development_id]
if (uniqueN(primary_signal$development_id) != nrow(primary_signal)) stop("Primary-address signal is not one row per development.", call. = FALSE)
question[primary_signal, `:=`(
  n_same_primary_address = i.n_same_primary_address,
  n_nondefault_primary_address = i.n_nondefault_primary_address
), on = "development_id"]
question[is.na(n_same_primary_address), `:=`(n_same_primary_address = 1L, n_nondefault_primary_address = 0L)]

full_site_summary[routing, route_for_site_set := i.routing_status, on = "development_id"]
site_set_group <- full_site_summary[, .(
  n_identical_site_set = .N,
  n_nondefault_identical_site_set = sum(!route_for_site_set %chin% default_routes)
), by = site_set]
question[site_set_group, `:=`(
  n_identical_site_set = i.n_identical_site_set,
  n_nondefault_identical_site_set = i.n_nondefault_identical_site_set
), on = "site_set"]
site_map <- unique(site[, .(development_id, site_key)])
site_map[routing, route_for_site_key := i.routing_status, on = "development_id"]
site_key_group <- site_map[, .(
  n_developments_at_site_key = uniqueN(development_id),
  n_nondefault_at_site_key = uniqueN(development_id[!route_for_site_key %chin% default_routes])
), by = site_key]
site_map[site_key_group, `:=`(
  n_developments_at_site_key = i.n_developments_at_site_key,
  n_nondefault_at_site_key = i.n_nondefault_at_site_key
), on = "site_key"]
overlap <- site_map[development_id %chin% question$development_id, .(
  n_overlapping_sites = sum(n_developments_at_site_key > 1L),
  n_nondefault_overlapping_sites = sum(n_nondefault_at_site_key > 0L)
), by = development_id]
question[overlap, `:=`(
  n_overlapping_sites = i.n_overlapping_sites,
  n_nondefault_overlapping_sites = i.n_nondefault_overlapping_sites
), on = "development_id"]
question[is.na(n_overlapping_sites), `:=`(n_overlapping_sites = 0L, n_nondefault_overlapping_sites = 0L)]

episode_summary <- episode[development_id %chin% question$development_id, .(
  n_distinct_episode_total = uniqueN(episode_units, na.rm = TRUE),
  n_distinct_episode_low_income = uniqueN(episode_low_income_units, na.rm = TRUE),
  any_bad_units = any(!is.na(episode_units) & episode_units <= 0) |
    any(!is.na(episode_low_income_units) & episode_low_income_units < 0) |
    any(!is.na(episode_units) & !is.na(episode_low_income_units) & episode_low_income_units > episode_units),
  timing_span = if (all(is.na(pis_year))) NA_integer_ else max(pis_year, na.rm = TRUE) - min(pis_year, na.rm = TRUE),
  n_coordinate_pairs = uniqueN(paste(latitude, longitude, sep = ":"), na.rm = TRUE),
  n_primary_site_keys = uniqueN(primary_site_key, na.rm = TRUE)
), by = development_id]
question[episode_summary, `:=`(
  n_distinct_episode_total = i.n_distinct_episode_total,
  n_distinct_episode_low_income = i.n_distinct_episode_low_income,
  any_bad_units = i.any_bad_units,
  timing_span = i.timing_span,
  n_coordinate_pairs = i.n_coordinate_pairs,
  n_primary_site_keys = i.n_primary_site_keys
), on = "development_id"]
question[, `:=`(
  same_normalized_name_state = n_same_normalized_name_state > 1L,
  same_nonplaceholder_state_id = n_same_nonplaceholder_state_id > 1L,
  identical_site_set = n_identical_site_set > 1L,
  overlapping_site_sets = n_overlapping_sites > 0L,
  same_primary_address = n_same_primary_address > 1L,
  suspicious_multisite_source_topology = routing_status == "default_singleton_multisite",
  unit_or_timing_anomaly = any_bad_units |
    (!is.na(n_distinct_episode_total) & n_distinct_episode_total > 1L) |
    (!is.na(n_distinct_episode_low_income) & n_distinct_episode_low_income > 1L) |
    (!is.na(timing_span) & timing_span >= 15L),
  coordinate_address_conflict = !is.na(n_coordinate_pairs) & n_coordinate_pairs > 1L & n_primary_site_keys <= 1L
)]
question[, candidate_stratum := fcase(
  same_nonplaceholder_state_id, "same_nonplaceholder_state_id",
  same_normalized_name_state, "same_normalized_name_state",
  identical_site_set, "identical_site_set",
  overlapping_site_sets, "overlapping_site_sets",
  same_primary_address, "same_primary_address",
  suspicious_multisite_source_topology, "suspicious_multisite_source_topology",
  unit_or_timing_anomaly, "unit_or_timing_anomaly",
  coordinate_address_conflict, "coordinate_address_conflict",
  default = "no_negative_candidate_signal"
)]
diagnostic_counts <- data.table(
  diagnostic = c(
    "same_normalized_name_state", "same_nonplaceholder_state_id",
    "identical_site_set", "overlapping_site_sets", "same_primary_address",
    "suspicious_multisite_source_topology", "unit_or_timing_anomaly",
    "coordinate_address_conflict"
  ),
  n_flagged = c(
    sum(question$same_normalized_name_state), sum(question$same_nonplaceholder_state_id),
    sum(question$identical_site_set), sum(question$overlapping_site_sets),
    sum(question$same_primary_address), sum(question$suspicious_multisite_source_topology),
    sum(question$unit_or_timing_anomaly), sum(question$coordinate_address_conflict)
  ),
  n_with_nondefault_counterpart = c(
    sum(question$n_nondefault_normalized_name_state > 0L),
    sum(question$n_nondefault_nonplaceholder_state_id > 0L),
    sum(question$n_nondefault_identical_site_set > 0L),
    sum(question$n_nondefault_overlapping_sites > 0L),
    sum(question$n_nondefault_primary_address > 0L),
    NA_integer_, NA_integer_, NA_integer_
  )
)
question[, `:=`(
  review_decision = "not_adjudicated",
  reader_1_review_decision = "not_adjudicated",
  reader_2_review_decision = "not_adjudicated",
  disagreement_adjudication_decision = "not_adjudicated",
  geocoding_approval = "not_approved",
  escalation_status = "not_escalated",
  preparation_status = "prepared_for_independent_review_not_accepted"
)]

strata <- question[, .(
  n_developments = .N,
  n_one_primary = sum(routing_status == "default_singleton_one_primary_site"),
  n_one_nonprimary = sum(routing_status == "default_singleton_one_nonprimary_site"),
  n_multisite = sum(routing_status == "default_singleton_multisite")
), by = candidate_stratum][order(-n_developments, candidate_stratum)]
question[, mandatory_two_read_sample :=
  same_nonplaceholder_state_id | same_normalized_name_state | unit_or_timing_anomaly]
allocation <- question[, .(
  n_developments = .N,
  n_mandatory_raw_signal = sum(mandatory_two_read_sample)
), by = .(candidate_stratum, routing_status)]
allocation[, planned_random_n := 0L]
allocation[candidate_stratum == "suspicious_multisite_source_topology", planned_random_n := pmin(n_developments, 600L)]
allocation[candidate_stratum == "no_negative_candidate_signal", planned_random_n := floor(600 * n_developments / sum(n_developments)), by = candidate_stratum]
no_signal_remainder <- allocation[candidate_stratum == "no_negative_candidate_signal"]
no_signal_remainder[, allocation_remainder := 600 * n_developments / sum(n_developments) - planned_random_n]
setorder(no_signal_remainder, -allocation_remainder, routing_status)
no_signal_remainder[seq_len(600L - sum(planned_random_n)), planned_random_n := planned_random_n + 1L]
allocation[no_signal_remainder, planned_random_n := i.planned_random_n, on = c("candidate_stratum", "routing_status")]
question[allocation, planned_random_n := i.planned_random_n, on = c("candidate_stratum", "routing_status")]

setorder(question, candidate_stratum, routing_status, development_id)
set.seed(20260812L)
random_draw <- question[planned_random_n > 0L,
  .SD[sample.int(.N, unique(planned_random_n))],
  by = .(candidate_stratum, routing_status)
]
mandatory_ids <- question[mandatory_two_read_sample == TRUE, development_id]
topology_random_ids <- random_draw[candidate_stratum == "suspicious_multisite_source_topology", development_id]
no_signal_random_ids <- random_draw[candidate_stratum == "no_negative_candidate_signal", development_id]
sample_ids <- unique(c(mandatory_ids, topology_random_ids, no_signal_random_ids))
sample <- copy(question[development_id %chin% sample_ids])
sample[, `:=`(
  selected_mandatory_raw_signal = development_id %chin% mandatory_ids,
  selected_topology_random = development_id %chin% topology_random_ids,
  selected_no_signal_random = development_id %chin% no_signal_random_ids
)]
sample[, sample_selection_reason := fcase(
  selected_mandatory_raw_signal & selected_topology_random,
  "mandatory_raw_signal+multisite_topology_random",
  selected_mandatory_raw_signal, "mandatory_raw_signal",
  selected_topology_random, "multisite_topology_random",
  selected_no_signal_random, "no_signal_random"
)]
setorder(sample, candidate_stratum, routing_status, development_id)
sample[, sample_id := sprintf("DSA_%04d", .I)]
set.seed(20260813L); sample[, read_1_order := sample.int(.N)]
set.seed(20260814L); sample[, read_2_order := sample.int(.N)]
random_counts <- random_draw[, .(random_n = .N), by = .(candidate_stratum, routing_status)]
random_check <- merge(
  allocation[planned_random_n > 0L, .(candidate_stratum, routing_status, planned_random_n)],
  random_counts,
  by = c("candidate_stratum", "routing_status"), all = TRUE, sort = FALSE
)
sample_counts <- sample[, .(selected_unique_n = .N), by = .(candidate_stratum, routing_status)]
allocation[sample_counts, selected_unique_n := i.selected_unique_n, on = c("candidate_stratum", "routing_status")]
allocation[is.na(selected_unique_n), selected_unique_n := 0L]

route_counts <- question[, .N, by = routing_status]
route_counts[, route_index := match(routing_status, default_routes)]
setorder(route_counts, route_index)
message("Default routing counts: ", paste(route_counts$routing_status, route_counts$N, collapse = "; "),
  "; name-state signals=", sum(question$same_normalized_name_state),
  "; state-ID signals=", sum(question$same_nonplaceholder_state_id),
  "; exact-site-set signals=", sum(question$identical_site_set),
  "; overlap signals=", sum(question$overlapping_site_sets),
  "; primary-address signals=", sum(question$same_primary_address),
  "; mandatory raw signals=", length(mandatory_ids),
  "; mandatory-random overlaps=", sum(sample$selected_mandatory_raw_signal & sample$selected_topology_random),
  "; sample rows=", nrow(sample))
if (!identical(route_counts$routing_status, default_routes) ||
    !identical(route_counts$N, c(28701L, 9214L, 7705L)) ||
    sum(question$same_normalized_name_state) != 1680L ||
    sum(question$same_nonplaceholder_state_id) != 484L ||
    sum(question$n_nondefault_normalized_name_state > 0L) != 163L ||
    sum(question$n_nondefault_nonplaceholder_state_id > 0L) != 80L ||
    sum(question$identical_site_set) != 0L || sum(question$overlapping_site_sets) != 0L || sum(question$same_primary_address) != 0L ||
    !identical(setNames(strata$n_developments, strata$candidate_stratum)[c(
      "same_nonplaceholder_state_id", "same_normalized_name_state",
      "suspicious_multisite_source_topology", "unit_or_timing_anomaly",
      "no_negative_candidate_signal"
    )], c(
      same_nonplaceholder_state_id = 484L,
      same_normalized_name_state = 1616L,
      suspicious_multisite_source_topology = 7556L,
      unit_or_timing_anomaly = 3L,
      no_negative_candidate_signal = 35961L
    )) ||
    uniqueN(question$development_id) != nrow(question) ||
    uniqueN(sample$development_id) != nrow(sample) || any(!sample$development_id %chin% question$development_id) ||
    uniqueN(sample$sample_id) != nrow(sample) ||
    !identical(sort(sample$read_1_order), seq_len(nrow(sample))) ||
    !identical(sort(sample$read_2_order), seq_len(nrow(sample))) ||
    length(mandatory_ids) != 2105L ||
    length(topology_random_ids) != 600L || length(no_signal_random_ids) != 600L ||
    sum(sample$selected_mandatory_raw_signal & sample$selected_topology_random) != 0L ||
    nrow(sample) != 3305L ||
    sum(strata$n_developments) != nrow(question) || sum(allocation$planned_random_n) != 1200L ||
    uniqueN(strata$candidate_stratum) != nrow(strata) ||
    uniqueN(allocation, by = c("candidate_stratum", "routing_status")) != nrow(allocation) ||
    anyNA(random_check$planned_random_n) || anyNA(random_check$random_n) ||
    any(random_check$planned_random_n != random_check$random_n) ||
    sum(sample$selected_mandatory_raw_signal) != 2105L ||
    sum(sample$selected_topology_random) != 600L ||
    sum(sample$selected_no_signal_random) != 600L ||
    any(!question[mandatory_two_read_sample == TRUE, development_id] %chin% sample$development_id) ||
    anyNA(question$n_sites_with_resolved_source_evidence) ||
    any(question$acceptance_identity_evidence_status != "rule_based_singleton_not_individually_reviewed") ||
    any(question$acceptance_status != "not_accepted_dataset_frozen") ||
    any(question$review_decision != "not_adjudicated") || any(question$geocoding_approval != "not_approved") ||
    any(question$reader_1_review_decision != "not_adjudicated") ||
    any(question$reader_2_review_decision != "not_adjudicated") ||
    any(question$disagreement_adjudication_decision != "not_adjudicated") ||
    any(question$preparation_status != "prepared_for_independent_review_not_accepted") ||
    question[development_id == "DEV_CAA19880195", n_same_normalized_name_state] != 2L ||
    question[development_id == "DEV_CAA19880195", n_nondefault_normalized_name_state] != 1L ||
    development[development_id == "DEV_CAA19870085", routing_status] != "no_retained_site" ||
    question[development_id == "DEV_AKA20010010", n_same_nonplaceholder_state_id] != 2L ||
    question[development_id == "DEV_AKA20010010", n_nondefault_nonplaceholder_state_id] != 1L ||
    development[development_id == "DEV_AKA20010015", routing_status] != "explicit_identity_review_nonblocked" ||
    question[development_id == "DEV_MAB20191004", resolved_site_evidence_status] != "resolved_source_site_evidence_annotated" ||
    question[development_id == "DEV_MAB20191004", n_sites_with_resolved_source_evidence] != 1L ||
    !question[development_id == "DEV_GAA20090103", unit_or_timing_anomaly] ||
    !question[development_id == "DEV_GAA20090103", mandatory_two_read_sample] ||
    sample[development_id == "DEV_GAA20090103", .N] != 1L ||
    sample[development_id == "DEV_MAB20191004", .N] > 1L) {
  stop("A default-route partition, diagnostic, or preparation-only status contract failed.", call. = FALSE)
}

question_out <- question[, .(development_id, development_name, development_name_key, development_state, development_city,
  routing_status, n_retained_sites, n_project_primary_sites, n_retained_episodes,
  acceptance_identity_evidence_status, acceptance_site_evidence_status, acceptance_status,
  resolved_site_evidence_status, n_sites_with_resolved_source_evidence,
  resolved_source_site_actions, resolved_source_site_status, candidate_stratum,
  n_same_normalized_name_state, n_nondefault_normalized_name_state,
  n_same_nonplaceholder_state_id, n_nondefault_nonplaceholder_state_id,
  n_identical_site_set, n_nondefault_identical_site_set,
  n_overlapping_sites, n_nondefault_overlapping_sites,
  n_same_primary_address, n_nondefault_primary_address,
  same_normalized_name_state, same_nonplaceholder_state_id, identical_site_set,
  overlapping_site_sets, same_primary_address, suspicious_multisite_source_topology, unit_or_timing_anomaly,
  coordinate_address_conflict, mandatory_two_read_sample,
  review_decision, reader_1_review_decision,
  reader_2_review_decision, disagreement_adjudication_decision,
  geocoding_approval, escalation_status, preparation_status)]
setorder(question_out, routing_status, development_state, development_id)
sample_out <- question[sample, on = "development_id"][, .(sample_id, read_1_order, read_2_order,
  development_id, development_name, development_name_key, development_state, development_city,
  routing_status, candidate_stratum, resolved_site_evidence_status,
  selected_mandatory_raw_signal, selected_topology_random,
  selected_no_signal_random, sample_selection_reason,
  review_decision, reader_1_review_decision, reader_2_review_decision,
  disagreement_adjudication_decision, geocoding_approval, escalation_status,
  preparation_status)]
setorder(sample_out, read_1_order)

write_parquet(question_out, "../output/lihtc_default_singleton_acceptance_questions.parquet", compression = "zstd")
write_parquet(diagnostic_counts, "../output/lihtc_default_singleton_acceptance_diagnostic_counts.parquet", compression = "zstd")
write_parquet(strata, "../output/lihtc_default_singleton_acceptance_diagnostic_strata.parquet", compression = "zstd")
write_parquet(allocation[order(candidate_stratum, routing_status)], "../output/lihtc_default_singleton_acceptance_sample_allocation.parquet", compression = "zstd")
write_parquet(sample_out, "../output/lihtc_default_singleton_acceptance_two_read_sample.parquet", compression = "zstd")

question_roundtrip <- as.data.table(read_parquet("../output/lihtc_default_singleton_acceptance_questions.parquet"))
diagnostic_counts_roundtrip <- as.data.table(read_parquet("../output/lihtc_default_singleton_acceptance_diagnostic_counts.parquet"))
strata_roundtrip <- as.data.table(read_parquet("../output/lihtc_default_singleton_acceptance_diagnostic_strata.parquet"))
allocation_roundtrip <- as.data.table(read_parquet("../output/lihtc_default_singleton_acceptance_sample_allocation.parquet"))
sample_roundtrip <- as.data.table(read_parquet("../output/lihtc_default_singleton_acceptance_two_read_sample.parquet"))
if (!isTRUE(all.equal(question_out, question_roundtrip)) ||
    !isTRUE(all.equal(diagnostic_counts, diagnostic_counts_roundtrip)) ||
    !isTRUE(all.equal(strata, strata_roundtrip)) ||
    !isTRUE(all.equal(allocation[order(candidate_stratum, routing_status)], allocation_roundtrip)) ||
    !isTRUE(all.equal(sample_out, sample_roundtrip))) {
  stop("A preparation-output Parquet round trip changed data.", call. = FALSE)
}
message("Prepared ", nrow(question_out), " default singleton acceptance questions and ", nrow(sample_out), " deterministic two-read sample rows.")
