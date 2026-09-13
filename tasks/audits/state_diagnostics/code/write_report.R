# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/state_diagnostics/code")
library(data.table)
library(jsonlite)
s <- fread("../output/state_summary.csv", na.strings = "")
y <- fread("../output/state_year_counts.csv")
n <- fread("../input/sample_sizes.csv")
stats <- fread("../input/summary_statistics.csv")
categories <- fread("../input/category_counts.csv")
stopifnot(nrow(s) == 51L, !anyDuplicated(s$state), !anyDuplicated(y[, .(state, year)]))
# Formatting helpers are shared by the tables and narrative numbers in this report.
number <- function(v) format(v,big.mark=",",scientific=FALSE,trim=TRUE)
percent <- function(v) ifelse(is.na(v),"—",sprintf("%.1f%%",v))
html_table <- function(d) {
  rows <- apply(as.data.frame(d),1,function(row) paste0("<tr><td>",paste(row,collapse="</td><td>"),"</td></tr>"))
  paste0("<div class='table-wrap'><table><thead><tr><th>",paste(names(d),collapse="</th><th>"),
    "</th></tr></thead><tbody>",paste(rows,collapse="\n"),"</tbody></table></div>")
}
embedded_plot <- function(path,alt) {
  paste0("<img alt='",alt,"' src='data:image/png;base64,",base64_enc(readBin(path,"raw",n=file.info(path)$size)),"'>")
}

# The same state and year counts feed the downloadable tables and figures.
totals <- s[, .(
  Sample = c("All HUD new-construction records", "Main dataset: HUD IDs with coordinates", "Sensitivity: first address with HUD coordinates"),
  Records = number(c(sum(new_records), sum(selected_records), sum(first_address_records))),
  `Reported units` = number(c(sum(new_units), sum(selected_units), sum(first_address_units))),
  `Records with units` = number(c(sum(new_units_known), sum(units_known), sum(first_address_units_known)))
)]
availability <- n[, .(Sample = sample, N = number(n), `Missing from master` = number(missing_from_master),
                      `Available %` = percent(available_pct))]
coverage <- s[order(-coordinates_missing_pct), .(
  State = state_name, `All HUD records` = number(hud_records), `Type missing %` = percent(type_missing_pct),
  `New construction` = number(new_records), `HUD coordinates` = number(hud_coordinate_records),
  `Coordinates missing %` = percent(coordinates_missing_pct),
  `Extra coordinate loss after year adjustment (pp)` = sprintf("%+.1f", excess_coordinate_loss_pp))]
selection <- s[order(state_name), .(
  State = state_name, `All IDs with HUD coordinates` = number(hud_coordinate_records),
  `First address + HUD coordinates` = number(first_address_records),
  `Units: main dataset` = number(selected_units), `Units: first address` = number(first_address_units),
  `Counting-rule reduction %` = percent(first_address_reduction_pct))]
reasons <- s[order(state_name), .(
  State = state_name, `Main dataset` = number(selected_records),
  `Unknown order at repeated address` = number(first_omitted_uncertain_order),
  `Later records` = number(first_omitted_later), `Other earliest-year ties` = number(first_omitted_same_year),
  `First-address comparison` = number(first_address_records))]
hedonics <- s[order(-all_controls_missing_pct), .(
  State = state_name, Locations = number(selected_records), `With year` = number(year_known),
  `With total units` = number(units_known), `With complete bedrooms` = number(bedrooms_known),
  `Year + units` = number(year_units_known), `Year + units + bedrooms` = number(year_units_bedrooms_known),
  `Plus three targeting indicators` = number(all_controls_known),
  `Extra joint-sample loss after year adjustment (pp)` = sprintf("%+.1f", excess_controls_loss_pp))]
flags <- s[order(state_name), .(
  State = state_name, `Unresolved address text` = number(unresolved_addresses),
  `Scattered-site flag` = number(scattered_records), `Resyndication flag` = number(resyndicated_records),
  `Records at shared addresses` = number(repeated_address_records))]
