# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/local_control/code")
library(data.table)
m <- fread("../output/metro_fragmentation.csv")
r <- fread("../output/metro_correlations.csv")
x <- fread("../output/metro_comparison.csv")
measure_labels <- c(general_purpose_governments = "Active government count",
  governments_per_100k = "Governments per 100,000", central_city_population_share = "Central-city population share")
variable_labels <- c(homeowner_share = "Homeowner share", nh_black_share = "Non-Hispanic Black share", log_income = "Household income")
owner <- r[sample == "all_city_tracts" & variable == "homeowner_share"]
finding <- sprintf("<p class='note'>For the homeowner gradient, the raw-count correlation is <b>%.2f</b>, compared with <b>%.2f</b> after omitting NYC. Governments per 100,000 residents have a correlation of <b>%.2f</b>. Compare these with the full omission ranges below before interpreting a general relationship.</p>",
  owner[measure == "general_purpose_governments" & omitted_city == "none", pearson],
  owner[measure == "general_purpose_governments" & omitted_city == "New York City", pearson],
  owner[measure == "governments_per_100k" & omitted_city == "none", pearson])
rows <- character()
for (i in seq_len(nrow(m))) {
  z <- m[i]
  effect <- x[city_name == z$city_name & sample == "all_city_tracts" & variable == "homeowner_share", 100 * (natural_rate_ratio - 1)]
  rows <- c(rows, sprintf("<tr><td>%s</td><td>%s</td><td>%d / %d / %d</td><td>%d</td><td>%.2f</td><td>%.1f%%</td><td>%.1f%%</td></tr>",
    z$city_name, format(z$metro_population, big.mark = ","), z$active_county_governments,
    z$active_municipal_governments, z$active_township_governments,
    z$general_purpose_governments, z$governments_per_100k, 100 * z$central_city_population_share, effect))
}
body <- c("<!doctype html><meta charset='utf-8'><title>Metro fragmentation and LIHTC placement</title>",
  "<style>body{max-width:1400px;margin:32px auto;padding:0 24px;font:17px/1.5 system-ui;color:#172735}table{border-collapse:collapse;width:100%;font-size:14px}td,th{padding:9px;border-bottom:1px solid #ddd;text-align:left}th{background:#edf3f5}img{width:100%}a{color:#176b9b}.note{max-width:1050px}</style>",
  "<h1>Does a more fragmented metro have a steeper homeowner placement gradient?</h1>",
  "<p class='note'>This first comparison uses independent Census government counts. It does not yet measure the legal discretion of city officials. There are eight observations: one central city and its surrounding metropolitan statistical area (MSA) per row.</p>",
  finding,
  "<h2>What is counted?</h2>",
  "<table><tr><th>Central city</th><th>Metro population</th><th>County / municipal / township governments</th><th>Total active</th><th>Per 100,000 residents</th><th>Central-city population share</th><th>Homeowner gradient (+10 points)</th></tr>", rows, "</table>",
  "<p class='note'>Government inventory: 2022. Population: 2021. MSA boundaries: March 2020. School and special districts are excluded. Functionally dormant governments are counted separately in the data; none falls in these eight assigned MSAs. Census assigns cross-county governments to a primary county, which can be the county most served or headquarters county. This is a broad inventory measure, not a reconstructed map of all zoning authorities. NYC boroughs do not become five independent county governments, and San Francisco's consolidated government is counted once.</p>",
  "<p class='note'>Each LIHTC gradient pools 1987–2022 within the central city, using the established year effects and joint controls for homeowner share, Black share, income, vacancy and housing density. The outcome is annual LIHTC projects per baseline housing unit. A value of −25% means about 25% fewer projects associated with a 10-percentage-point higher homeowner share, holding the model's other variables fixed. These are within-city patterns, not placements across the entire MSA.</p>",
  "<h2>Homeownership, race and income</h2><a href='metro_gradients.png'><img src='metro_gradients.png' alt='Nine scatterplots comparing three metro measures with three LIHTC demographic gradients'></a>",
  "<p class='note'>The chart shows percentage changes for interpretability. Correlations below use the underlying signed log-rate changes. Negative homeowner correlations mean a more negative homeowner placement slope as the listed metro measure rises. A larger central-city population share indicates greater central-city reach; it is not a higher-fragmentation score. No composite index is constructed.</p>")
for (s in c("all_city_tracts", "interior_tracts")) {
  body <- c(body, sprintf("<h2>%s: correlations and sensitivity</h2>", if (s == "all_city_tracts") "All city tracts" else "Interior tracts"),
    "<table><tr><th>Metro measure</th><th>LIHTC gradient</th><th>Cities</th><th>Pearson r</th><th>Rank correlation</th><th>Pearson range omitting one city</th></tr>")
  main <- r[sample == s & omitted_city == "none"]
  for (i in seq_len(nrow(main))) {
    z <- main[i]
    loo <- r[sample == s & variable == z$variable & measure == z$measure & omitted_city != "none"]
    body <- c(body, sprintf("<tr><td>%s</td><td>%s</td><td>%d</td><td>%.2f</td><td>%.2f</td><td>%.2f to %.2f</td></tr>",
      measure_labels[z$measure], variable_labels[z$variable], z$n_cities, z$pearson, z$spearman,
      min(loo$pearson), max(loo$pearson)))
  }
  body <- c(body, "</table>")
}
body <- c(body,
  "<p class='note'>Every main correlation uses eight cities; each omission uses seven. The cities were selected for the previous exploratory comparison, not sampled to represent all cities. Their slopes are estimated with different precision; the figure shows that uncertainty. Correlation coefficients are descriptive, unweighted and have no causal interpretation. The modern government snapshot does not reconstruct institutions throughout the construction years. State allocation rules and other city differences remain possible explanations.</p>",
  "<p>Download <a href='metro_fragmentation.csv'>metro variables</a>, <a href='metro_comparison.csv'>matched gradients</a>, or <a href='metro_correlations.csv'>all correlations and city omissions</a>.</p>",
  "<p>Sources: <a href='https://www.census.gov/data/datasets/2022/econ/gus/public-use-files.html'>Census government inventory</a>, <a href='https://www.census.gov/geographies/reference-files/time-series/demo/metro-micro/historical-delineation-files.html'>fixed metro definitions</a>, and <a href='https://www2.census.gov/programs-surveys/popest/datasets/2020-2021/counties/totals/'>2021 population estimates</a>.</p>",
  "<p><a href='diagnostics.html'>Separate LOCUS legal-text assessment</a> · <a href='../MEASUREMENT_PLAN.md'>Measurement definitions and remaining legal work</a> · <a href='../../placement_gradients/output/diagnostics.html'>Original city gradients</a></p>")
writeLines(body, "../output/metro_diagnostics.html")
