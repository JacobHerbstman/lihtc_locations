# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/nyc_homeownership/code")
library(data.table)
library(jsonlite)
coverage <- fread("../output/coverage.csv")
models <- fread("../output/models.csv")
annual <- fread("../output/annual_summary.csv", na.strings = "")
projects <- fread("../output/project_sample.csv", na.strings = "")
status <- projects[, .(projects = .N), by = sample_status]
models[, percent_change := 100 * (rate_ratio - 1)]
main <- models[specification == "main" & adjustment == "year"]
change <- main[comparison == "later_minus_earlier"]
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
body <- c("<!doctype html><meta charset='utf-8'><title>New York LIHTC and prior homeownership</title>",
  "<style>body{max-width:1150px;margin:35px auto;padding:0 24px;font:16px/1.5 system-ui;color:#172735}h1,h2{line-height:1.2}img{width:100%}.table{overflow:auto;margin:20px 0}table{border-collapse:collapse;font-size:13px}td,th{padding:7px 10px;border-bottom:1px solid #ddd;text-align:right}th{background:#edf3f5}td:first-child,th:first-child{text-align:left}</style>",
  "<h1>New York LIHTC placements and prior homeownership</h1>",
  "<p>Compare 1987–2002 with 2003–2022. This is a descriptive check of whether the relationship between homeowner concentration and new-construction placements became more negative. HUD's incomplete 2023–2024 cohorts are omitted from this analysis; the master dataset is unchanged.</p>",
  "<p>Homeowner share means owner-occupied units divided by occupied units. Each project's context comes from the latest Census observation ending before its placed-in-service year. Early observations can be several years old. These dates describe opening, not the start of construction or discretionary approval.</p>",
  "<h2>First result</h2>",
  sprintf("<p>Ten percentage points higher prior homeownership is associated with a <b>%.1f%%</b> change in the placement rate through 2002 and a <b>%.1f%%</b> change afterward, accounting for year-specific placement volume and existing housing. The later-to-earlier ratio is %.3f (95%% interval %.3f–%.3f). The interval includes one, so this first comparison does not establish a stronger relative homeowner gradient.</p>",
    main[comparison == "through_2002", percent_change], main[comparison == "after_2002", percent_change], change$rate_ratio, change$ci_low, change$ci_high),
  "<p>The later period has many more placements overall. Its absolute rate difference between low- and high-homeowner neighborhoods is larger, while the estimated proportional relationship is similar. Those are different comparisons. The borough/year model and the same-2000-Census comparison also do not show a clearly stronger later gradient.</p>",
  "<p>There are no retained NYC project records dated 1987–1989, so this sample does not provide a pre-Morris comparison. Three NYC records lack years, 24 are in the incomplete 2023–2024 cohorts, and two later projects have no defined prior homeowner share because their baseline tracts have zero housing. All remain in the national dataset.</p>",
  "<h2>Coverage</h2>", html_table(coverage), html_table(status),
  "<h2>Placements relative to existing housing</h2>",
  "<p>The denominator includes every eligible NYC tract-year, including zero placements. Rates divide project counts by baseline housing-unit-years, then multiply by 10,000. This accounts for the different lengths of the two periods and different quantities of existing housing. Unit rates sum only observed project unit counts.</p>")
for (file in c("rates_main.png", "annual_homeownership.png", "placement_maps.png", "rates_same_2000.png")) {
  path <- paste0("../output/", file)
  body <- c(body, paste0("<img alt='", file, "' src='data:image/png;base64,", base64_enc(readBin(path, "raw", file.info(path)$size)), "'>"))
}
body <- c(body, "<h2>Does the homeowner gradient become more negative?</h2>",
  "<p>Poisson regressions model annual project counts with a baseline housing-unit offset. The year specification allows overall placement rates to differ each year. Borough/year effects additionally compare neighborhoods within the same borough and year. Rate ratios describe ten percentage points higher homeownership: 0.80 means a 20% lower placement rate. The later-minus-earlier row reports the ratio of the two rate ratios; below one means a more negative later relationship.</p>",
  html_table(models),
  "<details><summary>Annual project counts and Census observation years</summary>", html_table(annual), "</details>",
  "<p>Intervals are 95% normal intervals using standard errors clustered on tract codes across years. Native tract boundaries change, so this is not a panel of identical geographic units. Zero-placement borough/year strata have no finite Poisson intercept and provide no slope information; omitted tract-year Ns are reported. The same-2000 comparison uses 2001–2002 versus 2003–2010 with the same demographic values and boundaries on both sides.</p>",
  "<h2>What this comparison can establish</h2>",
  "<p>A stronger negative gradient would be consistent with the proposed homeowner-opposition mechanism. It would not show that member deference caused it. The models do not measure which projects required discretionary review or control land availability, financing programs, neighborhood change, or approval-to-opening lags. A common 2002 opening cutoff cannot date each project's political exposure.</p>",
  "<p><a href='https://www.govinfo.gov/content/pkg/USREPORTS-489/pdf/USREPORTS-489-688.pdf'>Board of Estimate v. Morris</a> was decided March 22, 1989. The <a href='https://www.nyc.gov/html/records/pdf/govpub/35672001_per_vol.1.pdf'>2001 Campaign Finance Board report</a> records that term limits prevented Vallone's reelection and that Miller became speaker afterward. The evolution of member deference is the research hypothesis, not a variable observed in this dataset.</p>",
  "<p>Data definitions and reproducible execution order are in tasks/audits/nyc_homeownership/README.md. No manual building decisions or source changes enter this analysis.</p>")
writeLines(body, "../output/diagnostics.html")
