# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/local_control/code")
library(data.table)
c <- fread("../output/locus_city_coverage.csv")
# Decode CSV quotation marks before displaying the source text.
x <- as.data.table(read.csv("../output/locus_city_text.csv", na.strings = "", fileEncoding = "UTF-8",
  colClasses = c(place_geoid = "character", county = "character")))
x[is.na(content), content := ""] # Source content is never null; preserve its empty string.
escape <- function(z) {
  z <- gsub("&", "&amp;", z, fixed = TRUE)
  gsub("<", "&lt;", z, fixed = TRUE)
}
rows <- character()
for (i in seq_len(nrow(c))) {
  z <- c[i]
  rows <- c(rows, sprintf("<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>",
    z$city_name, format(z$raw_chunks, big.mark = ","),
    if (is.na(z$source_zoning_building_chunks)) "—" else format(z$source_zoning_building_chunks, big.mark = ","),
    if (z$city_in_public_release) "City text present; completeness unverified" else "No city text in this release"))
}
body <- c("<!doctype html><meta charset='utf-8'><title>Local control: raw text and measurement design</title>",
  "<style>body{max-width:1050px;margin:35px auto;padding:0 24px;font:17px/1.55 system-ui;color:#172735}table{border-collapse:collapse;width:100%;font-size:14px}td,th{padding:9px;border-bottom:1px solid #ddd;text-align:left}th{background:#edf3f5}pre{white-space:pre-wrap;font:14px/1.5 system-ui;background:#f3f6f8;padding:16px}details{margin:15px 0}a{color:#176b9b}</style>",
  "<h1>What local decisions can block new housing?</h1>",
  "<p>Start from the saved LOCUS legal text. The old phrase score and pilot labels do not enter this audit. This page establishes raw coverage; it does not yet report a new policy score or correlation.</p>",
  "<h2>What is available for the eight LIHTC cities?</h2>",
  "<table><tr><th>City</th><th>Raw chunks</th><th>Source labeled zoning/buildings</th><th>Coverage status</th></tr>",
  rows, "</table>",
  "<p>A chunk is an original text segment, not necessarily one legal rule. All city text is retained, including Process and Context. The source labels are automated and may be wrong. Neither text volume nor the number of zoning labels is a discretion measure.</p>",
  "<p>Los Angeles County is not Los Angeles city and is not substituted. The inspected NYC and San Francisco text includes charter provisions; presence of those does not establish coverage of their separate zoning/planning rules. The <a href='https://arxiv.org/html/2606.19334v1#S3'>LOCUS paper</a> distinguishes this county-harmonized public selection from the larger collected corpus.</p>",
  "<h2>Proposed measures, kept separate</h2>",
  "<ol><li><b>Board or elected-body approval:</b> must an elected body or appointed board approve the specified housing proposal? Retain which type.</li><li><b>Subjective standards:</b> can approval turn on judgments about compatibility or neighborhood character after numerical zoning rules are satisfied?</li><li><b>Fragmentation within a city:</b> how many distinct bodies must give binding approvals along that route?</li></ol>",
  "<p>The observation should be a city, legal snapshot and defined approval route. Record zoning-compliant construction separately from discretionary use approvals and rezonings. Hearings, advisory recommendations, appeal-triggered review and override powers remain separate. Unknown coverage never becomes a zero. Objective zoning restrictions and informal member deference are different objects.</p>",
  "<p><b>Fragmentation across a metro area is a separate measure:</b> how divided is land-use authority among independent governments? Start with a dated Census government inventory and metro boundaries, then establish the territory each government controls. Report government counts and population shares separately from the within-city approval count. LOCUS coverage counts cannot supply this measure.</p>",
  "<p><a href='metro_diagnostics.html'><b>See the separate Census metro-fragmentation comparison.</b></a> That first pass uses government counts, counts per resident and central-city population share. It does not yet measure these legal approval powers.</p>",
  "<p>The saved source revision is from May 2026. It cannot establish the rules faced by projects built in 1987–2022. A first snapshot comparison would relate current written institutions to long-run placement gradients; a historical claim needs historical rules.</p>",
  "<p>The <a href='../MEASUREMENT_PLAN.md'>measurement plan</a> specifies variables, tables, source gaps and the proposed comparison. The <a href='../README.md'>source notes</a> describe the extraction and build. The next step is to verify the relevant approval documents and code the same questions for each city before examining correlations.</p>",
  "<h2>Raw institutional provisions to inspect</h2>",
  "<p>These examples are selected by their source headings. They illustrate the available text, not completed city classifications. Full original content and shard-row identifiers are preserved below.</p>")
examples <- x[(place_geoid == "3651000" & grepl("Section 197-[cd][.]", header)) |
  (place_geoid == "0667000" & grepl("SEC[.] 4[.]105[.]", header))]
for (i in seq_len(nrow(examples))) {
  z <- examples[i]
  body <- c(body, sprintf("<details><summary>%s: %s</summary><p>Source %s; function: %s; topic: %s</p><pre>%s</pre></details>",
    escape(z$city_name), escape(z$header), escape(z$chunk_id), escape(z$source_function),
    if (is.na(z$source_topic)) "not assigned" else escape(z$source_topic), escape(z$content)))
}
body <- c(body, "<p><a href='../../placement_gradients/output/diagnostics.html'>Existing LIHTC placement gradients</a></p>")
writeLines(body, "../output/diagnostics.html")
