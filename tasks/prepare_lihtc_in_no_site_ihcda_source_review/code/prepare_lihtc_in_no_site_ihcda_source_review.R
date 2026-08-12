# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/prepare_lihtc_in_no_site_ihcda_source_review/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
  library(digest)
})

questions <- as.data.table(read_parquet(
  "../input/lihtc_no_site_development_questions.parquet"
))
if (nrow(questions) != 797L ||
    uniqueN(questions$no_site_review_question_id) != 797L ||
    uniqueN(questions$development_id) != 797L) {
  stop("The final no-site question input changed.", call. = FALSE)
}

questions <- questions[development_state == "IN"]
if (nrow(questions) != 40L || uniqueN(questions$development_id) != 40L ||
    anyNA(questions$development_name) || any(questions$development_name == "")) {
  stop("The Indiana no-site question universe changed.", call. = FALSE)
}

manifest <- fread("../input/source_manifest.csv")
if (nrow(manifest) != 1L || uniqueN(manifest$source_file) != 1L ||
    manifest$source_file != "ihcda_lihtc_landing_page.html" ||
    manifest$source_url !=
      "https://www.in.gov/ihcda/developers/rental-housing-tax-credits-rhtc/" ||
    manifest$retrieved_on != "2026-08-12" || manifest$bytes != 60748L ||
    manifest$sha256 !=
      "545dc70de4fa1c9852752c8b6f3d986ac2f604528d1dfb3f2a2e31cb6e7d5b60" ||
    file.info("../input/ihcda_lihtc_landing_page.html")$size != manifest$bytes ||
    digest(file = "../input/ihcda_lihtc_landing_page.html", algo = "sha256") !=
      manifest$sha256) {
  stop("The frozen IHCDA landing page does not match its manifest.",
    call. = FALSE)
}

landing_page <- paste(readLines("../input/ihcda_lihtc_landing_page.html",
  warn = FALSE), collapse = "\n")
workbook_path <- "/ihcda/files/Existing-Properties-Report-2026.05.11-v2.xlsx"
if (!grepl(workbook_path, landing_page, fixed = TRUE) ||
    !grepl("listing of Existing Low Income Housing Tax Credit Properties - updated 5-11-2026",
      landing_page, fixed = TRUE)) {
  stop("The frozen IHCDA page no longer identifies the expected workbook.",
    call. = FALSE)
}

blocker <- questions[, .(
  no_site_review_question_id, development_id, development_name,
  development_city, development_state, n_units_development
)]
blocker[, `:=`(
  official_source = "IHCDA Existing Low Income Housing Tax Credit Properties",
  official_workbook_url = paste0("https://www.in.gov", workbook_path),
  source_access_status = "blocked_official_workbook_bytes_not_frozen",
  source_screen_status = "not_screened_no_source_records_available",
  review_status = "not_adjudicated",
  geocoding_query_approval = "not_approved"
)]
setorder(blocker, development_id)

summary <- data.table(
  measure = c(
    "in_no_site_questions", "frozen_ihcda_landing_pages",
    "frozen_ihcda_workbook_rows", "exact_name_candidates",
    "fuzzy_city_unit_candidates", "source_access_blocked_questions",
    "source_access_blocked_questions_without_city",
    "source_access_blocked_questions_without_units"
  ),
  value = c(
    nrow(blocker), 1L, 0L, 0L, 0L, nrow(blocker),
    sum(is.na(blocker$development_city) | blocker$development_city == ""),
    sum(is.na(blocker$n_units_development))
  )
)
expected <- c(
  in_no_site_questions = 40L, frozen_ihcda_landing_pages = 1L,
  frozen_ihcda_workbook_rows = 0L, exact_name_candidates = 0L,
  fuzzy_city_unit_candidates = 0L, source_access_blocked_questions = 40L,
  source_access_blocked_questions_without_city = 2L,
  source_access_blocked_questions_without_units = 1L
)
observed <- setNames(summary$value, summary$measure)
if (!identical(as.integer(observed[names(expected)]), as.integer(expected)) ||
    any(blocker$review_status != "not_adjudicated") ||
    any(blocker$geocoding_query_approval != "not_approved")) {
  stop("The Indiana source-access blocker failed its frozen contracts.",
    call. = FALSE)
}

write_parquet(blocker,
  "../output/lihtc_in_no_site_ihcda_source_access_blocker.parquet")
fwrite(summary, "../output/lihtc_in_no_site_ihcda_source_access_summary.csv")

blocker_roundtrip <- as.data.table(read_parquet(
  "../output/lihtc_in_no_site_ihcda_source_access_blocker.parquet"
))
summary_roundtrip <- fread(
  "../output/lihtc_in_no_site_ihcda_source_access_summary.csv"
)
if (!identical(blocker_roundtrip, blocker) ||
    !identical(summary_roundtrip, summary) ||
    any(blocker_roundtrip$review_status != "not_adjudicated") ||
    any(blocker_roundtrip$geocoding_query_approval != "not_approved")) {
  stop("The Indiana source-access blocker failed its round-trip checks.",
    call. = FALSE)
}
