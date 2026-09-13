# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/state_diagnostics/code")
library(data.table)
library(jsonlite)
s <- fread("../output/state_summary.csv", na.strings = "")
y <- fread("../output/state_year_counts.csv")
n <- fread("../input/sample_sizes.csv")
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
  Sample = c("All HUD new-construction records", "All HUD IDs with coordinates", "First-address locations with HUD coordinates"),
  Records = number(c(sum(new_records), sum(hud_coordinate_records), sum(selected_records))),
  `Reported units` = number(c(sum(new_units), sum(hud_coordinate_units), sum(selected_units))),
  `Records with units` = number(c(sum(new_units_known), sum(hud_coordinate_units_known), sum(units_known)))
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
  `First address + HUD coordinates` = number(selected_records),
  `Units: all located IDs` = number(hud_coordinate_units), `Units: first address` = number(selected_units),
  `Counting-rule reduction %` = percent(first_address_reduction_pct))]
reasons <- s[order(state_name), .(
  State = state_name, `Unknown order at repeated address` = number(drop_uncertain_order),
  `Later records` = number(drop_later), `Other earliest-year ties` = number(drop_same_year),
  `Selected first record lacks HUD coordinates` = number(drop_no_hud))]
hedonics <- s[order(-all_controls_missing_pct), .(
  State = state_name, Locations = number(selected_records), `With year` = number(year_known),
  `With total units` = number(units_known), `With complete bedrooms` = number(bedrooms_known),
  `Year + units` = number(year_units_known), `Year + units + bedrooms` = number(year_units_bedrooms_known),
  `Plus three targeting indicators` = number(all_controls_known),
  `Extra joint-sample loss after year adjustment (pp)` = sprintf("%+.1f", excess_controls_loss_pp))]
flags <- s[order(state_name), .(
  State = state_name, `Unresolved address text` = number(unresolved_addresses),
  `Scattered-site flag` = number(scattered_records), `Resyndication flag` = number(resyndicated_records),
  `Earliest-year ties` = number(tied_records), `Tied HUD points disagree` = number(tied_coordinate_disagreements))]
annual <- y[, .(Source = sum(new_records), `All IDs with HUD coordinates` = sum(hud_coordinate_records),
                Selected = sum(selected_records), `Units: all located IDs` = sum(hud_coordinate_units),
                `Units: selected` = sum(selected_units), `Selected with units` = sum(units_known),
                `Year + units + bedrooms` = sum(year_units_bedrooms_known)), by = .(Year = year)][order(Year)]
