# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/review_lihtc_compound_addresses/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
})

questions <- as.data.table(read_parquet(
  "../input/lihtc_compound_address_questions.parquet"
))
proposals <- as.data.table(read_parquet(
  "../input/lihtc_compound_address_parse_proposals.parquet"
))
review <- fread(
  "compound_address_question_reviews.csv",
  colClasses = "character",
  na.strings = "",
  strip.white = FALSE
)
components <- fread(
  "compound_address_component_reviews.csv",
  colClasses = "character",
  na.strings = "",
  strip.white = FALSE
)

review[, `:=`(
  strict_parse_candidate = strict_parse_candidate == "TRUE",
  n_proposed_components = as.integer(n_proposed_components),
  has_proposal_collision = has_proposal_collision == "TRUE",
  has_existing_site_collision = has_existing_site_collision == "TRUE",
  reads_agree = reads_agree == "TRUE"
)]
components[, `:=`(
  reviewed_component_rank = as.integer(reviewed_component_rank),
  collision_with_another_proposal =
    collision_with_another_proposal == "TRUE",
  collision_with_existing_site = collision_with_existing_site == "TRUE"
)]

required_review_text <- c(
  "review_1_method", "review_1_action", "review_1_reason",
  "review_1_notes", "review_1_on", "review_2_method",
  "review_2_action", "review_2_reason", "review_2_notes",
  "review_2_on", "final_action", "final_reason", "final_notes",
  "reviewed_on", "submission_approval"
)
allowed_read_actions <- c(
  "split_strict_components", "defer_manual",
  "retain_single_address", "exclude_nonphysical"
)
allowed_final_actions <- c(
  "split_to_reviewed_components", "retain_one_fractional_address",
  "defer_unresolved"
)

if (nrow(questions) != 5114L || nrow(proposals) != 11137L ||
    nrow(review) != nrow(questions) ||
    uniqueN(review$compound_address_question_id) != nrow(review) ||
    uniqueN(review$development_site_id) != nrow(review) ||
    !setequal(
      review$compound_address_question_id,
      questions$compound_address_question_id
    ) || !setequal(review$development_site_id, questions$development_site_id) ||
    review[, anyNA(.SD), .SDcols = required_review_text] ||
    review[, any(vapply(.SD, function(value) any(value == ""), logical(1L))),
      .SDcols = required_review_text] ||
    any(!review$review_1_action %chin% allowed_read_actions) ||
    any(!review$review_2_action %chin% allowed_read_actions) ||
    any(!review$final_action %chin% allowed_final_actions) ||
    any(review$review_1_on != "2026-08-12") ||
    any(review$review_2_on != "2026-08-12") ||
    any(review$reviewed_on != "2026-08-12") ||
    any(review$submission_approval != "not_approved")) {
  stop("The compound-address question-review contract failed.",
    call. = FALSE)
}

question_contract <- questions[, .(
  compound_address_question_id,
  development_site_id,
  development_id,
  source_site_street = site_street,
  source_site_city = site_city,
  source_site_state = site_state,
  source_site_zip = site_zip,
  parser_class,
  strict_parse_candidate,
  n_proposed_components,
  has_proposal_collision,
  has_existing_site_collision
)]
setorder(question_contract, compound_address_question_id)
review_contract <- review[, names(question_contract), with = FALSE]
setorder(review_contract, compound_address_question_id)

character_contract_columns <- c(
  "compound_address_question_id", "development_site_id", "development_id",
  "source_site_street", "source_site_city", "source_site_state",
  "source_site_zip", "parser_class"
)
if (any(vapply(
  character_contract_columns,
  function(column) !identical(
    fcoalesce(as.character(question_contract[[column]]), ""),
    fcoalesce(as.character(review_contract[[column]]), "")
  ),
  logical(1L)
)) || !identical(
  question_contract$strict_parse_candidate,
  review_contract$strict_parse_candidate
) || !identical(
  question_contract$n_proposed_components,
  review_contract$n_proposed_components
) || !identical(
  question_contract$has_proposal_collision,
  review_contract$has_proposal_collision
) || !identical(
  question_contract$has_existing_site_collision,
  review_contract$has_existing_site_collision
)) {
  stop("A frozen compound-address question field changed in review.",
    call. = FALSE)
}

review[, independently_agreed :=
  review_1_action == review_2_action &
    (review_1_action != "split_strict_components" |
      fcoalesce(review_1_component_streets, "") ==
        fcoalesce(review_2_component_streets, ""))]

