# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/review_lihtc_cross_development_addresses/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
})

format_markdown_table <- function(table) {
  header <- paste0("| ", paste(names(table), collapse = " | "), " |")
  divider <- paste0(
    "| ", paste(rep("---", ncol(table)), collapse = " | "), " |"
  )
  rows <- apply(table, 1L, function(row) {
    paste0("| ", paste(row, collapse = " | "), " |")
  })
  c(header, divider, rows)
}

decisions <- fread(
  "cross_development_address_decisions.csv",
  na.strings = ""
)
questions <- as.data.table(read_parquet(
  "../input/lihtc_cross_development_identity_questions.parquet"
))
members <- as.data.table(read_parquet(
  paste0(
    "../input/",
    "lihtc_cross_development_identity_question_members.parquet"
  )
))

if (nrow(decisions) != 137L ||
    nrow(questions) != 137L ||
    nrow(members) != 279L ||
    uniqueN(decisions$identity_question_id) != nrow(decisions) ||
    uniqueN(questions$identity_question_id) != nrow(questions) ||
    uniqueN(members$development_id) != nrow(members) ||
    !setequal(
      decisions$identity_question_id,
      questions$identity_question_id
    ) ||
    !setequal(
      members$identity_question_id,
      questions$identity_question_id
    )) {
  stop("The review ledger does not cover its prepared queue exactly.",
    call. = FALSE)
}

required_fields <- c(
  "review_origin", "pass1_identity_decision", "pass1_reason_code",
  "pass1_notes", "pass1_reviewed_on", "pass2_identity_decision",
  "pass2_reason_code", "pass2_search_engine", "pass2_search_url",
  "pass2_source_title", "pass2_source_type", "pass2_source_url",
  "pass2_notes", "pass2_reviewed_on", "final_identity_decision",
  "final_reason_code", "address_overlap_class", "final_notes",
  "final_reviewed_on", "shared_geocoding_query_decision"
)
if (anyNA(decisions[, ..required_fields]) ||
    any(vapply(
      decisions[, ..required_fields],
      function(value) any(as.character(value) == ""),
      logical(1L)
    ))) {
  stop("A required review field is empty.", call. = FALSE)
}

if (!all(decisions$pass1_identity_decision %chin% c(
      "merge", "defer"
    )) ||
    !all(decisions$pass2_identity_decision %chin% c(
      "merge", "retain_separate"
    )) ||
    !all(decisions$final_identity_decision %chin% c(
      "merge", "retain_separate"
    )) ||
    any(decisions$pass2_identity_decision !=
      decisions$final_identity_decision) ||
    any(decisions$pass2_reason_code != decisions$final_reason_code) ||
    any(decisions$shared_geocoding_query_decision != "not_approved") ||
    any(decisions$source_rows_changed) ||
    !all(decisions$pass2_search_engine == "Google") ||
    !all(grepl("^https://", decisions$pass2_search_url)) ||
    !all(grepl("^https://", decisions$pass2_source_url)) ||
    any(grepl(
      "google.com/search",
      decisions$pass2_source_url,
      fixed = TRUE
    ))) {
  stop("A review decision or outside-source field is invalid.",
    call. = FALSE)
}

questions[, expected_review_origin := fifelse(
  review_scope == "carry_forward_completed_review",
  "carried_forward_completed_two_pass_review",
  "new_two_pass_review"
)]
origin_check <- questions[
  decisions,
  on = "identity_question_id"
]
if (any(origin_check$expected_review_origin != origin_check$review_origin) ||
    origin_check[
      review_scope == "carry_forward_completed_review" &
        (final_identity_decision != inherited_identity_decision |
          final_reason_code != inherited_identity_reason_code |
          pass2_source_url != inherited_outside_source_url),
      .N
    ] > 0L) {
  stop("A carried-forward decision changed during this review.",
    call. = FALSE)
}

date_fields <- c(
  "pass1_reviewed_on", "pass2_reviewed_on", "final_reviewed_on"
)
decisions[, (date_fields) := lapply(.SD, as.IDate),
  .SDcols = date_fields]
if (anyNA(decisions[, ..date_fields]) ||
    decisions[final_identity_decision == "merge", .N] != 113L ||
    decisions[final_identity_decision == "retain_separate", .N] != 24L ||
    decisions[review_origin ==
      "carried_forward_completed_two_pass_review", .N] != 8L ||
    decisions[review_origin == "new_two_pass_review", .N] != 129L) {
  stop("The review counts or dates changed.", call. = FALSE)
}

