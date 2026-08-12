# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/audit_lihtc_reviewed_identity_evidence/code")

suppressPackageStartupMessages({ library(arrow); library(data.table) })

is_empty <- function(x) is.na(x) | trimws(x) == ""
split_tokens <- function(x) as.character(unlist(
  strsplit(x[!is_empty(x)], "|", fixed = TRUE), use.names = FALSE
))
valid_url <- function(x) !is_empty(x) & grepl("^https?://", x)
hud_like <- function(x) grepl(
  "(^|[^[:alnum:]])hud([^[:alnum:]]|$)|(^|[./])hud(user)?[.]gov([/:]|$)|national housing preservation|lihtc database",
  x, ignore.case = TRUE, perl = TRUE
)

development <- as.data.table(read_parquet("../input/lihtc_development_2024_low_income_share_adjudicated.parquet"))
episode <- as.data.table(read_parquet("../input/lihtc_project_episode_2024_low_income_share_adjudicated.parquet"))
site <- as.data.table(read_parquet("../input/lihtc_development_site_2024_low_income_share_adjudicated.parquet"))
if (nrow(development) != 53469L || nrow(episode) != 54902L || nrow(site) != 131473L ||
    uniqueN(development$development_id) != nrow(development) || uniqueN(episode$hud_id) != nrow(episode) ||
    uniqueN(site$development_site_id) != nrow(site) ||
    any(!episode$development_id %chin% development$development_id) ||
    any(!site$development_id %chin% development$development_id)) {
  stop("A final development, episode, or site key contract failed.", call. = FALSE)
}

explicit <- development[(development_linkage_status != "singleton" |
  !is.na(singleton_identity_scope_review_ids)) & source_site_unresolved_status == "none"]
if (nrow(explicit) != 3575L) stop("The explicit, nonblocked identity-review universe changed.", call. = FALSE)
explicit[, terminal_review_ledger := fcase(
  development_linkage_status == "adjudicated_linked", "development_linkage",
  grepl("^name_", development_linkage_status), "name_variant",
  grepl("^single_address", development_linkage_status), "single_address",
  grepl("^identical_address_set", development_linkage_status), "identical_address_set",
  grepl("^mixed_site", development_linkage_status), "mixed_site_identity",
  grepl("^cross_address_round2", development_linkage_status), "cross_address_round2",
  grepl("^cross_address", development_linkage_status), "cross_address",
  development_linkage_status == "singleton_identity_scope_reviewed_physical", "singleton_identity_scope",
  default = NA_character_
)]
if (anyNA(explicit$terminal_review_ledger)) stop("A final explicit linkage status has no terminal evidence-ledger route.", call. = FALSE)

development_linkage <- as.data.table(read_parquet("../input/lihtc_development_linkage_decisions_2024.parquet"))
name_variant <- as.data.table(read_parquet("../input/lihtc_name_variant_linkage_decisions_2024.parquet"))
single_address <- as.data.table(read_parquet("../input/lihtc_single_address_question_reviews.parquet"))
identical_address <- as.data.table(read_parquet("../input/lihtc_identical_address_set_reviews.parquet"))
mixed_site <- as.data.table(read_parquet("../input/lihtc_mixed_site_identity_question_reviews.parquet"))
cross_address <- as.data.table(read_parquet("../input/lihtc_cross_development_address_decisions.parquet"))
cross_address_round2 <- as.data.table(read_parquet("../input/lihtc_cross_development_address_question_reviews_round2.parquet"))
singleton_question <- as.data.table(read_parquet("../input/lihtc_singleton_identity_scope_question_reviews.parquet"))
singleton_member <- as.data.table(read_parquet("../input/lihtc_singleton_identity_scope_member_partitions.parquet"))

