# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/audit_lihtc_single_address_review_preparation/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
  library(stringr)
})

shared_delimited <- function(first_value, second_value) {
  if (is.na(first_value) || is.na(second_value)) {
    return(NA_character_)
  }
  first_tokens <- strsplit(first_value, "|", fixed = TRUE)[[1L]]
  second_tokens <- strsplit(second_value, "|", fixed = TRUE)[[1L]]
  shared_tokens <- intersect(first_tokens, second_tokens)
  if (length(shared_tokens) == 0L) NA_character_ else
    paste(sort(shared_tokens), collapse = "|")
}

development <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_identical_address_adjudicated.parquet"
))
episode <- as.data.table(read_parquet(
  "../input/lihtc_project_episode_2024_identical_address_adjudicated.parquet"
))
site <- as.data.table(read_parquet(
  "../input/lihtc_development_site_2024_identical_address_adjudicated.parquet"
))
questions <- as.data.table(read_parquet(
  "../input/lihtc_single_address_identity_questions.parquet"
))
members <- as.data.table(read_parquet(
  "../input/lihtc_single_address_identity_question_members.parquet"
))
pairs <- as.data.table(read_parquet(
  "../input/lihtc_single_address_identity_question_pairs.parquet"
))

if (nrow(development) != 54257L ||
    uniqueN(development$development_id) != nrow(development) ||
    nrow(episode) != 55345L || uniqueN(episode$hud_id) != nrow(episode) ||
    nrow(site) != 133551L ||
    uniqueN(site, by = c("development_id", "site_key")) != nrow(site) ||
    nrow(questions) != 1149L ||
    uniqueN(questions$single_address_question_id) != nrow(questions) ||
    uniqueN(questions$site_key) != nrow(questions) ||
    nrow(members) != 2463L ||
    uniqueN(members$development_id) != nrow(members) ||
    uniqueN(members, by = c(
      "single_address_question_id", "development_id"
    )) != nrow(members) ||
    nrow(pairs) != 1618L ||
    uniqueN(pairs$single_address_pair_id) != nrow(pairs) ||
    uniqueN(pairs, by = c(
      "development_id_1", "development_id_2"
    )) != nrow(pairs)) {
  stop("A single-address preparation table count or key changed.",
    call. = FALSE)
}

