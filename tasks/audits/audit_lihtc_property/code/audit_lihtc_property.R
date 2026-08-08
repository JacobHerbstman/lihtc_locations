# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/audit_lihtc_property/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
  library(stringr)
})

strict_numeric <- function(value) {
  !is.na(value) & str_detect(value, "^[+-]?(?:[0-9]+(?:\\.[0-9]+)?|\\.[0-9]+)$")
}

as_strict_numeric <- function(value) {
  parsed <- rep(NA_real_, length(value))
  valid <- strict_numeric(value)
  parsed[valid] <- as.numeric(value[valid])
  parsed
}

normalize_text <- function(value) {
  value <- iconv(value, from = "", to = "ASCII//TRANSLIT", sub = "")
  value <- str_to_upper(str_squish(value))
  value <- str_replace_all(value, "[^A-Z0-9]+", " ")
  str_squish(value)
}

number_summary <- function(value, statistic) {
  value <- value[!is.na(value)]
  if (length(value) == 0) {
    return(NA_real_)
  }
  as.numeric(statistic(value))
}

# Import the value-preserving analytical input and source claims.
raw <- as.data.table(read_parquet("../input/lihtc_property_2024_raw_text.parquet"))
dictionary <- fread("dictionary_claims.csv", colClasses = "character", na.strings = NULL)
validated_source <- fread("../input/lihtc_property_2024_files.csv")
workbook_structure <- fread("../output/workbook_structure.csv")

if (nrow(validated_source) != 1) {
  stop("The validated source manifest must contain exactly one row.", call. = FALSE)
}
if (nrow(raw) != as.integer(validated_source$project_rows)) {
  stop("Workbook row count differs from the validated source manifest.", call. = FALSE)
}
if (ncol(raw) != as.integer(validated_source$columns)) {
  stop("Workbook column count differs from the validated source manifest.", call. = FALSE)
}
if (any(names(raw) == "") || anyDuplicated(names(raw))) {
  stop("Workbook column names must be nonempty and unique.", call. = FALSE)
}
if (any(names(raw) != str_trim(names(raw)))) {
  stop("Workbook column names contain leading or trailing whitespace.", call. = FALSE)
}
if (anyDuplicated(dictionary$column) || any(is.na(dictionary$column))) {
  stop("Dictionary claims must have one nonmissing row per column.", call. = FALSE)
}
if (!identical(dictionary$column, names(raw))) {
  stop("Dictionary claims must match workbook columns and order exactly.", call. = FALSE)
}

release_year <- as.integer(validated_source$release_year)
source_row <- seq_len(nrow(raw)) + 1L

