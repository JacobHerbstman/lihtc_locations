# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/prepare_lihtc_compound_address_review/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
  library(stringr)
})

site <- as.data.table(read_parquet(
  "../input/lihtc_final_site_geocoding_readiness.parquet"
))

if (nrow(site) != 131473L ||
    uniqueN(site$development_site_id) != nrow(site) ||
    uniqueN(site, by = c("development_id", "site_key")) != nrow(site)) {
  stop("The final site input count or key changed.", call. = FALSE)
}

questions <- copy(site[flag_multiple_addresses == TRUE])
setorder(questions, development_site_id)
questions[, compound_address_question_id := sprintf(
  "CAQ_%05d",
  seq_len(.N)
)]

number_token <- "[0-9]+[A-Z]?"
separator <- "(?:,[[:space:]]*(?:AND|&AMP;|&|\\+|/)|,|;|AND|&AMP;|&|\\+|/)"
shared_tail_pattern <- paste0(
  "^(?=", number_token, "[[:space:]]*", separator, ")(",
  number_token, "(?:[[:space:]]*", separator, "[[:space:]]*",
  number_token, ")+)[[:space:]]+([A-Z].*)$"
)
full_component <- paste0(
  "[[:space:]]*", number_token,
  "[[:space:]]+[A-Z][^;]*[[:space:]]*"
)
full_semicolon_pattern <- paste0(
  "^", full_component, ";", full_component,
  "(?:;", full_component, ")*$"
)

questions[, source_street := str_to_upper(str_squish(site_street))]
questions[, shared_match := regmatches(
  source_street,
  regexec(shared_tail_pattern, source_street, perl = TRUE)
)]
questions[, shared_numbers := vapply(
  shared_match,
  function(value) if (length(value) == 0L) NA_character_ else value[2L],
  character(1L)
)]
questions[, shared_tail := vapply(
  shared_match,
  function(value) if (length(value) == 0L) NA_character_ else value[3L],
  character(1L)
)]
questions[, shared_number_vector := strsplit(
  str_replace_all(
    shared_numbers,
    "[[:space:]]*(,|;|AND|&AMP;|&|\\+|/)[[:space:]]*",
    "|"
  ),
  "|",
  fixed = TRUE
)]
questions[, shared_equal_digit_length := vapply(
  shared_number_vector,
  function(value) {
    value <- value[!is.na(value)]
    length(value) > 1L &&
      length(unique(nchar(str_remove(value, "[A-Z]$")))) == 1L
  },
  logical(1L)
)]
questions[, shared_tail_has_nested_address := str_detect(
  shared_tail,
  paste0(separator, "[[:space:]]*", number_token, "(?:[[:space:]]|$)")
)]
questions[is.na(shared_tail_has_nested_address),
  shared_tail_has_nested_address := FALSE]
questions[, full_semicolon_components := str_detect(
  source_street,
  full_semicolon_pattern
)]
questions[, strict_parse_candidate :=
  full_semicolon_components |
    (!is.na(shared_numbers) & shared_equal_digit_length &
      !shared_tail_has_nested_address)]
questions[, parser_class := fcase(
  full_semicolon_components,
  "complete_semicolon_components",
  strict_parse_candidate,
  "complete_number_list_shared_street_tail",
  str_detect(source_street, ";"),
  "manual_semicolon_expression",
  str_detect(source_street, "[0-9]+[[:space:]]*/[[:space:]]*[0-9]+"),
  "manual_slash_expression",
  str_detect(source_street, "[[:space:]](&AMP;|&|AND)[[:space:]]"),
  "manual_conjunction_expression",
  str_detect(source_street, "[[:space:]][+][[:space:]]*[0-9]+"),
  "manual_plus_expression",
  default = "manual_other_compound_expression"
)]

proposals <- questions[strict_parse_candidate == TRUE, {
  component_street <- if (full_semicolon_components) {
    str_squish(unlist(strsplit(source_street, ";", fixed = TRUE)))
  } else {
    paste(shared_number_vector[[1L]], shared_tail)
  }
  .(
    proposed_component_rank = seq_along(component_street),
    proposed_component_street = component_street
  )
}, by = .(
  compound_address_question_id,
  development_site_id,
  development_id,
  site_city,
  site_state,
  site_zip,
  parser_class
)]
proposals[, proposed_component_id := sprintf(
  "%s_COMPONENT_%02d",
  compound_address_question_id,
  proposed_component_rank
)]
proposals[, proposed_component_key := paste(
  str_to_upper(str_squish(proposed_component_street)),
  str_to_upper(str_squish(site_city)),
  str_to_upper(str_squish(site_state)),
  fcoalesce(str_to_upper(str_squish(site_zip)), ""),
  sep = "|"
)]

