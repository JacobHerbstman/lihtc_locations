# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/prepare_lihtc_range_address_review/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
  library(stringr)
})

components <- as.data.table(read_parquet(
  "../input/lihtc_site_address_component_2024_compound_adjudicated.parquet"
))
site <- as.data.table(read_parquet(
  "../input/lihtc_final_site_geocoding_readiness.parquet"
))

if (nrow(components) != 137255L ||
    uniqueN(components$development_site_address_component_id) !=
      nrow(components) ||
    nrow(site) != 131473L ||
    uniqueN(site$development_site_id) != nrow(site)) {
  stop("A range-preparation input count or key changed.", call. = FALSE)
}

site_evidence <- site[, .(
  development_site_id,
  development_name_examples,
  state_id_examples,
  site_source,
  latitude,
  longitude,
  requires_site_review,
  flag_po_box,
  flag_administrative_address,
  flag_scattered_or_unknown_label,
  flag_building_label_only,
  flag_parcel_or_legal_description,
  flag_multiple_addresses,
  flag_unit_or_building,
  flag_malformed_text,
  flag_missing_structure_number,
  flag_missing_city,
  flag_missing_zip,
  flag_invalid_zip,
  flag_placeholder_zip,
  flag_source_site_inventory_review,
  flag_zip_state_internal_conflict,
  flag_zip_state_internal_ambiguity,
  flag_repeated_across_developments,
  flag_shared_base_zip_conflict,
  flag_upstream_site_review_pending
)]
components[site_evidence, `:=`(
  development_name_examples = i.development_name_examples,
  state_id_examples = i.state_id_examples,
  site_source = i.site_source,
  latitude = i.latitude,
  longitude = i.longitude,
  requires_site_review = i.requires_site_review,
  flag_po_box = i.flag_po_box,
  flag_administrative_address = i.flag_administrative_address,
  flag_scattered_or_unknown_label = i.flag_scattered_or_unknown_label,
  flag_building_label_only = i.flag_building_label_only,
  flag_parcel_or_legal_description = i.flag_parcel_or_legal_description,
  flag_multiple_addresses = i.flag_multiple_addresses,
  flag_unit_or_building = i.flag_unit_or_building,
  flag_malformed_text = i.flag_malformed_text,
  flag_missing_structure_number = i.flag_missing_structure_number,
  flag_missing_city = i.flag_missing_city,
  flag_missing_zip = i.flag_missing_zip,
  flag_invalid_zip = i.flag_invalid_zip,
  flag_placeholder_zip = i.flag_placeholder_zip,
  flag_source_site_inventory_review =
    i.flag_source_site_inventory_review,
  flag_zip_state_internal_conflict = i.flag_zip_state_internal_conflict,
  flag_zip_state_internal_ambiguity =
    i.flag_zip_state_internal_ambiguity,
  flag_repeated_across_developments =
    i.flag_repeated_across_developments,
  flag_shared_base_zip_conflict = i.flag_shared_base_zip_conflict,
  flag_upstream_site_review_pending = i.flag_upstream_site_review_pending
), on = "development_site_id"]

if (components[, anyNA(development_name_examples)] ||
    components[, anyNA(requires_site_review)]) {
  stop("Final site evidence did not join one-to-many safely.",
    call. = FALSE)
}

components[, range_street := str_to_upper(str_squish(component_street))]
range_parts <- str_match(
  components$range_street,
  "^([0-9]+)([A-Z]?)[[:space:]]*(-|TO)[[:space:]]*([0-9]+)([A-Z]?)"
)
components[, `:=`(
  range_start = suppressWarnings(as.integer(range_parts[, 2L])),
  range_start_suffix = range_parts[, 3L],
  range_delimiter = range_parts[, 4L],
  range_end = suppressWarnings(as.integer(range_parts[, 5L])),
  range_end_suffix = range_parts[, 6L]
)]
questions <- components[!is.na(range_start)]