annual <- y[, .(Source = sum(new_records), Main = sum(selected_records),
                `First-address comparison` = sum(first_address_records),
                `Units: main` = sum(selected_units), `Units: first address` = sum(first_address_units),
                `Main with units` = sum(units_known),
                `Year + units + bedrooms` = sum(year_units_bedrooms_known)), by = .(Year = year)][order(Year)]

# Summary statistics use each record's own cleaned values and variable-specific Ns.
labels <- c(pis_year = "Placed-in-service year", allocation_year = "Allocation year",
            total_units = "Total project units", low_income_units = "Low-income project units",
            bedrooms_0 = "Efficiency units per project", bedrooms_1 = "One-bedroom units per project",
            bedrooms_2 = "Two-bedroom units per project", bedrooms_3 = "Three-bedroom units per project",
            bedrooms_4 = "Four-bedroom units per project", credit_type = "Credit type",
            target_family = "Targets families", target_elderly = "Targets elderly residents",
            target_disabled = "Targets disabled residents", scattered_site = "Scattered-site project",
            resyndicated = "Resyndication flag", repeated_address = "Shared standardized address")
statistics <- stats[, .(Characteristic = unname(labels[variable]), N = number(n), Missing = number(missing),
                       Mean = sprintf("%.1f", mean), SD = sprintf("%.1f", sd),
                       P25 = sprintf("%.1f", p25), Median = sprintf("%.1f", median),
                       P75 = sprintf("%.1f", p75))]
category_table <- categories[, .(Characteristic = unname(labels[variable]), Category = category,
                                N = number(n), `Percent of all projects` = percent(percent_all),
                                `Percent among known` = percent(percent_known))]
