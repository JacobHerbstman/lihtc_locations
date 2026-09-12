# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/state_diagnostics/code")
library(data.table)
library(jsonlite)
s <- fread("../output/state_summary.csv",na.strings="")
y <- fread("../output/state_year_counts.csv")
stopifnot(nrow(s)==51L,!anyDuplicated(s$state),!anyDuplicated(y[,.(state,year)]))
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
totals <- s[,.(Sample=c("All HUD new-construction records","First address","First address + confidence checks"),
  Records=number(c(sum(new_records),sum(first_records),sum(confident_records))),
  `Reported units`=number(c(sum(new_units),sum(first_units),sum(confident_units))),
  `Records missing unit counts`=number(c(sum(new_records-new_units_known),sum(first_records-first_units_known),sum(confident_records-confident_units_known))))]
coverage <- s[order(-type_missing_pct),.(State=state_name,`HUD records`=number(hud_records),`Type missing`=number(type_unknown),
  `Missing %`=percent(type_missing_pct),`Missing %, 2010–2024`=percent(recent_type_missing_pct),`New-construction records`=number(new_records))]
selection <- s[order(-confidence_loss_pct),.(State=state_name,`All new`=number(new_records),`First address`=number(first_records),
  `After checks`=number(confident_records),`First-address reduction`=percent(first_reduction_pct),
  `Further loss from checks`=percent(confidence_loss_pct),`Loss, 2010–2024`=percent(recent_confidence_loss_pct),
  `Excess loss after year adjustment (pp)`=sprintf("%+.1f",excess_confidence_loss_pp))]
reasons <- s[order(-confidence_loss_pct),.(State=state_name,`Address missing / unusable`=number(drop_address),
  `Year missing`=number(drop_year),`Resyndication`=number(drop_resyndication),`Scattered site`=number(drop_scattered),
  `HUD-only location`=number(drop_hud_only),`Coordinates disagree`=number(drop_coordinates),`Other location issue`=number(drop_other_location))]
units <- s[order(state_name),.(State=state_name,`Units: all new`=number(new_units),`Units: first address`=number(first_units),
  `Units: after checks`=number(confident_units),`Missing units: first address`=percent(first_units_missing_pct),
  `Missing units: after checks`=percent(confident_units_missing_pct),`Change in national record share (pp)`=sprintf("%+.2f",state_share_change_pp))]
screened <- s[,.(Comparison=c("All new construction, same record-level screens","First addresses, same screens plus agreement among tied records"),
  Records=number(c(sum(screened_new_records),sum(confident_records))),`Reported units`=number(c(sum(screened_new_units),sum(confident_units))))]
