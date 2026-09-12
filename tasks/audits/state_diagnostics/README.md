# Coverage and selection by state

Compare all HUD new-construction records, first-address choices, and the final
sample using HUD coordinates by default. Also reproduce the former requirement
for Census corroboration. This task never changes project records or introduces
building-specific corrections. Root `make` prepares all inputs; task-local `make`
uses those inputs through the symlinks listed in its Makefile.

## Outputs and definitions

- `state_year_counts.csv`: 2,040 rows keyed by `(state, year)`: 51 states including
  DC, 38 placed-in-service years from 1987 through 2024, and `unknown`/`after_2024`.
- `state_summary.csv`: 51 rows keyed by state, containing counts, unit sums, rates,
  recent-period comparisons, and the year-composition adjustment.
- `diagnostics.html`: self-contained report with maps and sortable/filterable
  tables. The CSV download links need the two CSV files alongside the report.
- `type_missing_pct.png`: unknown construction type divided by all HUD records.
- `confidence_loss_pct.png`: excluded first records divided by all first records,
  using the current HUD-default rule.
- `annual_comparison.png`: annual record counts and nonmissing reported-unit sums.
- `type_by_year.png`: construction-type missingness in each state and valid year.

Construction-type coverage uses every source record in the 50 states and DC.
TYPE blanks are unknown, not rehabilitation. The project comparisons start with
TYPE=1 only. The three count fields are `new_records`, `first_records`, and
`confident_records`. `corroborated_records` reproduces the former stricter rule.
All counts use HUD placed-in-service year; unknown years are not assigned to a
calendar cohort. Recent-period comparisons use observed years 2010–2024.

`*_units` sum reported nonmissing totals; `*_units_known` count contributing
records. Missing units are not imputed as zero. `confident_bedrooms_known` counts
retained records with a consistent complete breakdown. Disagreeing hedonics among
tied first records become missing and do not remove the location.

`later_records`, `same_year_records`, and `uncertain_order_records` account for
the loss between all TYPE=1 records and first choices. `drop_*` columns account
for the further loss in priority order: missing year, resyndication, scattered
site, conflicting tied/fallback coordinates, and other unavailable locations.
Each record has one primary reason; these counts sum to the total excluded.

`retained_hud_coordinates` and `retained_census_fallback` identify the point source.
`retained_unresolved_addresses` counts retained points with an unresolved address
key; their distinct physical identities have not been established. The unresolved
address counts and their missing/multiple-address subsets remain diagnostics,
not automatic exclusions. `retained_coordinate_disagreements` counts retained
HUD points that differ from Census by more than 500 meters.

`first_reduction_pct` divides the first-selection loss by all TYPE=1 records.
`confidence_loss_pct` divides the final-sample loss by first choices.
`excess_confidence_loss_pp` compares actual exclusions with those expected under
national retention rates for each state's own reported-year mix. Positive values
indicate extra loss beyond that composition difference. This is descriptive,
not a test proving representativeness. `state_share_change_pp` compares each
state's national record share before selection and in the final sample.

## Sources and build

The original HUD workbook and Census responses retain their existing pinned
snapshots. State outlines use the Census 2024 1:20 million ZIP; download_states.sh
contains the URL and checksum, and the Makefile lists the literal source target
and input link. Saved source snapshots are immutable and are downloaded only when
absent; a vintage change requires an explicit target/checksum change. Alaska and
Hawaii use separate insets. Geography is only for display, not project classification.

Only generic.make and shell_functions.make are included. SaveData writes the two
dataset metadata reports when their CSVs are saved; reports are never Make targets
or prerequisites. `checks.txt` in the external benchmark task is a substantive
audit result in output/, separate from dataset metadata reports.

## Interpretation

Accepting HUD coordinates raises the final sample from 21,380 to 25,832 records.
Kentucky rises from 12 to 94 and Minnesota from 391 to 678. Missing construction
type is unchanged; geographic selection remains visible. No state-specific
exceptions, manual adjudications, or weighting are applied. An available HUD point
does not certify a building footprint or every source construction classification.

## Verification of the HUD-default revision

The root build, task-local builds, and paper build pass on GNU Make 3.81. A fresh
`make -j3` in a disposable fixture reproduced CSV, map, and HTML fingerprints
without network requests. An unchanged second build does no work. Removing a
metadata report alone does not trigger rebuilding; removing its dataset regenerates
both. A synthetic unit change propagated through the data, reports, and state
tables while retaining the location. Changing the diagnostic distance threshold
to 250 meters in the fixture did not change final sample membership.

Each acquisition script retrieved a missing source from a local fixture response;
simulated transfer failures and bad checksums preserved the existing snapshot.
Changing acquisition implementation did not refresh a saved source. These are
local acquisition tests, not a live source refresh. The fixture used
OMP_NUM_THREADS=1 to avoid macOS sandbox shared-memory limitations.

Source fields and first-selected IDs are unchanged. Tests confirm HUD coordinate
priority, exact Census fallback, exact reproduction of the former sample, retained
missing hedonics, unique keys, and state/year arithmetic. The updated map, annual
plot, HTML table contents, and rendered logbook were inspected. HTML interaction
was not browser-tested because local-file navigation is blocked by browser policy.
