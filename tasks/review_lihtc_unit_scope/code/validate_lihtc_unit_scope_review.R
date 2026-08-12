# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/review_lihtc_unit_scope/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
})

question_columns <- c(
  "unit_scope_question_id",
  "development_id",
  "review_queue_type",
  "pass1_total_action",
  "pass1_total_value",
  "pass1_total_reason_code",
  "pass1_low_income_action",
  "pass1_low_income_value",
  "pass1_low_income_reason_code",
  "pass1_notes",
  "pass1_reviewed_on",
  "pass2_search_engine",
  "pass2_search_url",
  "pass2_source_title",
  "pass2_source_type",
  "pass2_source_url",
  "pass2_source_coverage",
  "pass2_published_total_units",
  "pass2_published_total_count_type",
  "pass2_published_low_income_units",
  "pass2_published_low_income_count_type",
  "pass2_notes",
  "pass2_reviewed_on",
  "final_total_action",
  "final_total_value",
  "final_total_reason_code",
  "final_low_income_action",
  "final_low_income_value",
  "final_low_income_reason_code",
  "final_notes",
  "final_reviewed_on",
  "source_rows_changed"
)
member_columns <- c(
  "unit_scope_question_id",
  "development_id",
  "hud_id",
  "pass1_total_member_role",
  "pass1_low_income_member_role",
  "final_total_member_role",
  "final_total_value_source",
  "final_total_member_reason_code",
  "final_low_income_member_role",
  "final_low_income_value_source",
  "final_low_income_member_reason_code",
  "member_notes"
)

decisions <- fread(
  "unit_scope_question_decisions.csv",
  na.strings = ""
)
member_decisions <- fread(
  "unit_scope_member_decisions.csv",
  na.strings = ""
)
questions <- as.data.table(read_parquet(
  "../input/lihtc_unit_scope_questions.parquet"
))
members <- as.data.table(read_parquet(
  "../input/lihtc_unit_scope_question_members.parquet"
))
prior_evidence <- as.data.table(read_parquet(
  "../input/lihtc_unit_scope_prior_evidence.parquet"
))

if (!identical(names(decisions), question_columns) ||
    !identical(names(member_decisions), member_columns)) {
  stop("A committed unit-scope ledger schema changed.", call. = FALSE)
}
if (nrow(decisions) == 0L || nrow(member_decisions) == 0L) {
  stop(
    paste(
      "The unit-scope CSV files are unpopulated templates.",
      "Complete both ledgers before running this review task."
    ),
    call. = FALSE
  )
}

if (nrow(questions) != 1224L ||
    nrow(members) != 2657L ||
    nrow(prior_evidence) != 1581L ||
    uniqueN(prior_evidence$prior_evidence_id) != nrow(prior_evidence) ||
    uniqueN(prior_evidence$unit_scope_question_id) != 1161L ||
    any(!prior_evidence$unit_scope_question_id %chin%
      questions$unit_scope_question_id) ||
    nrow(decisions) != nrow(questions) ||
    nrow(member_decisions) != nrow(members) ||
    uniqueN(questions$unit_scope_question_id) != nrow(questions) ||
    uniqueN(decisions$unit_scope_question_id) != nrow(decisions) ||
    uniqueN(members$hud_id) != nrow(members) ||
    uniqueN(member_decisions$hud_id) != nrow(member_decisions) ||
    !setequal(
      decisions$unit_scope_question_id,
      questions$unit_scope_question_id
    ) ||
    !setequal(member_decisions$hud_id, members$hud_id)) {
  stop("The decision ledgers do not cover the prepared queue exactly.",
    call. = FALSE)
}

question_evidence <- questions[, .(
  unit_scope_question_id,
  development_id,
  review_queue_type
)]
question_evidence[decisions, `:=`(
  reviewed_development_id = i.development_id,
  reviewed_queue_type = i.review_queue_type
), on = "unit_scope_question_id"]
if (anyNA(question_evidence$reviewed_development_id) ||
    question_evidence[
      development_id != reviewed_development_id |
        review_queue_type != reviewed_queue_type,
      .N
    ] > 0L) {
  stop("Prepared question identity changed in the decision ledger.",
    call. = FALSE)
}

member_evidence <- members[, .(
  unit_scope_question_id,
  development_id,
  hud_id
)]
member_evidence[member_decisions, `:=`(
  reviewed_question_id = i.unit_scope_question_id,
  reviewed_development_id = i.development_id
), on = "hud_id"]
if (anyNA(member_evidence$reviewed_question_id) ||
    member_evidence[
      unit_scope_question_id != reviewed_question_id |
        development_id != reviewed_development_id,
      .N
    ] > 0L) {
  stop("Prepared episode identity changed in the member ledger.",
    call. = FALSE)
}

numeric_fields <- c(
  "pass1_total_value",
  "pass1_low_income_value",
  "pass2_published_total_units",
  "pass2_published_low_income_units",
  "final_total_value",
  "final_low_income_value"
)
date_fields <- c(
  "pass1_reviewed_on",
  "pass2_reviewed_on",
  "final_reviewed_on"
)
for (field in numeric_fields) {
  supplied <- !is.na(decisions[[field]]) &
    trimws(as.character(decisions[[field]])) != ""
  parsed <- suppressWarnings(as.numeric(decisions[[field]]))
  if (any(supplied & is.na(parsed))) {
    stop(paste("A numeric decision field is malformed:", field),
      call. = FALSE)
  }
  set(decisions, j = field, value = parsed)
}
if (any(vapply(
  decisions[, ..numeric_fields],
  function(value) any(!is.na(value) & value != floor(value)),
  logical(1L)
))) {
  stop("A unit-count decision field is not a whole number.",
    call. = FALSE)
}
decisions[, (date_fields) := lapply(.SD, as.Date), .SDcols = date_fields]