# Profile every field without assigning an analytical type.
column_profile <- rbindlist(lapply(seq_along(raw), function(column_index) {
  column <- names(raw)[column_index]
  value <- raw[[column]]
  claim <- dictionary[column_index, ]
  nonmissing <- !is.na(value)
  numeric_value <- as_strict_numeric(value)
  normalized_case_whitespace <- str_to_upper(str_squish(value))

  domain_violation <- rep(FALSE, length(value))
  if (claim$domain_rule == "exact") {
    allowed <- str_split(claim$allowed_values, "\\|", simplify = TRUE)
    domain_violation <- nonmissing & !(value %in% allowed)
  }
  if (claim$domain_rule == "year_with_sentinels") {
    sentinels <- str_split(claim$allowed_values, "\\|", simplify = TRUE)
    in_range <- !is.na(numeric_value) &
      numeric_value >= as.numeric(claim$valid_min) &
      numeric_value <= as.numeric(claim$valid_max)
    domain_violation <- nonmissing & !(value %in% sentinels) & !in_range
  }
  if (claim$domain_rule == "number") {
    domain_violation <- nonmissing & !strict_numeric(value)
  }
  if (claim$domain_rule == "fips_tract") {
    domain_violation <- nonmissing & !str_detect(value, "^[0-9X]{11}$")
  }
  if (claim$domain_rule == "hud_id") {
    domain_violation <- nonmissing & !str_detect(value, "^[A-Z]{3}[0-9]{4}[0-9X][0-9]{3}$")
  }

  data.table(
    column_order = column_index,
    column = column,
    documented_name = claim$documented_name,
    documented_type = claim$documented_type,
    domain_rule = claim$domain_rule,
    role = claim$role,
    n_rows = length(value),
    n_missing = sum(!nonmissing),
    missing_rate = mean(!nonmissing),
    n_distinct_raw = uniqueN(value, na.rm = TRUE),
    n_distinct_trimmed = uniqueN(str_trim(value), na.rm = TRUE),
    n_distinct_case_whitespace_normalized = uniqueN(normalized_case_whitespace, na.rm = TRUE),
    n_leading_or_trailing_whitespace = sum(nonmissing & value != str_trim(value)),
    n_repeated_whitespace = sum(nonmissing & str_detect(value, "[[:space:]]{2,}")),
    n_control_characters = sum(nonmissing & str_detect(value, "[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F\\x7F]")),
    n_null_like_strings = sum(nonmissing & str_to_upper(str_trim(value)) %in% c("NA", "N/A", "NULL", "NONE", ".", "-")),
    maximum_character_length = ifelse(any(nonmissing), max(nchar(value[nonmissing])), NA_integer_),
    n_strict_numeric = sum(strict_numeric(value)),
    strict_numeric_rate_among_nonmissing = ifelse(
      sum(nonmissing) > 0,
      sum(strict_numeric(value)) / sum(nonmissing),
      NA_real_
    ),
    n_leading_zero_integer_strings = sum(nonmissing & str_detect(value, "^0[0-9]+$")),
    n_noninteger_numeric = sum(!is.na(numeric_value) & abs(numeric_value - round(numeric_value)) > 1e-9),
    numeric_minimum = number_summary(numeric_value, min),
    numeric_p01 = number_summary(numeric_value, function(x) quantile(x, 0.01, names = FALSE)),
    numeric_median = number_summary(numeric_value, median),
    numeric_p99 = number_summary(numeric_value, function(x) quantile(x, 0.99, names = FALSE)),
    numeric_maximum = number_summary(numeric_value, max),
    n_documented_domain_violations = sum(domain_violation)
  )
}), use.names = TRUE)

top_value_frequencies <- rbindlist(lapply(names(raw), function(column) {
  frequencies <- data.table(value = raw[[column]], is_missing = is.na(raw[[column]]))[
    , .(n = .N), by = .(value, is_missing)
  ]
  setorder(frequencies, -n, is_missing, value, na.last = TRUE)
  frequencies <- head(frequencies, 25)
  frequencies[, `:=`(
    column = column,
    rank = seq_len(.N),
    share_of_rows = n / nrow(raw)
  )]
  setcolorder(frequencies, c("column", "rank", "is_missing", "value", "n", "share_of_rows"))
  frequencies
}), use.names = TRUE)

issue_rows <- list()
issue_index <- 0L

add_issues <- function(mask, issue_code, severity, decision_class, columns, observed_value, explanation) {
  indices <- which(mask %in% TRUE)
  if (length(indices) == 0) {
    return(invisible(NULL))
  }
  if (length(observed_value) == 1) {
    observed_value <- rep(observed_value, nrow(raw))
  }
  issue_index <<- issue_index + 1L
  issue_rows[[issue_index]] <<- data.table(
    source_row = source_row[indices],
    hud_id = raw$hud_id[indices],
    issue_code = issue_code,
    severity = severity,
    decision_class = decision_class,
    columns = columns,
    observed_value = str_trunc(observed_value[indices], 500),
    explanation = explanation
  )
  invisible(NULL)
}

