# LIHTC new-construction locations

The main dataset is `tasks/build_lihtc/output/projects.csv`: **27,210 first-address
locations with HUD coordinates**, drawn from HUD's pinned 2024 release. Use HUD's
TYPE=1 new-construction classification in the 50 states and DC. Date projects by
placed-in-service year. Keep missing dates and hedonics; each analysis reports the
N for the fields it actually uses.

The [methods](tasks/build_lihtc/README.md), [variable dictionary](tasks/build_lihtc/codebook.md),
and [coverage and sample-size report](tasks/audits/state_diagnostics/output/diagnostics.html)
describe the dataset. There are 26,319 usable dates, 26,918 total-unit counts,
and 20,131 complete consistent bedroom breakdowns. These are overlapping samples.
The joint year/unit/bedroom sample has 19,618 observations.

## Build and execution order

Run `make setup` once, then `make` at the repository root. GNU Make 3.81 is supported.
The root Makefile owns cross-task dependencies. Task Makefiles show literal inputs,
plain symlinks and output producers; only generic.make and shell_functions.make
are included. Source download scripts acquire a missing pinned snapshot. Reports
are written with their CSVs and never act as Make targets.

1. `tasks/prepare_lihtc/code/prepare_lihtc.R` reads the original workbook, selects
   all 29,453 new-construction rows, preserves source values and cleans individual fields.
2. `tasks/build_lihtc/code/build_lihtc.R` establishes first-address selection and
   records an automatic reason for every excluded source row in `project_records.csv`.
3. `tasks/build_lihtc/code/select_projects.R` saves the main `projects.csv`, using
   HUD coordinates and consensus hedonics for earliest-year ties.
4. `tasks/build_lihtc/code/sample_sizes.R` reports marginal and joint Ns in
   `sample_sizes.csv`. State diagnostics compare counts, units and missingness by state/year.
5. The root builds the research logbook. `make` in `paper/` checks the dataset
   through the root and compiles the paper, which remains a research sketch.

There is one main location file. The former `confident_projects.csv` and
`review.csv` outputs are retired; exclusion accounting is in `project_records.csv`.
Census geocoding is outside the production build. Its task and original responses
remain available as a historical audit; no geocoder is needed to build this dataset.

## Counting definition and limits

First-address counting retains the earliest new-construction record at the same
standardized state/city/street. It precedes the coordinate requirement. A later
record with coordinates cannot replace an earlier record without coordinates.
Earliest-year ties use a stable HUD ID; conflicting hedonics become missing.
Repeated addresses with incomplete dates have uncertain order and are excluded
automatically. Undated singletons remain. Unresolved addresses retain separate
HUD IDs; addresses are not parcel identifiers.

The all-ID alternative has 28,456 HUD-coordinate records. Its counts and reported
units are compared with first-address counts by state and year. First-address
counting can omit later construction phases; counting all IDs can include repeated
financing. Neither is a verified count of distinct physical buildings.

Scattered-site, resyndication and conflicting tied-coordinate flags no longer
exclude locations. HUD supplies a primary project point, not a verified building
footprint. Scattered-site units remain project totals and are never copied across
sites. Missing construction type varies by state: this is HUD-reported new
construction with available locations, not a census of every LIHTC construction.
No manual adjudication, individual overrides, weighting or imputation enters production.

## Source and research history

The HUD 2024 archive was retrieved August 8, 2026. It contains 55,345 project
records and remains unchanged in `data_raw/hud_lihtc_property/2024/lihtcpub.zip`.
SHA-256: `e07acee706174b276f89596d614ac5699efa9848659e5834fdfb5198fa0a7288`.
The rolling download must match that checksum; a new release needs an explicit
source-vintage change. No older development reconstruction enters this build.

On September 11, 2026, Jacob requested a reset to source-based construction
records. Git and the logbook retain that history. A pre-reset temporary snapshot
is at `/tmp/lihtc_locations_before_reset_2026-09-11.tar.gz`; temporary storage is
not permanent. Settled methodological choices do not require release copies or tags.
The [literature note](tasks/audits/external_benchmarks/literature_methods.md) describes
paper-specific methods and their limits. Counts above are from September 12, 2026.