source_rows_changed_text <- toupper(trimws(as.character(
  decisions$source_rows_changed
)))
if (anyNA(source_rows_changed_text) ||
    any(!source_rows_changed_text %chin% c("TRUE", "FALSE"))) {
  stop("source_rows_changed must be TRUE or FALSE.", call. = FALSE)
}
decisions[, source_rows_changed := source_rows_changed_text == "TRUE"]

required_question_text <- c(
  "unit_scope_question_id",
  "development_id",
  "review_queue_type",
  "pass1_total_action",
  "pass1_total_reason_code",
  "pass1_low_income_action",
  "pass1_low_income_reason_code",
  "pass1_notes",
  "pass2_search_engine",
  "pass2_source_title",
  "pass2_source_type",
  "pass2_source_coverage",
  "pass2_published_total_count_type",
  "pass2_published_low_income_count_type",
  "pass2_notes",
  "final_total_action",
  "final_total_reason_code",
  "final_low_income_action",
  "final_low_income_reason_code",
  "final_notes"
)
required_member_text <- setdiff(member_columns, "member_notes")
if (anyNA(decisions[, ..required_question_text]) ||
    any(vapply(
      decisions[, ..required_question_text],
      function(value) any(trimws(as.character(value)) == ""),
      logical(1L)
    )) ||
    anyNA(decisions[, ..date_fields]) ||
    anyNA(member_decisions[, ..required_member_text]) ||
    any(vapply(
      member_decisions[, ..required_member_text],
      function(value) any(trimws(as.character(value)) == ""),
      logical(1L)
    ))) {
  stop("A required two-read or member-decision field is empty.",
    call. = FALSE)
}

allowed_pass1_actions <- c(
  "candidate_use_once",
  "candidate_sum_components",
  "candidate_select_episode",
  "candidate_external_value_needed",
  "candidate_episode_specific",
  "defer_outside_read"
)
if (any(!decisions$pass1_total_action %chin% allowed_pass1_actions) ||
    any(!decisions$pass1_low_income_action %chin% allowed_pass1_actions)) {
  stop("A first-read action is invalid.", call. = FALSE)
}
pass1_reason_contract <- data.table(
  action = allowed_pass1_actions,
  allowed_reasons = list(
    c(
      "equal_counts_with_repeat_lineage",
      "equal_counts_without_scope_evidence"
    ),
    "component_lineage_nonoverlap_unconfirmed",
    c(
      "changed_counts_current_configuration_unconfirmed",
      "original_hud_count_may_resolve_reconciliation"
    ),
    c(
      "bad_or_missing_episode_count",
      "mixed_component_and_repeat_lineage",
      "ambiguous_identity_scope_lineage",
      "internal_evidence_insufficient"
    ),
    c(
      "changed_counts_episode_specific_unconfirmed",
      "ambiguous_identity_scope_lineage"
    ),
    c(
      "equal_counts_without_scope_evidence",
      "component_lineage_nonoverlap_unconfirmed",
      "mixed_component_and_repeat_lineage",
      "ambiguous_identity_scope_lineage",
      "internal_evidence_insufficient"
    )
  )
)
total_pass1_reasons <- pass1_reason_contract[
  decisions,
  on = c(action = "pass1_total_action")
]$allowed_reasons
low_income_pass1_reasons <- pass1_reason_contract[
  decisions,
  on = c(action = "pass1_low_income_action")
]$allowed_reasons
valid_total_pass1_reason <- mapply(
  function(value, allowed) value %chin% allowed,
  decisions$pass1_total_reason_code,
  total_pass1_reasons
)
valid_low_income_pass1_reason <- mapply(
  function(value, allowed) value %chin% allowed,
  decisions$pass1_low_income_reason_code,
  low_income_pass1_reasons
)
pass1_numeric_actions <- c(
  "candidate_use_once",
  "candidate_sum_components",
  "candidate_select_episode"
)
if (any(!valid_total_pass1_reason) ||
    any(!valid_low_income_pass1_reason) ||
    decisions[
      pass1_total_action %chin% pass1_numeric_actions &
        is.na(pass1_total_value),
      .N
    ] > 0L ||
    decisions[
      !pass1_total_action %chin% pass1_numeric_actions &
        !is.na(pass1_total_value),
      .N
    ] > 0L ||
    decisions[
      pass1_low_income_action %chin% pass1_numeric_actions &
        is.na(pass1_low_income_value),
      .N
    ] > 0L ||
    decisions[
      !pass1_low_income_action %chin% pass1_numeric_actions &
        !is.na(pass1_low_income_value),
      .N
    ] > 0L ||
    decisions[
      !is.na(pass1_total_value) & pass1_total_value <= 0,
      .N
    ] > 0L ||
    decisions[
      !is.na(pass1_low_income_value) & pass1_low_income_value < 0,
      .N
    ] > 0L ||
    decisions[
      !is.na(pass1_total_value) & !is.na(pass1_low_income_value) &
        pass1_low_income_value > pass1_total_value,
      .N
    ] > 0L) {
  stop("A first-read action and value disagree.", call. = FALSE)
}

