# Construction-type coverage and automatic exclusions by state

Produce maps and sortable tables for all 50 states and DC. This task reads the
original HUD workbook and the two production tables. It never changes projects
or introduces building-specific corrections. Run root `make` for all upstream
inputs, or task-local `make` against prepared inputs.

## Data and outputs

- `state_year_counts.csv`: one row per state and reported year; key `(state, year)`.
  The grid has 2,040 rows: 51 states including DC, 38 years from 1987 to 2024, and
  separate `unknown` and `after_2024` groups. Year is HUD placed-in-service year,
  not the first calendar year in which a database download contained the record.
- `state_summary.csv`: one row per state (51 rows); sums, rates, recent-period
  comparisons, and the year-adjusted exclusion diagnostic.
- `diagnostics.html`: self-contained report with maps, sortable/filterable tables,
  annual record/unit comparisons, and a state-year completeness heatmap. The two
  CSV files must accompany it for the download links to work.
- `type_missing_pct.png`: unknown construction type divided by all source records.
- `confidence_loss_pct.png`: excluded first addresses divided by all first addresses.
- `annual_comparison.png`: record counts and observed unit sums under three rules.
- `type_by_year.png`: construction-type missingness in each state and valid year.

Coverage includes every HUD construction type in the 50 states and DC. TYPE blanks
are unknown, not rehabilitation. Selection comparisons begin with TYPE=1 only.
All new records, first-address choices, and first addresses passing confidence
checks remain distinct stages. An additional comparison screens all TYPE=1 records
with the same individual location/year rules before comparing them with first
addresses. Tied first records additionally require location agreement.

## Variables and arithmetic

`hud_records`, `type_unknown`, and `type_known` describe construction-type coverage.
`new_records`, `first_records`, and `confident_records` are the three sample counts.
Their `*_units` columns sum nonmissing reported totals; `*_units_known` count
records contributing to the sum. Missing totals are never imputed as zero.
`confident_bedrooms_known` counts retained records with a consistent full breakdown.
The final sample keeps locations when hedonics are missing or inconsistent.

`later_records`, `same_year_records`, and `uncertain_order_records` sum to the loss
between all TYPE=1 records and first-address choices. Every first-address exclusion
is assigned one reason in priority order: unusable address, missing year,
resyndication, scattered site, then coordinate or other location problems. The
`drop_*` counts sum to `first_records - confident_records`. Multiple problems may
coexist, so this is primary-reason accounting, not a count of every flag.
`address_missing_count` and `address_multiple_count` describe subsets of unusable
addresses; the latter matches MULTIPLE, SCATTERED, VARIOUS, semicolons, or ampersands.

`type_missing_pct = 100 * type_unknown / hud_records`.
`first_reduction_pct = 100 * (new_records - first_records) / new_records`.
`confidence_loss_pct = 100 * (first_records - confident_records) / first_records`.
`excess_confidence_loss_pp` compares actual exclusions with exclusions expected
under national retention rates for each state's own reported-year mix. Positive
values indicate extra loss beyond that composition difference. Unknown/future
cohorts are included and have zero confidence retention. This is descriptive,
not a test proving that retained projects are representative. Recent comparisons
use observed years 2010–2024; unknown years are not assigned to that period.

## Provenance and interpretation

HUD and Census geocoder sources remain pinned to the existing project snapshots.
State outlines use the Census 2024 1:20 million ZIP recorded in source.make and
`data_raw/census_boundaries/2024/README.md`. Alaska and Hawaii are inset separately;
all maps use the same 0–100% scale. Geography is only for display.

The results show substantial geographic differences in both missing construction
type and confidence exclusions. They do not support treating dropped records as
random across states. No rate-based state exclusions or individual adjudications
are applied. Passing the automatic checks does not independently validate each
source construction classification or turn an address into a parcel identifier.

## Verification, September 12, 2026

Root and task-local builds pass on GNU Make 3.81, including an unchanged second
build; `make` in paper/ also passes. A disposable fresh build with `make -j3`
reproduced CSV, map, and HTML fingerprints. Removing actual outputs and a report
regenerated the same results. Changing the distance threshold to 250 meters only
in that fixture reduced retention to 20,488 and updated downstream tables and
HTML. A simulated failed checksum preserved the existing boundary ZIP. The
fixture used OMP_NUM_THREADS=1 after macOS sandbox shared-memory restrictions
interrupted its first attempt; the ordinary project build passed unchanged.

Checks confirm unchanged source values, the 488 added first-address choices,
consensus among tied fields, retention with missing hedonics, unique keys, and
reconciliation of state/year counts, unit sums, and exclusion reasons. Both maps,
the annual plot, the heatmap, and rendered logbook entries were inspected.
Browser interaction with the HTML report could not be verified because browser
policy blocked local-file navigation; its embedded figures and generated tables
were checked separately. The source files and deterministic report are retained.