valid_states <- c(state.abb, "DC")
site_scope <- development[, .(
  development_id,
  development_state,
  n_development_sites,
  development_name,
  cross_address_identity_question_id,
  cross_address_review_decision,
  cross_address_review_reason_code,
  cross_address_round2_review_reason_codes
)][site, on = "development_id", nomatch = 0L]
site_scope[, address_review_text := fcoalesce(
  str_to_upper(str_squish(site_street)),
  ""
)]
site_scope[, `:=`(
  flag_scattered_or_unknown_label = str_detect(
    address_review_text,
    paste0(
      "^(MULTIPLE|VARIOUS|SCATTERED)[[:space:]]+",
      "(BUILDING[[:space:]]+)?",
      "(ADDRESS|ADDRESSES|LOCATIONS)([^A-Z]|$)"
    )
  ),
  flag_multiple_addresses =
    str_detect(address_review_text, ";") |
      str_detect(
        address_review_text,
        "^[0-9]+[A-Z]?([[:space:]]*,[[:space:]]*[0-9]+[A-Z]?)+"
      ) |
      str_detect(
        address_review_text,
        paste0(
          "^[0-9]+[A-Z]?[[:space:]]+(&|AND)",
          "[[:space:]]+[0-9]+[A-Z]?"
        )
      ) |
      str_detect(
        address_review_text,
        "[0-9]+[[:space:]]*/[[:space:]]*[0-9]+"
      ) |
      str_detect(
        address_review_text,
        "[[:space:]][+][[:space:]]*[0-9]+"
      ) |
      str_detect(address_review_text, "&AMP;"),
  flag_address_range = str_detect(
    address_review_text,
    "^[0-9]+[A-Z]?[[:space:]]*(-|–|TO)[[:space:]]*[0-9]+"
  ),
  flag_po_box = str_detect(
    address_review_text,
    paste0(
      "(^|[^A-Z])(P[.]?[[:space:]]*O[.]?|POST OFFICE)",
      "[[:space:]]*BOX([^A-Z]|$)|^BOX[[:space:]]+[0-9]"
    )
  ),
  flag_administrative_address = str_detect(
    address_review_text,
    "^(C/O|CARE OF|OFFICE|MANAGEMENT OFFICE)([^A-Z]|$)"
  ),
  flag_parcel_or_legal_description = str_detect(
    address_review_text,
    paste0(
      "(^|[^A-Z])(VACANT PARCEL|PARCEL|TAX MAP|APN|",
      "LEGAL DESCRIPTION|PLAT NO[.]?|TOWNSHIP)([^A-Z]|$)|",
      "^LOT[[:space:]]+[A-Z0-9]"
    )
  ),
  flag_intersection = str_detect(
    address_review_text,
    "(^|[^A-Z])(INTERSECTION|CORNER OF)([^A-Z]|$)"
  ) | (
    !str_detect(
      address_review_text,
      "^[0-9]+[A-Z]?([^0-9A-Z]|$)"
    ) &
      str_detect(
        address_review_text,
        "[[:space:]](&|AND)[[:space:]]"
      )
  ),
  flag_building_label_only = str_detect(
    address_review_text,
    paste0(
      "^(TBD[[:space:]]+)?(BLDG|BUILDING)[[:space:]]+",
      "[A-Z0-9.-]+([[:space:]]+ADDRESS[[:space:]]+TBD)?$"
    )
  ),
  flag_missing_structure_number = !str_detect(
    address_review_text,
    "^[0-9]+[A-Z]?([^0-9A-Z]|$)"
  ),
  flag_prior_source_or_portfolio_problem =
    str_detect(fcoalesce(development_name, ""), "PORTFOLIO") |
      str_detect(
        fcoalesce(cross_address_review_reason_code, ""),
        "bad_or_placeholder_shared_source_address|source_cross_listing|portfolio"
      ) |
      str_detect(
        fcoalesce(cross_address_round2_review_reason_codes, ""),
        "bad_or_placeholder_shared_source_address|source_cross_listing|portfolio"
      )
)]
site_scope[, deferred_address_form :=
  flag_scattered_or_unknown_label |
    flag_multiple_addresses |
    flag_address_range |
    flag_po_box |
    flag_administrative_address |
    flag_parcel_or_legal_description |
    flag_intersection |
    flag_building_label_only |
    flag_missing_structure_number |
    flag_prior_source_or_portfolio_problem]

one_address_scope <- site_scope[
  n_development_sites == 1L & site_state %chin% valid_states
]
address_scope <- site_scope[, .(
  n_developments = uniqueN(development_id),
  n_single_address_developments = uniqueN(
    development_id[n_development_sites == 1L]
  ),
  all_members_single_address = all(n_development_sites == 1L),
  any_single_address = any(n_development_sites == 1L),
  any_multi_address = any(n_development_sites > 1L),
  all_members_in_scope = all(site_state %chin% valid_states),
  all_members_have_singular_physical_address = all(
    deferred_address_form == FALSE
  )
), by = site_key]

shared_one_key_groups <- address_scope[
  n_developments > 1L &
    all_members_single_address == TRUE &
    all_members_in_scope == TRUE
]
deferred_address_form_groups <- shared_one_key_groups[
  all_members_have_singular_physical_address == FALSE
]
all_single_shared_groups <- shared_one_key_groups[
  all_members_have_singular_physical_address == TRUE
]
all_single_shared_members <- unique(site_scope[
  all_single_shared_groups,
  on = "site_key",
  nomatch = 0L,
  .(site_key, development_id)
])
all_single_shared_pairs <- all_single_shared_members[, {
  development_ids <- sort(unique(development_id))
  combinations <- combn(development_ids, 2L)
  .(
    development_id_1 = combinations[1L, ],
    development_id_2 = combinations[2L, ]
  )
}, by = site_key]

