# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/census_diagnostics/code")
library(data.table)
library(jsonlite)
city_list <- fread("cities.csv", colClasses = "character")
projects <- fread("../input/projects_with_tracts.csv", na.strings = "")
states <- fread("../output/coverage_by_state.csv")
vintages <- fread("../output/coverage_by_vintage.csv", na.strings = "")
cities <- fread("../output/city_tracts.csv", na.strings = "")
setorder(vintages, period_end)
groups <- fread("../output/city_income_groups.csv", na.strings = "")

# Small shared rendering routine for the report's data tables.
html_table <- function(x) {
  y <- copy(x)
  for (field in names(y)) {
    value <- y[[field]]
    if (is.numeric(value)) value <- format(round(value, 2), trim = TRUE, big.mark = ",", scientific = FALSE)
    value[is.na(value) | value == "NA"] <- "—"
    value <- gsub("&", "&amp;", value, fixed = TRUE)
    value <- gsub("<", "&lt;", value, fixed = TRUE)
    set(y, j = field, value = value)
  }
  paste0("<div class='table'><table><thead><tr><th>", paste(gsub("_", " ", names(y)), collapse = "</th><th>"),
    "</th></tr></thead><tbody>", paste(apply(y, 1L, function(z) paste0("<tr><td>", paste(z, collapse = "</td><td>"), "</td></tr>")), collapse = ""), "</tbody></table></div>")
}
city_summary <- cities[, .(tracts = .N, edge_tracts = sum(edge_tract),
  tracts_without_lihtc = sum(city_lihtc_projects == 0), projects_in_matched_city_tracts = sum(city_lihtc_projects)), by = city_name]
ceilings <- projects[, .(projects = .N), by = income_ceiling_type]
ceilings[is.na(income_ceiling_type), income_ceiling_type := "Not reported"]
ceilings[, percent := 100 * projects / nrow(projects)]
body <- c("<!doctype html><meta charset='utf-8'><title>LIHTC and Census tract diagnostics</title>",
  "<style>body{max-width:1200px;margin:35px auto;padding:0 24px;font:16px/1.5 system-ui;color:#172735}h1,h2{line-height:1.2}table{border-collapse:collapse;font-size:13px}td,th{padding:7px 10px;border-bottom:1px solid #ddd;text-align:right}td:first-child,th:first-child{text-align:left}th{background:#edf3f5}.table{overflow:auto;margin:20px 0}.maps{display:grid;grid-template-columns:repeat(3,1fr);gap:10px}img{width:100%}p{max-width:950px}</style>",
  "<h1>LIHTC locations and Census tracts</h1>",
  sprintf("<p><b>%s HUD project records remain in the dataset.</b> %s match the latest ACS; %s match a Census observation ending before placed-in-service. Missing dates or Census fields never remove a project.</p>",
    format(nrow(projects), big.mark = ","), format(sum(projects$latest_tract_match_status == "matched"), big.mark = ","), format(sum(projects$baseline_tract_match_status == "matched"), big.mark = ",")),
  "<p>One observation is one HUD new-construction ID with its own HUD coordinate. First-address deduplication remains a separate sensitivity. Tracts and cities are assigned from the same HUD coordinate. Original HUD tract codes are retained and disagreements are flagged. Multiple polygon matches remain unresolved.</p>",
  "<h2>HUD affordability fields</h2>", html_table(ceilings),
  "<p>These are HUD's elected income-ceiling categories, not observed rents. Lower-ceiling unit counts and low-income-unit shares remain in the project file. A separate HUD area-limit source is needed to express program eligibility in dollars.</p>",
  "<h2>National coverage by source observation</h2>",
  "<p>These files contain all available tracts in all 50 states and DC, including zero-LIHTC tracts. Historical tract coverage is incomplete geographically before full national tract/BNA coverage. ACS periods overlap; geography can change between releases.</p>", html_table(vintages),
  "<h2>Dollar and variable definitions</h2>",
  "<p>Income is median household income. Homeowner share is owner-occupied units divided by occupied units. Race/ethnicity shares divide by total population; Hispanic ethnicity is separated from non-Hispanic race. Poverty uses the population with poverty status determined; college uses people age 25 or older.</p>",
  "<p>Real values use 2024 dollars and Census’s published continuous national historical-income price series: R-CPI-U-RS before 2000, chained CPI-U from 2000. Income in the 1980, 1990 and 2000 Census uses 1979, 1989 and 1999 dollar years; housing dollars use the Census year. ACS dollars already refer to the final survey year. This is time deflation, not a comparison of local price levels. It differs from the all-years R-CPI-U-RS convention used in Census ACS comparison tables.</p>",
  "<p>Raw medians and annotations remain available. Suppression, Census negative sentinel codes, and bounded medians are not exact numeric estimates. ACS margins of error are retained and monetary MOEs use the same conversion as estimates. The 1980 education measure is four or more years of college; the later measure is a bachelor’s degree or more. Pre-2000 Asian categories are not silently equated to Asian alone. The 1980 rent series has weak usable coverage; positive published values are kept unless suppressed or identified as bounds in the original Census documentation.</p>",
  "<p>Sources: <a href='https://www.nhgis.org/'>IPUMS NHGIS v21 (2026)</a>; <a href='https://www.census.gov/data/developers/data-sets/acs-5year.html'>Census ACS five-year API</a>; <a href='https://www.census.gov/topics/income-poverty/income/guidance/current-vs-constant-dollars.html'>Census real-dollar methodology</a>.</p>",
  "<h2>City maps and comparisons</h2>", html_table(city_summary),
  "<p>City boundaries are fixed at 2024. Every positive-area intersecting tract is kept. Edge-tract characteristics describe the whole tract; city LIHTC counts include only points inside the city. The interior-tract sensitivity excludes edge tracts. The latest comparison below uses current housing units and is descriptive; baseline-period counts and rates are in tract_lihtc_counts.csv.</p>")
for (id in city_list$place_geoid) {
  city_name <- city_list$city_name[match(id, city_list$place_geoid)]
  body <- c(body, paste0("<h3 id='city-", id, "'>", city_name, "</h3><div class='maps'>"))
  for (variable in c("income", "race", "homeowners")) {
    file <- paste0("../output/", id, "_", variable, ".png")
    body <- c(body, paste0("<img alt='", city_name, " ", variable, " map' src='data:image/png;base64,", base64_enc(readBin(file, "raw", file.info(file)$size)), "'>"))
  }
  body <- c(body, "</div>")
}
body <- c(body, "<h2>Latest income groups</h2>", html_table(groups),
  "<h2>Project coverage by state</h2>", html_table(states),
  "<p>The downloadable coverage_by_cohort.csv further breaks these denominators down by state and placed-in-service year. No manual building decisions enter the pipeline.</p>")
writeLines(body, "../output/diagnostics.html")