# Record cell-level format and documented-domain conflicts.
for (column_index in seq_along(raw)) {
  column <- names(raw)[column_index]
  value <- raw[[column]]
  claim <- dictionary[column_index, ]
  nonmissing <- !is.na(value)
  numeric_value <- as_strict_numeric(value)

  add_issues(
    nonmissing & value != str_trim(value),
    "leading_or_trailing_whitespace",
    "low",
    "data-quality",
    column,
    value,
    "Raw value changes when leading and trailing whitespace are trimmed."
  )
  add_issues(
    nonmissing & str_detect(value, "[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F\\x7F]"),
    "control_character",
    "moderate",
    "data-quality",
    column,
    value,
    "Raw value contains a nonprinting control character."
  )
  add_issues(
    nonmissing & str_to_upper(str_trim(value)) %in% c("NA", "N/A", "NULL", "NONE", ".", "-"),
    "null_like_string",
    "low",
    "data-quality",
    column,
    value,
    "A literal string may be functioning as an undocumented missing-value code."
  )

  if (claim$domain_rule == "number") {
    add_issues(
      nonmissing & is.na(numeric_value),
      "documented_numeric_parse_failure",
      "high",
      "data-quality",
      column,
      value,
      "HUD documents the field as numeric, but the raw text is not a strict number."
    )
  }
  if (claim$domain_rule == "exact") {
    allowed <- str_split(claim$allowed_values, "\\|", simplify = TRUE)
    add_issues(
      nonmissing & !(value %in% allowed),
      "documented_code_violation",
      "moderate",
      "data-quality",
      column,
      value,
      paste0("Raw value is outside HUD's documented codes: ", claim$allowed_values, ".")
    )
  }
  if (claim$domain_rule == "year_with_sentinels") {
    sentinels <- str_split(claim$allowed_values, "\\|", simplify = TRUE)
    in_range <- !is.na(numeric_value) &
      numeric_value >= as.numeric(claim$valid_min) &
      numeric_value <= as.numeric(claim$valid_max)
    add_issues(
      nonmissing & !(value %in% sentinels) & !in_range,
      "dictionary_year_range_conflict",
      "moderate",
      "data-quality",
      column,
      value,
      paste0(
        "Raw value conflicts with HUD's stated year range ", claim$valid_min, "–", claim$valid_max,
        " and is not a documented sentinel (", claim$allowed_values,
        "); the documentation may be stale."
      )
    )
  }
  if (claim$domain_rule == "fips_tract") {
    add_issues(
      nonmissing & !str_detect(value, "^[0-9X]{11}$"),
      "documented_fips_format_violation",
      "moderate",
      "data-quality",
      column,
      value,
      "HUD documents an 11-character tract identifier with X replacing a missing county or tract component."
    )
  }
  if (claim$domain_rule == "hud_id") {
    add_issues(
      nonmissing & !str_detect(value, "^[A-Z]{3}[0-9]{4}[0-9X][0-9]{3}$"),
      "hud_id_format_violation",
      "high",
      "data-quality",
      column,
      value,
      paste(
        "HUD_ID does not follow the documented 3-letter agency, 4-digit year,",
        "1 update-position, and 3-digit record pattern."
      )
    )
  }
}

for (column in c(
  "hud_id", "project", "proj_add", "proj_cty", "proj_st", "proj_zip",
  "latitude", "longitude", "fips2020"
)) {
  add_issues(
    is.na(raw[[column]]),
    paste0("missing_", column),
    ifelse(column == "hud_id", "high", "moderate"),
    "data-quality",
    column,
    NA_character_,
    "A field needed to identify or locate a project is missing."
  )
}

add_issues(
  !is.na(raw$proj_st) & !str_detect(raw$proj_st, "^[A-Z]{2}$"),
  "state_code_format_violation",
  "moderate",
  "data-quality",
  "proj_st",
  raw$proj_st,
  "Project state is not a two-letter uppercase code."
)
add_issues(
  !is.na(raw$proj_zip) & !str_detect(raw$proj_zip, "^[0-9]{5}(?:-[0-9]{4})?$"),
  "zip_format_violation",
  "moderate",
  "data-quality",
  "proj_zip",
  raw$proj_zip,
  "Project ZIP is neither five digits nor ZIP+4."
)

