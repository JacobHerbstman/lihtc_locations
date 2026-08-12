# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/prepare_lihtc_site_exception_review/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
})

require_unique <- function(table, columns, label) {
  if (uniqueN(table, by = columns) != nrow(table)) {
    stop(label, " is not unique by ", paste(columns, collapse = ", "),
      call. = FALSE)
  }
}

acceptance <- as.data.table(read_parquet(
  "../input/lihtc_dataset_acceptance_observations.parquet"
))
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
    nrow(site) != 131473L) {
  stop("A final low-income-share input row count changed.", call. = FALSE)
}
require_unique(development, "development_id", "Development input")
require_unique(episode, "hud_id", "Episode input")
require_unique(site, "development_site_id", "Site input")
require_unique(site, c("development_id", "site_key"), "Site input")
if (anyNA(site$site_key) || any(site$site_key == "") ||
    any(!episode$development_id %chin% development$development_id) ||
    any(!site$development_id %chin% development$development_id)) {
  stop("A final input key or foreign-key contract failed.", call. = FALSE)
}

acceptance_site <- acceptance[observation_level == "retained_site"]
if (nrow(acceptance_site) != nrow(site)) {
  stop("The acceptance retained-site universe changed.", call. = FALSE)
}
require_unique(
  acceptance_site,
  "development_site_id",
  "Acceptance retained-site inventory"
)
acceptance_site[site[, .(development_site_id, final_development_id = development_id)],
  final_development_id := i.final_development_id,
on = "development_site_id"]
if (anyNA(acceptance_site$final_development_id) ||
    any(acceptance_site$development_id !=
      acceptance_site$final_development_id) ||
    !setequal(acceptance_site$development_site_id, site$development_site_id)) {
  stop("Acceptance and final retained-site lineage disagree.", call. = FALSE)
}

queue_classes <- c(
  "explicit_source_site_review_retained_unresolved",
  "explicit_singleton_site_review_retained_unresolved",
  "inherited_without_site_decision_review_flag_present"
)
acceptance_queue <- acceptance_site[site_evidence_status %chin% queue_classes]
if (nrow(acceptance_queue) != 1937L ||
    uniqueN(acceptance_queue$development_site_id) != nrow(acceptance_queue) ||
    uniqueN(acceptance_queue$development_id) != 211L ||
    acceptance_queue[
      site_evidence_status ==
        "inherited_without_site_decision_review_flag_present",
      .N
    ] != 1804L ||
    acceptance_queue[
      site_evidence_status ==
        "explicit_source_site_review_retained_unresolved",
      .N
    ] != 59L ||
    acceptance_queue[
      site_evidence_status ==
        "explicit_singleton_site_review_retained_unresolved",
      .N
    ] != 74L) {
  stop("The retained-site exception queue changed.", call. = FALSE)
}

site_key_scope <- site[, .(
  n_final_developments_at_site_key = uniqueN(development_id)
), by = site_key]
require_unique(site_key_scope, "site_key", "Final site-key scope")
site[site_key_scope,
  n_final_developments_at_site_key :=
    i.n_final_developments_at_site_key,
on = "site_key"]
site[, site_key_shared_across_final_developments :=
  n_final_developments_at_site_key > 1L]

queued_site <- site[
  development_site_id %chin% acceptance_queue$development_site_id
]
queued_site[acceptance_queue[, .(
  development_site_id,
  original_evidence_class = site_evidence_status,
  acceptance_shared_address_status = shared_address_status,
  acceptance_reason_codes,
  acceptance_status
)], `:=`(
  original_evidence_class = i.original_evidence_class,
  acceptance_shared_address_status = i.acceptance_shared_address_status,
  acceptance_reason_codes = i.acceptance_reason_codes,
  acceptance_status = i.acceptance_status
), on = "development_site_id"]
if (nrow(queued_site) != nrow(acceptance_queue) ||
    anyNA(queued_site$original_evidence_class) ||
    any(
      queued_site$site_key_shared_across_final_developments !=
        (queued_site$acceptance_shared_address_status !=
          "not_shared_across_final_developments")
    )) {
  stop("A queued site failed its acceptance or shared-key cross-check.",
    call. = FALSE)
}

queued_site[, review_priority := fcase(
  original_evidence_class ==
    "explicit_source_site_review_retained_unresolved", 1L,
  original_evidence_class ==
    "explicit_singleton_site_review_retained_unresolved", 2L,
  original_evidence_class ==
    "inherited_without_site_decision_review_flag_present", 3L
)]
queued_site[, review_priority_label := fcase(
  review_priority == 1L, "explicit_source_site_unresolved",
  review_priority == 2L, "explicit_singleton_site_unresolved",
  review_priority == 3L, "inherited_site_review_flag"
)]

