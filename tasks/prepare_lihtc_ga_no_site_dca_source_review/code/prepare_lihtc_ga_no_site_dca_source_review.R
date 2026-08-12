# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/prepare_lihtc_ga_no_site_dca_source_review/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
  library(digest)
  library(jsonlite)
})

require_unique <- function(table, columns, label) {
  if (uniqueN(table, by = columns) != nrow(table)) {
    stop(label, " is not unique by ", paste(columns, collapse = ", "),
      call. = FALSE)
  }
}

questions <- as.data.table(read_parquet(
  "../input/lihtc_no_site_development_questions.parquet"
))
if (nrow(questions) != 797L) {
  stop("The final no-site question input changed.", call. = FALSE)
}
require_unique(questions, "no_site_review_question_id", "No-site questions")
require_unique(questions, "development_id", "No-site questions")

questions <- questions[development_state == "GA"]
if (nrow(questions) != 41L ||
    anyNA(questions$development_name) || any(questions$development_name == "") ||
    anyNA(questions$n_units_development)) {
  stop("The Georgia no-site question universe changed.", call. = FALSE)
}

manifest <- fread("../input/manifest.csv")
expected_files <- c(
  "experience_configuration.json", "web_map_configuration.json",
  "layer_metadata.json"
)
expected_urls <- c(
  "https://www.arcgis.com/sharing/rest/content/items/acf6a5ace8794e4ca129bf0c4165c436/data?f=json",
  "https://Georgia-DCA.maps.arcgis.com/sharing/rest/content/items/1bbc7a5077c5442a983af4910dfcda6e/data?f=json",
  "https://services2.arcgis.com/Gqyymy5JISeLzyNM/arcgis/rest/services/PIS_LIHTC_Properties_(Monitored)/FeatureServer/0?f=pjson"
)
if (nrow(manifest) != 3L || !identical(manifest$source_file, expected_files) ||
    !identical(manifest$source_url, expected_urls) ||
    any(manifest$retrieved_on != "2026-08-12") ||
    anyNA(manifest$bytes) || any(manifest$bytes <= 0L) ||
    any(!grepl("^[0-9a-f]{64}$", manifest$sha256))) {
  stop("The Georgia DCA source manifest changed.", call. = FALSE)
}
for (file in manifest$source_file) {
  row <- manifest[source_file == file]
  if (file.info(file.path("../input", file))$size != row$bytes ||
      digest(file = file.path("../input", file), algo = "sha256") != row$sha256) {
    stop("A frozen Georgia DCA source file does not match its manifest.",
      call. = FALSE)
  }
}

experience <- fromJSON("../input/experience_configuration.json", simplifyVector = FALSE)
web_map <- fromJSON("../input/web_map_configuration.json", simplifyVector = FALSE)
layer <- fromJSON("../input/layer_metadata.json", simplifyVector = FALSE)
experience_text <- paste(readLines("../input/experience_configuration.json", warn = FALSE),
  collapse = "\n")
web_map_text <- paste(readLines("../input/web_map_configuration.json", warn = FALSE),
  collapse = "\n")
if (is.null(experience$dataSources$dataSource_1$itemId) ||
    experience$dataSources$dataSource_1$itemId != "1bbc7a5077c5442a983af4910dfcda6e" ||
    experience$dataSources$dataSource_1$portalUrl !=
      "https://Georgia-DCA.maps.arcgis.com" ||
    !grepl("Placed in Service LIHTC Properties", experience_text, fixed = TRUE) ||
    length(web_map$operationalLayers) != 1L ||
    web_map$operationalLayers[[1]]$itemId != "dc3637858383487e8db6d8888e923bf1" ||
    web_map$operationalLayers[[1]]$url !=
      "https://services2.arcgis.com/Gqyymy5JISeLzyNM/arcgis/rest/services/PIS_LIHTC_Properties_(Monitored)/FeatureServer/0" ||
    !grepl("PIS_LIHTC_Properties_(Monitored)/FeatureServer/0", web_map_text,
      fixed = TRUE) ||
    layer$name != "PIS_LIHTC_Data" || layer$capabilities != "Query") {
  stop("The frozen DCA configurations no longer identify the expected service.",
    call. = FALSE)
}
field_names <- vapply(layer$fields, `[[`, character(1), "name")
if (!all(c("PropName", "CityClean", "Units", "FullAddy") %chin% field_names)) {
  stop("The DCA layer no longer advertises key screening fields.", call. = FALSE)
}

blocker <- questions[, .(
  no_site_review_question_id, development_id, development_name,
  development_city, development_state, n_units_development
)]
blocker[, `:=`(
  official_source = "Georgia DCA LIHTC Placed-In-Service Map",
  official_source_feature_service = "PIS_LIHTC_Properties_(Monitored)",
  source_access_status = "blocked_feature_rows_not_frozen",
  source_screen_status = "not_screened_no_source_records_available",
  review_status = "not_adjudicated",
  geocoding_query_approval = "not_approved"
)]
setorder(blocker, development_id)

summary <- data.table(
  measure = c(
    "ga_no_site_questions", "frozen_dca_metadata_files",
    "frozen_dca_feature_rows", "exact_name_candidates",
    "fuzzy_city_unit_candidates", "source_access_blocked_questions",
    "source_access_blocked_questions_without_city"
  ),
  value = c(41L, 3L, 0L, 0L, 0L, nrow(blocker),
    sum(is.na(blocker$development_city) | blocker$development_city == ""))
)
expected <- c(
  ga_no_site_questions = 41L, frozen_dca_metadata_files = 3L,
  frozen_dca_feature_rows = 0L, exact_name_candidates = 0L,
  fuzzy_city_unit_candidates = 0L, source_access_blocked_questions = 41L,
  source_access_blocked_questions_without_city = 4L
)
observed <- setNames(summary$value, summary$measure)
if (!identical(as.integer(observed[names(expected)]), as.integer(expected)) ||
    any(blocker$review_status != "not_adjudicated") ||
    any(blocker$geocoding_query_approval != "not_approved")) {
  stop("The Georgia source-access blocker no longer reproduces frozen counts.",
    call. = FALSE)
}

write_parquet(blocker,
  "../output/lihtc_ga_no_site_dca_source_access_blocker.parquet")
fwrite(summary, "../output/lihtc_ga_no_site_dca_source_access_summary.csv")

blocker_roundtrip <- as.data.table(read_parquet(
  "../output/lihtc_ga_no_site_dca_source_access_blocker.parquet"
))
summary_roundtrip <- fread("../output/lihtc_ga_no_site_dca_source_access_summary.csv")
if (nrow(blocker_roundtrip) != 41L ||
    !identical(summary_roundtrip, summary) ||
    any(blocker_roundtrip$review_status != "not_adjudicated") ||
    any(blocker_roundtrip$geocoding_query_approval != "not_approved")) {
  stop("The Georgia source-access blocker outputs failed their round-trip checks.",
    call. = FALSE)
}
