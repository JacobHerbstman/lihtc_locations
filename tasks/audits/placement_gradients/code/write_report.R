# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/placement_gradients/code")
library(data.table)
library(jsonlite)
m <- fread("../output/models.csv")
c <- fread("../output/coverage.csv")
s <- fread("../output/scales.csv")
p <- fread("../output/project_sample.csv", na.strings = "")
period <- fread("periods.csv")
labels <- c(homeowner_share = "Homeowner share", nh_black_share = "Non-Hispanic Black share", log_income = "Median household income")
html_table <- function(x) {
  y <- copy(x)
  for (field in names(y)) {
    v <- y[[field]]
    if (is.numeric(v)) v <- format(round(v, 3), trim = TRUE, big.mark = ",", scientific = FALSE)
    v[is.na(v) | v == "NA"] <- "—"
    v <- gsub("&", "&amp;", v, fixed = TRUE)
    v <- gsub("<", "&lt;", v, fixed = TRUE)
    set(y, j = field, value = v)
  }
  paste0("<div class='table'><table><tr><th>", paste(gsub("_", " ", names(y)), collapse = "</th><th>"),
    "</th></tr>", paste(apply(y, 1L, function(z) paste0("<tr><td>", paste(z, collapse = "</td><td>"), "</td></tr>")), collapse = ""), "</table></div>")
}
main <- m[sample == "all_city_tracts" & model == "separate" & comparison == "pooled" & adjustment == "baseline"]
main[, percent_change := 100 * (rate_ratio - 1)]
main[, characteristic := labels[variable]]
main[, study_period := sprintf("Pooled %d–%d", period$first_year, period$last_year)]
main[, interval := sprintf("%.1f%% to %.1f%%", 100 * (ci_low - 1), 100 * (ci_high - 1))]
scales <- s[, .(city_name, characteristic = labels[variable],
  one_SD = sprintf("%.1f %s", sd_in_percent_units, fifelse(variable == "log_income", "% higher income", "percentage points")))]
before <- m[sample == "all_city_tracts" & model == "joint" & adjustment == "same_sample",
  .(city_name, variable, before_rate_ratio = rate_ratio)]
after <- m[sample == "all_city_tracts" & model == "joint" & adjustment == "housing_controls",
  .(city_name, variable, after_rate_ratio = rate_ratio, ci_low, ci_high, projects)]
stopifnot(!anyDuplicated(before[, .(city_name, variable)]), !anyDuplicated(after[, .(city_name, variable)]))
controls <- merge(before, after, by = c("city_name", "variable"))
stopifnot(nrow(controls) == nrow(before), nrow(controls) == nrow(after))
controls[, characteristic := labels[variable]]
controls[, interval_after := sprintf("%.3f–%.3f", ci_low, ci_high)]
body <- c("<!doctype html><meta charset='utf-8'><title>New York and Chicago LIHTC placement gradients</title>",
  "<style>body{max-width:1200px;margin:35px auto;padding:0 24px;font:16px/1.5 system-ui;color:#172735}h1,h2{line-height:1.2}img{width:100%}.table{overflow:auto;margin:20px 0}table{border-collapse:collapse;font-size:13px}td,th{padding:7px 10px;border-bottom:1px solid #ddd;text-align:right}th{background:#edf3f5}td:first-child,th:first-child{text-align:left}</style>",
  "<h1>Compare homeownership, race and income gradients</h1>",
  sprintf("<p><b>Pooled %d–%d, separately for New York City and Chicago.</b> Each city has one estimated gradient per characteristic for the full study period. Neighborhood observations still change over time and end strictly before opening. Each city's three models use exactly the same tracts and projects. The outcome is annual HUD new-construction project records per baseline housing unit, accounting for differences in overall placement rates across years.</p>",
    period$first_year, period$last_year),
  "<p><b>Every model includes year fixed effects, estimated separately for each city.</b> The added-control comparison below uses exactly the same rows and standardization before and after adding prior vacancy and housing density.</p>",
  "<p><b>How to compare sizes:</b> each effect describes one standard deviation higher neighborhood characteristic, using a fixed scale calculated across the full study period within that city. Income is logged, so a change is proportional. Larger absolute log rate changes mean stronger associations: twice as many and half as many have the same proportional strength. The rankings below compare point estimates, without a formal test that one characteristic's gradient exceeds another's.</p>",
  "<h2>Add prior vacancy and housing density</h2>",
  "<p>Vacancy is vacant housing units divided by all housing units. Density is housing units divided by square kilometers of the complete mapped native tract. Both housing counts and vacancy come from the same prior Census observation as the other characteristics. Vacancy enters linearly; density enters in logs. This uses the neighborhood's existing housing, not the LIHTC project's own size or bedroom mix.</p>",
  "<p>The table includes homeownership, Black share and income together in both columns. A smaller homeowner rate ratio means a more negative association. Confidence intervals below apply to the estimates after adding controls; these are not tests that the before and after coefficients differ.</p>",
  html_table(controls[, .(city_name, characteristic, before_rate_ratio, after_rate_ratio, interval_after, projects)]),
  paste0("<img alt='Same-sample comparison before and after adding vacancy and density' src='data:image/png;base64,",
    base64_enc(readBin("../output/housing_controls.png", "raw", file.info("../output/housing_controls.png")$size)), "'>"),
  "<p>The blue and red estimates use the same observations within each city and geographic sample. The upper panels consider one of the three main characteristics at a time; the lower panels include all three together. Red adds vacancy and density in either case.</p>",
  html_table(c[, .(city_name, common_projects, controls_projects, common_tract_years, controls_tract_years,
    missing_vacancy_tract_years, missing_density_tract_years)]),
  "<p><a href='https://www.nhgis.org/gis-files'>NHGIS clips coastal and Great Lakes waters from its polygons</a>, but <a href='https://forum.ipums.org/t/land-area-variable-for-1990-census-tracts/3836'>mapped polygon area can include inland water</a>. Density therefore measures broad housing concentration; it is not density per developable land area. No newer tract's area substitutes for a missing historical polygon.</p>",
  "<h2>Original pooled gradients</h2>")
