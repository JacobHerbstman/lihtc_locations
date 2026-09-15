# What decisions can local officials make about new housing?

Defined September 15, 2026. Jacob requested a fresh measure from the raw law and chose to keep within-city and metropolitan fragmentation separate. The legal measures below remain a proposal: the current build extracts text and checks coverage without producing legal classifications or discretion scores. The separate Census metro-inventory comparison is now implemented, using the variables specified before viewing its correlations.

## Start with an approval route, not a word count

The main question is: **When a proposed apartment building satisfies the applicable zoning rules, can local officials still reject it or demand changes using their judgment?** A separate question is how many independent bodies must agree before it can proceed.

An objective height limit can be restrictive without granting discretion. A required hearing can give neighbors a voice without giving them a legal veto. Administrative approval can itself involve judgment. A rezoning may face political approval even where a conforming project receives a routine permit. These distinctions rule out simply counting “hearing,” “council,” “variance” or “administrative approval” as high/low discretion.

The proposed unit is **city × legal snapshot × residential approval route**. Begin with new multifamily construction on private land, outside explicitly special geographic overlays. Distinguish zoning-compliant construction, an application requiring a discretionary use approval, and an application requiring rezoning. Record dimensional variances, public-land disposition, historic/environmental overlays and affordable-housing-specific exceptions separately. Do not infer which route actual LIHTC projects used from their coordinates or completed-building records alone.

Where approval rules depend on district, size or project type, retain those conditions or multiple route rows. Do not invent a city-wide binary answer. Do not average routes with equal weights and call that the chance a random parcel or project faces discretion; that requires separate information about where housing is allowed and actual application routes.

## Within-city discretion and fragmentation

| Measure | What it records for a defined route | What does not count |
| --- | --- | --- |
| Board or elected-body approval | Whether an elected body or appointed board has binding approval/denial authority; retain which type | A body merely receiving notice, commenting or recommending |
| Subjective standards | Whether approval requires open-ended findings such as compatibility or neighborhood character | The same words in a purpose statement, definition or unrelated enforcement provision |
| Fragmentation within a city | Number of distinct bodies whose affirmative decisions are required on the ordinary approval sequence | Number of mentions, public meetings, staff departments or advisory bodies |

Record the individual decision bodies and powers before counting them. An authority whose denial can be overridden is different from an unconditional veto: retain the override rule. Keep initial approvals, appeal-triggered review and advisory neighborhood involvement separate. A hearing is not automatically a veto. Missing evidence is unknown, not “not required.”

Jacob chose to keep fragmentation **within cities and across metro areas as separate measures**. The approval count above measures the first. The metro measure below has a different geography, denominator and source.

Formal authority also differs from informal member deference. Ordinances may reveal who has legal power without revealing whose objections are decisive in practice. Record a documented council-member approval rule if present; do not infer informal deference from silence or automatically equate it with the number of council districts.

## Fragmentation across a metropolitan area