writeLines(c(
"<!doctype html><html lang='en'><meta charset='utf-8'><meta name='viewport' content='width=device-width, initial-scale=1'>",
"<title>LIHTC dataset: coverage and sample sizes</title><style>",
"body{font:17px/1.55 system-ui,sans-serif;color:#19313e;background:#fff;margin:0}main{max-width:1180px;margin:50px auto;padding:0 28px}h1{font-size:37px;line-height:1.15;margin-bottom:12px}h2{margin-top:48px;font-size:25px}h3{font-size:20px}p{max-width:920px}.muted{color:#596b75;font-size:14px}img{width:100%;height:auto;margin:16px 0}.table-wrap{overflow:auto;max-height:640px;border:1px solid #dbe2e5;margin:18px 0}table{width:100%;border-collapse:collapse;font-size:14px;white-space:nowrap}th,td{padding:10px 13px;border-bottom:1px solid #e4e9ec;text-align:right}th:first-child,td:first-child{text-align:left}thead th{position:sticky;top:0;background:#edf3f5;color:#203d4d;cursor:pointer;z-index:1}tbody tr:nth-child(even){background:#f7f9fa}a{color:#136b82}input{font:inherit;padding:9px 12px;border:1px solid #aabdc8;border-radius:4px;width:300px}.finding{border-left:4px solid #bf7538;padding-left:18px}details{margin:24px 0}summary{cursor:pointer;font-weight:650}@media print{.table-wrap{max-height:none;overflow:visible}input{display:none}main{margin:0}thead th{position:static}img{break-inside:avoid}}</style><main>",
"<p class='muted'>HUD 2024 release · 50 states and DC · September 12, 2026</p>",
"<h1>LIHTC new-construction locations and available characteristics</h1>",
"<p class='finding'><strong>The master file keeps first-address new-construction records with HUD coordinates.</strong> Missing dates or hedonics do not remove locations. Scattered-site, resyndication and coordinate-disagreement flags remain diagnostic. No Census fallback or individual adjudication enters selection.</p>",
html_table(totals),
"<p>One row is the first HUD-reported new-construction event at a standardized primary address, with unresolved addresses kept separately by HUD ID. The date is placed-in-service year, not groundbreaking. This counting rule can omit later construction phases. It does not establish one building or parcel per row.</p>",
"<p class='muted'>Reported unit sums omit missing values; the adjacent N shows their coverage. All-ID sums can count repeat financing. Missing construction type prevents describing this as a census of every LIHTC construction.</p>",
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
"<p>The comparison applies the same HUD-coordinate requirement to both counting alternatives. Earliest-year ties use the smallest HUD ID and preserve all tied source IDs. Disagreeing characteristics become missing. A repeated address with any missing year has uncertain order and is excluded automatically. Undated singleton addresses remain. We select the first record before checking coordinates, so a later geocoded record cannot replace an earlier unlocated record.</p>",
embedded_plot("../output/annual_comparison.png", "Annual record and unit counts under the source, all-located-ID and first-address rules"),
html_table(selection),
"<details><summary>Account for every excluded source row</summary><p>Reasons are mutually exclusive in the displayed order. These counts plus selected locations equal all source new-construction rows. Later records and ties are accounting choices, not confirmed source errors.</p>",
html_table(reasons), "</details>",
"<h2>Does availability of hedonics vary by state?</h2>",
html_table(hedonics),
"<p class='muted'>The joint sample requires year, total units, a complete bedroom breakdown and known family, elderly and disabled targeting indicators. Year adjustment applies national availability within each reported cohort to the state's own cohort composition. Positive percentage points mean extra loss beyond that year mix. This diagnostic neither fixes selection nor establishes representativeness.</p>",
"<details><summary>Retained scope and address flags</summary>", html_table(flags),
"<p>A scattered-site project has only its HUD primary point; its units are project totals and must not be copied to multiple sites. A resyndication flag is retained despite TYPE=1 and does not prove fresh physical construction. HUD points are not verified building footprints.</p></details>",
"<details><summary>Annual counts, including missing dates</summary>", html_table(annual), "</details>",
"<p><a href='state_summary.csv'>State table (CSV)</a> · <a href='state_year_counts.csv'>State-year table (CSV)</a></p>",
"<p class='muted'>Sources: pinned HUD 2024 workbook and Census 2024 state boundaries. Census geocoder responses are preserved as a historical audit and are not an input to this dataset.</p>",
"</main><script>document.querySelectorAll('table').forEach(table=>{table.querySelectorAll('th').forEach((th,index)=>{th.addEventListener('click',()=>{const direction=th.dataset.direction==='asc'?-1:1;th.dataset.direction=direction===1?'asc':'desc';const value=row=>row.cells[index].textContent.trim();const numeric=text=>Number(text.replace(/[%+,]/g,''));const rows=Array.from(table.tBodies[0].rows);rows.sort((a,b)=>{const av=value(a),bv=value(b);return direction*(av!==''&&bv!==''&&Number.isFinite(numeric(av))&&Number.isFinite(numeric(bv))?numeric(av)-numeric(bv):av.localeCompare(bv));});rows.forEach(row=>table.tBodies[0].appendChild(row));});});});document.getElementById('state-filter').addEventListener('input',event=>{const query=event.target.value.toLowerCase();document.querySelectorAll('table').forEach(table=>{if(table.tHead.rows[0].cells[0].textContent==='State')Array.from(table.tBodies[0].rows).forEach(row=>row.hidden=!row.cells[0].textContent.toLowerCase().includes(query));});});</script></html>"
), "../output/diagnostics.html")