for (city in unique(main$city_name)) {
  body <- c(body, paste0("<h2>", city, "</h2>"))
  z <- main[city_name == city][order(-abs(log_rate_change))]
  body <- c(body, sprintf("<p>The magnitude ordering is %s. For a one-SD increase, the associated changes are %s.</p>",
    paste(z$characteristic, collapse = " → "),
    paste(sprintf("%s %+.1f%%", z$characteristic, z$percent_change), collapse = "; ")))
}
body <- c(body, "<h2>Original common-scale comparison</h2>",
  "<p>The upper panels examine each characteristic separately. The lower panels include all three together. Every model pools the full study period within its city, retaining year effects. Differences between those panels show overlap between the characteristics, not causal effects.</p>",
  paste0("<img alt='Placement rate ratios by city, period, and characteristic' src='data:image/png;base64,",
    base64_enc(readBin("../output/gradients.png", "raw", file.info("../output/gradients.png")$size)), "'>"),
  html_table(main[, .(city_name, study_period, characteristic, percent_change, interval)]),
  "<h2>What is a one-standard-deviation difference here?</h2>", html_table(scales),
  "<p>Scales equally weight eligible tract-years, including zero-project tracts, and remain fixed for the interior-tract check. They are city-specific: use these to compare characteristics within a city. The additional natural-scale estimates below describe the same ten-percentage-point increase in either share, or 10% higher income, in both cities.</p>",
  "<h2>Sample coverage</h2>", html_table(c),
  "<p>Missing fields can overlap; their counts are not additive. Master HUD records remain unchanged. Only these regressions require all three characteristics and positive baseline housing. The following project statuses apply exclusions in the displayed data-cleaning order.</p>",
  html_table(p[, .(projects = .N), by = .(city_name, sample_status)]),
  "<h2>All estimates and boundary check</h2>",
  "<p>New York retains every available native tract in its five borough counties, matching the earlier homeowner analysis. Chicago keeps tracts with positive-area overlap with 2024 city limits. Demographics and housing denominators describe whole tracts; project counts include only HUD points inside the city. Interior models restrict both cities to tracts with at least 99% of their area inside current city limits. Chicago's main sample is not all of Cook County.</p>",
  "<p>Adjustment labels: baseline uses the original pooled sample; same_sample repeats that specification on rows with both added controls; housing_controls adds vacancy and density on those exact rows. Original standardization scales and year effects are retained in all cases.</p>",
  "<details><summary>All original and adjusted models, including natural-scale estimates</summary>", html_table(m), "</details>",
  "<h2>Timing and interpretation</h2>",
  "<p>Homeowner share is owner-occupied units divided by occupied units. Black share is non-Hispanic Black residents divided by population. Income is log median household income in 2024 dollars, using the existing national Census historical-income price index. Real dollars adjust time, not local living costs.</p>",
  "<p>For openings in 1987–1990, use 1980 Census observations; 1991–2000 use 1990; 2001–2010 use 2000. From 2011, use the ACS five-year release ending the preceding year (2022 openings use 2017–2021 ACS). These are prior observations, potentially ten years old, rather than interpolated conditions in the opening year. No field-specific backfilling is used.</p>",
  "<p>Poisson models have year effects and log baseline housing as an offset. Intervals use standard errors clustered on tract codes across years. Years with zero projects have no finite intercept and no slope information; their rows remain in the data and coverage counts. Native tract boundaries change over time.</p>",
  "<p>Both cities are pooled as Jacob requested. These results do not test a change after 2002 or identify effects of member deference or homeowner opposition. They omit approval dates, discretionary review status, land availability and other determinants of placement. See the task README for data definitions and execution order.</p>",
  "<p><a href='../../nyc_homeownership/output/diagnostics.html'>Earlier New York homeowner analysis and same-2000-Census sensitivity</a></p>")
writeLines(body, "../output/diagnostics.html")