The first pass uses the [2022 Census Government Units Listing](https://www.census.gov/data/datasets/2022/econ/gus/public-use-files.html), a government inventory independent of LOCUS coverage. The [Individual State Descriptions](https://www.census.gov/library/publications/2024/econ/2022isd.html) explain how municipal, township and county governments differ and overlap. The inventory, March 2020 MSA county/principal-city lists and vintage 2021 county population file are now saved through `tasks/fetch_local_governments`. The state descriptions inform the stronger land-use-specific measure; they are not coded data in this build.

Use one fixed metropolitan statistical area (MSA) definition for all eight central cities, covering every member county even across state lines. Record the CBSA code and boundary vintage. Do not use the central county alone or combine MSAs into larger combined statistical areas. Proposed first-pass variables are:

| Variable | Definition and interpretation |
| --- | --- |
| `general_purpose_governments` | Count active counties, municipalities and towns/townships in the MSA, retaining separate counts by type. Exclude school and special districts. This is a broad government-fragmentation proxy, not a count of zoning authorities. |
| `governments_per_100k` | That count divided by total MSA population, times 100,000. Report both the raw count and this density so metropolitan size is visible. |
| `central_city_population_share` | Central-city population divided by total MSA population, using the same population year. This measures the central city's reach, not its approval discretion. |

Keep the government reference year (2022), population year/vintage (2021) and MSA boundary vintage (March 2020) as separate columns. The source documentation revealed that each government is classified to one primary county, sometimes its headquarters county. The implemented first pass uses that supplied county FIPS to assign an MSA once per government. It does not infer complete territorial membership. This limitation was established before estimating correlations. Mailing ZIP codes are not used. Exclude `IS_ACTIVE=N` from the primary count and preserve a Census-inclusive count: all 96 dormant national rows fall outside these eight assigned MSAs. Metro population sums disjoint counties, including counties without an independent county government; local-government populations are not summed.

The stronger measure would replace primary-county assignment with covered territory. Multicounty governments would count once within each MSA they serve; a government-to-MSA bridge would preserve genuine cross-boundary membership and uncertainty. That extension is not yet implemented.

A stronger land-use-specific measure would count governments with independent approval authority and measure how the metro's population is divided among their **nonoverlapping areas of primary authority**. Once those areas are established, let `p_j` be each authority's share of MSA population; `1 / sum(p_j^2)` is the effective number of equally sized authorities. One authority covering everyone gives 1; four equally sized authorities give 4. Do not calculate this from overlapping county and city populations, or assume every general-purpose government controls zoning. Keep overlapping layers of authority separately. The broad inventory proxy can be built first without claiming it is this stronger measure.

Comparing an MSA measure with its central city's LIHTC gradient asks whether the **surrounding metropolitan structure** is associated with that city's placement pattern. It does not describe sorting across all the MSA's municipalities. That second question requires extending the LIHTC outcome to all tracts in each MSA, including places with no projects.

## Data structure

Build a short chain of tables, with evidence carried forward:

1. **Source text:** `chunk_id`, raw shard and row, city, header, full text, recorded snapshot. This is now prepared. All source function/topic categories remain available.
2. **Approval rules:** `rule_id`, `place_geoid`, source/effective date, residential scope, route, applicability conditions, decision body, binding/advisory role, required approval, subjective finding, hearing, appeal/override route, affordable-housing exception, and exact supporting source span. A separate rule-to-source table can preserve multiple citations without multiplying policy observations.
3. **City-route measures:** one row per city, snapshot and specified route, containing the three within-city measures, coverage status and evidence count. Known zero requires affirmative evidence from the complete relevant procedure. Unknown or conflicting rules remain missing with reasons.
4. **Governments and metro measures:** `governments.csv` retains one national government row per source identifier, type, primary county, reference year and selected-MSA assignment. `metro_fragmentation.csv` has one row per selected central city and MSA, with counts, denominators and vintages. The official principal-city crosswalk validates each central-city match. A full territorial government-to-MSA bridge remains future work.
5. **Comparison:** select one route and snapshot, then join city-route measures one-to-one to the chosen city-specific LIHTC coefficient using Census place GEOID. Join the separate metro summary through the crosswalk. Count cities as observations, not text passages or LIHTC projects; repeated cities within one MSA would not be independent metro observations.

## Feasible work sequence

1. **Establish document coverage.** Inventory the charter, zoning/planning approval procedures and applicable state overrides for each city. Retain LOCUS where it has the relevant text; identify missing documents explicitly. For NYC/SF, verify the separate planning/zoning materials; for LA, acquire city material rather than using the county. Use dated snapshots. No city is assigned a score from an incomplete document set.
2. **Specify the same questions for every city.** Use the three measures above and record route conditions. A generic building permit or every legal hearing is not the denominator. Source definitions and questions must be fixed before seeing their correlation with LIHTC.
3. **Extract reproducibly.** Retrieve relevant complete sections and their cross-references from the raw text. Use a fixed structured coding schema with exact evidence, recorded model/prompt and reusable responses if model assistance is adopted. Ambiguous passages remain unknown rather than entering a hand-tuned score. A documented validation exercise evaluates the coding rule; no city-specific override is selected to improve the correlation.
4. **Build the independent metro inventory.** Acquire the government listing and fixed geographic crosswalks; check identifier matches and count coverage. Produce the three broad metro variables above before attempting the stronger land-use-authority concentration measure. This work can proceed independently of legal-text coding.
5. **Compare the separate measures.** Begin with a labeled scatterplot against the adjusted homeowner log-rate slope for a 10-point share increase, then the equivalent racial and income slopes. Keep the sign convention explicit: a more negative slope means stronger avoidance of high-homeownership tracts. Show Pearson and rank correlations, exact matched city N and leave-one-city-out results, alongside the uncertainty of the estimated LIHTC slopes. With at most eight cities, this is descriptive and any pattern driven by NYC must be visible. Do not fit a many-control city-level regression or select a composite by whichever weights yield the strongest result.
6. **Resolve timing before historical claims.** The saved legal snapshot is from 2026 while the existing LIHTC gradients pool 1987–2022. A first comparison would describe current written institutions versus long-run placement patterns. It would not measure the law faced at construction, explain the 2002 NYC break, or establish causality. Historical legal versions or independently dated institutional changes are required for those claims. The government inventory's 2022 reference year also does not reconstruct metro institutions throughout 1987–2022.

The legal-score comparison remains downstream of the common coding definition and source coverage. The independently defined metro-inventory comparison is in `output/metro_diagnostics.html`: eight metros, three proxies, three gradients, both established tract samples, and all city omissions. No old phrase score is used. The city list and existing LIHTC models remain unchanged.

## September 15 pilot

The [within-city pilot](../within_city_discretion/README.md) implements the route/evidence tables and compares all three existing city gradients alongside them. It documents state-law limits in California, the Seattle affordable exception and the conditional force of Board recommendations. Boston's operative 2022 text and a common dated proposal comparison remain unresolved. No selected-route average is interpreted as a city exposure share.