allowed_search_engines <- c(
  "Google",
  "Bing",
  "DuckDuckGo",
  "public_registry",
  "prior_review_source"
)
allowed_source_types <- c(
  "allocating_agency",
  "housing_authority",
  "municipal_record",
  "county_record",
  "property_owner",
  "property_manager",
  "developer",
  "public_property_directory",
  "housing_sector_source",
  "newspaper",
  "other_public_record",
  "developer_project_page",
  "official_state_government",
  "official_state_housing_finance_agency",
  "official_state_housing_agency",
  "official_local_government",
  "official_local_housing_agency",
  "property_owner_developer_site",
  "property_owner_manager_site",
  "owner_developer",
  "independent_public_housing_directory",
  "independent_local_market_report",
  "public_program_guide",
  "no_reliable_source"
)
allowed_source_coverage <- c(
  "development_total_and_affordable",
  "development_total_only",
  "development_affordable_only",
  "component_structure_only",
  "partial_component_counts",
  "identity_only",
  "no_reliable_source"
)
allowed_count_types <- c(
  "exact",
  "lower_bound",
  "upper_bound",
  "not_reported"
)
direct_source_required <- decisions$pass2_source_coverage !=
  "no_reliable_source"
nonnumeric_directory_source <- decisions$pass2_source_type %chin% c(
  "public_property_directory",
  "independent_public_housing_directory"
)
if (any(!decisions$pass2_search_engine %chin% allowed_search_engines) ||
    any(!decisions$pass2_source_type %chin% allowed_source_types) ||
    any(!decisions$pass2_source_coverage %chin% allowed_source_coverage) ||
    any(!decisions$pass2_published_total_count_type %chin%
      allowed_count_types) ||
    any(!decisions$pass2_published_low_income_count_type %chin%
      allowed_count_types) ||
    any(
      is.na(decisions$pass2_search_url) |
        !grepl("^https?://", decisions$pass2_search_url)
    ) ||
    any(
      direct_source_required & (
        is.na(decisions$pass2_source_url) |
          !grepl("^https?://", decisions$pass2_source_url)
      )
    ) ||
    any(
      !direct_source_required &
        !is.na(decisions$pass2_source_url) &
        trimws(decisions$pass2_source_url) != ""
    ) ||
    any(
      direct_source_required &
        grepl("google.com/search", decisions$pass2_source_url, fixed = TRUE)
    ) ||
    any(
      (decisions$pass2_source_type == "no_reliable_source") !=
        (decisions$pass2_source_coverage == "no_reliable_source")
    ) ||
    any(
      nonnumeric_directory_source &
        decisions$pass2_source_coverage != "identity_only"
    ) ||
    decisions[
      pass2_source_coverage == "development_total_and_affordable" &
        (is.na(pass2_published_total_units) |
          is.na(pass2_published_low_income_units) |
          pass2_published_total_count_type == "not_reported" |
          pass2_published_low_income_count_type == "not_reported"),
      .N
    ] > 0L ||
    decisions[
      pass2_source_coverage == "development_total_only" &
        (is.na(pass2_published_total_units) |
          !is.na(pass2_published_low_income_units) |
          pass2_published_total_count_type == "not_reported" |
          pass2_published_low_income_count_type != "not_reported"),
      .N
    ] > 0L ||
    decisions[
      pass2_source_coverage == "development_affordable_only" &
        (!is.na(pass2_published_total_units) |
          is.na(pass2_published_low_income_units) |
          pass2_published_total_count_type != "not_reported" |
          pass2_published_low_income_count_type == "not_reported"),
      .N
    ] > 0L ||
    decisions[
      pass2_source_coverage %chin% c(
        "component_structure_only",
        "partial_component_counts",
        "identity_only",
        "no_reliable_source"
      ) &
        (!is.na(pass2_published_total_units) |
          !is.na(pass2_published_low_income_units) |
          pass2_published_total_count_type != "not_reported" |
          pass2_published_low_income_count_type != "not_reported"),
      .N
    ] > 0L ||
    decisions[
      (is.na(pass2_published_total_units) !=
        (pass2_published_total_count_type == "not_reported")) |
        (is.na(pass2_published_low_income_units) !=
          (pass2_published_low_income_count_type == "not_reported")),
      .N
    ] > 0L) {
  stop("An outside-read source or coverage field is invalid.",
    call. = FALSE)
}

prior_source_urls <- unique(prior_evidence[, .(
  source_url = trimws(unlist(strsplit(
    source_url,
    " | ",
    fixed = TRUE
  )))
), by = unit_scope_question_id])
reused_prior_sources <- decisions[
  pass2_search_engine == "prior_review_source",
  .(
    source_url = trimws(unlist(strsplit(
      pass2_source_url,
      " | ",
      fixed = TRUE
    )))
  ),
  by = unit_scope_question_id
]
reused_prior_sources[, source_url_is_frozen_for_question := FALSE]
reused_prior_sources[
  prior_source_urls,
  source_url_is_frozen_for_question := TRUE,
  on = c("unit_scope_question_id", "source_url")
]
if (reused_prior_sources[
      source_url_is_frozen_for_question == FALSE,
      .N
    ] > 0L) {
  stop("A reused prior source URL is not frozen for that question.",
    call. = FALSE)
}

forbidden_final_text <- "candidate|defer|unresolved|not_adjudicated"
if (any(grepl(forbidden_final_text, decisions$final_total_action)) ||
    any(grepl(forbidden_final_text, decisions$final_low_income_action)) ||
    any(grepl(
      forbidden_final_text,
      member_decisions$final_total_member_role
    )) ||
    any(grepl(
      forbidden_final_text,
      member_decisions$final_low_income_member_role
    ))) {
  stop("An unresolved label is masquerading as a final decision.",
    call. = FALSE)
}

