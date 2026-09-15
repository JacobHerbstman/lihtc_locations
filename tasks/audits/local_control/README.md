# Start the local-control measurement from raw law

This audit starts from the unchanged public LOCUS text already downloaded in `local_laws`. It does not import that project's phrase scores, pilot labels, retrieval rules or segmentation choices. The existing LIHTC gradients remain unchanged. It preserves legal text for the design in [MEASUREMENT_PLAN.md](MEASUREMENT_PLAN.md) and separately implements a first comparison using Census metro-government fragmentation proxies.

## Source and coverage

- Publisher: [LocalLaws/LOCUS-v1](https://huggingface.co/datasets/LocalLaws/LOCUS-v1).
- Recorded revision: `519c0cff5278609b18547bf0fa3b66e088ffb04e`; publisher metadata last modified May 7, 2026. This is a source snapshot date, not a legal effective date.
- Existing source owner: `../local_laws/data_raw/locus_v1/20260507/`, relative to this repository. The eight unchanged Parquet shards are linked explicitly in Make. Expected publisher SHA-256 hashes are in `code/source_hashes.csv` and are verified before extraction. No download or modification of the other project occurs.
- Public release license: CC BY-NC 4.0, as recorded in the source README. Raw extracts remain ignored build products; reports contain metadata rather than the corpus text.
- The [LOCUS paper, sections 3.1–3.2](https://arxiv.org/html/2606.19334v1#S3) distinguishes the released county-harmonized selection from the larger collected corpus. We use only true city rows. A county code never substitutes for its central city.

Seven of the eight selected cities have raw city text. Los Angeles city does not; Los Angeles County is a different government. New York and San Francisco have charter-form provisions in the inspected raw text. Their low zoning-topic counts are not a complete-code diagnosis by themselves, but city presence cannot establish coverage of the separate zoning/planning code. Official separate code entry points include the [NYC Zoning Resolution](https://zr.planning.nyc.gov/) and [San Francisco Planning Code](https://codelibrary.amlegal.com/codes/san_francisco/latest/sf_planning/0-0-0-17747).

LOCUS's `function` and `topic` labels are automated predictions, retained for diagnostics. Process provisions often have no topic. All raw city chunks are therefore retained, with no keyword or topic exclusion. The four original source-model scores are preserved as source fields but are not adopted as measures of housing approval discretion.

The earlier task, **Analyze LOCUS-v1 dataset**, developed a phrase score and later an annotation pilot. Its July work identified noisy phrase matches, missing procedural text under topic-only retrieval, and multi-rule chunks. Those findings inform the reset, but its proposed city measures were not completed or validated. The old project is left intact.

## Files and execution order

Run root `make setup` for dependencies, then root `make`. With prepared sources, task-local Make also works from `code/`.

1. `extract_locus.R` verifies all eight source hashes, matches cities by state and normalized city name using `city_keys.csv`, and writes `locus_city_text.csv`. The key table must contain exactly the Census place IDs in the existing placement-gradient city list. An unmatched source city name appears explicitly as missing city-text coverage.
2. `summarize_coverage.R` writes one row per selected city, including Los Angeles's missing city-text status. Counts describe raw chunks and source labels; none is a policy score.
3. `summarize_coverage_tex.R` produces the logbook table. `write_report.R` displays coverage and full raw examples, linking the proposed measurement definitions.

`locus_city_text.csv` has one row per selected original Parquet row. `chunk_id` combines the shard filename and **one-based row within that shard**, under the recorded source revision. It preserves header, full content, source function/topic, original jurisdiction labels and original model scores. No deduplication, segmentation or new legal classification occurs. The key of `locus_city_coverage.csv` is `place_geoid`.

The text consumers use base R CSV parsing to decode embedded quotation marks exactly. The source has one empty content string and no null headers or content; consumers preserve that empty string. Source-value checks compare the exported text directly with the original Parquet rows.

Missing city text is represented by `city_in_public_release = FALSE` and `legal_coverage_status = no_city_text_in_public_release`. A present city has `city_text_present_completeness_not_established`. Zero raw chunks for an absent city never becomes zero discretion. The raw extract is not yet a dataset of unique laws or approval routes.

This build requires the recorded sibling-project source files to exist. Their acquisition belongs to the source project; this audit deliberately does not invoke or refresh that older pipeline. The corresponding immutable Hugging Face revision and shard hashes document how to recover the same bytes elsewhere.

## Separate metropolitan comparison

`output/metro_diagnostics.html` shows the first completed comparison. Inputs come from [fetch_local_governments](../../fetch_local_governments/README.md), with all public source files explicitly linked in Make. Execution continues as follows:

4. `build_metro_governments.R` reads the national General Purpose sheet and validates the selected cities against the official March 2020 principal-city/CBSA crosswalk. It writes `governments.csv`: 38,736 national rows keyed by `government_id`, retaining Census's primary county, type, active status, population year and selected-metro assignment.
5. `summarize_metros.R` writes `metro_fragmentation.csv`: eight rows keyed by central-city `place_geoid`, each with a unique `cbsa`. It counts active general-purpose governments and their three types, divides by disjoint county population totals for counts per 100,000, and calculates the central city's population share. Source year is 2022, population year/vintage is 2021, and MSA boundaries are March 2020. Official counts including dormant units remain separate; no selected-metro units are dormant.
6. `compare_metros.R` joins the fixed eight-city joint models with housing controls, retaining both all-city and interior-tract samples. `metro_comparison.csv` has 48 rows keyed by `place_geoid`, `sample`, `variable`: eight cities × two samples × three demographics. It preserves actual tract-year/project Ns and coefficient intervals.
7. `correlate_metros.R` writes 162 rows in `metro_correlations.csv`: two samples × three gradients × three metro proxies × nine omission choices. Each full-sample correlation has eight cities; each omission has seven. Pearson and Spearman correlations use signed natural-scale log-rate changes, with each city equally weighted. No additional city-level regression or composite score is fitted.
8. `plot_metros.R`, `summarize_metros_tex.R` and `write_metro_report.R` display the underlying points, source definitions, correlations and sensitivity.

The government count uses the county Census classifies as primarily served or headquarters county. This is not an exhaustive territorial assignment for governments spanning MSA boundaries. County, municipal and township powers vary across states; these are broad **government-fragmentation proxies**, not counts of independent zoning authorities. County/city populations overlap and are never summed as the metro denominator. The central-city share measures reach, with larger values indicating more population inside that city. No inversion makes it a discretion score.

The raw-count/homeowner correlation is −0.50, but +0.08 without NYC; governments per 100,000 give −0.09. The raw-count leave-one-city-out range is −0.83 to +0.08. This first pass does not establish a stable relationship between metro fragmentation and the homeowner gradient. The report also shows race, income, rank correlations and the existing interior-tract sensitivity. These modern snapshots relate to pooled 1987–2022 central-city placements, not historical laws or outcomes across the full MSA. The independent within-city legal measures remain unfinished.

## Within-city follow-up

The separate [within_city_discretion pilot](../within_city_discretion/README.md) now preserves 12 approval routes for these eight cities, their evidence, affordable exceptions and state-law limits. Its [report](../within_city_discretion/output/diagnostics.html) pairs them with all three existing gradients. It does not yet supply a validated 2022 city index or a legal-discretion correlation. The metro measure above remains separate.