latitude <- as_strict_numeric(raw$latitude)
longitude <- as_strict_numeric(raw$longitude)
add_issues(
  xor(is.na(raw$latitude), is.na(raw$longitude)),
  "coordinate_pair_incomplete",
  "high",
  "data-quality",
  "latitude|longitude",
  paste(raw$latitude, raw$longitude, sep = " | "),
  "Exactly one member of the latitude-longitude pair is missing."
)
add_issues(
  !is.na(latitude) & (latitude < -90 | latitude > 90),
  "latitude_outside_globe",
  "high",
  "data-quality",
  "latitude",
  raw$latitude,
  "Latitude is outside the mathematically possible range."
)
add_issues(
  !is.na(longitude) & (longitude < -180 | longitude > 180),
  "longitude_outside_globe",
  "high",
  "data-quality",
  "longitude",
  raw$longitude,
  "Longitude is outside the mathematically possible range."
)
add_issues(
  !is.na(latitude) & !is.na(longitude) & latitude == 0 & longitude == 0,
  "zero_coordinate_pair",
  "high",
  "data-quality",
  "latitude|longitude",
  paste(raw$latitude, raw$longitude, sep = " | "),
  "The coordinate pair is exactly zero-zero."
)

st2020 <- as_strict_numeric(raw$st2020)
cnty2020 <- as_strict_numeric(raw$cnty2020)
trct2020 <- as_strict_numeric(raw$trct2020)
integer_fips_components <- !is.na(st2020) & !is.na(cnty2020) & !is.na(trct2020) &
  st2020 == round(st2020) & cnty2020 == round(cnty2020) & trct2020 == round(trct2020)
complete_fips_components <- integer_fips_components & str_detect(raw$fips2020, "^[0-9]{11}$")
constructed_fips2020 <- ifelse(
  integer_fips_components,
  sprintf("%02d%03d%06d", as.integer(st2020), as.integer(cnty2020), as.integer(trct2020)),
  NA_character_
)
add_issues(
  complete_fips_components & constructed_fips2020 != raw$fips2020,
  "fips2020_component_mismatch",
  "high",
  "data-quality",
  "fips2020|st2020|cnty2020|trct2020",
  paste(raw$fips2020, constructed_fips2020, sep = " | constructed: "),
  "The published component fields do not concatenate to the published 2020 tract identifier."
)

yr_pis <- as_strict_numeric(raw$yr_pis)
yr_alloc <- as_strict_numeric(raw$yr_alloc)
year_sentinels <- c(8888, 9999)
calendar_yr_pis <- ifelse(yr_pis %in% year_sentinels, NA_real_, yr_pis)
calendar_yr_alloc <- ifelse(yr_alloc %in% year_sentinels, NA_real_, yr_alloc)
add_issues(
  !is.na(calendar_yr_pis) & calendar_yr_pis > release_year,
  "placed_in_service_after_release_window",
  "high",
  "data-quality",
  "yr_pis",
  raw$yr_pis,
  paste0("Placed-in-service year is later than the ", release_year, " database coverage stated by HUD.")
)
add_issues(
  !is.na(calendar_yr_alloc) & calendar_yr_alloc > release_year,
  "allocation_after_release_window",
  "high",
  "data-quality",
  "yr_alloc",
  raw$yr_alloc,
  paste0("Allocation year is later than the ", release_year, " database coverage stated by HUD.")
)
add_issues(
  !is.na(calendar_yr_pis) & !is.na(calendar_yr_alloc) & calendar_yr_alloc > calendar_yr_pis,
  "allocation_after_placed_in_service",
  "moderate",
  "data-quality",
  "yr_alloc|yr_pis",
  paste(raw$yr_alloc, raw$yr_pis, sep = " | "),
  "Allocation year is later than placed-in-service year; this may be valid but requires interpretation."
)

hud_id_year <- suppressWarnings(as.numeric(substr(raw$hud_id, 4, 7)))
add_issues(
  !is.na(hud_id_year) & !is.na(calendar_yr_pis) & hud_id_year >= 1987 & hud_id_year != calendar_yr_pis,
  "hud_id_year_disagrees_with_yr_pis",
  "moderate",
  "data-quality",
  "hud_id|yr_pis",
  paste(raw$hud_id, raw$yr_pis, sep = " | "),
  "The year encoded in HUD_ID differs from the published placed-in-service year."
)