allowed_final_actions <- c(
  "use_once_reporting_value",
  "sum_selected_components",
  "select_current_episode_value",
  "use_external_property_value",
  "retain_episode_specific_no_static_value",
  "unavailable_after_review"
)
allowed_final_reasons <- c(
  "duplicate_reporting_use_once",
  "distinct_components_sum",
  "current_configuration_selected",
  "direct_source_property_value",
  "episode_specific_no_static_value",
  "unavailable_after_search",
  "singleton_source_value_recovered"
)
numeric_final_actions <- c(
  "use_once_reporting_value",
  "sum_selected_components",
  "select_current_episode_value",
  "use_external_property_value"
)
if (any(!decisions$final_total_action %chin% allowed_final_actions) ||
    any(!decisions$final_low_income_action %chin% allowed_final_actions) ||
    any(!decisions$final_total_reason_code %chin% allowed_final_reasons) ||
    any(!decisions$final_low_income_reason_code %chin%
      allowed_final_reasons) ||
    decisions[
      final_total_action %chin% numeric_final_actions &
        (is.na(final_total_value) | final_total_value <= 0),
      .N
    ] > 0L ||
    decisions[
      !final_total_action %chin% numeric_final_actions &
        !is.na(final_total_value),
      .N
    ] > 0L ||
    decisions[
      final_low_income_action %chin% numeric_final_actions &
        (is.na(final_low_income_value) | final_low_income_value < 0),
      .N
    ] > 0L ||
    decisions[
      !final_low_income_action %chin% numeric_final_actions &
        !is.na(final_low_income_value),
      .N
    ] > 0L ||
    decisions[
      !is.na(final_total_value) & !is.na(final_low_income_value) &
        final_low_income_value > final_total_value,
      .N
    ] > 0L) {
  stop("A final action, reason, or numeric value is invalid.",
    call. = FALSE)
}
if (decisions[
      (final_total_action == "unavailable_after_review" |
        final_low_income_action == "unavailable_after_review") &
        !grepl(
          "no defensible static physical-development value",
          final_notes,
          fixed = TRUE
        ),
      .N
    ] > 0L) {
  stop(
    paste(
      "An unavailable decision does not distinguish the missing static",
      "development value from the preserved episode evidence."
    ),
    call. = FALSE
  )
}

valid_total_reason <- with(decisions,
  final_total_action == "use_once_reporting_value" &
    final_total_reason_code == "duplicate_reporting_use_once" |
    final_total_action == "sum_selected_components" &
      final_total_reason_code == "distinct_components_sum" |
    final_total_action == "select_current_episode_value" &
      final_total_reason_code %chin% c(
        "current_configuration_selected",
        "singleton_source_value_recovered"
      ) |
    final_total_action == "use_external_property_value" &
      final_total_reason_code %chin% c(
        "direct_source_property_value",
        "singleton_source_value_recovered"
      ) |
    final_total_action == "retain_episode_specific_no_static_value" &
      final_total_reason_code == "episode_specific_no_static_value" |
    final_total_action == "unavailable_after_review" &
      final_total_reason_code == "unavailable_after_search"
)
valid_low_income_reason <- with(decisions,
  final_low_income_action == "use_once_reporting_value" &
    final_low_income_reason_code == "duplicate_reporting_use_once" |
    final_low_income_action == "sum_selected_components" &
      final_low_income_reason_code == "distinct_components_sum" |
    final_low_income_action == "select_current_episode_value" &
      final_low_income_reason_code %chin% c(
        "current_configuration_selected",
        "singleton_source_value_recovered"
      ) |
    final_low_income_action == "use_external_property_value" &
      final_low_income_reason_code %chin% c(
        "direct_source_property_value",
        "singleton_source_value_recovered"
      ) |
    final_low_income_action ==
      "retain_episode_specific_no_static_value" &
      final_low_income_reason_code ==
        "episode_specific_no_static_value" |
    final_low_income_action == "unavailable_after_review" &
      final_low_income_reason_code == "unavailable_after_search"
)
if (any(!valid_total_reason) || any(!valid_low_income_reason) ||
    decisions[
      final_total_reason_code == "singleton_source_value_recovered" &
        !review_queue_type %chin% c(
          "singleton_source_count_problem",
          "external_unit_count_conflict"
        ),
      .N
    ] > 0L ||
    decisions[
      final_low_income_reason_code ==
        "singleton_source_value_recovered" &
        !review_queue_type %chin% c(
          "singleton_source_count_problem",
          "external_unit_count_conflict"
        ),
      .N
    ] > 0L ||
    decisions[
      unit_scope_question_id %chin% questions[
        n_episode_members == 1L,
        unit_scope_question_id
      ] & (
        final_total_action ==
          "retain_episode_specific_no_static_value" |
          final_low_income_action ==
            "retain_episode_specific_no_static_value"
      ),
      .N
    ] > 0L) {
  stop("A final action and reason code are incompatible.", call. = FALSE)
}

use_once_support <- questions[, .(
  unit_scope_question_id,
  n_total_nonpositive,
  n_distinct_nonmissing_total_values,
  n_low_income_negative,
  n_low_income_exceeds_total,
  n_distinct_nonmissing_low_income_values,
  prior_repeat_episode_reason,
  n_prior_repeat_sources_linked_to_full_review_group
)]
use_once_support[decisions, `:=`(
  final_total_action = i.final_total_action,
  final_low_income_action = i.final_low_income_action
), on = "unit_scope_question_id"]
if (use_once_support[
      final_total_action == "use_once_reporting_value" & (
        n_total_nonpositive > 0L |
          n_distinct_nonmissing_total_values != 1L |
          !prior_repeat_episode_reason |
          n_prior_repeat_sources_linked_to_full_review_group == 0L
      ),
      .N
    ] > 0L ||
    use_once_support[
      final_low_income_action == "use_once_reporting_value" & (
        n_low_income_negative > 0L |
          n_low_income_exceeds_total > 0L |
          n_distinct_nonmissing_low_income_values != 1L |
          !prior_repeat_episode_reason |
          n_prior_repeat_sources_linked_to_full_review_group == 0L
      ),
      .N
    ] > 0L) {
  stop(
    paste(
      "A use-once decision lacks one consistent nonmissing episode value,",
      "or a full-group review row carrying the repeat/source-variant",
      "reason."
    ),
    call. = FALSE
  )
}