if (any(review$reads_agree != review$independently_agreed) ||
    review[
      final_action == "split_to_reviewed_components" &
        (!reads_agree | review_1_action != "split_strict_components" |
          !strict_parse_candidate),
      .N
    ] > 0L ||
    review[
      final_action == "retain_one_fractional_address" &
        (!reads_agree | review_1_action != "retain_single_address" |
          !grepl("^[0-9]+[[:space:]]+[0-9]+/[0-9]+", source_site_street)),
      .N
    ] > 0L ||
    review[
      final_action != "defer_unresolved" & !reads_agree,
      .N
    ] > 0L ||
    review[final_action == "split_to_reviewed_components", .N] != 3309L ||
    review[final_action == "retain_one_fractional_address", .N] != 37L ||
    review[final_action == "defer_unresolved", .N] != 1768L) {
  stop("A final compound-address decision is not supported by two reads.",
    call. = FALSE)
}

approved_questions <- review[
  final_action == "split_to_reviewed_components",
  compound_address_question_id
]
expected_components <- proposals[
  compound_address_question_id %chin% approved_questions,
  .(
    compound_address_question_id,
    development_site_id,
    development_id,
    reviewed_component_rank = proposed_component_rank,
    reviewed_component_street = proposed_component_street,
    reviewed_component_city = site_city,
    reviewed_component_state = site_state,
    reviewed_component_zip = site_zip,
    parser_class,
    proposed_component_key,
    collision_with_another_proposal,
    collision_with_existing_site,
    existing_site_id
  )
]
component_contract <- components[, names(expected_components), with = FALSE]
setorder(expected_components, compound_address_question_id,
  reviewed_component_rank)
setorder(component_contract, compound_address_question_id,
  reviewed_component_rank)
reviewed_component_strings <- components[
  order(reviewed_component_rank),
  .(
    reviewed_component_streets = paste(
      reviewed_component_street,
      collapse = "|"
    )
  ),
  by = compound_address_question_id
]
split_support <- review[
  final_action == "split_to_reviewed_components",
  .(
    compound_address_question_id,
    review_1_component_streets,
    review_2_component_streets
  )
]
split_support[reviewed_component_strings,
  reviewed_component_streets := i.reviewed_component_streets,
  on = "compound_address_question_id"]

character_component_columns <- setdiff(
  names(expected_components),
  c(
    "reviewed_component_rank", "collision_with_another_proposal",
    "collision_with_existing_site"
  )
)
if (nrow(components) != 9091L ||
    uniqueN(components$reviewed_component_id) != nrow(components) ||
    nrow(expected_components) != nrow(components) ||
    any(vapply(
      character_component_columns,
      function(column) !identical(
        fcoalesce(as.character(expected_components[[column]]), ""),
        fcoalesce(as.character(component_contract[[column]]), "")
      ),
      logical(1L)
    )) || !identical(
      expected_components$reviewed_component_rank,
      component_contract$reviewed_component_rank
    ) || !identical(
      expected_components$collision_with_another_proposal,
      component_contract$collision_with_another_proposal
    ) || !identical(
      expected_components$collision_with_existing_site,
      component_contract$collision_with_existing_site
    ) || any(components$component_decision !=
      "retain_reviewed_address_component") ||
    any(components$component_reason !=
      "two_independent_reads_confirm_exact_parser_component") ||
    any(components$reviewed_on != "2026-08-12") ||
    any(components$submission_approval != "not_approved") ||
    split_support[, anyNA(reviewed_component_streets)] ||
    split_support[, any(
      review_1_component_streets != reviewed_component_streets |
        review_2_component_streets != reviewed_component_streets
    )] ||
    components[, any(reviewed_component_rank != seq_len(.N)),
      by = compound_address_question_id][V1 == TRUE, .N] > 0L) {
  stop("The reviewed compound-address component contract failed.",
    call. = FALSE)
}

review[, independently_agreed := NULL]
setorder(review, compound_address_question_id)
setorder(components, reviewed_component_id)
write_parquet(
  review,
  "../output/lihtc_compound_address_question_reviews.parquet",
  compression = "zstd"
)
write_parquet(
  components,
  "../output/lihtc_compound_address_component_reviews.parquet",
  compression = "zstd"
)

if (!identical(
  review,
  as.data.table(read_parquet(
    "../output/lihtc_compound_address_question_reviews.parquet"
  ))
) || !identical(
  components,
  as.data.table(read_parquet(
    "../output/lihtc_compound_address_component_reviews.parquet"
  ))
)) {
  stop("A compound-address review Parquet changed on round trip.",
    call. = FALSE)
}

cat(
  "Validated ", nrow(review), " two-read compound decisions and ",
  nrow(components), " explicit reviewed components; none is approved.\n",
  sep = ""
)
