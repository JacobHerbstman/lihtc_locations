# National Census extension

Implemented September 13, 2026, following Jacob's September 12 plan and approval.
The 28,456-project HUD sample and all previous project values are preserved.
Chicago is first; Detroit exercises the same code. National acquisition is independent
of the city selection in `tasks/audits/census_diagnostics/code/cities.csv`.
The [verification record](tasks/audits/census_diagnostics/verification.md) documents
the unchanged HUD sample, complete tract coverage within each source, and fresh build.

## Execution and data structure

The root Makefile is the full graph. Run `make setup`, then root `make`; run `make`
in `paper/` to compile the research sketch after checking the data. Task-local Makefiles
run from `code/` against plain input symlinks. No analysis installs packages.

| Order | Producer | Main output | One row represents |
| --- | --- | --- | --- |
| 1 | Existing prepare/build LIHTC tasks | `tasks/build_lihtc/output/projects.csv` | One retained HUD ID |
| 2 | `fetch_census` | Explicit archives in `data_raw/census_acs`, `data_raw/nhgis`, `data_raw/price_indexes` | Original source responses/files |
| 3 | `clean_census` | `tract_demographics.csv` | One tract in one Census/ACS observation |
| 4 | `assign_lihtc_tracts` | `lihtc_tracts_YEAR.csv`, `lihtc_places.csv` | One HUD ID in one boundary snapshot |
| 5 | `assign_lihtc_tracts` | `projects_with_tracts.csv` | One HUD ID with latest and prior Census fields |
| 6 | `assign_lihtc_tracts` | `tract_lihtc_counts.csv` | Every tract observation, including zero-project tracts |
| 7 | `audits/census_diagnostics` | Coverage CSVs, city CSVs, maps, HTML | Stated state/cohort/vintage/city denominators |

Output paths in this table are within each producer's `output/` unless given in full.
Geographic IDs are character strings, including leading zeros. Read CSV geography
columns explicitly as character; a CSV has no embedded type declaration.

## Sources and years

- Pinned original HUD 2024 ZIP; no source refresh or sample change.
- IPUMS NHGIS v21.0: 1980_STF3, 1990_STF3, 2000_SF3a. Exact national tract selections
  are in `tasks/fetch_census/code/nhgis_tables.json`; source ZIP includes codebooks.
- National ACS five-year API, every release ending 2010–2024, all 50 states and DC.
  Each state response is preserved verbatim inside its annual archive, with the
  release's variable metadata and public query. `acs_variables.csv` lists the codes.
  B15002 supplies the education categories by sex in 2010/2011; B15003 starts in 2012.
- NHGIS national tract shapes: 1980 and 1990 on TIGER 2008 bases; 2000 on TIGER 2010;
  native 2010, 2020, 2024. National places use 2024. Selections are separate JSON files.