ordinal_parts <- str_match(
  questions$range_street,
  paste0(
    "^([0-9]+)[[:space:]]*-[[:space:]]*",
    "([0-9]+(?:ST|ND|RD|TH)(?:[[:space:]].*)?)$"
  )
)
questions[, ordinal_single_address_proposal := fifelse(
  !is.na(ordinal_parts[, 2L]),
  str_squish(paste(ordinal_parts[, 2L], ordinal_parts[, 3L])),
  NA_character_
)]
questions[, syntax_class := fcase(
  !is.na(ordinal_single_address_proposal),
  "ordinal_street_false_positive",
  address_component_action == "retained_blocked_compound_source_cell",
  "compound_contains_range",
  range_delimiter == "TO",
  "word_to_interval",
  str_detect(range_street, "^[0-9]+[A-Z]?[[:space:]]+-") |
    str_detect(
      range_street,
      "^[0-9]+[A-Z]?[[:space:]]*-[[:space:]]+[0-9]+"
    ),
  "spaced_hyphen_interval_syntax",
  default = "tight_hyphen_ambiguous"
)]
questions[, range_tail := str_squish(str_replace(
  range_street,
  "^[0-9]+[A-Z]?[[:space:]]*(?:-|TO)[[:space:]]*[0-9]+[A-Z]?",
  ""
))]
questions[, `:=`(
  flag_range_end_below_start = range_end < range_start,
  flag_lettered_endpoint = range_start_suffix != "" |
    range_end_suffix != "",
  parser_proposed_action = fcase(
    syntax_class == "ordinal_street_false_positive",
    "normalize_single_ordinal_address_for_review",
    syntax_class == "compound_contains_range",
    "defer_unresolved_compound_range",
    default = "retain_literal_without_expansion_for_review"
  ),
  submission_approval = "not_approved"
)]
setorder(questions, development_site_address_component_id)
questions[, range_address_question_id := sprintf(
  "RAQ_%05d",
  seq_len(.N)
)]
setcolorder(questions, c(
  "range_address_question_id",
  "development_site_address_component_id", "development_site_id",
  "development_id", "component_street", "component_city",
  "component_state", "component_zip", "syntax_class", "range_start",
  "range_start_suffix", "range_delimiter", "range_end",
  "range_end_suffix", "range_tail", "flag_range_end_below_start",
  "flag_lettered_endpoint", "ordinal_single_address_proposal",
  "parser_proposed_action", "submission_approval"
))

expected_syntax_counts <- data.table(
  syntax_class = c(
    "compound_contains_range", "ordinal_street_false_positive",
    "spaced_hyphen_interval_syntax", "tight_hyphen_ambiguous",
    "word_to_interval"
  ),
  expected_n = c(53L, 383L, 922L, 7419L, 38L)
)
observed_syntax_counts <- questions[, .N, by = syntax_class]
expected_syntax_counts[observed_syntax_counts, observed_n := i.N,
  on = "syntax_class"]

if (nrow(questions) != 8815L ||
    uniqueN(questions$range_address_question_id) != nrow(questions) ||
    uniqueN(questions$development_site_address_component_id) !=
      nrow(questions) ||
    anyNA(expected_syntax_counts$observed_n) ||
    any(expected_syntax_counts$expected_n !=
      expected_syntax_counts$observed_n) ||
    questions[flag_range_end_below_start == TRUE, .N] != 1059L ||
    any(questions$submission_approval != "not_approved")) {
  stop("A range-address preparation invariant changed.", call. = FALSE)
}

write_parquet(
  questions,
  "../output/lihtc_range_address_questions.parquet",
  compression = "zstd"
)

if (!identical(
  questions,
  as.data.table(read_parquet(
    "../output/lihtc_range_address_questions.parquet"
  ))
)) {
  stop("The range-address question Parquet changed on round trip.",
    call. = FALSE)
}

cat(
  "Prepared ", nrow(questions),
  " range-address questions without expanding an endpoint; none is approved.\n",
  sep = ""
)