if (decisions[
      final_total_action == "select_current_episode_value" &
        !pass2_source_coverage %chin% c(
          "development_total_and_affordable",
          "development_total_only",
          "partial_component_counts"
        ),
      .N
    ] > 0L ||
    decisions[
      final_total_action == "sum_selected_components" &
        !pass2_source_coverage %chin% c(
          "development_total_and_affordable",
          "development_total_only",
          "component_structure_only",
          "partial_component_counts"
        ),
      .N
    ] > 0L ||
    decisions[
      final_low_income_action == "select_current_episode_value" &
        !pass2_source_coverage %chin% c(
          "development_total_and_affordable",
          "development_affordable_only",
          "partial_component_counts"
        ),
      .N
    ] > 0L ||
    decisions[
      final_low_income_action == "sum_selected_components" &
        !pass2_source_coverage %chin% c(
          "development_total_and_affordable",
          "development_total_only",
          "development_affordable_only",
          "component_structure_only",
          "partial_component_counts"
        ),
      .N
    ] > 0L) {
  stop("A summed or selected episode lacks source scope evidence.",
    call. = FALSE)
}

external_value_action <- "use_external_property_value"
if (decisions[
      final_total_action == external_value_action &
        (is.na(pass2_published_total_units) |
          pass2_published_total_count_type != "exact" |
          final_total_value != pass2_published_total_units),
      .N
    ] > 0L ||
    decisions[
      final_low_income_action == external_value_action &
        (is.na(pass2_published_low_income_units) |
          pass2_published_low_income_count_type != "exact" |
          final_low_income_value != pass2_published_low_income_units),
      .N
    ] > 0L ||
    decisions[
      final_total_action %chin% numeric_final_actions &
        pass2_published_total_count_type == "exact" &
        !is.na(pass2_published_total_units) &
        final_total_value != pass2_published_total_units,
      .N
    ] > 0L ||
    decisions[
      final_low_income_action %chin% numeric_final_actions &
        pass2_published_low_income_count_type == "exact" &
        !is.na(pass2_published_low_income_units) &
        final_low_income_value != pass2_published_low_income_units,
      .N
    ] > 0L ||
    decisions[
      !is.na(pass2_published_total_units) &
        pass2_published_total_units <= 0,
      .N
    ] > 0L ||
    decisions[
      !is.na(pass2_published_low_income_units) &
        pass2_published_low_income_units < 0,
      .N
    ] > 0L ||
    decisions[
      !is.na(pass2_published_total_units) &
        !is.na(pass2_published_low_income_units) &
        pass2_published_low_income_units > pass2_published_total_units,
      .N
    ] > 0L) {
  stop("A published development count and final decision disagree.",
    call. = FALSE)
}

if (any(decisions$pass1_reviewed_on > decisions$pass2_reviewed_on) ||
    any(decisions$pass2_reviewed_on > decisions$final_reviewed_on) ||
    anyNA(decisions$source_rows_changed) ||
    any(decisions$source_rows_changed)) {
  stop("Review dates or source-row safeguards are invalid.",
    call. = FALSE)
}

allowed_pass1_member_roles <- c(
  "candidate_representative",
  "candidate_component",
  "candidate_duplicate",
  "candidate_superseded",
  "evidence_only",
  "unresolved_pending_outside_read"
)
allowed_final_member_roles <- c(
  "select_representative",
  "include_component",
  "exclude_duplicate",
  "exclude_superseded",
  "evidence_only"
)
allowed_value_sources <- c(
  "reconciled_episode",
  "original_hud",
  "none"
)
allowed_member_reasons <- c(
  "selected_reporting_representative",
  "distinct_component_included",
  "current_configuration_selected",
  "duplicate_reporting_excluded",
  "superseded_configuration_excluded",
  "external_value_not_episode_allocated",
  "episode_specific_no_static_value",
  "no_reliable_value_after_search",
  "source_value_recovered"
)
if (any(!member_decisions$pass1_total_member_role %chin%
      allowed_pass1_member_roles) ||
    any(!member_decisions$pass1_low_income_member_role %chin%
      allowed_pass1_member_roles) ||
    any(!member_decisions$final_total_member_role %chin%
      allowed_final_member_roles) ||
    any(!member_decisions$final_low_income_member_role %chin%
      allowed_final_member_roles) ||
    any(!member_decisions$final_total_value_source %chin%
      allowed_value_sources) ||
    any(!member_decisions$final_low_income_value_source %chin%
      allowed_value_sources) ||
    any(!member_decisions$final_total_member_reason_code %chin%
      allowed_member_reasons) ||
    any(!member_decisions$final_low_income_member_reason_code %chin%
      allowed_member_reasons)) {
  stop("A member role, source, or reason code is invalid.",
    call. = FALSE)
}