member_actions <- copy(members)
member_actions[, anchor_sort_year := fifelse(
  !is.na(first_pis_year),
  as.integer(first_pis_year),
  9999L
)]
anchors <- member_actions[
  order(
    identity_question_id,
    anchor_sort_year,
    development_anchor_hud_id,
    development_id
  ),
  .(
    adjudicated_development_id = first(development_id),
    adjudicated_development_anchor_hud_id =
      first(development_anchor_hud_id)
  ),
  by = identity_question_id
]
member_actions[decisions, `:=`(
  final_identity_decision = i.final_identity_decision,
  final_reason_code = i.final_reason_code,
  address_overlap_class = i.address_overlap_class,
  shared_geocoding_query_decision =
    i.shared_geocoding_query_decision
), on = "identity_question_id"]
member_actions[anchors, `:=`(
  adjudicated_development_id = i.adjudicated_development_id,
  adjudicated_development_anchor_hud_id =
    i.adjudicated_development_anchor_hud_id
), on = "identity_question_id"]
member_actions[, member_action := fifelse(
  final_identity_decision == "merge",
  "merge_identity_question",
  "retain_current_development"
)]
member_actions[final_identity_decision == "retain_separate", `:=`(
  adjudicated_development_id = development_id,
  adjudicated_development_anchor_hud_id = development_anchor_hud_id
)]
member_actions[, anchor_sort_year := NULL]

if (member_actions[
      final_identity_decision == "merge",
      .N
    ] != 226L ||
    member_actions[
      final_identity_decision == "retain_separate",
      .N
    ] != 53L ||
    member_actions[
      final_identity_decision == "merge",
      uniqueN(adjudicated_development_id)
    ] != 113L ||
    member_actions[
      final_identity_decision == "retain_separate",
      any(adjudicated_development_id != development_id)
    ] ||
    any(member_actions$shared_geocoding_query_decision !=
      "not_approved")) {
  stop("A member action does not implement its question decision.",
    call. = FALSE)
}

questions[, c(
  "expected_review_origin", "new_identity_decision",
  "shared_geocoding_query_decision", "source_rows_changed"
) := NULL]
decision_output <- questions[
  decisions,
  on = "identity_question_id"
]
setorder(decision_output, identity_question_id)
setorder(member_actions, identity_question_id, development_id)
setindexv(decision_output, NULL)
setindexv(member_actions, NULL)

reason_counts <- decision_output[, .(
  identity_questions = .N,
  development_members = sum(n_developments)
), by = .(
  final_identity_decision,
  final_reason_code
)][order(final_identity_decision, -identity_questions, final_reason_code)]
overlap_counts <- decision_output[, .(
  identity_questions = .N,
  development_members = sum(n_developments)
), by = address_overlap_class][
  order(-identity_questions, address_overlap_class)
]
summary_lines <- c(
  "# LIHTC Cross-Development Address Review",
  "",
  "## Results",
  "",
  "- Connected identity questions reviewed: 137.",
  "- Current development members reviewed: 279.",
  "- Questions merged to one physical development: 113.",
  "- Questions retained as separate physical developments: 24.",
  "- Shared geocoding queries approved: 0.",
  "- Source rows changed: 0.",
  "",
  "## Identity decisions",
  "",
  format_markdown_table(reason_counts),
  "",
  "## Address-overlap classes",
  "",
  format_markdown_table(overlap_counts),
  "",
  "## Interpretation",
  "",
  paste0(
    "A merge changes only the physical-development identifier. ",
    "Every HUD row remains a project episode and every site row remains ",
    "available. Retained portfolio overlaps, cross-listed sites, ",
    "placeholders, and campus cases require later source repair or ",
    "address review; none authorizes a shared coordinate query."
  ),
  ""
)

write_parquet(
  decision_output,
  "../output/lihtc_cross_development_address_decisions.parquet",
  compression = "zstd"
)
write_parquet(
  member_actions,
  paste0(
    "../output/",
    "lihtc_cross_development_address_member_decisions.parquet"
  ),
  compression = "zstd"
)
writeLines(summary_lines, "../output/review_summary.md")

if (nrow(as.data.table(read_parquet(
      "../output/lihtc_cross_development_address_decisions.parquet"
    ))) != 137L ||
    nrow(as.data.table(read_parquet(paste0(
      "../output/",
      "lihtc_cross_development_address_member_decisions.parquet"
    )))) != 279L) {
  stop("A review output failed its round trip.", call. = FALSE)
}

cat(
  "Validated 137 cross-development address questions: ",
  "113 merged and 24 retained; no query approved.\n",
  sep = ""
)
