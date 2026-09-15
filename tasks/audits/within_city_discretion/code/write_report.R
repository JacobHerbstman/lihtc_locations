# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/within_city_discretion/code")
library(data.table)
x <- fread("../output/city_comparison.csv")
routes <- fread("../output/approval_routes.csv", na.strings = "")
evidence <- as.data.table(read.csv("../output/evidence.csv", na.strings = ""))
cities <- unique(x[, .(place_geoid, city_name, short_description, answer, trigger, date_evidence, scope_limit)])
setorder(cities, city_name)
escape <- function(z) {
  z[is.na(z)] <- "Not established"
  z <- gsub("&", "&amp;", z, fixed = TRUE)
  z <- gsub("<", "&lt;", z, fixed = TRUE)
  gsub(">", "&gt;", z, fixed = TRUE)
}
body <- c("<!doctype html><html lang='en'><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'>",
  "<title>Can a compliant apartment still face discretionary approval?</title>",
  "<style>body{max-width:1250px;margin:36px auto;padding:0 24px;font:17px/1.55 system-ui;color:#20303d}h1{line-height:1.2}h2{margin-top:36px}table{border-collapse:collapse;width:100%;font-size:14px}td,th{padding:11px;border-bottom:1px solid #d5dde2;text-align:left;vertical-align:top}th{background:#edf2f5}img{width:100%}a{color:#176b9b}.note{border-left:4px solid #bc6d2d;padding:8px 18px;background:#fbf5ed}.scroll{overflow:auto}details{margin:18px 0;padding:14px;background:#f3f6f8}summary{cursor:pointer;font-weight:600}.muted{color:#596771}pre{white-space:pre-wrap;font-size:12px;max-height:340px;overflow:auto}</style>",
  "<h1>Can a compliant apartment still face discretionary approval?</h1>",
  "<p>First pilot for the eight cities in our LIHTC comparison. Start with a private apartment proposal whose use, density, height, setbacks and other objective requirements are allowed. Ask whether land-use approval still requires a judgment about design or neighborhood compatibility.</p>",
  "<p class='note'><b>The useful distinction is approval based on compliance, additional subjective review, and local review constrained by state law.</b> These are documented routes, not a city ranking. Some routes depend on project size or affordability. The reference year is 2022, but the evidence does not yet constitute eight complete 2022 legal snapshots.</p>",
  "<h2>First answers, beside the existing placement gradients</h2>",
  "<p>Each percentage is the associated change in annual LIHTC projects per baseline housing unit. Homeowner and non-Hispanic Black shares increase by 10 percentage points; household income increases by 10%. These are separate changes within the same joint model, not a comparison of equal-sized demographic shifts.</p>",
  "<div class='scroll'><table><tr><th>City</th><th>Approval route assessment</th><th>Homeowner</th><th>Black share</th><th>Income</th></tr>")
for (i in seq_len(nrow(cities))) {
  z <- cities[i]
  m <- x[place_geoid == z$place_geoid & sample == "all_city_tracts"]
  body <- c(body, sprintf("<tr><td><a href='#city-%s'>%s</a></td><td>%s</td><td>%.1f%%</td><td>%.1f%%</td><td>%.1f%%</td></tr>",
    z$place_geoid, z$city_name, escape(z$short_description),
    m[variable == "homeowner_share", percent_change], m[variable == "nh_black_share", percent_change], m[variable == "log_income", percent_change]))
}
body <- c(body, "</table></div>",
  "<p><b>New York is a useful check:</b> the ordinary as-of-right route requires no discretionary planning approval, yet its homeowner gradient is the most negative here. Formal review of a compliant proposal and the amount of land on which apartments are permitted are different mechanisms. Member deference may operate through requests to change zoning.</p>",
  "<img src='city_comparison.png' alt='Three panels showing city-specific LIHTC homeowner, Black-share and income gradients with 95 percent confidence intervals'>",
  "<p class='muted'>Pooled 1987–2022 placements within each city. All shown models retain year effects, the other two demographics, prior vacancy and housing density. Intervals are tract-clustered. The matched CSV preserves both all-city and interior-tract samples, all coefficient intervals and actual model Ns. Legal categories do not enter these models.</p>",
  "<h2>What the fields mean</h2>",
  "<p><code>local_subjective_review</code> records whether the selected route applies judgment beyond objective compliance. <code>subjective_denial_code</code> asks the narrower question of lawful denial solely on subjective land-use grounds: 1 = supported, 0 = compliance route or applicable state limit, blank = not established. A zero does not mean freedom from building, environmental or health-and-safety requirements. <code>binding_land_use_actor</code> identifies the decision maker; board and elected approval, advice, appeals, state limits and affordable exceptions remain separate.</p>",
  "<p>No number of independent vetoes is inferred by counting every meeting or agency. Chicago's Plan Commission recommends and its Council decides. Seattle's Director decides, but a four-member Design Review Board recommendation constrains permit conditions unless a specified inconsistency or legal conflict applies. That is stronger than purely optional advice.</p>",
  "<h2>City evidence and route conditions</h2>")