- Census 2025 publication of its continuous historical-income price series, 1979–2024,
  pinned from the [2024 income report](https://www2.census.gov/programs-surveys/demo/tables/p60/286/annual-index-value_annual-percent-change.xls).

The ACS 2005–2009 release is omitted because its tract geography has documented
exceptions. Historical tract coverage is incomplete, especially in rural areas in
1980. We do not invent historical tracts or fill demographic gaps from future years.
There are no 2010/2020 decennial income questions to substitute for the ACS.

Credentials stay in the existing private R environment: `CENSUS_API_KEY` and
`IPUMS_API_KEY`. Requests and errors omit keys. Original downloaded files stay in
`data_raw`; ordinary builds reuse these snapshots. NHGIS archives are not committed
because its license restricts redistribution. Extract specifications, codebooks in
the local archives, and committed reports provide the replication trail.

## Project fields

`income_ceiling_raw` preserves INC_CEIL. `income_ceiling_type` is `50_pct_ami`,
`60_pct_ami`, `income_averaging`, or missing. Income averaging is not coded as one
common percentage. `lower_income_ceiling` is 1/0/missing from LOW_CEIL;
`lower_ceiling_units` comes from CEILUNIT. Invalid counts or counts above known total
units become missing; the raw count and conflict flag remain. A disagreement between
the indicator and count is flagged without forcing reconciliation. `low_income_share`
is known low-income units divided by known total units.

Original HUD tract/place IDs for 1990, 2000, 2010 and 2020 remain available. HUD points
are primary project locations, and scattered-site unit totals must not be copied to
other locations. No Census merge removes a project.

## Tract characteristics

| Characteristic | Numerator or level | Denominator for share |
| --- | --- | --- |
| Income | Median household income | No share |
| Homeownership | Owner-occupied housing units | Occupied housing units |
| Non-Hispanic White/Black/Asian | Corresponding population count | Total population |
| Hispanic | Hispanic population of any race | Total population |
| Poverty | People below poverty threshold | People with poverty status determined |
| College | People 25+ with bachelor's degree or more | Population 25+ |
| Vacancy | Housing units minus occupied units | All housing units |
| Rent | Median gross rent among cash-rent units | No share |
| Home value | Median value of owner-occupied homes | No share |

Counts, denominators and ACS MOEs are retained; conflicting components blank only
the affected share. Negative ACS sentinel codes, suppressed historical cells and
published bounds are not exact estimates. Raw medians and annotations are retained.
For 1980 the college measure is four or more years of college. The 1990 Asian/Pacific
Islander combined category remains separate from Asian alone; 1980 does not provide
the necessary non-Hispanic Asian separation. Older rent/value universes cover
specified housing units and are not identical to current universes. 1980 median
home value is unavailable in the selected source; its rent coverage is weak.

## Real dollars and geography

The price index is explicitly **national**, with 2024 as the common dollar year.
It is Census's continuous historical-income series: R-CPI-U-RS before 2000 and
chained CPI-U from 2000. The direct BLS all-years R-CPI-U-RS workbook returned HTTP
403 during acquisition, so the available Census-published series was adopted
explicitly. This differs from the all-years R-CPI-U-RS convention for official ACS
comparisons; it is not a silent fallback inside the build.

`real_value = reported_value * index_2024 / index_source_dollar_year`.
Income in the 1980/1990/2000 Census uses 1979/1989/1999 dollars. Housing medians use
1980/1990/2000 dollars. ACS five-year dollar values already refer to the release's
final year. Monetary MOEs receive the same factor. Original values and both
conversion factors remain in the tract file.

This adjusts purchasing power over time, not cost-of-living differences across
cities. Local CPI index levels cannot compare local price levels. LIHTC dollar
eligibility benchmarks require HUD's area-specific family-income limits and
household sizes; a tract's median household income cannot produce those limits.
Actual project rents remain unavailable.

## Geography and timing

Cities and tracts use the **same HUD coordinate** in the appropriate polygons.
The final rule follows the project's recorded location directly, rather than mixing
tract-code and point-based neighborhood assignment. HUD's original tract codes
remain available for comparison; a disagreement is not a confirmed error in either
source field. Among source codes present in the 2024 boundary file, 1,352 differ
from the tract containing the recorded point.

An intermediate explanatory check mistakenly counted both Detroit, Michigan and
Detroit, Texas by place name (119 total) and compared that with Michigan's 118.
The production city filter always used official place GEOIDs and was correct.
That count was not evidence of a tract error. Michigan has 118 retained points;
Chicago has 179. Point-based assignment is retained as the explicit choice for
consistent spatial descriptions, not as a response to that mistaken count.
No coordinate is replaced or independently verified. No nearest polygon,
arbitrary boundary tie, address search, manual building override or source-ID
fallback is used.

`latest_` uses 2020–2024 ACS. `baseline_` uses the latest observation whose period
ends strictly before placed-in-service: 2018 uses 2013–2017 ACS; 1987 uses 1980 Census.
Missing project years have no baseline. Missing values do not cause field-specific
backfilling. Baseline age is explicit; it predates placed-in-service, not necessarily
planning or construction. Native-vintage observations do not constitute a panel of
unchanged boundaries.

Boundary snapshots and demographic release years are separate fields. ACS 2010–2019
uses the 2010 boundary snapshot; 2020/2021 uses 2020; 2022–2024 uses 2024, covering
Connecticut's new county codes. A tract must still match the actual demographic
release. Annual exceptions that do not match remain explicit. No code-only crosswalk
or count reallocation fills those gaps.

## Counts and city comparisons

`tract_lihtc_counts.csv` begins with all source tract observations. For each baseline,
new-project counts cover the years after that observation and through the next
observation's end year. The 2000 baseline covers 2001–2010. The latest observation
has no observed future window, so its new-project count is missing, not zero.
It separately reports all retained projects assigned to current tracts. Missing unit
counts have their own N; the known-unit sum never pretends to include them.

City membership uses 2024 Census place polygons. Every positive-area intersecting
tract is retained, including zero-LIHTC tracts; edge tracts are flagged. Medians and
counts describe whole tracts, even when the display clips a polygon to the city.
City project counts include only points in the city. Income quintiles keep ties
in the same group. The interior-tract sensitivity drops edge tracts. Latest city
rates use current housing units; national baseline-window rates use baseline housing
units. Neither establishes causal siting effects. Adding cities changes the explicit
city list and output targets, not source acquisition or cleaning code.

## Remaining external source

A separate HUD-income-limit source is needed for dollar affordability benchmarks.
The official [2024 MTSP workbook](https://www.huduser.gov/portal/datasets/mtsp/mtsp24/MTSP-Data-FY24.xlsx)
returned HTTP 202 with an AWS web-application-firewall challenge and zero data bytes.
No eligibility or rent proxy has been substituted. Household-size and HUD area
geography must be verified after that source is accessible, including New England
town-based areas and project-specific hold-harmless/HERA rules. These are area
benchmarks initially, not claimed observed project rents or exact legal limits.

## Source guidance

- [NHGIS geography and historical coverage](https://www.nhgis.org/gis-files)
- [NHGIS API extract specification](https://developer.ipums.org/docs/v2/workflows/create_extracts/nhgis_data/)
- [ACS API](https://www.census.gov/data/developers/data-sets/acs-5year.html)
- [ACS dollar years](https://www.census.gov/help/topics/faq.are-dollar-estimates-adjusted-in-acs-multiyear-tables.html)
- [Census price series](https://www.census.gov/topics/income-poverty/income/guidance/current-vs-constant-dollars.html)
- [BLS geographic price-index limits](https://www.bls.gov/opub/hom/cpi/concepts.htm)
- [1980 original STF3 documentation, including suppression and bounds](https://assets.nhgis.org/original-data/modern-census/1980STF3.pdf)
- [HUD MTSP limits](https://www.huduser.gov/portal/datasets/mtsp.html)