queued_class_scope <- queued_site[, .(
  n_evidence_classes = uniqueN(original_evidence_class),
  n_priorities = uniqueN(review_priority),
  n_priority_labels = uniqueN(review_priority_label)
), by = development_id]
if (queued_class_scope[
      n_evidence_classes != 1L |
        n_priorities != 1L |
        n_priority_labels != 1L,
      .N
    ] != 0L) {
  stop("A development spans multiple mutually exclusive queue classes.",
    call. = FALSE)
}

queued_summary <- queued_site[, .(
  original_evidence_class = first(original_evidence_class),
  review_priority = first(review_priority),
  review_priority_label = first(review_priority_label),
  n_queued_sites = .N,
  n_queued_sites_shared_across_final_developments = sum(
    site_key_shared_across_final_developments
  )
), by = development_id]
require_unique(queued_summary, "development_id", "Queued-site summary")

review_development_ids <- queued_summary$development_id
all_site <- site[development_id %chin% review_development_ids]
episode_context_source <- episode[
  development_id %chin% review_development_ids
]
if (nrow(all_site) != 2776L ||
    uniqueN(all_site$development_site_id) != nrow(all_site) ||
    uniqueN(all_site$development_id) != 211L ||
    nrow(episode_context_source) != 243L ||
    uniqueN(episode_context_source$hud_id) != nrow(episode_context_source) ||
    uniqueN(episode_context_source$development_id) != 211L) {
  stop("The complete site or episode context changed.", call. = FALSE)
}

all_site_summary <- all_site[, .(
  n_all_sites = .N,
  n_all_sites_shared_across_final_developments = sum(
    site_key_shared_across_final_developments
  )
), by = development_id]
episode_summary <- episode_context_source[, .(
  n_episode_context_rows = .N
), by = development_id]

questions <- development[development_id %chin% review_development_ids, .(
  development_id,
  development_anchor_hud_id,
  development_name,
  development_name_key,
  development_state,
  development_city,
  n_project_episodes,
  first_pis_year,
  last_pis_year,
  n_units_development,
  li_units_development,
  unit_scope_review_status,
  low_income_share_analysis_status,
  n_development_sites,
  n_sites_with_hud_coordinates,
  n_sites_requiring_review,
  development_linkage_status,
  development_linkage_basis,
  source_site_review_scope,
  source_site_group_decision,
  source_site_inventory_status,
  source_site_property_structure_status,
  source_site_development_scope_status,
  source_site_unresolved_status,
  source_site_requires_episode_property_bridge,
  source_site_repair_status,
  singleton_identity_scope_review_ids,
  singleton_identity_scope_action,
  singleton_identity_scope_cluster_status,
  singleton_identity_scope_reviewed_scope_status,
  singleton_identity_development_scope_status
)]
questions[queued_summary, `:=`(
  original_evidence_class = i.original_evidence_class,
  review_priority = i.review_priority,
  review_priority_label = i.review_priority_label,
  n_queued_sites = i.n_queued_sites,
  n_queued_sites_shared_across_final_developments =
    i.n_queued_sites_shared_across_final_developments
), on = "development_id"]
questions[all_site_summary, `:=`(
  n_all_sites = i.n_all_sites,
  n_all_sites_shared_across_final_developments =
    i.n_all_sites_shared_across_final_developments
), on = "development_id"]
questions[episode_summary,
  n_episode_context_rows := i.n_episode_context_rows,
on = "development_id"]
if (anyNA(questions$original_evidence_class) ||
    anyNA(questions$n_all_sites) ||
    anyNA(questions$n_episode_context_rows) ||
    any(questions$n_all_sites != questions$n_development_sites) ||
    any(questions$n_episode_context_rows != questions$n_project_episodes)) {
  stop("A question summary failed its development-level cross-check.",
    call. = FALSE)
}

questions[, site_portfolio_size_rank := as.integer(frank(
  -n_all_sites,
  ties.method = "min"
))]
setorder(
  questions,
  review_priority,
  -n_all_sites,
  -n_queued_sites,
  development_id
)
questions[, review_order := .I]
questions[, site_exception_review_question_id := paste0(
  "SERQ_", development_id
)]
questions[, `:=`(
  any_queued_site_shared_across_final_developments =
    n_queued_sites_shared_across_final_developments > 0L,
  any_site_shared_across_final_developments =
    n_all_sites_shared_across_final_developments > 0L,
  review_status = "not_adjudicated",
  geocoding_query_approval = "not_approved"
)]
setcolorder(questions, c(
  "site_exception_review_question_id",
  "review_order",
  "review_priority",
  "review_priority_label",
  "site_portfolio_size_rank",
  "original_evidence_class",
  setdiff(names(questions), c(
    "site_exception_review_question_id",
    "review_order",
    "review_priority",
    "review_priority_label",
    "site_portfolio_size_rank",
    "original_evidence_class"
  ))
))