questions <- rbindlist(list(
  development_linkage[, .(
    ledger = "development_linkage", question_id = development_id,
    final_decision, final_reviewed_on,
    read_1_date = as.character(pass1_reviewed_on), read_2_date = as.character(pass2_reviewed_on),
    source_1_title = pass2_source_1_title, source_1_type = pass2_source_1_type, source_1_url = pass2_source_1_url,
    source_2_title = pass2_source_2_title, source_2_type = pass2_source_2_type, source_2_url = pass2_source_2_url
  )],
  name_variant[, .(
    ledger = "name_variant", question_id = candidate_group_id,
    final_decision, final_reviewed_on,
    read_1_date = as.character(pass1_reviewed_on), read_2_date = as.character(pass2_reviewed_on),
    source_1_title = pass2_source_1_title, source_1_type = pass2_source_1_type, source_1_url = pass2_source_1_url,
    source_2_title = NA_character_, source_2_type = NA_character_, source_2_url = NA_character_
  )],
  single_address[, .(
    ledger = "single_address", question_id = single_address_question_id,
    final_decision = final_identity_decision, final_reviewed_on,
    read_1_date = as.character(pass1_reviewed_on), read_2_date = as.character(pass2_reviewed_on),
    source_1_title = outside_source_title, source_1_type = outside_source_type, source_1_url = outside_source_url,
    source_2_title = NA_character_, source_2_type = NA_character_, source_2_url = NA_character_
  )],
  identical_address[, .(
    ledger = "identical_address_set", question_id = review_question_id,
    final_decision = final_identity_decision, final_reviewed_on,
    read_1_date = as.character(internal_reviewed_on), read_2_date = as.character(external_reviewed_on),
    source_1_title = external_source_title, source_1_type = external_source_type, source_1_url = external_source_url,
    source_2_title = NA_character_, source_2_type = NA_character_, source_2_url = NA_character_
  )],
  mixed_site[, .(
    ledger = "mixed_site_identity", question_id = mixed_site_question_id,
    final_decision = final_identity_decision, final_reviewed_on,
    read_1_date = as.character(first_read_reviewed_on), read_2_date = as.character(outside_read_reviewed_on),
    source_1_title = outside_source_title, source_1_type = outside_source_type, source_1_url = outside_source_url,
    source_2_title = NA_character_, source_2_type = NA_character_, source_2_url = NA_character_
  )],
  cross_address[, .(
    ledger = "cross_address", question_id = identity_question_id,
    final_decision = final_identity_decision, final_reviewed_on,
    read_1_date = as.character(pass1_reviewed_on), read_2_date = as.character(pass2_reviewed_on),
    source_1_title = pass2_source_title, source_1_type = pass2_source_type, source_1_url = pass2_source_url,
    source_2_title = NA_character_, source_2_type = NA_character_, source_2_url = NA_character_
  )],
  cross_address_round2[, .(
    ledger = "cross_address_round2", question_id = identity_question_id,
    final_decision = final_identity_decision, final_reviewed_on,
    read_1_date = as.character(pass1_reviewed_on), read_2_date = as.character(pass2_reviewed_on),
    source_1_title = pass2_source_title, source_1_type = pass2_source_type, source_1_url = pass2_source_url,
    source_2_title = NA_character_, source_2_type = NA_character_, source_2_url = NA_character_
  )]
), use.names = TRUE)

singleton_sources <- singleton_member[, .(
  source_1_title = unique(identity_source_title)[1L],
  source_1_type = unique(identity_source_type)[1L],
  source_1_url = unique(identity_source_url)[1L],
  source_2_title = unique(count_source_title)[1L],
  source_2_type = unique(count_source_type)[1L],
  source_2_url = unique(count_source_url)[1L],
  n_identity_source_urls = uniqueN(identity_source_url[valid_url(identity_source_url)]),
  n_count_source_urls = uniqueN(count_source_url[valid_url(count_source_url)])
), by = singleton_identity_scope_review_id]
singleton_question[singleton_sources, `:=`(
  source_1_title = i.source_1_title, source_1_type = i.source_1_type, source_1_url = i.source_1_url,
  source_2_title = i.source_2_title, source_2_type = i.source_2_type, source_2_url = i.source_2_url,
  n_identity_source_urls = i.n_identity_source_urls, n_count_source_urls = i.n_count_source_urls
), on = "singleton_identity_scope_review_id"]
if (anyNA(singleton_question$n_identity_source_urls) || anyNA(singleton_question$n_count_source_urls)) {
  stop("A singleton question has no unique member-source summary.", call. = FALSE)
}
questions <- rbindlist(list(questions, singleton_question[, .(
  ledger = "singleton_identity_scope", question_id = singleton_identity_scope_review_id,
  final_decision = final_identity_decision, final_reviewed_on = reviewed_on,
  read_1_date = as.character(reviewed_on), read_2_date = as.character(reviewed_on),
  source_1_title, source_1_type, source_1_url, source_2_title, source_2_type, source_2_url
)]), use.names = TRUE)