prior_evidence <- development[, .(
  development_id,
  prior_question_ids = cross_address_identity_question_id,
  prior_decisions = cross_address_review_decision
)]
all_single_shared_pairs[prior_evidence, `:=`(
  prior_question_ids_1 = i.prior_question_ids,
  prior_decisions_1 = i.prior_decisions
), on = c(development_id_1 = "development_id")]
all_single_shared_pairs[prior_evidence, `:=`(
  prior_question_ids_2 = i.prior_question_ids,
  prior_decisions_2 = i.prior_decisions
), on = c(development_id_2 = "development_id")]
all_single_shared_pairs[, prior_review_question_ids := mapply(
  shared_delimited,
  prior_question_ids_1,
  prior_question_ids_2
)]
all_single_shared_pairs[, prior_reviewed_distinct :=
  !is.na(prior_review_question_ids) &
    !is.na(prior_decisions_1) &
    !is.na(prior_decisions_2) &
    str_detect(prior_decisions_1, "(^|\\|)retain_separate($|\\|)") &
    str_detect(prior_decisions_2, "(^|\\|)retain_separate($|\\|)")]

expected_question_scope <- all_single_shared_pairs[, .(
  n_unresolved_pairs = sum(!prior_reviewed_distinct),
  n_prior_reviewed_distinct_pairs = sum(prior_reviewed_distinct)
), by = site_key][n_unresolved_pairs > 0L]
expected_members <- all_single_shared_members[
  site_key %chin% expected_question_scope$site_key
]
expected_pairs <- all_single_shared_pairs[
  site_key %chin% expected_question_scope$site_key,
  .(
    site_key,
    development_id_1,
    development_id_2,
    expected_prior_reviewed_distinct = prior_reviewed_distinct
  )
]
observed_members <- members[, .(site_key, development_id)]
observed_pairs <- pairs[, .(
  site_key,
  development_id_1,
  development_id_2,
  expected_prior_reviewed_distinct = prior_reviewed_distinct
)]
setorder(expected_members, site_key, development_id)
setorder(observed_members, site_key, development_id)
setorder(expected_pairs, site_key, development_id_1, development_id_2)
setorder(observed_pairs, site_key, development_id_1, development_id_2)

if (nrow(shared_one_key_groups) != 1332L ||
    nrow(deferred_address_form_groups) != 177L ||
    nrow(all_single_shared_groups) != 1155L ||
    nrow(all_single_shared_members) != 2476L ||
    nrow(all_single_shared_pairs) != 1626L ||
    all_single_shared_pairs[prior_reviewed_distinct == TRUE, .N] != 9L ||
    nrow(expected_question_scope) != 1149L ||
    !setequal(expected_question_scope$site_key, questions$site_key) ||
    !identical(expected_members, observed_members) ||
    !identical(expected_pairs, observed_pairs)) {
  stop("The prepared queue does not match the current one-address scope.",
    call. = FALSE)
}

question_reconciliation <- members[, .(
  observed_developments = .N
), by = single_address_question_id]
question_reconciliation[pairs[, .(
  observed_pairs = .N,
  observed_unresolved_pairs = sum(requires_new_identity_review),
  observed_prior_distinct_pairs = sum(prior_reviewed_distinct)
), by = single_address_question_id], `:=`(
  observed_pairs = i.observed_pairs,
  observed_unresolved_pairs = i.observed_unresolved_pairs,
  observed_prior_distinct_pairs = i.observed_prior_distinct_pairs
), on = "single_address_question_id"]
question_reconciliation[questions[, .(
  single_address_question_id,
  expected_developments = n_developments,
  expected_pairs = n_pairs,
  expected_unresolved_pairs = n_unresolved_pairs,
  expected_prior_distinct_pairs =
    n_prior_reviewed_distinct_pairs
)], `:=`(
  expected_developments = i.expected_developments,
  expected_pairs = i.expected_pairs,
  expected_unresolved_pairs = i.expected_unresolved_pairs,
  expected_prior_distinct_pairs =
    i.expected_prior_distinct_pairs
), on = "single_address_question_id"]
if (anyNA(question_reconciliation) ||
    any(
      question_reconciliation$observed_developments !=
        question_reconciliation$expected_developments
    ) ||
    any(
      question_reconciliation$observed_pairs !=
        question_reconciliation$expected_pairs
    ) ||
    any(
      question_reconciliation$observed_unresolved_pairs !=
        question_reconciliation$expected_unresolved_pairs
    ) ||
    any(
      question_reconciliation$observed_prior_distinct_pairs !=
        question_reconciliation$expected_prior_distinct_pairs
    )) {
  stop("A single-address question summary is inconsistent.",
    call. = FALSE)
}