question_key <- questions[, .(
  site_exception_review_question_id,
  development_id,
  review_order,
  review_priority,
  review_priority_label,
  n_all_sites
)]
queued_site[question_key, `:=`(
  site_exception_review_question_id =
    i.site_exception_review_question_id,
  review_order = i.review_order,
  development_n_all_sites = i.n_all_sites
), on = "development_id"]
queued_sites <- queued_site[, .(
  site_exception_review_question_id,
  review_order,
  review_priority,
  review_priority_label,
  development_n_all_sites,
  original_evidence_class,
  development_site_id,
  development_id,
  site_number,
  site_key,
  site_street,
  site_city,
  site_state,
  site_zip,
  site_source,
  n_project_episodes,
  hud_ids,
  n_bin_values,
  bin_example,
  n_coordinate_pairs,
  latitude,
  longitude,
  n_final_developments_at_site_key,
  site_key_shared_across_final_developments,
  requires_site_review,
  source_site_review_scope,
  source_site_exception_group_id,
  source_site_group_decision,
  source_site_operative_action,
  source_site_decision_status,
  source_site_inventory_status,
  source_site_property_structure_status,
  source_site_development_scope_status,
  source_site_unresolved_status,
  source_site_requires_episode_property_bridge,
  source_site_replacement_transaction_id,
  source_site_reviewed_on,
  source_site_application_status,
  source_site_row_origin,
  singleton_identity_scope_review_id,
  singleton_identity_scope_action,
  singleton_identity_scope_cluster_status,
  singleton_identity_scope_reviewed_scope_status,
  singleton_identity_scope_site_action,
  singleton_identity_scope_site_decision_reason,
  singleton_identity_scope_site_source_title,
  singleton_identity_scope_site_source_type,
  singleton_identity_scope_site_source_url,
  singleton_identity_scope_site_source_statement,
  singleton_identity_development_scope_status,
  acceptance_shared_address_status,
  acceptance_reason_codes,
  acceptance_status,
  review_status = "not_adjudicated",
  geocoding_query_approval = "not_approved"
)]

all_site[question_key, `:=`(
  site_exception_review_question_id =
    i.site_exception_review_question_id,
  review_order = i.review_order,
  review_priority = i.review_priority,
  review_priority_label = i.review_priority_label,
  development_n_all_sites = i.n_all_sites
), on = "development_id"]
all_site[, is_queued_site :=
  development_site_id %chin% queued_sites$development_site_id]
all_site[acceptance_queue[, .(
  development_site_id,
  queued_original_evidence_class = site_evidence_status
)], queued_original_evidence_class := i.queued_original_evidence_class,
on = "development_site_id"]
all_site_context <- all_site[, .(
  site_exception_review_question_id,
  review_order,
  review_priority,
  review_priority_label,
  development_n_all_sites,
  development_site_id,
  development_id,
  is_queued_site,
  queued_original_evidence_class,
  site_number,
  site_key,
  site_street,
  site_city,
  site_state,
  site_zip,
  site_source,
  n_project_episodes,
  hud_ids,
  n_bin_values,
  bin_example,
  n_coordinate_pairs,
  latitude,
  longitude,
  n_final_developments_at_site_key,
  site_key_shared_across_final_developments,
  requires_site_review,
  source_site_review_scope,
  source_site_exception_group_id,
  source_site_group_decision,
  source_site_operative_action,
  source_site_decision_status,
  source_site_inventory_status,
  source_site_property_structure_status,
  source_site_development_scope_status,
  source_site_unresolved_status,
  source_site_requires_episode_property_bridge,
  source_site_row_origin,
  singleton_identity_scope_review_id,
  singleton_identity_scope_action,
  singleton_identity_scope_cluster_status,
  singleton_identity_scope_reviewed_scope_status,
  singleton_identity_scope_site_action,
  singleton_identity_scope_site_decision_reason,
  singleton_identity_development_scope_status,
  review_status = "not_adjudicated",
  geocoding_query_approval = "not_approved"
)]