stopifnot(!anyNA(statistics$Characteristic), !anyNA(category_table$Characteristic))
writeLines(c(
"<!doctype html><html lang='en'><meta charset='utf-8'><meta name='viewport' content='width=device-width, initial-scale=1'>",
"<title>LIHTC dataset: coverage and sample sizes</title><style>",
"body{font:17px/1.55 system-ui,sans-serif;color:#19313e;background:#fff;margin:0}main{max-width:1180px;margin:50px auto;padding:0 28px}h1{font-size:37px;line-height:1.15;margin-bottom:12px}h2{margin-top:48px;font-size:25px}h3{font-size:20px}p{max-width:920px}.muted{color:#596b75;font-size:14px}img{width:100%;height:auto;margin:16px 0}.table-wrap{overflow:auto;max-height:640px;border:1px solid #dbe2e5;margin:18px 0}table{width:100%;border-collapse:collapse;font-size:14px;white-space:nowrap}th,td{padding:10px 13px;border-bottom:1px solid #e4e9ec;text-align:right}th:first-child,td:first-child{text-align:left}thead th{position:sticky;top:0;background:#edf3f5;color:#203d4d;cursor:pointer;z-index:1}tbody tr:nth-child(even){background:#f7f9fa}a{color:#136b82}input{font:inherit;padding:9px 12px;border:1px solid #aabdc8;border-radius:4px;width:300px}.finding{border-left:4px solid #bf7538;padding-left:18px}details{margin:24px 0}summary{cursor:pointer;font-weight:650}@media print{.table-wrap{max-height:none;overflow:visible}input{display:none}main{margin:0}thead th{position:static}img{break-inside:avoid}}</style><main>",
"<p class='muted'>HUD 2024 release · 50 states and DC · September 12, 2026</p>",
"<h1>LIHTC new-construction locations and available characteristics</h1>",
"<p class='finding'><strong>The master file keeps every unique HUD new-construction project ID with HUD coordinates.</strong> Missing dates or hedonics do not remove locations. Shared-address, scattered-site and resyndication flags remain diagnostic. No Census fallback or individual adjudication enters selection.</p>",
html_table(totals),
"<p>One row is one HUD-reported new-construction project ID, with its own date and hedonics. Different phases can share an address and remain separate rows. The date is placed-in-service year, not groundbreaking. No cross-record averaging, unit summation or consensus changes a project. This is a project dataset, not a verified building or parcel census.</p>",
"<p class='muted'>Reported unit sums omit missing values; the adjacent N shows their coverage. Project-unit sums can include repeated financing when source records describe the same physical housing. Missing construction type prevents describing this as a census of every LIHTC construction.</p>",
"<h2>Project size and bedroom counts</h2>",
html_table(statistics),
"<p class='muted'>Means and quantiles give each project equal weight and use only that variable's observed values. Bedroom columns count units per project, not bedrooms per unit. Individual bedroom categories can have different Ns because valid partial breakdowns remain. SD is the sample standard deviation; the CSV also reports minima and maxima.</p>",
embedded_plot("../output/project_characteristics.png", "Project size distribution and unit-weighted bedroom mix"),
"<p><a href='characteristic_distributions.csv'>Distribution counts, denominators and percentages (CSV)</a></p>",
"<h2>What about rent?</h2>",
"<p>The original HUD property workbook has no dollar rent field, so average actual rent is unavailable for this sample. INC_CEIL and LOW_CEIL describe rent/income restrictions, and rental-assistance fields describe program participation; they are not observed rents. No rent proxy has been added.</p>",
"<p>HUD collects rent information separately through its <a href='https://www.huduser.gov/portal/datasets/lihtc/tenant.html'>tenant data</a>. Its published state tables describe rent burdens and rental assistance. They are not a mean dollar rent for these construction projects, and a later tenant observation would not establish rent at construction.</p>",
"<h2>Credit type, targeting and scope flags</h2>",
html_table(category_table),
"<p class='muted'>Percent of all projects includes missing responses in the denominator. Percent among known excludes them. Family, elderly and disabled targeting can overlap and their shares must not be added.</p>",
"<h2>How N changes when an analysis needs more information</h2>",
html_table(availability),
"<p>Each variable uses its observed values. The joint rows show explicit combinations of required fields; they do not define additional dataset versions. Regressions must report the N for their actual outcome and controls. When adding controls, also compare specifications on the same observations to distinguish a control effect from a changing sample.</p>",
"<p>Valid partial bedroom counts are retained. A complete bedroom mix requires all five counts to sum to total units. A contradictory breakdown becomes missing, while total units and the project remain. Targeting indicators distinguish yes (1), no (0), and unknown (missing); HUD's not-indicated code is not treated as no.</p>",
"<h2>Which states are missing source information?</h2>",
sprintf("<p>%s of %s source records lack construction type (%s). Separately, %s of %s new-construction records lack HUD coordinates (%s).</p>",
        number(sum(s$type_unknown)), number(sum(s$hud_records)), percent(100*sum(s$type_unknown)/sum(s$hud_records)),
        number(sum(s$new_records-s$hud_coordinate_records)), number(sum(s$new_records)),
        percent(100*sum(s$new_records-s$hud_coordinate_records)/sum(s$new_records))),
embedded_plot("../output/type_missing_pct.png", "Share of all HUD records missing construction type by state"),
embedded_plot("../output/coordinates_missing_pct.png", "Share of new-construction records missing HUD coordinates by state"),
"<label>Find a state: <input id='state-filter' placeholder='e.g. Kentucky' aria-label='Find a state'></label><p class='muted'>Click a table heading to sort.</p>",
html_table(coverage),
"<details><summary>Construction type by state and year</summary>",
embedded_plot("../output/type_by_year.png", "Construction-type missingness by state and year"), "</details>",
"<h2>How much does first-address counting change the dataset?</h2>",
"<p>First address is a sensitivity comparison only. It keeps the earliest year at a standardized address, breaking ties with the smallest HUD ID. An address with incomplete dates cannot be ordered and is omitted only from this comparison; an undated singleton remains. The comparison selects first records before requiring HUD coordinates. Both series retain each chosen record's own hedonics, so their difference reflects counting alone. The previous consensus treatment of tied hedonics is retired.</p>",
embedded_plot("../output/annual_comparison.png", "Annual record and unit counts under the source, all-located-ID and first-address rules"),
html_table(selection),
"<details><summary>Why first-address counting produces fewer records</summary><p>These mutually exclusive counts describe records retained in the main file but omitted from the first-address comparison. They plus first-address records equal the main sample. They are counting choices, not confirmed source errors. Only missing HUD coordinates exclude TYPE=1 records from the main dataset.</p>",
html_table(reasons), "</details>",
"<h2>Does availability of hedonics vary by state?</h2>",
html_table(hedonics),
"<p class='muted'>The joint sample requires year, total units, a complete bedroom breakdown and known family, elderly and disabled targeting indicators. Year adjustment applies national availability within each reported cohort to the state's own cohort composition. Positive percentage points mean extra loss beyond that year mix. This diagnostic neither fixes selection nor establishes representativeness.</p>",
"<details><summary>Retained scope and address flags</summary>", html_table(flags),
"<p>A scattered-site project has only its HUD primary point; its units are project totals and must not be copied to multiple sites. A resyndication flag is retained despite TYPE=1 and does not prove fresh physical construction. HUD points are not verified building footprints.</p></details>",
"<details><summary>Annual counts, including missing dates</summary>", html_table(annual), "</details>",
"<h2>External sanity checks</h2>",
"<p>The pinned workbook exactly reproduces the <a href='https://www.huduser.gov/portal/Datasets/lihtc/LIHTC-2024-Tables.pdf'>HUD 2024 published table</a>: 55,345 properties and 3,860,546 adjusted units across all construction types and geographies. All ten annual property counts and adjusted-unit totals for 2015–2024 also match. These check the source import; our new-construction sample has a narrower definition and uses reported rather than adjusted unit counts.</p>",
"<p>New construction is 61.43% of source records with known construction type, versus 61.5% in the publication. Annual differences are less than 0.34 percentage points. These small differences are recorded in the audit, without changing source classifications to force agreement. HUD marks 2023–2024 as incomplete; low recent counts cannot establish a construction slowdown.</p>",
"<p>The next independent check should use state housing-agency project lists or <a href='https://www.ncsha.org/hfa-factbook-online-data-visualization-and-reports-user-guide/'>NCSHA's agency survey</a>, comparing new construction with new construction and aligning dates. NCSHA's 4% and 9% tables count allocations, so they cannot directly validate our placed-in-service counts. An automated state-ID match to completed-project lists would allow state/cohort counts, units and match rates without individual adjudication. That cross-source comparison has not yet been performed.</p>",
"<p><a href='../../external_benchmarks/output/checks.txt'>Reproduced HUD benchmark calculations</a> · <a href='../../external_benchmarks/README.md'>External sources, findings and limits</a></p>",
"<p><a href='state_summary.csv'>State table (CSV)</a> · <a href='state_year_counts.csv'>State-year table (CSV)</a> · <a href='../../../build_lihtc/output/summary_statistics.csv'>Summary statistics (CSV)</a> · <a href='../../../build_lihtc/output/category_counts.csv'>Category counts (CSV)</a></p>",
"<p class='muted'>Sources: pinned HUD 2024 workbook and Census 2024 state boundaries. Census geocoder responses are preserved as a historical audit and are not an input to this dataset.</p>",
"</main><script>document.querySelectorAll('table').forEach(table=>{table.querySelectorAll('th').forEach((th,index)=>{th.addEventListener('click',()=>{const direction=th.dataset.direction==='asc'?-1:1;th.dataset.direction=direction===1?'asc':'desc';const value=row=>row.cells[index].textContent.trim();const numeric=text=>Number(text.replace(/[%+,]/g,''));const rows=Array.from(table.tBodies[0].rows);rows.sort((a,b)=>{const av=value(a),bv=value(b);return direction*(av!==''&&bv!==''&&Number.isFinite(numeric(av))&&Number.isFinite(numeric(bv))?numeric(av)-numeric(bv):av.localeCompare(bv));});rows.forEach(row=>table.tBodies[0].appendChild(row));});});});document.getElementById('state-filter').addEventListener('input',event=>{const query=event.target.value.toLowerCase();document.querySelectorAll('table').forEach(table=>{if(table.tHead.rows[0].cells[0].textContent==='State')Array.from(table.tBodies[0].rows).forEach(row=>row.hidden=!row.cells[0].textContent.toLowerCase().includes(query));});});</script></html>"
), "../output/diagnostics.html")