member_check <- members[, .(
  unit_scope_question_id,
  development_id,
  hud_id,
  episode_units,
  episode_low_income_units,
  original_total_units = suppressWarnings(as.numeric(n_units)),
  original_low_income_units = suppressWarnings(as.numeric(li_units))
)]
member_fields <- setdiff(member_columns, c(
  "unit_scope_question_id",
  "development_id",
  "hud_id",
  "member_notes"
))
member_check[member_decisions, (member_fields) :=
  mget(paste0("i.", member_fields)),
on = c("unit_scope_question_id", "development_id", "hud_id")]
member_check[decisions[, .(
  unit_scope_question_id,
  pass1_total_action,
  pass1_low_income_action,
  final_total_action,
  final_low_income_action
)], `:=`(
  pass1_total_action = i.pass1_total_action,
  pass1_low_income_action = i.pass1_low_income_action,
  final_total_action = i.final_total_action,
  final_low_income_action = i.final_low_income_action
), on = "unit_scope_question_id"]

total_only_low_income_sums <- decisions[
  pass2_source_coverage == "development_total_only" &
    final_low_income_action == "sum_selected_components",
  unit_scope_question_id
]
if (decisions[
      unit_scope_question_id %chin% total_only_low_income_sums & (
        final_total_action != "sum_selected_components" |
          pass2_published_total_count_type != "exact" |
          is.na(pass2_published_total_units) |
          final_total_value != pass2_published_total_units
      ),
      .N
    ] > 0L ||
    member_check[
      unit_scope_question_id %chin% total_only_low_income_sums,
      .(
        same_component_set = all(
          (final_total_member_role == "include_component") ==
            (final_low_income_member_role == "include_component")
        )
      ),
      by = unit_scope_question_id
    ][same_component_set == FALSE, .N] > 0L) {
  stop(
    paste(
      "A low-income component sum supported by a total-only source",
      "does not use the validated total component set."
    ),
    call. = FALSE
  )
}

member_check[, selected_total_value := fcase(
  final_total_value_source == "reconciled_episode",
  episode_units,
  final_total_value_source == "original_hud",
  original_total_units,
  default = NA_real_
)]
member_check[, selected_low_income_value := fcase(
  final_low_income_value_source == "reconciled_episode",
  episode_low_income_units,
  final_low_income_value_source == "original_hud",
  original_low_income_units,
  default = NA_real_
)]

total_value_role <- member_check$final_total_member_role %chin% c(
  "select_representative",
  "include_component"
)
low_income_value_role <-
  member_check$final_low_income_member_role %chin% c(
    "select_representative",
    "include_component"
  )
if (any(total_value_role &
      member_check$final_total_value_source == "none") ||
    any(!total_value_role &
      member_check$final_total_value_source != "none") ||
    any(total_value_role &
      (is.na(member_check$selected_total_value) |
        member_check$selected_total_value <= 0)) ||
    any(low_income_value_role &
      member_check$final_low_income_value_source == "none") ||
    any(!low_income_value_role &
      member_check$final_low_income_value_source != "none") ||
    any(low_income_value_role &
      (is.na(member_check$selected_low_income_value) |
        member_check$selected_low_income_value < 0))) {
  stop("A value-bearing member role has an invalid source value.",
    call. = FALSE)
}

member_reason_contract <- data.table(
  role = allowed_final_member_roles,
  allowed_reasons = list(
    c(
      "selected_reporting_representative",
      "current_configuration_selected",
      "source_value_recovered"
    ),
    "distinct_component_included",
    "duplicate_reporting_excluded",
    "superseded_configuration_excluded",
    c(
      "external_value_not_episode_allocated",
      "episode_specific_no_static_value",
      "no_reliable_value_after_search"
    )
  )
)
total_member_reasons <- member_reason_contract[
  member_check,
  on = c(role = "final_total_member_role")
]
low_income_member_reasons <- member_reason_contract[
  member_check,
  on = c(role = "final_low_income_member_role")
]
valid_total_member_reason <- mapply(
  function(value, allowed) value %chin% allowed,
  member_check$final_total_member_reason_code,
  total_member_reasons$allowed_reasons
)
valid_low_income_member_reason <- mapply(
  function(value, allowed) value %chin% allowed,
  member_check$final_low_income_member_reason_code,
  low_income_member_reasons$allowed_reasons
)
if (any(!valid_total_member_reason) ||
    any(!valid_low_income_member_reason)) {
  stop("A member role and reason code are incompatible.", call. = FALSE)
}

if (member_check[
      pass1_total_action == "candidate_use_once" &
        !pass1_total_member_role %chin% c(
          "candidate_representative",
          "candidate_duplicate"
        ),
      .N
    ] > 0L ||
    member_check[
      pass1_total_action == "candidate_sum_components" &
        !pass1_total_member_role %chin% c(
          "candidate_component",
          "candidate_duplicate",
          "candidate_superseded"
        ),
      .N
    ] > 0L ||
    member_check[
      pass1_total_action == "candidate_select_episode" &
        !pass1_total_member_role %chin% c(
          "candidate_representative",
          "candidate_duplicate",
          "candidate_superseded"
        ),
      .N
    ] > 0L ||
    member_check[
      pass1_total_action %chin% c(
        "candidate_external_value_needed",
        "candidate_episode_specific",
        "defer_outside_read"
      ) &
        !pass1_total_member_role %chin% c(
          "evidence_only",
          "unresolved_pending_outside_read"
        ),
      .N
    ] > 0L ||
    member_check[
      pass1_low_income_action == "candidate_use_once" &
        !pass1_low_income_member_role %chin% c(
          "candidate_representative",
          "candidate_duplicate"
        ),
      .N
    ] > 0L ||
    member_check[
      pass1_low_income_action == "candidate_sum_components" &
        !pass1_low_income_member_role %chin% c(
          "candidate_component",
          "candidate_duplicate",
          "candidate_superseded"
        ),
      .N
    ] > 0L ||
    member_check[
      pass1_low_income_action == "candidate_select_episode" &
        !pass1_low_income_member_role %chin% c(
          "candidate_representative",
          "candidate_duplicate",
          "candidate_superseded"
        ),
      .N
    ] > 0L ||
    member_check[
      pass1_low_income_action %chin% c(
        "candidate_external_value_needed",
        "candidate_episode_specific",
        "defer_outside_read"
      ) &
        !pass1_low_income_member_role %chin% c(
          "evidence_only",
          "unresolved_pending_outside_read"
        ),
      .N
    ] > 0L) {
  stop("A first-read action and member role are incompatible.",
    call. = FALSE)
}