proposal_key_counts <- proposals[, .(
  proposed_key_n_components = .N,
  proposed_key_n_source_sites = uniqueN(development_site_id)
), by = .(development_id, proposed_component_key)]
proposals[proposal_key_counts, `:=`(
  proposed_key_n_components = i.proposed_key_n_components,
  proposed_key_n_source_sites = i.proposed_key_n_source_sites
), on = c("development_id", "proposed_component_key")]

existing_site_keys <- unique(site[flag_multiple_addresses == FALSE, .(
  development_id,
  existing_site_id = development_site_id,
  proposed_component_key = paste(
    str_to_upper(str_squish(site_street)),
    str_to_upper(str_squish(site_city)),
    str_to_upper(str_squish(site_state)),
    fcoalesce(str_to_upper(str_squish(site_zip)), ""),
    sep = "|"
  )
)], by = c("development_id", "proposed_component_key"))
proposals[existing_site_keys, existing_site_id := i.existing_site_id,
  on = c("development_id", "proposed_component_key")]
proposals[, `:=`(
  collision_with_another_proposal = proposed_key_n_source_sites > 1L,
  collision_with_existing_site = !is.na(existing_site_id),
  submission_approval = "not_approved"
)]

proposal_summary <- proposals[, .(
  n_proposed_components = .N,
  n_unique_proposed_component_keys = uniqueN(proposed_component_key),
  has_proposal_collision = any(collision_with_another_proposal),
  has_existing_site_collision = any(collision_with_existing_site)
), by = compound_address_question_id]
questions[proposal_summary, `:=`(
  n_proposed_components = i.n_proposed_components,
  n_unique_proposed_component_keys =
    i.n_unique_proposed_component_keys,
  has_proposal_collision = i.has_proposal_collision,
  has_existing_site_collision = i.has_existing_site_collision
), on = "compound_address_question_id"]
questions[is.na(n_proposed_components), `:=`(
  n_proposed_components = 0L,
  n_unique_proposed_component_keys = 0L,
  has_proposal_collision = FALSE,
  has_existing_site_collision = FALSE
)]
questions[, parser_proposed_action := fifelse(
  strict_parse_candidate,
  "split_to_strict_components_for_review",
  "defer_for_manual_review"
)]
questions[, submission_approval := "not_approved"]

questions[, c("shared_match", "shared_number_vector") := NULL]
setcolorder(questions, c(
  "compound_address_question_id", "development_site_id",
  "development_id", "site_street", "site_city", "site_state",
  "site_zip", "parser_class", "strict_parse_candidate",
  "parser_proposed_action", "n_proposed_components",
  "n_unique_proposed_component_keys", "has_proposal_collision",
  "has_existing_site_collision", "submission_approval"
))
setcolorder(proposals, c(
  "proposed_component_id", "compound_address_question_id",
  "development_site_id", "development_id",
  "proposed_component_rank", "proposed_component_street",
  "site_city", "site_state", "site_zip", "parser_class",
  "proposed_component_key", "proposed_key_n_components",
  "proposed_key_n_source_sites", "collision_with_another_proposal",
  "collision_with_existing_site", "existing_site_id",
  "submission_approval"
))

if (nrow(questions) != 5114L ||
    uniqueN(questions$compound_address_question_id) != nrow(questions) ||
    uniqueN(questions$development_site_id) != nrow(questions) ||
    questions[strict_parse_candidate == TRUE, .N] != 4150L ||
    questions[strict_parse_candidate == FALSE, .N] != 964L ||
    nrow(proposals) != 11137L ||
    uniqueN(proposals$proposed_component_id) != nrow(proposals) ||
    proposals[, any(proposed_component_rank != seq_len(.N)),
      by = compound_address_question_id][V1 == TRUE, .N] > 0L ||
    any(proposals$submission_approval != "not_approved") ||
    any(questions$submission_approval != "not_approved")) {
  stop("A compound-address preparation invariant changed.", call. = FALSE)
}

setorder(questions, compound_address_question_id)
setorder(proposals, proposed_component_id)
write_parquet(
  questions,
  "../output/lihtc_compound_address_questions.parquet",
  compression = "zstd"
)
write_parquet(
  proposals,
  "../output/lihtc_compound_address_parse_proposals.parquet",
  compression = "zstd"
)

if (!identical(
  questions,
  as.data.table(read_parquet(
    "../output/lihtc_compound_address_questions.parquet"
  ))
) || !identical(
  proposals,
  as.data.table(read_parquet(
    "../output/lihtc_compound_address_parse_proposals.parquet"
  ))
)) {
  stop("A compound-address preparation Parquet changed on round trip.",
    call. = FALSE)
}

cat(
  "Prepared ", nrow(questions), " compound-address questions and ",
  nrow(proposals), " strict component proposals; none is approved.\n",
  sep = ""
)
