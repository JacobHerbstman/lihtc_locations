# Build the first-address location dataset

`output/projects.csv` is the main dataset: 27,210 rows and 34 columns, keyed by
HUD ID. It includes 891 undated locations and 292 locations without total units.
`output/project_records.csv` preserves all 29,453 source new-construction rows,
original fields and selection flags. `output/sample_sizes.csv` gives availability
of each characteristic and explicit joint samples. The [codebook](codebook.md)
defines every main-file variable.

## Rules, in execution order

1. Read prepared TYPE=1 rows in the 50 states and DC from the pinned HUD 2024 workbook.
2. Group by standardized state/city/street, before filtering locations. Uppercase,
   trim whitespace and normalize common street/direction abbreviations. ZIP is not
   part of the key. A missing/nonqueryable address or missing city gets its own
   `UNRESOLVED:HUD_ID` key; no fuzzy matching or parcel reconstruction occurs.
3. Keep the earliest placed-in-service year. Repeated addresses require every year
   to be usable, otherwise ordering is unresolved. A singleton can be undated.
   Earliest-year ties use the smallest HUD ID. Later phases are excluded by the
   counting definition, not classified as errors.
4. Keep that representative if HUD latitude/longitude pass the existing broad
   numerical bounds: latitude 18–72, longitude -180–180 and nonzero, both present.
   In this source, all 997 unavailable coordinate pairs are missing. The rule does
   not require address completeness, a state-polygon check, or external confirmation.
   Never substitute a later record or Census point for the representative's location.
5. For tied earliest records, retain a characteristic when the nonmissing values
   agree; blank that field when they disagree. Keep all tied IDs. Coordinates stay
   those of the representative, with disagreement flagged. Any affirmative scattered
   or resyndication flag among tied earliest rows is retained. These flags do not exclude.
6. Recheck arithmetic after forming consensus values. Missing or inconsistent
   hedonics affect fields, not inclusion. Save one main file, without separate
   dated or complete-case dataset copies.

Dates use HUD placed-in-service year, with allocation year separate. Years outside
1987–2024 and 8888/9999 are missing in derived fields; source strings remain.
Total units must be a positive integer. Low-income units must be a nonnegative
integer no larger than observed total units. Reported units take priority over
HUD adjusted counts. No unit counts are summed across repeated records.

Valid partial bedroom counts remain. Negative/noninteger counts become missing.
If observed counts exceed total units, or a complete breakdown differs from total
units, blank the breakdown and flag the conflict. Missing categories alone do not
invalidate observed categories. Complete bedroom-mix analyses use `bedrooms_consistent`.
Targeting indicators recode HUD yes/no to 1/0 and not-indicated/blank to missing.

## Exclusion accounting and varying N

The 29,453 source rows are 27,210 retained, 618 later records, 558 other records in
earliest-year ties, 81 records with uncertain repeated-address order, and 986
first representatives without HUD coordinates. This priority makes reasons mutually
exclusive. Across all source rows, 997 lack HUD coordinates; 11 of them already
appear in the earlier counting-rule reasons.

There are 26,319 observed years and 26,918 unit counts. Their intersection is 26,066.
Year, total units and complete bedrooms together are available for 19,618. Adding
known family, elderly and disabled targeting indicators leaves 7,013. These are
illustrations of required fields, not an instruction to use every control. Report
actual regression Ns and compare specifications on a common sample when assessing
what adding controls changes. Reporting N alone does not establish missingness at random.

State/year diagnostics report both all-HUD-ID and first-address counts under the
same coordinate rule, known-unit Ns, partial unit sums, marginal and joint coverage,
and retained flags. Missing type and missing hedonics can be geographically systematic.
The source-only rule is feasible and reproducible; it cannot certify every source
classification or recover construction absent from HUD.

## Build

Root `make` prepares upstream inputs; task-local `make` runs from code/ against
those inputs. Scripts run in this order: build_lihtc.R, select_projects.R,
sample_sizes.R, summarize_projects.R. Their Makefile lists every producer and
input symlink. SaveData writes reports with CSVs. Census geocoding, the old
confidence filters, select_confident.R and review_projects.R are retired from
production. The original HUD archive and historical Census responses are unchanged.