if (member_check[
      final_total_action == "use_once_reporting_value" &
        !final_total_member_role %chin% c(
          "select_representative",
          "exclude_duplicate"
        ),
      .N
    ] > 0L ||
    member_check[
      final_total_action == "sum_selected_components" &
        !final_total_member_role %chin% c(
          "include_component",
          "exclude_duplicate",
          "exclude_superseded"
        ),
      .N
    ] > 0L ||
    member_check[
      final_total_action == "select_current_episode_value" &
        !final_total_member_role %chin% c(
          "select_representative",
          "exclude_duplicate",
          "exclude_superseded"
        ),
      .N
    ] > 0L ||
    member_check[
      final_total_action %chin% c(
        "use_external_property_value",
        "retain_episode_specific_no_static_value",
        "unavailable_after_review"
      ) & final_total_member_role != "evidence_only",
      .N
    ] > 0L ||
    member_check[
      final_low_income_action == "use_once_reporting_value" &
        !final_low_income_member_role %chin% c(
          "select_representative",
          "exclude_duplicate"
        ),
      .N
    ] > 0L ||
    member_check[
      final_low_income_action == "sum_selected_components" &
        !final_low_income_member_role %chin% c(
          "include_component",
          "exclude_duplicate",
          "exclude_superseded"
        ),
      .N
    ] > 0L ||
    member_check[
      final_low_income_action == "select_current_episode_value" &
        !final_low_income_member_role %chin% c(
          "select_representative",
          "exclude_duplicate",
          "exclude_superseded"
        ),
      .N
    ] > 0L ||
    member_check[
      final_low_income_action %chin% c(
        "use_external_property_value",
        "retain_episode_specific_no_static_value",
        "unavailable_after_review"
      ) & final_low_income_member_role != "evidence_only",
      .N
    ] > 0L) {
  stop("A final action and member role are incompatible.",
    call. = FALSE)
}

if (member_check[
      final_total_action == "use_once_reporting_value" &
        final_total_member_role == "select_representative" &
        final_total_member_reason_code !=
          "selected_reporting_representative",
      .N
    ] > 0L ||
    member_check[
      final_total_action == "sum_selected_components" &
        final_total_member_role == "include_component" &
        final_total_member_reason_code != "distinct_component_included",
      .N
    ] > 0L ||
    member_check[
      final_total_action == "select_current_episode_value" &
        final_total_member_role == "select_representative" &
        !final_total_member_reason_code %chin% c(
          "current_configuration_selected",
          "source_value_recovered"
        ),
      .N
    ] > 0L ||
    member_check[
      final_total_action == "use_external_property_value" &
        final_total_member_reason_code !=
          "external_value_not_episode_allocated",
      .N
    ] > 0L ||
    member_check[
      final_total_action ==
        "retain_episode_specific_no_static_value" &
        final_total_member_reason_code !=
          "episode_specific_no_static_value",
      .N
    ] > 0L ||
    member_check[
      final_total_action == "unavailable_after_review" &
        final_total_member_reason_code !=
          "no_reliable_value_after_search",
      .N
    ] > 0L ||
    member_check[
      final_low_income_action == "use_once_reporting_value" &
        final_low_income_member_role == "select_representative" &
        final_low_income_member_reason_code !=
          "selected_reporting_representative",
      .N
    ] > 0L ||
    member_check[
      final_low_income_action == "sum_selected_components" &
        final_low_income_member_role == "include_component" &
        final_low_income_member_reason_code !=
          "distinct_component_included",
      .N
    ] > 0L ||
    member_check[
      final_low_income_action == "select_current_episode_value" &
        final_low_income_member_role == "select_representative" &
        !final_low_income_member_reason_code %chin% c(
          "current_configuration_selected",
          "source_value_recovered"
        ),
      .N
    ] > 0L ||
    member_check[
      final_low_income_action == "use_external_property_value" &
        final_low_income_member_reason_code !=
          "external_value_not_episode_allocated",
      .N
    ] > 0L ||
    member_check[
      final_low_income_action ==
        "retain_episode_specific_no_static_value" &
        final_low_income_member_reason_code !=
          "episode_specific_no_static_value",
      .N
    ] > 0L ||
    member_check[
      final_low_income_action == "unavailable_after_review" &
        final_low_income_member_reason_code !=
          "no_reliable_value_after_search",
      .N
    ] > 0L) {
  stop("A final action and member reason code are incompatible.",
    call. = FALSE)
}