questions[, source_row_count := .N, by = .(ledger, question_id)]
questions[, source_row_conflict := uniqueN(paste(
  final_decision, final_reviewed_on, read_1_date, read_2_date,
  source_1_url, source_2_url, sep = "\r"
)) > 1L, by = .(ledger, question_id)]
questions <- questions[, lapply(.SD, function(x) x[1L]),
  by = .(ledger, question_id), .SDcols = setdiff(names(questions), c("ledger", "question_id"))]
questions[, `:=`(
  missing_final_decision = is_empty(final_decision),
  missing_final_date = is_empty(final_reviewed_on),
  missing_read_1_date = is_empty(read_1_date),
  missing_read_2_date = is_empty(read_2_date),
  missing_primary_source_url = !valid_url(source_1_url),
  n_distinct_direct_source_urls = uniqueN(c(source_1_url, source_2_url)[valid_url(c(source_1_url, source_2_url))]),
  same_document_for_source_roles = valid_url(source_1_url) & valid_url(source_2_url) & source_1_url == source_2_url,
  potential_hud_or_hud_derived_common_mode = hud_like(paste(
    source_1_title, source_1_type, source_1_url, source_2_title, source_2_type, source_2_url
  )),
  all_documented_source_urls_https = grepl("^https://", source_1_url) &
    (is_empty(source_2_url) | grepl("^https://", source_2_url))
), by = .(ledger, question_id)]
questions[, fatal_ledger_contract := source_row_conflict | missing_final_decision | missing_final_date |
  missing_read_1_date | missing_read_2_date | missing_primary_source_url]
questions[, needs_source_reread := !fatal_ledger_contract &
  (n_distinct_direct_source_urls < 2L | potential_hud_or_hud_derived_common_mode)]
questions[, evidence_audit_status := fcase(
  fatal_ledger_contract, "fail_ledger_contract",
  needs_source_reread, "needs_source_reread",
  default = "pass_documented_source_paths"
)]
questions[, evidence_gap_reason := fcase(
  fatal_ledger_contract, "ledger_contract_incomplete",
  n_distinct_direct_source_urls < 2L & potential_hud_or_hud_derived_common_mode,
    "claimed_two_read_but_less_than_two_distinct_direct_urls|potential_hud_or_hud_derived_common_mode",
  n_distinct_direct_source_urls < 2L, "claimed_two_read_but_less_than_two_distinct_direct_urls",
  potential_hud_or_hud_derived_common_mode, "potential_hud_or_hud_derived_common_mode",
  default = "two_distinct_non_hud_like_source_paths_documented"
)]
if (nrow(questions) != 2387L || uniqueN(questions, by = c("ledger", "question_id")) != nrow(questions) ||
    questions[evidence_audit_status == "pass_documented_source_paths", .N] != 297L ||
    questions[evidence_audit_status == "needs_source_reread", .N] != 2090L ||
    questions[evidence_audit_status == "fail_ledger_contract", .N] != 0L ||
    questions[n_distinct_direct_source_urls < 2L & ledger != "singleton_identity_scope", .N] != 2036L ||
    questions[same_document_for_source_roles == TRUE, .N] != 51L ||
    questions[potential_hud_or_hud_derived_common_mode == TRUE, .N] != 7L ||
    any(!questions$all_documented_source_urls_https)) {
  stop("The frozen question-evidence partition changed.", call. = FALSE)
}

development_linkage_member <- as.data.table(read_parquet("../input/lihtc_development_linkage_member_decisions_2024.parquet"))
name_variant_member <- as.data.table(read_parquet("../input/lihtc_name_variant_linkage_member_decisions_2024.parquet"))
single_address_member <- as.data.table(read_parquet("../input/lihtc_single_address_member_partitions.parquet"))
identical_address_member <- as.data.table(read_parquet("../input/lihtc_identical_address_set_proposed_member_mapping.parquet"))
mixed_site_member <- as.data.table(read_parquet("../input/lihtc_mixed_site_identity_member_partitions.parquet"))
cross_address_member <- as.data.table(read_parquet("../input/lihtc_cross_development_address_member_decisions.parquet"))
cross_address_round2_member <- as.data.table(read_parquet("../input/lihtc_cross_development_address_member_partitions_round2.parquet"))

