# Source coverage and available characteristics by state

This task describes the main first-address/HUD-coordinate dataset without changing
selection. Root `make` prepares inputs. Scripts run in order: summarize_states.R,
compare_states.R, the three plotting scripts, and write_report.R. Each input,
symlink and output producer is visible in the task Makefile.

## Outputs

- `state_year_counts.csv`: 2,040 rows keyed by state/year, covering 50 states and
  DC, 1987–2024, and separate unknown/after_2024 groups.
- `state_summary.csv`: 51 rows with source counts, selected counts, unit sums,
  marginal and joint availability, retained flags and year-adjusted loss diagnostics.
- `diagnostics.html`: self-contained maps and sortable/filterable tables, including
  the main task's sample_sizes.csv. Keep both state CSVs alongside it for download links.
- `type_missing_pct.png`: missing construction type divided by all source HUD records.
- `coordinates_missing_pct.png`: missing HUD coordinates divided by all TYPE=1 records.
- `annual_comparison.png`: source, all located HUD IDs, and first-address locations,
  with reported units under each definition.
- `type_by_year.png`: construction-type missingness by state and valid year.

## Denominators

`new_records` counts source TYPE=1 rows. `hud_coordinate_records` counts all such
IDs with HUD points. `selected_records` counts the main first-address/HUD-point
sample. The latter two apply the same coordinate requirement. `first_records`
is the intermediate first-address count before requiring coordinates.

`new_units`, `hud_coordinate_units` and `selected_units` sum nonmissing reported
totals; `new_units_known`, `hud_coordinate_units_known` and `units_known` count
contributors. If no counts are known, a zero aggregate is an empty sum, not evidence
of zero housing. All-ID sums may include repeated financing.

`drop_uncertain_order`, `drop_later`, `drop_same_year`, `drop_no_hud` are mutually
exclusive source-row exclusion counts, in that priority. Their sum plus selected
records equals new_records in every state/year cell. An undated singleton remains
in the master and appears in unknown or after_2024, not a fabricated calendar year.

`year_known`, `units_known`, `low_income_units_known`, `bedrooms_known`,
`family_known`, `elderly_known` and `disabled_known` count availability separately.
Bedroom availability here requires the complete consistent five-category breakdown;
individual bedroom-field availability is in the main sample_sizes.csv.
`year_units_known`, `year_units_bedrooms_known` and `all_controls_known` are joint
Ns. The last additionally requires all three targeting indicators. These example
control sets do not prescribe later regressions. Missing indicators are not recoded
to no, and sample availability does not select another master dataset.

Scattered, resyndicated, unresolved-address and tied-coordinate-disagreement counts
are retained flags, not exclusion reasons. No state exceptions or weights are used.

`excess_coordinate_loss_pp` and `excess_controls_loss_pp` compare each state's
observed availability with national availability at its own cohort composition,
including unknown dates as a separate cohort. Positive values indicate extra loss
beyond that year mix, not proof of selection bias or its absence. The unadjusted
counts and rates remain primary.

## Findings and sources

The main sample contains 27,210 locations; Kentucky retains 99. Requiring year,
units and a complete bedroom mix gives 19,618 nationally. Adding known family,
elderly and disabled targeting indicators gives 7,013, including none in Hawaii
or Virginia. Coordinate gaps are also uneven: 18.2% in Maine versus 3.4% nationally.
Showing changing Ns is necessary but does not make missingness random.

Source bytes are unchanged: HUD 2024 and Census 2024 1:20 million state boundaries.
The boundary download script pins its checksum. Geography is for maps only.
Census geocoder responses are not a dependency. SaveData writes metadata reports
with each CSV; reports never enter Make targets or prerequisites.

## Verification

The source-field and sample checks pass, including unchanged first-address IDs,
exact use of representative HUD points, retained missing dates/hedonics/scope
flags, and state/year exclusion arithmetic. A fresh GNU Make 3.81 build without
Census responses or network access reproduced the datasets, maps and HTML. An
unchanged second build did no work; deleting the main CSV regenerated its data
and metadata report, while deleting metadata alone did not trigger a build. A
synthetic prepared-input unit change propagated to the main file, state tables
and HTML, retained the location and blanked its contradictory bedroom counts.
Root and paper builds passed. The map, annual figure and rendered logbook were
inspected; HTML table contents were checked, but browser interaction was not tested.
