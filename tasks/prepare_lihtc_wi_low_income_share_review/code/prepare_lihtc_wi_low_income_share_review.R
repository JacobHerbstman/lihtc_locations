# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/prepare_lihtc_wi_low_income_share_review/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
  library(rvest)
  library(stringdist)
  library(stringr)
})

development <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_unit_scope_adjudicated.parquet"
))
site <- as.data.table(read_parquet(
  "../input/lihtc_development_site_2024_unit_scope_adjudicated.parquet"
))
wheda_html <- read_html(
  "../input/wheda_monitored_htc_projects_2026-08-12.html"
)

normalize_key <- function(x) {
  str_squish(str_replace_all(str_to_upper(x), "[^A-Z0-9 ]", " "))
}

name_prefix <- function(x) {
  substr(gsub(" ", "", normalize_key(x)), 1L, 6L)
}

wheda_cards <- html_elements(wheda_html, ".project-item")
wheda <- rbindlist(lapply(wheda_cards, function(card) {
  statistics <- html_text2(html_elements(card, ".stat-item"))
  extract_statistic <- function(label) {
    as.numeric(str_extract(
      statistics[str_detect(statistics, label)][1L], "\\d+"
    ))
  }

  data.table(
    wheda_project_id = str_extract(
      html_attr(html_element(card, ".project-id"), "aria-label"), "\\d+"
    ),
    wheda_name = html_text2(html_element(card, ".project-name")),
    wheda_address = str_squish(str_replace_all(
      html_text2(html_element(card, ".project-address")), "\\n", " | "
    )),
    wheda_total_units = extract_statistic("Total Units"),
    wheda_low_income_units = extract_statistic("LI Units"),
    wheda_placed_in_service = html_attr(html_element(card, "time"), "datetime")
  )
}))
wheda[, `:=`(
  wheda_name_key = normalize_key(wheda_name),
  wheda_name_prefix = name_prefix(wheda_name),
  wheda_pis_year = as.integer(substr(wheda_placed_in_service, 7L, 10L))
)]
setorder(wheda, wheda_project_id)
wheda <- unique(wheda, by = "wheda_project_id")

review_developments <- development[
  development_state == "WI" &
    !is.na(n_units_development) &
    !is.na(li_units_development) &
    li_units_development / n_units_development < 0.20,
  .(
    development_id,
    development_name,
    development_city,
    first_pis_year,
    n_project_episodes,
    n_development_sites,
    hud_total_units = n_units_development,
    hud_low_income_units = li_units_development
  )
]
review_developments[, development_name_key := normalize_key(development_name)]
review_developments[, development_name_prefix := name_prefix(development_name)]

review_site <- site[development_id %chin% review_developments$development_id,
  .(development_id, site_address_key = normalize_key(paste(
    site_street, site_city, site_state, site_zip
  )))]
review_site <- unique(review_site, by = c("development_id", "site_address_key"))
wheda[, wheda_address_key := normalize_key(wheda_address)]

candidate_pairs <- rbindlist(lapply(
  seq_len(nrow(review_developments)),
  function(row_number) {
    one_development <- review_developments[row_number]
    one_candidate_set <- wheda[
      wheda_name_prefix == one_development$development_name_prefix &
        wheda_total_units == one_development$hud_total_units
    ]
    if (nrow(one_candidate_set) == 0L) {
      return(NULL)
    }
    one_candidate_set[, `:=`(
      development_id = one_development$development_id,
      development_name = one_development$development_name,
      development_city = one_development$development_city,
      first_pis_year = one_development$first_pis_year,
      n_project_episodes = one_development$n_project_episodes,
      n_development_sites = one_development$n_development_sites,
      hud_total_units = one_development$hud_total_units,
      hud_low_income_units = one_development$hud_low_income_units,
      development_name_key = one_development$development_name_key,
      development_name_prefix = one_development$development_name_prefix
    )]
    one_candidate_set
  }
), use.names = TRUE)
candidate_pairs[, `:=`(
  name_distance = stringdist(
    development_name_key, wheda_name_key, method = "jw", p = 0.1
  ),
  pis_year_agrees = first_pis_year == wheda_pis_year,
  total_units_agree = TRUE
)]
candidate_pairs <- candidate_pairs[
  name_distance <= 0.15
]
candidate_pairs[, best_name_distance := name_distance == min(name_distance),
  by = development_id]
candidate_pairs[, n_best_name_candidates := sum(best_name_distance),
  by = development_id]
candidate_pairs[, wheda_project_used_by_n_developments := .N,
  by = wheda_project_id]
candidate_pairs[, site_address_agrees := FALSE]
for (development_id_i in unique(candidate_pairs$development_id)) {
  candidate_pairs[development_id == development_id_i,
    site_address_agrees := wheda_address_key %chin%
      review_site[development_id == development_id_i, site_address_key]]
}
candidate_pairs[, candidate_evidence := fcase(
  pis_year_agrees & best_name_distance & total_units_agree & n_best_name_candidates == 1L &
    wheda_project_used_by_n_developments == 1L,
  "unique_name_year_total_match",
  pis_year_agrees & best_name_distance & n_best_name_candidates == 1L,
  "unique_name_year_match_total_disagrees",
  default = "candidate_not_unique_or_not_best_name_match"
)]
setorder(candidate_pairs, development_id, name_distance, wheda_project_id)

if (nrow(wheda) != 902L ||
    uniqueN(wheda$wheda_project_id) != nrow(wheda) ||
    nrow(review_developments) != 197L ||
    uniqueN(review_developments$development_id) !=
      nrow(review_developments) ||
    candidate_pairs[, anyNA(c(
      development_id, wheda_project_id, wheda_low_income_units
    ))] ||
    candidate_pairs[, any(name_distance < 0 | name_distance > 1)] ||
    nrow(candidate_pairs) < 1L) {
  stop("The Wisconsin low-share candidate contract changed.", call. = FALSE)
}

write_parquet(
  candidate_pairs,
  "../output/lihtc_wi_low_income_share_candidates.parquet",
  compression = "zstd"
)

if (!identical(
  candidate_pairs,
  as.data.table(read_parquet(
    "../output/lihtc_wi_low_income_share_candidates.parquet"
  ))
)) {
  stop("The candidate Parquet changed on round trip.", call. = FALSE)
}

cat(
  "Prepared ", nrow(candidate_pairs), " WHEDA candidates for ",
  uniqueN(candidate_pairs$development_id),
  " of 197 Wisconsin low-share developments.\n", sep = ""
)