arithmetic <- member_check[, .(
  n_episode_members = .N,
  n_pass1_total_representatives = sum(
    pass1_total_member_role == "candidate_representative"
  ),
  n_pass1_total_components = sum(
    pass1_total_member_role == "candidate_component"
  ),
  n_pass1_low_income_representatives = sum(
    pass1_low_income_member_role == "candidate_representative"
  ),
  n_pass1_low_income_components = sum(
    pass1_low_income_member_role == "candidate_component"
  ),
  n_total_representatives = sum(
    final_total_member_role == "select_representative"
  ),
  n_total_components = sum(
    final_total_member_role == "include_component"
  ),
  n_total_evidence_only = sum(
    final_total_member_role == "evidence_only"
  ),
  reconstructed_total = sum(
    selected_total_value[
      final_total_member_role %chin% c(
        "select_representative",
        "include_component"
      )
    ],
    na.rm = TRUE
  ),
  n_low_income_representatives = sum(
    final_low_income_member_role == "select_representative"
  ),
  n_low_income_components = sum(
    final_low_income_member_role == "include_component"
  ),
  n_low_income_evidence_only = sum(
    final_low_income_member_role == "evidence_only"
  ),
  reconstructed_low_income = sum(
    selected_low_income_value[
      final_low_income_member_role %chin% c(
        "select_representative",
        "include_component"
      )
    ],
    na.rm = TRUE
  )
), by = unit_scope_question_id]
arithmetic[decisions, `:=`(
  pass1_total_action = i.pass1_total_action,
  pass1_low_income_action = i.pass1_low_income_action,
  final_total_action = i.final_total_action,
  final_total_value = i.final_total_value,
  final_low_income_action = i.final_low_income_action,
  final_low_income_value = i.final_low_income_value
), on = "unit_scope_question_id"]

if (arithmetic[
      pass1_total_action %chin% c(
        "candidate_use_once",
        "candidate_select_episode"
      ) &
        (n_pass1_total_representatives != 1L |
          n_pass1_total_components != 0L),
      .N
    ] > 0L ||
    arithmetic[
      pass1_total_action == "candidate_sum_components" &
        (n_pass1_total_representatives != 0L |
          n_pass1_total_components < 2L),
      .N
    ] > 0L ||
    arithmetic[
      !pass1_total_action %chin% c(
        "candidate_use_once",
        "candidate_sum_components",
        "candidate_select_episode"
      ) &
        (n_pass1_total_representatives != 0L |
          n_pass1_total_components != 0L),
      .N
    ] > 0L ||
    arithmetic[
      pass1_low_income_action %chin% c(
        "candidate_use_once",
        "candidate_select_episode"
      ) &
        (n_pass1_low_income_representatives != 1L |
          n_pass1_low_income_components != 0L),
      .N
    ] > 0L ||
    arithmetic[
      pass1_low_income_action == "candidate_sum_components" &
        (n_pass1_low_income_representatives != 0L |
          n_pass1_low_income_components < 2L),
      .N
    ] > 0L ||
    arithmetic[
      !pass1_low_income_action %chin% c(
        "candidate_use_once",
        "candidate_sum_components",
        "candidate_select_episode"
      ) &
        (n_pass1_low_income_representatives != 0L |
          n_pass1_low_income_components != 0L),
      .N
    ] > 0L) {
  stop("A first-read action fails its member-role count contract.",
    call. = FALSE)
}

if (arithmetic[
      final_total_action %chin% c(
        "use_once_reporting_value",
        "select_current_episode_value"
      ) &
        (n_total_representatives != 1L |
          n_total_components != 0L |
          reconstructed_total != final_total_value),
      .N
    ] > 0L ||
    arithmetic[
      final_total_action == "sum_selected_components" &
        (n_total_representatives != 0L |
          n_total_components < 2L |
          reconstructed_total != final_total_value),
      .N
    ] > 0L ||
    arithmetic[
      final_total_action %chin% c(
        "use_external_property_value",
        "retain_episode_specific_no_static_value",
        "unavailable_after_review"
      ) &
        (n_total_representatives != 0L |
          n_total_components != 0L |
          n_total_evidence_only != n_episode_members),
      .N
    ] > 0L ||
    arithmetic[
      final_low_income_action %chin% c(
        "use_once_reporting_value",
        "select_current_episode_value"
      ) &
        (n_low_income_representatives != 1L |
          n_low_income_components != 0L |
          reconstructed_low_income != final_low_income_value),
      .N
    ] > 0L ||
    arithmetic[
      final_low_income_action == "sum_selected_components" &
        (n_low_income_representatives != 0L |
          n_low_income_components < 2L |
          reconstructed_low_income != final_low_income_value),
      .N
    ] > 0L ||
    arithmetic[
      final_low_income_action %chin% c(
        "use_external_property_value",
        "retain_episode_specific_no_static_value",
        "unavailable_after_review"
      ) &
        (n_low_income_representatives != 0L |
          n_low_income_components != 0L |
          n_low_income_evidence_only != n_episode_members),
      .N
    ] > 0L) {
  stop("A final unit value fails independent member arithmetic.",
    call. = FALSE)
}

setorder(decisions, unit_scope_question_id)
setorder(
  member_decisions,
  unit_scope_question_id,
  development_id,
  hud_id
)
write_parquet(
  decisions,
  "../output/lihtc_unit_scope_question_decisions.parquet",
  compression = "zstd"
)
write_parquet(
  member_decisions,
  "../output/lihtc_unit_scope_member_decisions.parquet",
  compression = "zstd"
)

decisions_round_trip <- as.data.table(read_parquet(
  "../output/lihtc_unit_scope_question_decisions.parquet"
))
member_decisions_round_trip <- as.data.table(read_parquet(
  "../output/lihtc_unit_scope_member_decisions.parquet"
))
if (!isTRUE(all.equal(decisions, decisions_round_trip)) ||
    !isTRUE(all.equal(member_decisions, member_decisions_round_trip))) {
  stop("A unit-scope decision Parquet round trip changed data.",
    call. = FALSE)
}

message(
  "Validated ",
  format(nrow(decisions), big.mark = ","),
  " unit-scope decisions and ",
  format(nrow(member_decisions), big.mark = ","),
  " episode-member decisions."
)
