# Within-city discretion: first approval-route pilot

Question: a proposed apartment satisfies the written objective rules. Does approval still require judgment about its design or compatibility with neighbors?

The pilot covers the same eight cities as placement_gradients. Its main legal unit is **city × approval route**, not a building or a generic word count. Twelve routes retain their conditions rather than being averaged into a city score. The report pairs city assessments with all three existing LIHTC gradients. No correlation or city ranking is estimated from uneven, incompletely dated legal coverage.

## Scope and definitions

The baseline is private land, a permitted apartment use and compliance with objective density, height, setbacks, parking and other applicable requirements. It excludes a requested variance, rezoning, public-land disposition, historic/coastal overlay and special-use permit. A size-triggered mandatory planned development is retained as a separate branch: fitting base dimensional rules need not remove that requirement. This is a land-use approval measure; it does not establish freedom from environmental, building, infrastructure or specific health-and-safety requirements.

`code/route_coding.csv` contains disclosed agent judgments. It is a source table, not the output of an automatic legal classifier. The code checks evidence references and joins the decisions; it does not pretend to replicate their interpretation independently. No building-by-building adjudication or old LOCUS phrase/model score enters this work.

| Variable | Meaning |
| --- | --- |
| `place_geoid`, `route_id` | Census city identifier and unique route identifier |
| `trigger` | When this route applies; size, district and exemptions matter |
| `local_subjective_review` | 1: judgment beyond objective compliance; 0: none in selected route; blank: unresolved |
| `subjective_denial_code` | 1: evidence supports lawful rejection on subjective land-use grounds; 0: compliance route or state limit rules that out under stated assumptions; blank: not established |
| `binding_land_use_actor` | Official or body making the selected land-use decision |
| `binding_board_approval`, `elected_approval` | 0, 1, conditional or missing; no inference from a meeting alone |
| `board_conditions_binding` | Presumptive force of Seattle Board recommendations, with specified Director exceptions; not a separate final permit veto |
| `advisory_or_comment_role`, `appeal_or_request` | Advice, comments and review requests, distinguished from required approval |
| `state_limit`, `affordable_exception` | Rules limiting the ordinary local procedure |
| `evidence_ids`, `scope_limit` | Exact source references and limits of the interpretation |

`code/city_coding.csv` has one row per city, keyed by `place_geoid`. Its categories describe documented routes; a category is not an ordinal discretion score. Three cities have an ordinary compliance route (Atlanta, Houston, NYC), Chicago and Seattle have triggered subjective review, the two California cities combine local review with state limits, and Boston's operative 2022 coding is unresolved. California zeros refer only to subjective rejection of HAA-qualifying, objectively compliant housing. They do not imply no review, no delay, or actual compliance by officials. Seattle's denial field remains missing: the selected provisions establish design-condition authority but do not independently settle all denial grounds. The affordable exemption removes design review, not every other permit requirement.

## Dates and source integrity

2022 is the proposed reference year, chosen provisionally while awaiting an optional user preference. **This pilot is not a complete 2022 legal panel.** The 2026 LOCUS release date is never used as a law's effective date. Each city has `date_evidence` stating the source's actual temporal support:

- Atlanta, Houston and Chicago: selected raw code sections and their amendment annotations; not complete reconstructed historical codes.
- NYC: official 2018 Handbook, printed page 25; continuity to 2022 is an inference.
- LA: archived January 2024 code, selected subsection annotations from 2012–2019; not a certified January 2022 compilation. Exemptions and subsequent changes require explicit dating.
- California: 2021 appellate opinion, California Renters Legal Advocacy and Education Fund v. City of San Mateo, A159320. The opinion itself is primary evidence, reproduced by Justia. HAA protection is distinct from ministerial processing.
- SF: October 2023 HCD review, including analysis of 2014–2021 approvals. It documents conflict between local procedures and state limits, not a new unrestricted legal veto.
- Seattle: full design-review section last amended 2020, administrative and Board-condition sections 2022. Ordinance 126741, signed December 15, 2022, describes the prior 2020 exemption and its expiration and renews the exemption. Its new operative period is not silently backdated over all of 2022. Later HB1293 fiscal-note evidence is contextual, not an enacted 2022 rule.
- Boston: April 2022 board agenda confirms Article 80 review existed; the downloaded full Article 80 PDF is explicitly a **July 2025 modernization proposal**. It is retained as rejected evidence for operative-2022 coding. Boston's numeric legal fields remain missing.

LOCUS evidence links to the unchanged extraction owned by local_control. Source shard identifiers and one-based rows survive in `evidence.csv`, together with the recorded LOCUS revision. Full selected raw chunks are retained because headings may contain several provisions. The pilot adds no segmentation based on previous model labels.

Original external PDFs are pinned under `data_raw/approval_rules/2026-09-15/` and have explicit URL, output and SHA-256 checks in the task Makefile. `sources.csv` records bytes, SHA-256, URL and retrieval date. Some servers rejected direct downloads; five committed `code/evidence/*_web.txt` files instead preserve the web retrieval service's returned excerpts. These are **not original HTML/PDF bytes and may be incomplete**. They retain source links and page/line locators; their hashes prove local snapshot integrity, not publisher authenticity. The build checks all recorded hashes. It never silently refreshes legal evidence.

## Files and execution order

Run root `make`; with prepared inputs, `make` from this task's `code/` directory also works. The shared environment already supplies R, data.table and ggplot2. No new packages are installed by analysis.

1. `build_evidence.R` reads the committed notes and source inventory, checks external bytes and hashes, and selects LOCUS chunks by exact key. `output/evidence.csv` has 21 rows keyed by `evidence_id`.
2. `build_routes.R` checks the committed legal judgments, city coverage and evidence references. It writes 12 rows to `output/approval_routes.csv`, keyed by `route_id`. Joining city context is many-to-one and checked.
3. `compare_cities.R` joins one city coding row to each existing joint, housing-control estimate. `output/city_comparison.csv` has 48 rows keyed by city, sample and demographic: eight cities × two geographic samples × three variables. It preserves estimates, intervals, actual tract-year/project Ns and all original rows. Routes are never joined to the model rows, avoiding an ambiguous many-to-many comparison.
4. `plot_comparison.R`, `write_report.R` and `summarize_tex.R` produce the three-variable plot, HTML report and logbook table. Dollar and demographic definitions remain those of placement_gradients. Plot increments are +10 percentage points for owner/Black shares and +10% for income; these are not standardized comparable demographic shifts.

Each durable output CSV writes its standard data report as a side effect through SaveData. The codebook tables are small versioned source judgments, not claimed automated outputs. External acquisition uses temporary downloads and checksum validation before replacing a missing source. The standard reports do not become Make dependencies.

## What would turn this into a comparable measure?

First finish the operative Boston text and the unresolved denial/exception fields. Then use a common proposal size and geography across cities, recording ordinary and affordable routes separately. Do not interpret the count or average of our selected routes as a fraction of local housing exposed to discretion. For a city-level exposure share, the denominator needs all eligible parcels or a consistently specified set of proposals.

The NYC result makes another variable relevant: **how much land allows apartments without rezoning?** Formal member deference can affect zoning-change routes even when a complying building has an as-of-right route. That is separate from both within-city approval discretion and the existing metro-government counts. Eight modern city observations alone will not establish a causal institutional explanation of placements over 1987–2022.
