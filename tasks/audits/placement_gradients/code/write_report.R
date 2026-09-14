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
main <- m[sample == "all_city_tracts" & model == "separate" & comparison != "later_minus_earlier"]
main[, percent_change := 100 * (rate_ratio - 1)]
main[, characteristic := labels[variable]]
main[, period := fifelse(comparison == "through_2002", "Through 2002", "After 2002")]
main[, interval := sprintf("%.1f%% to %.1f%%", 100 * (ci_low - 1), 100 * (ci_high - 1))]
scales <- s[, .(city_name, characteristic = labels[variable],
  one_SD = sprintf("%.1f %s", sd_in_percent_units, fifelse(variable == "log_income", "% higher income", "percentage points")))]
body <- c("<!doctype html><meta charset='utf-8'><title>New York and Chicago LIHTC placement gradients</title>",
  "<style>body{max-width:1200px;margin:35px auto;padding:0 24px;font:16px/1.5 system-ui;color:#172735}h1,h2{line-height:1.2}img{width:100%}.table{overflow:auto;margin:20px 0}table{border-collapse:collapse;font-size:13px}td,th{padding:7px 10px;border-bottom:1px solid #ddd;text-align:right}th{background:#edf3f5}td:first-child,th:first-child{text-align:left}</style>",
  "<h1>Compare homeownership, race and income gradients</h1>",
  sprintf("<p>New York City and Chicago; project openings in %d–%d versus %d–%d. Each city's three models use exactly the same tracts and projects, with neighborhood observations ending strictly before opening. The outcome is annual HUD new-construction project records per baseline housing unit, accounting for differences in overall placement rates across years.</p>",
    period$first_year, period$cutoff_year, period$cutoff_year + 1L, period$last_year),
  "<p><b>How to compare sizes:</b> each effect describes one standard deviation higher neighborhood characteristic, using a fixed scale calculated across both periods within that city. Income is logged, so a change is proportional. Larger absolute log rate changes mean stronger associations: twice as many and half as many have the same proportional strength. The rankings below compare point estimates, without a formal test that one characteristic's gradient exceeds another's.</p>")
for (city in unique(main$city_name)) {
  body <- c(body, paste0("<h2>", city, "</h2>"))
  for (era_name in c("through_2002", "after_2002")) {
    z <- main[city_name == city & comparison == era_name][order(-abs(log_rate_change))]
    body <- c(body, sprintf("<p><b>%s:</b> the magnitude ordering is %s. For a one-SD increase, the associated changes are %s.</p>",
      if (era_name == "through_2002") "Through 2002" else "After 2002",
      paste(z$characteristic, collapse = " → "),
      paste(sprintf("%s %+.1f%%", z$characteristic, z$percent_change), collapse = "; ")))
  }
}
body <- c(body, "<h2>The common-scale comparison</h2>",
  "<p>The upper panels examine each characteristic separately. The lower panels include all three together, allowing every coefficient to differ across periods. Differences between those panels show overlap between the characteristics, not causal effects.</p>",
  paste0("<img alt='Placement rate ratios by city, period, and characteristic' src='data:image/png;base64,",
    base64_enc(readBin("../output/gradients.png", "raw", file.info("../output/gradients.png")$size)), "'>"),
  html_table(main[, .(city_name, period, characteristic, percent_change, interval)]),
  "<h2>What is a one-standard-deviation difference here?</h2>", html_table(scales),
  "<p>Scales equally weight eligible tract-years, including zero-project tracts, and remain fixed across both periods and the interior-tract check. They are city-specific: use these to compare characteristics within a city. The additional natural-scale estimates below describe the same ten-percentage-point increase in either share, or 10% higher income, in both cities.</p>",
  "<h2>Sample coverage</h2>", html_table(c),
  "<p>Missing fields can overlap; their counts are not additive. Master HUD records remain unchanged. Only these regressions require all three characteristics and positive baseline housing. The following project statuses apply exclusions in the displayed data-cleaning order.</p>",
  html_table(p[, .(projects = .N), by = .(city_name, sample_status)]),
  "<h2>All estimates and boundary check</h2>",
  "<p>New York retains every available native tract in its five borough counties, matching the earlier homeowner analysis. Chicago keeps tracts with positive-area overlap with 2024 city limits. Demographics and housing denominators describe whole tracts; project counts include only HUD points inside the city. Interior models restrict both cities to tracts with at least 99% of their area inside current city limits. Chicago's main sample is not all of Cook County.</p>",
  "<details><summary>Separate and joint models, including changes after 2002 and natural-scale estimates</summary>", html_table(m), "</details>",
  "<h2>Timing and interpretation</h2>",
  "<p>Homeowner share is owner-occupied units divided by occupied units. Black share is non-Hispanic Black residents divided by population. Income is log median household income in 2024 dollars, using the existing national Census historical-income price index. Real dollars adjust time, not local living costs.</p>",
  "<p>For openings in 1987–1990, use 1980 Census observations; 1991–2000 use 1990; 2001–2010 use 2000. From 2011, use the ACS five-year release ending the preceding year (2022 openings use 2017–2021 ACS). These are prior observations, potentially ten years old, rather than interpolated conditions in the opening year. No field-specific backfilling is used.</p>",
  "<p>Poisson models have year effects and log baseline housing as an offset. Intervals use standard errors clustered on tract codes across years. Years with zero projects have no finite intercept and no slope information; their rows remain in the data and coverage counts. Native tract boundaries change over time. The later-minus-earlier rows report ratios of rate ratios.</p>",
  "<p>The 2002 cutoff is the previously chosen NYC timing comparison; in Chicago it is a common descriptive split, not an identified change in institutions. These results do not identify the effect of member deference or homeowner opposition. They omit approval dates, discretionary review status, land availability and other determinants of placement. See the task README for data definitions and execution order.</p>",
  "<p><a href='../../nyc_homeownership/output/diagnostics.html'>Earlier New York homeowner analysis and same-2000-Census sensitivity</a></p>")
writeLines(body, "../output/diagnostics.html")