for (i in seq_len(nrow(cities))) {
  z <- cities[i]
  body <- c(body, sprintf("<h3 id='city-%s'>%s</h3><p>%s</p><p><b>Trigger:</b> %s</p><p><b>Dates:</b> %s</p><p><b>Scope:</b> %s</p>",
    z$place_geoid, z$city_name, escape(z$answer), escape(z$trigger), escape(z$date_evidence), escape(z$scope_limit)))
  n <- unique(x[place_geoid == z$place_geoid & sample == "all_city_tracts", .(projects, tract_years, tract_code_clusters)])
  stopifnot(nrow(n) == 1)
  body <- c(body, sprintf("<p class='muted'>Shown model sample: %s projects, %s tract-years, %s tract-code clusters.</p>",
    format(n$projects, big.mark = ","), format(n$tract_years, big.mark = ","), format(n$tract_code_clusters, big.mark = ",")))
  rr <- routes[place_geoid == z$place_geoid]
  for (j in seq_len(nrow(rr))) {
    a <- rr[j]
    ids <- strsplit(a$evidence_ids, ";", fixed = TRUE)[[1]]
    links <- paste(sprintf("<a href='#evidence-%s'>%s</a>", ids, ids), collapse = " · ")
    body <- c(body, sprintf("<details><summary>%s</summary><p>%s</p><p><b>Subjective review:</b> %s. <b>Subjective denial code:</b> %s.</p><p><b>Binding actor:</b> %s</p><p><b>Board and public role:</b> %s</p><p><b>Appeal/request:</b> %s</p><p><b>State law:</b> %s</p><p><b>Affordable housing:</b> %s</p><p>%s</p><p>Evidence: %s</p></details>",
      escape(a$route_name), escape(a$trigger), escape(as.character(a$local_subjective_review)), escape(as.character(a$subjective_denial_code)),
      escape(a$binding_land_use_actor), escape(a$advisory_or_comment_role), escape(a$appeal_or_request), escape(a$state_limit),
      escape(a$affordable_exception), escape(a$scope_limit), links))
  }
}
body <- c(body,
  "<h2>What this pilot establishes</h2>",
  "<p>The unit is a city and approval route, with the evidence's actual dates retained. Twelve routes cover eight cities. Three cities have a documented ordinary compliance route; Chicago and Seattle have review triggered by specified conditions; California cities require separate treatment of local process and state constraints; Boston's 2022 legal coding is unresolved.</p>",
  "<p>Before estimating a city-level discretion correlation, finish the dated Boston text and the remaining denial/exception fields, then apply the same proposal definition across cities. Keep ordinary and affordable routes separate. Do not average the listed routes: their number is not the fraction of parcels or projects exposed to discretion. A further measure of how often apartments need rezoning would address a different part of the local-control hypothesis.</p>",
  "<p>This is a disclosed agent-coded pilot with committed decisions and evidence, not an automated classifier or an independently validated legal dataset. It asks for no building-by-building adjudication. A replay reproduces the table; it does not independently validate the legal judgments. No city-level correlation is reported from incomplete, differently dated route coverage.</p>",
  "<p>Downloads: <a href='approval_routes.csv'>approval routes and definitions</a> · <a href='city_comparison.csv'>all three matched gradients and actual Ns</a> · <a href='evidence.csv'>evidence locators and source text</a> · <a href='../README.md'>codebook and execution order</a>.</p>",
  "<h2>Sources</h2>")
for (i in seq_len(nrow(evidence))) {
  e <- evidence[i]
  body <- c(body, sprintf("<details id='evidence-%s'><summary>%s: %s</summary><p>%s</p><p><a href='%s'>Original source</a> · Locator: %s</p><p class='muted'>Source version/hash: %s</p></details>",
    e$evidence_id, e$evidence_id, escape(e$section), escape(e$interpretation), e$source_url, escape(e$source_locator), escape(e$source_version)))
}
body <- c(body, "<p><a href='../../local_control/output/metro_diagnostics.html'>Separate metro-fragmentation comparison</a> · <a href='../../placement_gradients/output/diagnostics.html'>Original placement analysis</a></p></html>")
writeLines(body, "../output/diagnostics.html")