members <- unique(rbindlist(list(
  development_linkage_member[, .(ledger = "development_linkage", question_id = development_id, final_development_id = adjudicated_development_id)],
  name_variant_member[, .(ledger = "name_variant", question_id = candidate_group_id, final_development_id = name_adjudicated_development_id)],
  single_address_member[, .(ledger = "single_address", question_id = single_address_question_id, final_development_id = adjudicated_development_id)],
  identical_address_member[, .(ledger = "identical_address_set", question_id = review_question_id, final_development_id = proposed_physical_development_id)],
  mixed_site_member[, .(ledger = "mixed_site_identity", question_id = mixed_site_question_id, final_development_id = adjudicated_development_id)],
  cross_address_member[, .(ledger = "cross_address", question_id = identity_question_id, final_development_id = adjudicated_development_id)],
  cross_address_round2_member[, .(ledger = "cross_address_round2", question_id = identity_question_id, final_development_id = adjudicated_development_id)],
  singleton_member[, .(ledger = "singleton_identity_scope", question_id = singleton_identity_scope_review_id, final_development_id = adjudicated_development_id)]
), use.names = TRUE))
members <- members[!is_empty(question_id) & !is_empty(final_development_id)]
members[, question_exists := paste(ledger, question_id) %chin% paste(questions$ledger, questions$question_id)]
members[, final_development_exists := final_development_id %chin% development$development_id]

successor_bridge <- rbindlist(list(
  development[, .(historical_development_id = split_tokens(pre_name_review_development_ids)),
    by = .(successor_development_id = development_id)][,
      successor_provenance_field := "pre_name_review_development_ids"],
  development[, .(historical_development_id = split_tokens(pre_cross_address_review_development_ids)),
    by = .(successor_development_id = development_id)][,
      successor_provenance_field := "pre_cross_address_review_development_ids"],
  development[, .(historical_development_id = split_tokens(pre_cross_address_round2_development_ids)),
    by = .(successor_development_id = development_id)][,
      successor_provenance_field := "pre_cross_address_round2_development_ids"],
  development[, .(historical_development_id = split_tokens(pre_identical_address_set_review_development_ids)),
    by = .(successor_development_id = development_id)][,
      successor_provenance_field := "pre_identical_address_set_review_development_ids"],
  development[, .(historical_development_id = split_tokens(pre_single_address_review_development_ids)),
    by = .(successor_development_id = development_id)][,
      successor_provenance_field := "pre_single_address_review_development_ids"],
  development[, .(historical_development_id = split_tokens(pre_mixed_site_identity_development_ids)),
    by = .(successor_development_id = development_id)][,
      successor_provenance_field := "pre_mixed_site_identity_development_ids"],
  development[, .(historical_development_id = split_tokens(pre_singleton_identity_scope_development_ids)),
    by = .(successor_development_id = development_id)][,
      successor_provenance_field := "pre_singleton_identity_scope_development_ids"]
))
successor_bridge <- successor_bridge[!is_empty(historical_development_id)]
if (successor_bridge[, uniqueN(successor_development_id), by = historical_development_id][V1 != 1L, .N] > 0L ||
    any(!successor_bridge$successor_development_id %chin% development$development_id)) {
  stop("A retained historical development ID has a nonunique or missing current successor.", call. = FALSE)
}
successor_bridge <- successor_bridge[, .(
  successor_development_id = successor_development_id[1L],
  successor_provenance_fields = paste(sort(unique(successor_provenance_field)), collapse = "|")
), by = historical_development_id]
members[successor_bridge, `:=`(
  successor_development_id = fifelse(!final_development_exists, i.successor_development_id, NA_character_),
  successor_provenance_fields = fifelse(!final_development_exists, i.successor_provenance_fields, NA_character_)
), on = .(final_development_id = historical_development_id)]
members[, resolved_final_development_id := fifelse(
  final_development_exists, final_development_id, successor_development_id
)]
members[, member_lineage_status := fcase(
  !question_exists, "question_missing",
  final_development_exists, "question_and_current_final_development_present",
  !is.na(successor_development_id), "question_present_historical_development_resolved_to_current_successor",
  default = "question_present_historical_development_requires_successor_bridge"
)]
if (nrow(members) != 3756L || uniqueN(members, by = c("ledger", "question_id", "final_development_id")) != nrow(members) ||
    members[question_exists == FALSE, .N] != 0L ||
    members[member_lineage_status == "question_and_current_final_development_present", .N] != 3690L ||
    members[member_lineage_status == "question_present_historical_development_resolved_to_current_successor", .N] != 32L ||
    members[member_lineage_status == "question_present_historical_development_requires_successor_bridge", .N] != 34L ||
    any(!members[!is.na(resolved_final_development_id), resolved_final_development_id] %chin% development$development_id)) {
  stop("The frozen member-lineage partition changed.", call. = FALSE)
}