annual <- y[year %in% as.character(1987:2024),.(new=sum(new_records),first=sum(first_records),confident=sum(confident_records)),by=year][order(year)]
annual <- annual[,.(Year=year,`All new`=number(new),`First address`=number(first),`After checks`=number(confident))]
writeLines(c(
"<!doctype html><html lang='en'><meta charset='utf-8'><meta name='viewport' content='width=device-width, initial-scale=1'>",
"<title>LIHTC state coverage and sample selection</title><style>",
"body{font:17px/1.55 system-ui,sans-serif;color:#19313e;background:#fff;margin:0}main{max-width:1180px;margin:50px auto;padding:0 28px}h1{font-size:37px;line-height:1.15;margin-bottom:12px}h2{margin-top:48px;font-size:25px}h3{font-size:20px}p{max-width:920px}.muted{color:#596b75;font-size:14px}img{width:100%;height:auto;margin:16px 0}.table-wrap{overflow:auto;max-height:640px;border:1px solid #dbe2e5;margin:18px 0}table{width:100%;border-collapse:collapse;font-size:14px;white-space:nowrap}th,td{padding:10px 13px;border-bottom:1px solid #e4e9ec;text-align:right}th:first-child,td:first-child{text-align:left}thead th{position:sticky;top:0;background:#edf3f5;color:#203d4d;cursor:pointer;z-index:1}tbody tr:nth-child(even){background:#f7f9fa}a{color:#136b82}input{font:inherit;padding:9px 12px;border:1px solid #aabdc8;border-radius:4px;width:300px}.finding{border-left:4px solid #bf7538;padding-left:18px}details{margin:24px 0}summary{cursor:pointer;font-weight:650}@media print{.table-wrap{max-height:none;overflow:visible}input{display:none}main{margin:0}thead th{position:static}img{break-inside:avoid}}</style><main>",
"<p class='muted'>HUD 2024 release · 50 states and DC · September 12, 2026 · Automatic rules; no individual adjudications</p>",
"<h1>LIHTC coverage and sample selection by state</h1>",
sprintf("<p class='finding'><strong>The confidence exclusions are geographically uneven.</strong> The first-address rule reduces records by %.1f%% nationally; the subsequent checks exclude %.1f%% of first-address records. Losses range from %.1f%% in %s to %.1f%% in %s.</p>",
  100*(1-sum(s$first_records)/sum(s$new_records)),100*(1-sum(s$confident_records)/sum(s$first_records)),min(s$confidence_loss_pct),s[which.min(confidence_loss_pct),state_name],max(s$confidence_loss_pct),s[which.max(confidence_loss_pct),state_name]),
html_table(totals),
"<p class='muted'>A record is a HUD project entry before selection and a first-address event after selection. Missing units are omitted from sums, never filled with zero. These partial unit totals are not estimates of the complete housing stock. The first two rows include undated records and dates outside 1987–2024; the final row requires a valid year in that range.</p>",
sprintf("<p>Missing or inconsistent hedonics do not exclude a location: the final sample retains <strong>%s records without total units</strong> and <strong>%s without a consistent bedroom breakdown</strong>. Among tied earliest records, we keep a characteristic only when the nonmissing values agree. Reported total units have priority over the bedroom breakdown; an inconsistent breakdown is blanked.</p>",number(sum(s$confident_records-s$confident_units_known)),number(sum(s$confident_records-s$confident_bedrooms_known))),
"<h2>Construction-type completeness</h2>",
sprintf("<p>Across the full source, %s of %s records (%s) have no construction type. They are outside the TYPE=1 sample; they have not been reclassified as rehabilitation. The map denominator includes all construction types, not just new construction.</p>",number(sum(s$type_unknown)),number(sum(s$hud_records)),percent(100*sum(s$type_unknown)/sum(s$hud_records))),
embedded_plot("../output/type_missing_pct.png","Percent of HUD records missing construction type by state"),
"<label>Find a state in the tables: <input id='state-filter' placeholder='e.g. Indiana' aria-label='Find a state'></label><p class='muted'>Click a column heading to sort. Each state table includes all 50 states and DC.</p>",
html_table(coverage),
"<details><summary>See construction-type completeness by state and year</summary>",embedded_plot("../output/type_by_year.png","State-year heatmap of missing construction type"),"</details>",
"<h2>All new construction versus first address</h2>",
"<p>The first-address rule retains the earliest known year at each standardized address. If earliest records tie, a stable HUD ID labels the address and all tied source IDs remain recorded. Different names or hedonics do not prevent selection. Later phases at the same address are omitted by this definition; the comparison measures dependence on that assumption.</p>",
embedded_plot("../output/annual_comparison.png","Annual comparison of all new-construction records, first addresses, and confidence-filtered first addresses"),
"<details><summary>Compare the counting rules after applying the same confidence screens</summary><p>The first row also includes later and same-year source records; the second row retains one first-address event. Tied first records additionally require agreement about location.</p>",html_table(screened),"</details>",
"<h2>Which states lose records under the confidence checks?</h2>",
"<p>A retained record needs a usable numbered street address, a known 1987–2024 placed-in-service year, and a checked primary point. Census must match the reported state and agree with HUD within 500 meters; an exact Census match can pass when HUD coordinates are absent. Scattered-site and resyndication flags exclude the record. We do not exclude an entire state or require its loss rate to meet a chosen threshold.</p>",
embedded_plot("../output/confidence_loss_pct.png","Percent of first-address records excluded by confidence checks by state"),
html_table(selection),
"<p class='muted'>Further loss = (first-address records − records after checks) / first-address records. Year adjustment compares each state's actual loss with the loss expected if its first-address records experienced the national retention rate for each of their reported years. Positive percentage points indicate extra loss beyond that explained by the year mix. This is a descriptive adjustment, not evidence that the remaining sample is representative.</p>",
"<h3>Why records are excluded</h3><p>These reasons are mutually exclusive, in the displayed priority order. A record can have several problems; only its first reason is counted here. The columns sum to each state's loss after first-address selection. This is an exclusion accounting table, not a manual review queue.</p>",html_table(reasons),
sprintf("<p>Kentucky loses %s first-address records because the address fails the current street-address requirements. Minnesota loses %s for this reason, including %s with text indicating multiple or scattered addresses. These are source-format and site-scope limitations that the same rule exposes unevenly across states.</p>",number(s[state=="KY",drop_address]),number(s[state=="MN",drop_address]),number(s[state=="MN",address_multiple_count])),
"<h3>Reported units and changes in state representation</h3>",html_table(units),
"<p class='muted'>National record share compares a state's share of all TYPE=1 records with its share after first-address selection and confidence checks. Units can become missing when tied source records disagree, even though the address remains in the sample.</p>",
"<details><summary>Annual counts</summary>",html_table(annual),"</details>",
"<h2>Scope of the result</h2><p>The geographic losses are large enough to affect comparisons across states. These diagnostics support using an explicitly defined sample, not treating dropped records as geographically random. No weighting or state-specific exception has been applied. Automatic confidence refers to the documented address, timing, and location screens; it does not certify every source construction classification. The previously documented Oconee Park classification conflict has no ID-specific override.</p>",
"<p><a href='state_summary.csv'>State table (CSV)</a> · <a href='state_year_counts.csv'>State-year counts (CSV)</a></p>",
"<p class='muted'>Sources: unchanged HUD LIHTC 2024 workbook, archived Census ACS2025 geocoder responses, and <a href='https://www2.census.gov/geo/tiger/GENZ2024/shp/cb_2024_us_state_20m.zip'>Census 2024 state boundaries</a>. Coordinates are address-range matches, not building footprints. All computations are in this task's R scripts and Makefile.</p>",
"</main><script>document.querySelectorAll('table').forEach(table=>{table.querySelectorAll('th').forEach((th,index)=>{th.addEventListener('click',()=>{const direction=th.dataset.direction==='asc'?-1:1;th.dataset.direction=direction===1?'asc':'desc';const value=row=>row.cells[index].textContent.trim();const numeric=text=>Number(text.replace(/[%+,]/g,''));const rows=Array.from(table.tBodies[0].rows);rows.sort((a,b)=>{const av=value(a),bv=value(b);return direction*(av!==''&&bv!==''&&Number.isFinite(numeric(av))&&Number.isFinite(numeric(bv))?numeric(av)-numeric(bv):av.localeCompare(bv));});rows.forEach(row=>table.tBodies[0].appendChild(row));});});});document.getElementById('state-filter').addEventListener('input',event=>{const query=event.target.value.toLowerCase();document.querySelectorAll('table').forEach(table=>{if(table.tHead.rows[0].cells[0].textContent==='State')Array.from(table.tBodies[0].rows).forEach(row=>row.hidden=!row.cells[0].textContent.toLowerCase().includes(query));});});</script></html>"
),"../output/diagnostics.html")
