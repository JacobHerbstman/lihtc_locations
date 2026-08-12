# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/review_lihtc_range_addresses/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
})

questions <- as.data.table(read_parquet(
  "../input/lihtc_range_address_questions.parquet"
))
review <- fread(
  "range_address_reviews.csv",
  colClasses = "character",
  na.strings = "",
  strip.white = FALSE
)

logical_columns <- c(
  "flag_range_end_below_start", "flag_lettered_endpoint",
  "reads_1_2_agree", "read_1_tiebreak_agree",
  "read_2_tiebreak_agree", "endpoint_expansion_applied"
)
review[, (logical_columns) := lapply(.SD, function(value) value == "TRUE"),
  .SDcols = logical_columns]
review[, `:=`(
  range_start = as.integer(range_start),
  range_end = as.integer(range_end)
)]
query_street_columns <- c(
  "review_1_query_street", "review_2_query_street",
  "tiebreak_query_street", "final_query_street"
)
review[, (query_street_columns) := lapply(.SD, function(value) {
  value[value == ""] <- NA_character_
  value
}), .SDcols = query_street_columns]

frozen_columns <- c(
  "range_address_question_id",
  "development_site_address_component_id", "development_site_id",
  "development_id", "source_component_street", "source_component_city",
  "source_component_state", "source_component_zip", "syntax_class",
  "range_start", "range_start_suffix", "range_delimiter", "range_end",
  "range_end_suffix", "range_tail", "flag_range_end_below_start",
  "flag_lettered_endpoint", "ordinal_single_address_proposal"
)
expected <- questions[, .(
  range_address_question_id,
  development_site_address_component_id,
  development_site_id,
  development_id,
  source_component_street = component_street,
  source_component_city = component_city,
  source_component_state = component_state,
  source_component_zip = component_zip,
  syntax_class,
  range_start,
  range_start_suffix,
  range_delimiter,
  range_end,
  range_end_suffix,
  range_tail,
  flag_range_end_below_start,
  flag_lettered_endpoint,
  ordinal_single_address_proposal
)]
observed <- review[, ..frozen_columns]
setorder(expected, range_address_question_id)
setorder(observed, range_address_question_id)

numeric_logical_columns <- c(
  "range_start", "range_end", "flag_range_end_below_start",
  "flag_lettered_endpoint"
)
character_frozen_columns <- setdiff(
  frozen_columns,
  numeric_logical_columns
)

required_text <- c(
  "review_1_method", "review_1_syntax_class", "review_1_action",
  "review_1_reason", "review_1_notes", "review_1_on",
  "review_2_method", "review_2_syntax_class", "review_2_action",
  "review_2_reason", "review_2_notes", "review_2_on", "final_action",
  "final_reason", "final_notes", "reviewed_on", "submission_approval"
)
allowed_actions <- c(
  "retain_literal_range_query", "normalize_single_ordinal_address",
  "defer_manual", "exclude_nonphysical"
)
query_actions <- c(
  "retain_literal_range_query", "normalize_single_ordinal_address"
)

if (nrow(questions) != 8815L || nrow(review) != nrow(questions) ||
    uniqueN(review$range_address_question_id) != nrow(review) ||
    uniqueN(review$development_site_address_component_id) != nrow(review) ||
    review[, anyNA(.SD), .SDcols = required_text] ||
    review[, any(vapply(.SD, function(value) any(value == ""), logical(1L))),
      .SDcols = required_text] ||
    any(!review$review_1_action %chin% allowed_actions) ||
    any(!review$review_2_action %chin% allowed_actions) ||
    any(!review$final_action %chin% allowed_actions) ||
    any(review$review_1_on != "2026-08-12") ||
    any(review$review_2_on != "2026-08-12") ||
    any(review$reviewed_on != "2026-08-12") ||
    any(review$submission_approval != "not_approved") ||
    review[
      review_1_action %chin% query_actions &
        is.na(review_1_query_street),
      .N
    ] > 0L ||
    review[
      !review_1_action %chin% query_actions &
        !is.na(review_1_query_street),
      .N
    ] > 0L ||
    review[
      review_2_action %chin% query_actions &
        is.na(review_2_query_street),
      .N
    ] > 0L ||
    review[
      !review_2_action %chin% query_actions &
        !is.na(review_2_query_street),
      .N
    ] > 0L ||
    review[
      !is.na(tiebreak_action) & tiebreak_action %chin% query_actions &
        is.na(tiebreak_query_street),
      .N
    ] > 0L ||
    review[
      !is.na(tiebreak_action) & !tiebreak_action %chin% query_actions &
        !is.na(tiebreak_query_street),
      .N
    ] > 0L ||
    any(vapply(
      character_frozen_columns,
      function(column) !identical(
        fcoalesce(as.character(expected[[column]]), ""),
        fcoalesce(as.character(observed[[column]]), "")
      ),
      logical(1L)
    )) || !identical(expected$range_start, observed$range_start) ||
    !identical(expected$range_end, observed$range_end) ||
    !identical(
      expected$flag_range_end_below_start,
      observed$flag_range_end_below_start
    ) || !identical(
      expected$flag_lettered_endpoint,
      observed$flag_lettered_endpoint
    )) {
  stop("The frozen range-question or review contract failed.",
    call. = FALSE)
}