count_columns <- c(
  "n_units", "li_units", "n_0br", "n_1br", "n_2br", "n_3br", "n_4br",
  "ceilunit", "n_unitsr", "li_unitr", "aff_yrs"
)
for (column in count_columns) {
  value <- as_strict_numeric(raw[[column]])
  add_issues(
    !is.na(value) & value < 0,
    "negative_count",
    "high",
    "data-quality",
    column,
    raw[[column]],
    "A unit or year count is negative."
  )
  add_issues(
    !is.na(value) & abs(value - round(value)) > 1e-9,
    "noninteger_count",
    "moderate",
    "data-quality",
    column,
    raw[[column]],
    "A unit or year count is not an integer."
  )
}

n_units <- as_strict_numeric(raw$n_units)
li_units <- as_strict_numeric(raw$li_units)
n_unitsr <- as_strict_numeric(raw$n_unitsr)
li_unitr <- as_strict_numeric(raw$li_unitr)
ceilunit <- as_strict_numeric(raw$ceilunit)
add_issues(
  !is.na(n_units) & !is.na(li_units) & li_units > n_units,
  "low_income_units_exceed_total_units",
  "high",
  "data-quality",
  "li_units|n_units",
  paste(raw$li_units, raw$n_units, sep = " | "),
  "Reported low-income units exceed reported total units."
)
add_issues(
  !is.na(n_unitsr) & !is.na(li_unitr) & li_unitr > n_unitsr,
  "replacement_low_income_units_exceed_total",
  "high",
  "data-quality",
  "li_unitr|n_unitsr",
  paste(raw$li_unitr, raw$n_unitsr, sep = " | "),
  "HUD's replacement low-income unit count exceeds its replacement total unit count."
)
add_issues(
  !is.na(ceilunit) & !is.na(li_units) & ceilunit > li_units,
  "lower_ceiling_units_exceed_low_income_units",
  "high",
  "data-quality",
  "ceilunit|li_units",
  paste(raw$ceilunit, raw$li_units, sep = " | "),
  "Units below the elected ceiling exceed reported low-income units."
)

bedroom_columns <- c("n_0br", "n_1br", "n_2br", "n_3br", "n_4br")
bedroom_values <- as.data.frame(lapply(raw[, ..bedroom_columns], as_strict_numeric))
bedroom_reported <- rowSums(!is.na(bedroom_values)) > 0
bedroom_sum <- rowSums(bedroom_values, na.rm = TRUE)
add_issues(
  bedroom_reported & !is.na(n_units) & bedroom_sum > n_units,
  "bedroom_counts_exceed_total_units",
  "high",
  "data-quality",
  paste(bedroom_columns, collapse = "|") |> paste0("|n_units"),
  paste(bedroom_sum, raw$n_units, sep = " | "),
  "The sum of reported bedroom categories exceeds total units."
)

amount_columns <- c("allocamt", "home_amt", "tcap_amt", "cdbg_amt", "htf_amt", "hpvi_amt", "tcep_amt", "qozf_amt")
for (column in amount_columns) {
  value <- as_strict_numeric(raw[[column]])
  add_issues(
    !is.na(value) & value < 0,
    "negative_funding_amount",
    "high",
    "data-quality",
    column,
    raw[[column]],
    "A reported funding or credit amount is negative."
  )
}

program_amount_pairs <- list(
  c("home", "home_amt"),
  c("tcap", "tcap_amt"),
  c("cdbg", "cdbg_amt"),
  c("htf", "htf_amt"),
  c("hopevi", "hpvi_amt"),
  c("tcep", "tcep_amt"),
  c("qozf", "qozf_amt")
)
for (pair in program_amount_pairs) {
  flag_column <- pair[1]
  amount_column <- pair[2]
  amount <- as_strict_numeric(raw[[amount_column]])
  add_issues(
    !is.na(amount) & amount > 0 & (is.na(raw[[flag_column]]) | raw[[flag_column]] != "1"),
    "positive_amount_without_yes_flag",
    "moderate",
    "data-quality",
    paste(flag_column, amount_column, sep = "|"),
    paste(raw[[flag_column]], raw[[amount_column]], sep = " | "),
    "A positive program amount is reported without the corresponding Yes code."
  )
  add_issues(
    raw[[flag_column]] == "1" & (is.na(amount) | amount == 0),
    "yes_flag_without_positive_amount",
    "low",
    "data-quality",
    paste(flag_column, amount_column, sep = "|"),
    paste(raw[[flag_column]], raw[[amount_column]], sep = " | "),
    "A program Yes code has no positive amount; amounts may not have been collected for all years."
  )
}