episode_context_source[question_key, `:=`(
  site_exception_review_question_id =
    i.site_exception_review_question_id,
  review_order = i.review_order,
  review_priority = i.review_priority,
  review_priority_label = i.review_priority_label,
  development_n_all_sites = i.n_all_sites
), on = "development_id"]
episode_context <- episode_context_source[, .(
  site_exception_review_question_id,
  review_order,
  review_priority,
  review_priority_label,
  development_n_all_sites,
  development_id,
  hud_id,
  episode_number,
  is_development_anchor,
  source_property_row,
  project,
  name_key,
  proj_add,
  proj_cty,
  proj_st,
  proj_zip,
  state_id,
  primary_site_key,
  pis_year,
  allocation_year,
  latitude,
  longitude,
  episode_units,
  episode_low_income_units,
  n_units,
  li_units,
  scattered_site_cd,
  resyndication_cd,
  datanote,
  record_stat,
  development_linkage_status,
  development_linkage_basis,
  source_site_review_scope,
  source_site_exception_group_id,
  source_site_group_decision,
  source_site_inventory_status,
  source_site_property_structure_status,
  source_site_development_scope_status,
  source_site_unresolved_status,
  source_site_requires_episode_property_bridge,
  source_site_episode_action,
  source_site_episode_decision_status,
  source_site_repair_status,
  singleton_identity_scope_review_id,
  singleton_identity_scope_action,
  singleton_identity_scope_cluster_status,
  singleton_identity_scope_reviewed_scope_status,
  singleton_identity_development_scope_status,
  review_status = "not_adjudicated",
  geocoding_query_approval = "not_approved"
)]

setorder(queued_sites, review_order, development_site_id)
setorder(all_site_context, review_order, development_site_id)
setorder(episode_context, review_order, hud_id)
require_unique(questions, "site_exception_review_question_id", "Question output")
require_unique(questions, "development_id", "Question output")
require_unique(queued_sites, "development_site_id", "Queued-site output")
require_unique(all_site_context, "development_site_id", "All-site context")
require_unique(episode_context, "hud_id", "Episode context")
if (nrow(questions) != 211L || nrow(queued_sites) != 1937L ||
    nrow(all_site_context) != 2776L || nrow(episode_context) != 243L ||
    all_site_context[is_queued_site == TRUE, .N] != nrow(queued_sites) ||
    !setequal(
      all_site_context[is_queued_site == TRUE, development_site_id],
      queued_sites$development_site_id
    ) ||
    any(!queued_sites$development_id %chin% questions$development_id) ||
    any(!all_site_context$development_id %chin% questions$development_id) ||
    any(!episode_context$development_id %chin% questions$development_id)) {
  stop("An output count, membership, or foreign-key contract failed.",
    call. = FALSE)
}
for (table in list(questions, queued_sites, all_site_context, episode_context)) {
  if (any(table$review_status != "not_adjudicated") ||
      any(table$geocoding_query_approval != "not_approved")) {
    stop("An output violates the preparation-only safety contract.",
      call. = FALSE)
  }
}

write_parquet(
  questions,
  "../output/lihtc_site_exception_questions.parquet"
)
write_parquet(
  queued_sites,
  "../output/lihtc_site_exception_queued_sites.parquet"
)
write_parquet(
  all_site_context,
  "../output/lihtc_site_exception_all_site_context.parquet"
)
write_parquet(
  episode_context,
  "../output/lihtc_site_exception_episode_context.parquet"
)

questions_roundtrip <- as.data.table(read_parquet(
  "../output/lihtc_site_exception_questions.parquet"
))
queued_sites_roundtrip <- as.data.table(read_parquet(
  "../output/lihtc_site_exception_queued_sites.parquet"
))
all_site_roundtrip <- as.data.table(read_parquet(
  "../output/lihtc_site_exception_all_site_context.parquet"
))
episode_roundtrip <- as.data.table(read_parquet(
  "../output/lihtc_site_exception_episode_context.parquet"
))
if (!isTRUE(all.equal(
      as.data.frame(questions_roundtrip),
      as.data.frame(questions),
      check.attributes = FALSE
    )) ||
    !isTRUE(all.equal(
      as.data.frame(queued_sites_roundtrip),
      as.data.frame(queued_sites),
      check.attributes = FALSE
    )) ||
    !isTRUE(all.equal(
      as.data.frame(all_site_roundtrip),
      as.data.frame(all_site_context),
      check.attributes = FALSE
    )) ||
    !isTRUE(all.equal(
      as.data.frame(episode_roundtrip),
      as.data.frame(episode_context),
      check.attributes = FALSE
    ))) {
  stop("A prepared parquet failed its exact round-trip check.",
    call. = FALSE)
}
