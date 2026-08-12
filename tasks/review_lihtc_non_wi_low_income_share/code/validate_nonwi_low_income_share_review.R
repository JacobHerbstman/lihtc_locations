# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/review_lihtc_non_wi_low_income_share/code")

library(arrow)
library(data.table)

review <- fread("nonwi_low_income_share_review.csv", na.strings = "")
frozen <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_unit_scope_adjudicated.parquet"
))

required <- c("development_id", "hud_id", "state_id", "development_state", "development_name", "development_city", "proj_add", "proj_cty", "proj_st", "proj_zip", "first_pis_year", "last_pis_year", "n_project_episodes", "frozen_total_units", "frozen_low_income_units", "classification", "replacement_total_units", "replacement_low_income_units", "replacement_count_type", "source_1_url", "source_1_title", "source_1_type", "source_1_statement", "source_2_url", "source_2_title", "source_2_type", "source_2_statement", "reviewer_1", "reviewer_2", "reviewer_1_reviewed_on", "reviewer_2_reviewed_on", "source_scope", "final_action")
stopifnot(identical(names(review), required))
stopifnot(nrow(review) == 78L, uniqueN(review$development_id) == 78L)
stopifnot(all(review$development_state != "WI"))
stopifnot(all(!is.na(review$source_1_url)), all(!is.na(review$source_2_url)))
stopifnot(all(!is.na(review$source_1_statement)), all(!is.na(review$source_2_statement)))
stopifnot(all(!is.na(review$reviewer_1)), all(!is.na(review$reviewer_2)))
stopifnot(all(review$reviewer_1 != review$reviewer_2))
stopifnot(all(review$reviewer_1_reviewed_on == as.IDate("2026-08-12")))
stopifnot(all(review$reviewer_2_reviewed_on == as.IDate("2026-08-12")))
stopifnot(all(!is.na(review$source_scope)))
stopifnot(all(review$final_action %chin% c("replace_low_income_units", "retain_frozen_counts", "unresolved_exclude_low_income_share")))

frozen <- frozen[development_state != "WI" & !is.na(n_units_development) & n_units_development > 0 & !is.na(li_units_development) & li_units_development / n_units_development < 0.20, .(development_id, n_units_development, li_units_development)]
setkey(frozen, development_id)
setkey(review, development_id)
stopifnot(setequal(review$development_id, frozen$development_id))
setorder(review, development_id)
setorder(frozen, development_id)
stopifnot(all(review$frozen_total_units == frozen$n_units_development))
stopifnot(all(review$frozen_low_income_units == frozen$li_units_development))

replacement <- review[final_action == "replace_low_income_units"]
stopifnot(nrow(replacement) == 0L || all(!is.na(replacement$replacement_low_income_units)))
stopifnot(nrow(replacement) == 0L || all(!is.na(replacement$replacement_total_units)))
stopifnot(nrow(replacement) == 0L || all(replacement$replacement_total_units == replacement$frozen_total_units))
stopifnot(nrow(replacement) == 0L || all(replacement$replacement_low_income_units >= 0))
stopifnot(nrow(replacement) == 0L || all(replacement$replacement_low_income_units <= replacement$frozen_total_units))
stopifnot(nrow(replacement) == 0L || all(replacement$source_1_type %chin% c("state agency bulletin", "municipal report", "municipal record", "county record", "state record", "state housing-agency document", "county report") | replacement$source_2_type %chin% c("state agency bulletin", "municipal report", "municipal record", "county record", "state record", "state housing-agency document", "county report")))

write_parquet(review, "../output/nonwi_low_income_share_review_validated.parquet")
