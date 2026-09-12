# LIHTC new-construction locations

Build a simple dataset of where LIHTC housing was newly constructed, with its
placed-in-service year, unit counts, and bedroom mix. HUD's new-construction
classification is accepted unless a repeat record or concrete inconsistency
gives a reason to investigate. Missing hedonics do not remove usable locations.

## Build

Run `make setup` once, then `make` from this directory. The root Makefile is the
explicit end-to-end dependency graph. Task-local Makefiles operate on prepared
inputs; `make` in `paper/` checks the dataset through the root before compiling.
GNU Make 3.81 is supported. Sources and Census responses are reused unchanged;
missing Census responses require network access and send only public addresses.

Three tasks produce the data:

1. `prepare_lihtc`: read the pinned original HUD workbook and keep new construction.
2. `geocode_lihtc`: obtain Census address matches and preserve the raw responses.
3. `build_lihtc`: select first new-construction records at each standardized primary
   address, attach basic characteristics and locations, and record exclusions.

Start with `tasks/build_lihtc/output/confident_projects.csv`: 21,380 dated locations
that pass the documented address and location checks. `projects.csv` contains the
broader 28,196 first-address choices, including unconfirmed locations and undated
unique records. `project_records.csv` preserves all 29,453 source TYPE=1 rows and
original hedonics. `review.csv` accounts for exclusions; no manual adjudication is
required. This is a project/address dataset, not one building or lot per row.
Census matches are address-range points, not rooftop checks.

Earliest-year ties use a stable HUD ID and preserve all tied IDs. Conflicting
characteristics become missing; missing or inconsistent hedonics never exclude a
location. Repeated addresses with missing dates have uncertain order. Later phases
are omitted by the first-address definition, not declared source errors.

Open [the state diagnostics](tasks/audits/state_diagnostics/output/diagnostics.html)
for maps and sortable tables of construction-type coverage, all new construction
versus first addresses, unit counts, and confidence exclusions. Both state and
state-year CSV tables are linked from the report. The first-address rule reduces
records by 4.3%; confidence checks then exclude 24.2% of first-address records.
These losses differ substantially across states, including after accounting for
reported-year composition. Missing construction type also varies by state and
must not be treated as evidence of rehabilitation.

Shareable reports in each task's report/ describe saved data and fingerprints.
The logbook records consequential decisions and results. Counts above reflect
September 12, 2026. The paper remains a research sketch.

## Source and reset

The HUD 2024 release was downloaded August 8, 2026 and contains 55,345 source
project records. Its original archive remains in data_raw; extraction checks the
recorded checksum. Census uses Public_AR_ACS2025 and Census2020_ACS2025, with
request definitions recorded September 11, 2026. Returned tract codes do not
establish the eventual historical neighborhood specification.

On September 11, 2026, Jacob requested replacing the prior reconstruction with
this three-step workflow. Old task code, reviews, and exploratory sources were
removed from the active tree. Git history remains; a complete pre-reset snapshot
including untracked work is at `/tmp/lihtc_locations_before_reset_2026-09-11.tar.gz`.
That snapshot is outside the build and system temporary storage is not permanent.
No old development links or adjudications enter this pipeline.