lineage <- unique(rbindlist(list(
  members[
    ledger == "development_linkage" & resolved_final_development_id %chin% explicit$development_id,
    .(development_id = resolved_final_development_id, ledger, question_id)
  ],
  explicit[, .(question_id = split_tokens(name_variant_candidate_group_id)), by = development_id][,
    ledger := "name_variant"],
  explicit[, .(question_id = split_tokens(single_address_review_question_ids)), by = development_id][,
    ledger := "single_address"],
  explicit[, .(question_id = split_tokens(identical_address_set_review_question_ids)), by = development_id][,
    ledger := "identical_address_set"],
  explicit[, .(question_id = split_tokens(mixed_site_identity_question_ids)), by = development_id][,
    ledger := "mixed_site_identity"],
  explicit[, .(question_id = split_tokens(cross_address_identity_question_id)), by = development_id][,
    ledger := "cross_address"],
  explicit[, .(question_id = split_tokens(cross_address_round2_identity_question_ids)), by = development_id][,
    ledger := "cross_address_round2"],
  explicit[, .(question_id = split_tokens(singleton_identity_scope_review_ids)), by = development_id][,
    ledger := "singleton_identity_scope"]
), use.names = TRUE))
lineage[explicit[, .(
  development_id,
  terminal_review_ledger,
  linkage_status = development_linkage_status
)], `:=`(
  terminal_review_ledger = i.terminal_review_ledger,
  linkage_status = i.linkage_status
), on = "development_id"]
lineage[questions[, .(ledger, question_id, question_evidence_status = evidence_audit_status)],
  question_evidence_status := i.question_evidence_status, on = .(ledger, question_id)]
lineage[, `:=`(
  missing_question_id = is_empty(question_id),
  missing_question_evidence = is.na(question_evidence_status)
)]
lineage[, lineage_status := fcase(
  missing_question_id | missing_question_evidence, "fail_lineage_or_status",
  question_evidence_status == "fail_ledger_contract", "fail_ledger_contract",
  question_evidence_status == "needs_source_reread", "needs_source_reread",
  default = "pass_documented_source_paths"
)]

question_lineage_counts <- lineage[, .(
  n_explicit_final_developments = uniqueN(development_id)
), by = .(ledger, question_id)]
questions[question_lineage_counts, n_explicit_final_developments := i.n_explicit_final_developments,
  on = .(ledger, question_id)]
questions[is.na(n_explicit_final_developments), n_explicit_final_developments := 0L]
questions[, retained_in_explicit_final_lineage := n_explicit_final_developments > 0L]
if (nrow(lineage) != 3703L || uniqueN(lineage$development_id) != 3575L ||
    uniqueN(lineage, by = c("ledger", "question_id")) != 2363L ||
    any(lineage$missing_question_id) || any(lineage$missing_question_evidence) ||
    any(!paste(explicit$development_id, explicit$terminal_review_ledger) %chin%
      paste(lineage$development_id, lineage$ledger)) ||
    questions[retained_in_explicit_final_lineage == TRUE, .N] != 2363L ||
    questions[retained_in_explicit_final_lineage == FALSE, .N] != 24L ||
    questions[retained_in_explicit_final_lineage == TRUE &
      evidence_audit_status == "pass_documented_source_paths", .N] != 294L ||
    questions[retained_in_explicit_final_lineage == TRUE &
      evidence_audit_status == "needs_source_reread", .N] != 2069L) {
  stop("The cumulative retained question lineage changed.", call. = FALSE)
}

development_audit <- lineage[, .(
  terminal_review_ledger = terminal_review_ledger[1L],
  cumulative_review_ledgers = paste(sort(unique(ledger)), collapse = "|"),
  question_keys = paste(sort(unique(paste(ledger, question_id, sep = ":"))), collapse = "|"),
  question_ids = paste(sort(unique(question_id[!is_empty(question_id)])), collapse = "|"),
  linkage_status = linkage_status[1L],
  n_question_lineage_rows = .N,
  n_review_ledgers = uniqueN(ledger),
  n_questions = uniqueN(paste(ledger, question_id, sep = "\r")),
  missing_question_id = any(missing_question_id),
  missing_question_evidence = any(missing_question_evidence),
  development_evidence_status = fcase(
    any(lineage_status == "fail_lineage_or_status"), "fail_lineage_or_status",
    any(lineage_status == "fail_ledger_contract"), "fail_ledger_contract",
    any(lineage_status == "needs_source_reread"), "needs_source_reread",
    default = "pass_documented_source_paths"
  )
), by = development_id]
if (nrow(development_audit) != 3575L || uniqueN(development_audit$development_id) != nrow(development_audit) ||
    development_audit[development_evidence_status == "pass_documented_source_paths", .N] != 257L ||
    development_audit[development_evidence_status == "needs_source_reread", .N] != 3318L ||
    development_audit[grepl("^fail", development_evidence_status), .N] != 0L ||
    development_audit[n_questions > 1L, .N] != 115L ||
    development_audit[n_review_ledgers > 1L, .N] != 108L) {
  stop("The frozen final-development evidence partition changed.", call. = FALSE)
}