target_columns <- c("trgt_fam", "trgt_eld", "trgt_dis", "trgt_hml", "trgt_oth")
any_specific_target <- rowSums(as.matrix(raw[, ..target_columns]) == "1", na.rm = TRUE) > 0
add_issues(
  raw$trgt_pop == "2" & any_specific_target,
  "target_population_summary_disagrees",
  "moderate",
  "data-quality",
  paste(c("trgt_pop", target_columns), collapse = "|"),
  paste(raw$trgt_pop, apply(raw[, ..target_columns], 1, paste, collapse = "|"), sep = " | "),
  "The project-level target-population No code conflicts with at least one specific Yes code."
)

row_issues <- if (length(issue_rows) == 0) {
  data.table(
    source_row = integer(), hud_id = character(), issue_code = character(),
    severity = character(), decision_class = character(), columns = character(),
    observed_value = character(), explanation = character()
  )
} else {
  rbindlist(issue_rows, use.names = TRUE)
}
setorder(row_issues, issue_code, source_row, columns)

row_issue_summary <- row_issues[
  , .(
    n_flagged_rows = uniqueN(source_row),
    example_hud_id = first(hud_id),
    example_observed_value = first(observed_value)
  ),
  by = .(issue_code, severity, decision_class, columns, explanation)
]
row_issue_summary[, severity_order := match(severity, c("high", "moderate", "low"))]
setorder(row_issue_summary, severity_order, -n_flagged_rows, issue_code, columns)
row_issue_summary[, severity_order := NULL]

# Build review-only duplicate groups under explicit comparison keys.
if (any(vapply(raw, function(value) any(str_detect(value, fixed("\u001F")), na.rm = TRUE), logical(1)))) {
  stop("Raw data contain the reserved duplicate-key separator.", call. = FALSE)
}

make_key <- function(columns, normalize = FALSE) {
  values <- lapply(raw[, ..columns], function(value) {
    if (normalize) normalize_text(value) else value
  })
  complete <- Reduce(`&`, lapply(values, function(value) !is.na(value) & value != ""))
  key <- do.call(paste, c(values, sep = "\u001F"))
  key[!complete] <- NA_character_
  key
}

duplicate_specs <- list(
  list(
    group_type = "hud_id",
    key = make_key("hud_id"),
    interpretation = "HUD documents hud_id as unique; repeated values are structural duplicate candidates."
  ),
  list(
    group_type = "state_id_within_state",
    key = make_key(c("proj_st", "state_id"), normalize = TRUE),
    interpretation = paste(
      "Repeated state identifiers may represent duplicate records or legitimate",
      "reuse by an allocating agency."
    )
  ),
  list(
    group_type = "normalized_address",
    key = make_key(c("proj_add", "proj_cty", "proj_st", "proj_zip"), normalize = TRUE),
    interpretation = paste(
      "Repeated normalized addresses may be duplicate records, phases,",
      "resyndications, or co-located projects."
    )
  ),
  list(
    group_type = "normalized_project_place",
    key = make_key(c("project", "proj_cty", "proj_st"), normalize = TRUE),
    interpretation = paste(
      "Repeated normalized names within a place may be duplicate records, phases,",
      "or distinct sites with reused names."
    )
  ),
  list(
    group_type = "exact_coordinates",
    key = make_key(c("latitude", "longitude")),
    interpretation = paste(
      "Exact coordinate matches identify co-located or repeatedly geocoded records,",
      "not necessarily duplicate projects."
    )
  ),
  list(
    group_type = "core_project_signature",
    key = make_key(
      c("project", "proj_add", "proj_cty", "proj_st", "proj_zip", "yr_pis", "n_units", "li_units"),
      normalize = TRUE
    ),
    interpretation = paste(
      "Agreement on normalized identity, location, year, and unit counts is a",
      "strong but still review-only duplicate signal."
    )
  ),
  list(
    group_type = "exact_all_fields",
    key = do.call(
      paste,
      c(lapply(raw, function(value) ifelse(is.na(value), "<NA>", value)), sep = "\u001F")
    ),
    interpretation = "Every published field is identical."
  )
)

