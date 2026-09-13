# Project summary statistics, coverage and counting comparison

The main dataset keeps every HUD TYPE=1 project ID with its own HUD coordinates
in the 50 states and DC. This task describes the dataset and computes the optional
first-address comparison; it never changes production selection or hedonics.

Root `make` prepares inputs. `summarize_states.R` reads all source records and
main projects, computes first-address choices within the audit, and aggregates by
state/year. `compare_states.R` sums counts by state before forming rates. Plotting
scripts and `write_report.R` produce maps and HTML; the latter reads the main task's
sample-size, numeric-summary and category-count tables through explicit input links.

## Outputs and denominators

- `state_year_counts.csv`: 2,040 rows keyed by state/year, covering the 50 states
  and DC, 1987–2024, and separate unknown/after_2024 groups.
- `state_summary.csv`: 51 rows with source and main counts, first-address counts,
  reported unit sums and known-unit Ns, marginal/joint coverage and retained flags.
- `diagnostics.html`: self-contained figures and sortable/filterable tables, including
  project size, bedroom counts, targeting, credit types, missingness and sample Ns.
  CSV links refer to ordinary project output files, so preserve the directory layout.
- `type_missing_pct.png` and `type_by_year.png`: missing construction type divided
  by all HUD records in the relevant state or state/year.
- `coordinates_missing_pct.png`: missing HUD coordinates divided by all TYPE=1 rows.
- `annual_comparison.png`: source, main HUD-ID and first-address counts and units.

`new_records` counts all source TYPE=1 rows. `selected_records` counts the main
file and equals `hud_coordinate_records`. `drop_no_hud` is the sole production
exclusion: main plus missing-coordinate rows equals all new-construction source
rows in every state/year. Dates and hedonics do not determine main inclusion.

`new_units`, `selected_units` and `first_address_units` sum known total-unit
counts; `new_units_known`, `units_known` and `first_address_units_known` count
contributors. An empty sum is not evidence of zero housing. The sums are reported
project totals, not verified distinct physical stock; repeated financing may remain.

## First-address comparison

The audit first identifies the earliest placed-in-service year at each standardized
state/city/street across all source TYPE=1 rows. A singleton may be undated. A
repeated address with any missing year has uncertain ordering in this comparison.
Earliest-year ties use the smallest HUD ID; only then is HUD-coordinate availability
required. Each chosen record keeps its own cleaned hedonics. No values are combined
across records, so only the counting rule differs from the main sample.

`first_address_records` counts that comparison sample. `first_omitted_later`,
`first_omitted_same_year` and `first_omitted_uncertain_order` describe HUD-coordinate
records kept in the main file but omitted from this comparison. Their sum plus
first_address_records equals the main count in every state/year. These are counting
choices, not source-error classifications or a manual queue.

The main sample has 28,456 records versus 27,210 first-address records, a 4.4%
reduction. Corresponding reported units are 1,903,603 versus 1,834,264. The former
first-address consensus policy produced 1,817,049; that policy is retired and its
historical table is preserved in the logbook.

## Availability and scope

`year_known`, `units_known`, `low_income_units_known`, `bedrooms_known`,
`family_known`, `elderly_known` and `disabled_known` count available fields.
Bedroom availability here requires the complete consistent five-category breakdown.
Individual valid partial counts remain in the main dataset and summary tables.
`year_units_known`, `year_units_bedrooms_known` and `all_controls_known` are joint
Ns. The last additionally requires all three targeting indicators. They illustrate
requirements, not chosen regression specifications or additional master samples.

Scattered, resyndicated, unresolved-address and repeated-address counts remain
flags. No state-specific exceptions, weighting or source replacement occurs.
`excess_coordinate_loss_pp` and `excess_controls_loss_pp` compare observed state
availability with national availability at each state's own cohort composition,
including unknown dates. Positive values indicate extra loss beyond that year mix,
not a correction for selection bias. Unadjusted counts and rates remain primary.

HUD 2024 and Census 2024 1:20 million boundary bytes remain pinned and unchanged.
Boundaries are for display only; Census geocoder responses are not a dependency.
SaveData writes reports alongside each CSV; reports never enter Make dependencies.

## Verification

All main-file fields match the corresponding prepared HUD ID; later phases,
same-year records and undated records at repeated addresses remain. The source,
coordinate and first-address counts reconcile in every state/year. Independent
Python calculations reproduce numeric N, means, sample SDs, medians and ranges;
category counts and both percentage denominators reconcile. A fresh GNU Make 3.81
build without Census responses or network access reproduces the data, figures
and HTML. Missing actual data regenerates its report; missing reports alone do
not trigger rebuilding. A synthetic unit change before cleaning propagates to
project values, summary tables and HTML while retaining the project. Root and
paper builds pass. The annual figure, rendered logbook, HTML table contents and
CSV links were inspected; HTML browser interaction was not tested.
