# LIHTC new-construction locations

The [Census extension](CENSUS_PLAN.md) adds national tract characteristics and
income-ceiling fields. It combines NHGIS 1980/1990/2000 with ACS five-year releases
2010–2024, retains tracts with zero LIHTC, and expresses monetary characteristics
in 2024 dollars. [Chicago and Detroit maps and coverage tables](tasks/audits/census_diagnostics/output/diagnostics.html)
use the same national pipeline.

The main dataset is `tasks/build_lihtc/output/projects.csv`: **28,456 HUD-reported
new-construction project IDs with HUD coordinates**. It uses TYPE=1 in the 50
states and DC from the pinned 2024 release. Every ID keeps its own placed-in-service
year, unit counts, bedroom counts and targeting indicators. Shared addresses,
missing dates and missing hedonics do not remove projects.

The [methods](tasks/build_lihtc/README.md), [variable dictionary](tasks/build_lihtc/codebook.md),
and [summary statistics and coverage report](tasks/audits/state_diagnostics/output/diagnostics.html)
describe the dataset. There are 27,513 usable placed-in-service years and 28,342
total-unit counts. Mean project size is 67.2 units; the median is 48. The joint
year/unit/complete-bedroom sample has 20,627 observations. These requirements
apply to specific analyses, not to additional master datasets.

The report also shows project-size distributions and bedroom mix, with explicit
denominators. **Actual dollar rents are not in the HUD property source.** Rent
restrictions and rental-assistance indicators are not observed rents.
See the [external checks](tasks/audits/external_benchmarks/README.md) for comparisons
with HUD's published totals and a feasible agency-data audit. HUD marks the
2023–2024 cohorts incomplete; they remain in the dataset and are shaded in the
annual figure.

## Build and execution order

Run `make setup` once, then `make` at the repository root. GNU Make 3.81 is supported.
The root Makefile owns cross-task dependencies. Task Makefiles show literal inputs,
plain symlinks and output producers; only generic.make and shell_functions.make
are included. Source download scripts acquire a missing pinned snapshot. Reports
are written with their CSVs and never act as Make targets.

1. `tasks/prepare_lihtc/code/prepare_lihtc.R` reads the original workbook, selects
   all 29,453 new-construction rows, preserves source values and cleans individual fields.
2. `tasks/build_lihtc/code/build_lihtc.R` flags shared addresses and records HUD
   coordinate availability in the all-source `project_records.csv`.
3. `tasks/build_lihtc/code/select_projects.R` saves every HUD-coordinate record's
   own cleaned fields in the main `projects.csv`.
4. `sample_sizes.R`, `summary_statistics.R` and `category_counts.R` in the same
   directory produce availability, continuous summaries and category frequencies.
5. `tasks/fetch_census/code/Makefile` acquires explicit ACS, NHGIS and price-index
   snapshots. `CENSUS_API_KEY` and `IPUMS_API_KEY` come from the existing private R
   environment; keys never enter the repository or request logs.
6. `tasks/clean_census/code/Makefile` cleans the national tract observations and
   prepares native tract/place polygons. Nominal values, source years, margins of
   error, real values, counts and denominators remain explicit.
7. `tasks/assign_lihtc_tracts/code/Makefile` assigns the HUD points to each tract
   geography and to 2024 Census places. It joins latest and prior observations and
   counts projects starting from all tracts.
8. The two audit tasks produce construction/sample diagnostics and Census/city
   diagnostics. Root `make` also builds the logbook. `make` in `paper/` checks the
   data through the root and compiles the research sketch.

The location file remains unchanged in membership. The extended project file is
`tasks/assign_lihtc_tracts/output/projects_with_tracts.csv`; the all-tract observation
file with zero counts is `tasks/assign_lihtc_tracts/output/tract_lihtc_counts.csv`.
NHGIS source archives are kept locally in `data_raw/nhgis/` and excluded from Git
because NHGIS restricts redistribution. The explicit extract selections and
source fingerprints are tracked; replication needs an authorized NHGIS account.

There is one main location file. The former `confident_projects.csv` and
`review.csv` outputs are retired; exclusion accounting is in `project_records.csv`.
Census geocoding is outside the production build. Its task and original responses
remain available as a historical audit; no geocoder is needed to build this dataset.

## Counting definition and limits

One row is a HUD-reported new-construction project, not a verified unique building
or parcel. Separate construction phases can share one address, so address repeats
are flags. The pinned HUD IDs are unique; no address-based deduplication or
cross-record consensus changes the main file. Missing dates do not prevent a
location from entering; analyses using dates report their smaller N.

First-address counting remains a sensitivity comparison in the state/year audit.
It retains 27,210 records and uses each selected record's own hedonics. Its smaller
count reflects later records, same-year ties and uncertain ordering. The former
consensus treatment of hedonics is retired, so this comparison changes counting
alone. No separate first-address project dataset is needed by production.

Scattered-site and resyndication flags remain visible. Units are project totals
and must not be copied across sites. The 1,903,603 reported total units sum 28,342
known counts; repeated financing may remain, so this is not a verified unique
housing stock. Missing construction type varies by state and prevents interpreting
the dataset as complete national construction coverage. No manual adjudication,
individual overrides, weighting or imputation enters production.

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