duplicate_groups_list <- list()
duplicate_members_list <- list()
for (spec_index in seq_along(duplicate_specs)) {
  spec <- duplicate_specs[[spec_index]]
  key_counts <- table(spec$key, useNA = "no")
  repeated_keys <- names(key_counts)[key_counts > 1]
  if (length(repeated_keys) == 0) {
    next
  }

  group_id <- paste0(spec$group_type, "_", sprintf("%05d", seq_along(repeated_keys)))
  duplicate_groups_list[[spec_index]] <- data.table(
    duplicate_group_id = group_id,
    group_type = spec$group_type,
    n_records = as.integer(key_counts[repeated_keys]),
    comparison_key = str_trunc(str_replace_all(repeated_keys, fixed("\u001F"), " | "), 500),
    interpretation = spec$interpretation
  )

  member_indices <- which(spec$key %in% repeated_keys)
  key_position <- match(spec$key[member_indices], repeated_keys)
  duplicate_members_list[[spec_index]] <- data.table(
    duplicate_group_id = group_id[key_position],
    group_type = spec$group_type,
    source_row = source_row[member_indices],
    hud_id = raw$hud_id[member_indices],
    project = raw$project[member_indices],
    proj_add = raw$proj_add[member_indices],
    proj_cty = raw$proj_cty[member_indices],
    proj_st = raw$proj_st[member_indices],
    proj_zip = raw$proj_zip[member_indices],
    latitude = raw$latitude[member_indices],
    longitude = raw$longitude[member_indices],
    yr_pis = raw$yr_pis[member_indices],
    yr_alloc = raw$yr_alloc[member_indices],
    n_units = raw$n_units[member_indices],
    li_units = raw$li_units[member_indices],
    resyndication_cd = raw$resyndication_cd[member_indices],
    record_stat = raw$record_stat[member_indices]
  )
}

duplicate_groups <- if (length(duplicate_groups_list) == 0) {
  data.table(
    duplicate_group_id = character(), group_type = character(), n_records = integer(),
    comparison_key = character(), interpretation = character()
  )
} else {
  rbindlist(duplicate_groups_list, use.names = TRUE)
}
setorder(duplicate_groups, group_type, duplicate_group_id)
duplicate_members <- if (length(duplicate_members_list) == 0) {
  data.table(
    duplicate_group_id = character(), group_type = character(), source_row = integer(),
    hud_id = character(), project = character(), proj_add = character(), proj_cty = character(),
    proj_st = character(), proj_zip = character(), latitude = character(), longitude = character(),
    yr_pis = character(), yr_alloc = character(), n_units = character(), li_units = character(),
    resyndication_cd = character(), record_stat = character()
  )
} else {
  rbindlist(duplicate_members_list, use.names = TRUE)
}
setorder(duplicate_members, group_type, duplicate_group_id, source_row)

# Write audit evidence and the human-readable summary.
fwrite(column_profile, "../output/column_profile.csv", na = "")
fwrite(top_value_frequencies, "../output/top_value_frequencies.csv", na = "")
fwrite(row_issue_summary, "../output/row_issue_summary.csv", na = "")
fwrite(row_issues, "../output/row_issues.csv", na = "")
fwrite(duplicate_groups, "../output/duplicate_groups.csv", na = "")
fwrite(duplicate_members, "../output/duplicate_members.csv", na = "")