fully_resolved_site_keys <- setdiff(
  all_single_shared_groups$site_key,
  expected_question_scope$site_key
)
fully_resolved_members <- all_single_shared_members[
  site_key %chin% fully_resolved_site_keys
]
fully_resolved_pairs <- all_single_shared_pairs[
  site_key %chin% fully_resolved_site_keys
]
deferred_address_form_members <- unique(site_scope[
  deferred_address_form_groups,
  on = "site_key",
  nomatch = 0L,
  .(site_key, development_id)
])
mixed_groups <- address_scope[
  n_developments > 1L &
    any_single_address == TRUE &
    any_multi_address == TRUE &
    all_members_in_scope == TRUE
]

if (one_address_scope[, uniqueN(development_id)] != 42030L ||
    one_address_scope[
      !site_key %chin% address_scope[n_developments > 1L, site_key],
      uniqueN(development_id)
    ] != 38191L ||
    length(fully_resolved_site_keys) != 6L ||
    nrow(fully_resolved_members) != 13L ||
    nrow(fully_resolved_pairs) != 8L ||
    nrow(deferred_address_form_members) != 470L ||
    nrow(mixed_groups) != 813L ||
    sum(mixed_groups$n_single_address_developments) != 893L ||
    pairs[requires_new_identity_review == TRUE, .N] != 1617L ||
    pairs[prior_reviewed_distinct == TRUE, .N] != 1L ||
    any(members$n_development_sites != 1L) ||
    any(!members$site_state %chin% valid_states) ||
    uniqueN(
      episode[development_id %chin% members$development_id],
      by = "development_id"
    ) != nrow(members) ||
    pairs[
      requires_new_identity_review == TRUE,
      any(same_normalized_name | any_state_id_overlap)
    ] ||
    any(questions$shared_geocoding_query_decision != "not_approved") ||
    any(pairs$shared_geocoding_query_decision != "not_approved") ||
    any(questions$source_rows_changed) ||
    any(pairs$source_rows_changed)) {
  stop("A single-address preparation safeguard failed.",
    call. = FALSE)
}

question_strata <- questions[, .(questions = .N), by = review_stratum][
  order(-questions, review_stratum)
]
question_strata_rows <- sprintf(
  "| %s | %s |",
  question_strata$review_stratum,
  question_strata$questions
)
pair_strata <- pairs[, .(pairs = .N), by = pair_review_stratum][
  order(-pairs, pair_review_stratum)
]
pair_strata_rows <- sprintf(
  "| %s | %s |",
  pair_strata$pair_review_stratum,
  pair_strata$pairs
)

writeLines(c(
  "# LIHTC Single-Address Review Preparation Audit",
  "",
  "## Scope",
  "",
  "- In-scope developments with one standardized site key: 42,030.",
  "- One-address developments at an otherwise unique address: 38,191.",
  "- Shared one-key groups containing only one-key developments: 1,332 (2,946 developments).",
  "- Weak, nonphysical, compound, portfolio, or range-address groups deferred: 177 (470 developments).",
  "- Numbered singular-address groups after that deferral: 1,155 (2,476 developments).",
  "- Fully prior-reviewed groups excluded from the new queue: 6 (13 developments).",
  "- Mixed single-/multi-address groups deferred: 813 (893 one-address developments).",
  "",
  "## Prepared review",
  "",
  "- Identity questions requiring new review: 1,149.",
  "- Development members: 2,463.",
  "- Unresolved development pairs: 1,617.",
  "- Prior reviewed-distinct pair constraints retained: 1.",
  "",
  "| Question stratum | Questions |",
  "| --- | ---: |",
  question_strata_rows,
  "",
  "| Pair stratum | Pairs |",
  "| --- | ---: |",
  pair_strata_rows,
  "",
  "## Safety",
  "",
  "- Territory address groups included: 0.",
  "- Multi-address developments included: 0.",
  "- Weak, nonphysical, compound, portfolio, or range-address groups included: 0.",
  "- Previously linked exact-name or same-state-ID pairs reopened: 0.",
  "- Shared geocoding queries approved: 0.",
  "- Source rows changed: 0."
), "../output/audit_summary.md")