episode_descendant <- episode[development_id %chin% development_audit$development_id, .(
  descendant_level = "episode", development_id, descendant_id = hud_id
)]
site_descendant <- site[development_id %chin% development_audit$development_id, .(
  descendant_level = "retained_site", development_id, descendant_id = development_site_id
)]
descendant <- rbindlist(list(
  development_audit[, .(descendant_level = "development", development_id, descendant_id = development_id)],
  episode_descendant,
  site_descendant
))
descendant[development_audit[, .(development_id, development_evidence_status)],
  development_evidence_status := i.development_evidence_status, on = "development_id"]
if (nrow(descendant) != 20124L || uniqueN(descendant, by = c("descendant_level", "descendant_id")) != nrow(descendant) ||
    descendant[descendant_level == "development", .N] != 3575L ||
    descendant[descendant_level == "episode", .N] != 5007L ||
    descendant[descendant_level == "retained_site", .N] != 11542L ||
    descendant[descendant_level == "episode" & development_evidence_status == "pass_documented_source_paths", .N] != 571L ||
    descendant[descendant_level == "retained_site" & development_evidence_status == "pass_documented_source_paths", .N] != 1608L ||
    anyNA(descendant$development_evidence_status)) {
  stop("The evidence-status descendant propagation changed.", call. = FALSE)
}

status_counts <- rbindlist(list(
  questions[, .(observation_level = "review_question", evidence_status = evidence_audit_status, n_observations = .N), by = evidence_audit_status][, evidence_audit_status := NULL],
  development_audit[, .(observation_level = "development", evidence_status = development_evidence_status, n_observations = .N), by = development_evidence_status][, development_evidence_status := NULL],
  members[, .(observation_level = "member_mapping", evidence_status = member_lineage_status, n_observations = .N), by = member_lineage_status][, member_lineage_status := NULL]
))
setorder(questions, ledger, question_id)
setorder(members, ledger, question_id, final_development_id)
setorder(development_audit, development_evidence_status, development_id)
setorder(descendant, descendant_level, development_id, descendant_id)
setorder(status_counts, observation_level, evidence_status)

write_parquet(development_audit, "../output/lihtc_reviewed_identity_development_evidence_audit.parquet", compression = "zstd")
write_parquet(questions, "../output/lihtc_reviewed_identity_question_evidence_audit.parquet", compression = "zstd")
write_parquet(members, "../output/lihtc_reviewed_identity_member_lineage_audit.parquet", compression = "zstd")
write_parquet(descendant, "../output/lihtc_reviewed_identity_descendant_propagation_audit.parquet", compression = "zstd")
write_parquet(status_counts, "../output/lihtc_reviewed_identity_evidence_status_counts.parquet", compression = "zstd")

if (!identical(development_audit, as.data.table(read_parquet("../output/lihtc_reviewed_identity_development_evidence_audit.parquet"))) ||
    !identical(questions, as.data.table(read_parquet("../output/lihtc_reviewed_identity_question_evidence_audit.parquet"))) ||
    !identical(members, as.data.table(read_parquet("../output/lihtc_reviewed_identity_member_lineage_audit.parquet"))) ||
    !identical(descendant, as.data.table(read_parquet("../output/lihtc_reviewed_identity_descendant_propagation_audit.parquet"))) ||
    !identical(status_counts, as.data.table(read_parquet("../output/lihtc_reviewed_identity_evidence_status_counts.parquet")))) {
  stop("An evidence-audit Parquet round trip changed data.", call. = FALSE)
}
message("Audited ", nrow(questions), " review questions covering ", nrow(development_audit),
  " explicit, nonblocked final developments; ",
  development_audit[development_evidence_status == "needs_source_reread", .N], " developments require source re-read.")