severity_counts <- unique(row_issues[, .(source_row, severity)])[
  , .(n_rows = .N), by = severity
]
severity_counts[, severity_order := match(severity, c("high", "moderate", "low"))]
setorder(severity_counts, severity_order)
severity_counts[, severity_order := NULL]
duplicate_type_counts <- rbindlist(lapply(duplicate_specs, function(spec) {
  matching_groups <- duplicate_groups[group_type == spec$group_type]
  data.table(
    group_type = spec$group_type,
    n_groups = nrow(matching_groups),
    n_memberships = sum(matching_groups$n_records)
  )
}))

structure_value <- function(metric) {
  value <- workbook_structure$value[workbook_structure$metric == metric]
  if (length(value) != 1) NA_real_ else value
}

summary_lines <- c(
  "# HUD LIHTC Property Data Audit",
  "",
  paste0("- Source archive SHA-256: `", validated_source$archive_sha256, "`"),
  paste0("- Workbook: `", validated_source$workbook_member, "`"),
  paste0("- Published project rows: ", format(nrow(raw), big.mark = ",")),
  paste0("- Published columns: ", ncol(raw)),
  paste0("- Workbook sheets: ", format(structure_value("sheet_count"), big.mark = ",", scientific = FALSE)),
  paste0("- Formula cells: ", format(structure_value("formula_cell_count"), big.mark = ",", scientific = FALSE)),
  paste0("- Excel error cells: ", format(structure_value("error_cell_count"), big.mark = ",", scientific = FALSE)),
  "- Rows removed or values changed: 0",
  "",
  paste(
    "All cells were imported as raw text. Apparent numeric types, column labels,",
    "HUD value labels, and missing-value conventions were tested rather than",
    "accepted as clean. Flags below identify review candidates; they do not",
    "authorize corrections or exclusions."
  ),
  "",
  "## Row-level review queue",
  "",
  "| Severity | Distinct flagged rows |",
  "|---|---:|",
  if (nrow(severity_counts) == 0) {
    "| None | 0 |"
  } else {
    paste0("| ", severity_counts$severity, " | ", format(severity_counts$n_rows, big.mark = ","), " |")
  },
  "",
  "## Potential duplicate groups",
  "",
  "| Candidate key | Groups | Record memberships |",
  "|---|---:|---:|",
  if (nrow(duplicate_type_counts) == 0) {
    "| None | 0 | 0 |"
  } else {
    paste0(
      "| ", duplicate_type_counts$group_type,
      " | ", format(duplicate_type_counts$n_groups, big.mark = ","),
      " | ", format(duplicate_type_counts$n_memberships, big.mark = ","), " |"
    )
  },
  "",
  paste(
    "A record can appear under more than one duplicate key, so memberships must",
    "not be summed across rows. Address, project-name, state-ID, and coordinate",
    "matches can reflect legitimate phases, buildings, co-located projects, or",
    "resyndications."
  ),
  "",
  "## Highest-count deterministic issues",
  "",
  "| Issue | Severity | Field(s) | Flagged rows |",
  "|---|---|---|---:|",
  if (nrow(row_issue_summary) == 0) {
    "| None | | | 0 |"
  } else {
    top_issue_summary <- copy(row_issue_summary)
    setorder(top_issue_summary, -n_flagged_rows, issue_code, columns)
    top_issue_summary <- head(top_issue_summary, 20)
    paste0(
      "| `", top_issue_summary$issue_code, "` | ", top_issue_summary$severity,
      " | `", top_issue_summary$columns, "` | ",
      format(top_issue_summary$n_flagged_rows, big.mark = ","), " |"
    )
  },
  "",
  "## Research boundary",
  "",
  paste(
    "This task is an audit, not a cleaned-data producer. The next step is to review",
    "high-severity anomalies and sampled duplicate groups, decide what the research",
    "unit should be, and encode approved decisions with explicit reason codes in a",
    "separate construction task."
  )
)

writeLines(summary_lines, "../output/audit_summary.md", useBytes = TRUE)

cat(
  "Audited ", format(nrow(raw), big.mark = ","), " rows and ", ncol(raw),
  " columns; wrote ", format(nrow(row_issues), big.mark = ","),
  " row-level flags and ", format(nrow(duplicate_groups), big.mark = ","),
  " duplicate candidate groups.\n",
  sep = ""
)