review[, independently_agreed_1_2 :=
  review_1_action == review_2_action &
    (review_1_action %chin% c("defer_manual", "exclude_nonphysical") |
      fcoalesce(review_1_query_street, "") ==
        fcoalesce(review_2_query_street, ""))]
review[, independently_agreed_1_tiebreak :=
  !is.na(tiebreak_action) & review_1_action == tiebreak_action &
    (review_1_action %chin% c("defer_manual", "exclude_nonphysical") |
      fcoalesce(review_1_query_street, "") ==
        fcoalesce(tiebreak_query_street, ""))]
review[, independently_agreed_2_tiebreak :=
  !is.na(tiebreak_action) & review_2_action == tiebreak_action &
    (review_2_action %chin% c("defer_manual", "exclude_nonphysical") |
      fcoalesce(review_2_query_street, "") ==
      fcoalesce(tiebreak_query_street, ""))]
review[, final_query_read_support :=
  as.integer(
    review_1_action == final_action &
      !is.na(final_query_street) &
      !is.na(review_1_query_street) &
      review_1_query_street == final_query_street
  ) + as.integer(
    review_2_action == final_action &
      !is.na(final_query_street) &
      !is.na(review_2_query_street) &
      review_2_query_street == final_query_street
  ) + fifelse(
    is.na(tiebreak_action),
    0L,
    as.integer(
      tiebreak_action == final_action &
        !is.na(final_query_street) &
        !is.na(tiebreak_query_street) &
        tiebreak_query_street == final_query_street
    )
  )]

if (any(review$reads_1_2_agree != review$independently_agreed_1_2) ||
    any(review$read_1_tiebreak_agree !=
      review$independently_agreed_1_tiebreak) ||
    any(review$read_2_tiebreak_agree !=
      review$independently_agreed_2_tiebreak) ||
    review[reads_1_2_agree == FALSE & is.na(tiebreak_action), .N] > 0L ||
    review[reads_1_2_agree == TRUE & !is.na(tiebreak_action), .N] > 0L ||
    review[!is.na(tiebreak_action), .N] != 459L ||
    review[
      final_action != "defer_manual" &
        !(reads_1_2_agree | read_1_tiebreak_agree |
          read_2_tiebreak_agree),
      .N
    ] > 0L ||
    review[
      final_action == "retain_literal_range_query" &
        final_query_street != source_component_street,
      .N
    ] > 0L ||
    review[
      final_action == "normalize_single_ordinal_address" &
        (syntax_class != "ordinal_street_false_positive" |
          final_query_street != ordinal_single_address_proposal),
      .N
    ] > 0L ||
    review[
      final_action %chin% c("defer_manual", "exclude_nonphysical") &
        !is.na(final_query_street),
      .N
    ] > 0L ||
    review[
      final_action %chin% query_actions & final_query_read_support < 2L,
      .N
    ] > 0L ||
    review[final_action == "retain_literal_range_query", .N] != 665L ||
    review[final_action == "normalize_single_ordinal_address", .N] != 103L ||
    review[final_action == "defer_manual", .N] != 8045L ||
    review[final_action == "exclude_nonphysical", .N] != 2L ||
    any(review$endpoint_expansion_applied)) {
  stop("A final range decision lacks two-read support.", call. = FALSE)
}

review[, c(
  "independently_agreed_1_2", "independently_agreed_1_tiebreak",
  "independently_agreed_2_tiebreak", "final_query_read_support"
) := NULL]
setorder(review, range_address_question_id)
write_parquet(
  review,
  "../output/lihtc_range_address_reviews.parquet",
  compression = "zstd"
)

if (!identical(
  review,
  as.data.table(read_parquet(
    "../output/lihtc_range_address_reviews.parquet"
  ))
)) {
  stop("The range-address review Parquet changed on round trip.",
    call. = FALSE)
}

cat(
  "Validated ", nrow(review),
  " range decisions with no endpoint expansion; none is approved.\n",
  sep = ""
)
