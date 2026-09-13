# Build HUD new-construction project locations

`output/projects.csv` is the main dataset: **28,456 rows and 31 columns**, keyed by
original HUD ID. Each row keeps its own coordinates, date and cleaned hedonics.
Shared addresses are flags. There is no address deduplication or cross-record
consensus. See the [codebook](codebook.md) for every variable.

## Rules and execution order

1. Upstream preparation reads the pinned HUD 2024 workbook and keeps all 29,453
   TYPE=1 records in the 50 states and DC. Source HUD IDs must be unique.
2. `build_lihtc.R` reads those prepared records. It counts records sharing a
   standardized address and flags repeats without combining anything. It records
   coordinate availability and a reason for each source record's inclusion/exclusion.
3. `select_projects.R` keeps every record with its own HUD coordinates and saves
   the main file. Missing dates, characteristics, shared addresses, scattered-site
   and resyndication flags never remove a record.
4. `sample_sizes.R` reports availability and joint Ns. `summary_statistics.R`
   reports N, missing counts, mean, sample SD, minimum, quartiles and maximum.
   `category_counts.R` reports credit, targeting and scope categories, including
   missing values, with both all-project and nonmissing denominators.
5. `summarize_projects.R` produces the logbook's sample table. The state-diagnostics
   task produces first-address comparisons, state/year counts, maps and the HTML report.

Coordinates retain the existing numerical bounds: latitude 18–72, longitude
-180–180 and nonzero, both present. In this source, all 997 unavailable coordinate
pairs are missing. No Census match, numbered address, boundary check or manual
confirmation is required. The 28,456 included and 997 excluded rows exhaust the
29,453 source new-construction rows. The raw ZIP is unchanged.

## Dates and hedonics

Preparation is the sole owner of field cleaning. Placed-in-service and allocation
years remain separate; values outside 1987–2024 and status codes 8888/9999 are
missing in derived fields, with source strings preserved. Placed-in-service is
our timing variable, not an observed groundbreaking date.

Total units must be a positive integer. Low-income units must be nonnegative
integers and cannot exceed known total units. Reported counts take priority over
HUD adjusted fields. No repeated records are summed into a project.

Valid partial bedroom counts remain. Negative/noninteger counts become missing.
If known bedroom counts exceed total units, or a complete breakdown differs from
total units, the breakdown becomes missing and is flagged. A complete bedroom-mix
analysis requires all five categories to sum to known total units. Missing
categories alone do not erase valid observed categories. Targeting indicators
recode HUD yes/no/not-indicated to 1/0/missing, retaining original codes upstream.

Different HUD IDs can have different values even at the same address. We no
longer blank a project's fields because another project reports different values.
The main file retains 943 missing placed-in-service years and 114 missing total-unit
counts. The intersection of known year and total units is 27,444; requiring a
complete bedroom mix gives 20,627. Adding all three targeting indicators gives
7,384. Actual analyses must report their actual N and compare controls on a common
sample when distinguishing control effects from sample changes.

## Outputs and interpretation

- `project_records.csv`: all 29,453 source TYPE=1 rows, original fields, cleaned
  fields, address flags, `selected` and `exclusion_reason`; key `hud_id`.
- `projects.csv`: main 28,456-record location dataset; key `hud_id`.
- `sample_sizes.csv`: marginal and explicit joint availability; key `sample`.
- `summary_statistics.csv`: project-weighted summaries for dates and unit counts;
  key `variable`. Each row uses its own nonmissing observations.
- `category_counts.csv`: category frequencies; key `(variable, category)`.
  Percent among known excludes missing responses, while percent of all includes them.

Total units sum to 1,903,603 over 28,342 known counts. Mean project size is 67.2,
median 48, and the middle half is 27–82 units. These are reported project totals;
repeated financing may remain, so the sum is not a verified stock of unique housing.
The sample retains 2,287 records sharing standardized addresses, 467 scattered-site
flags and 115 resyndication flags. Those flags do not themselves establish errors.

The first-address comparison is computed only in the state-diagnostics task. It
keeps the earliest fully orderable record at an address (smallest ID for ties),
then requires HUD coordinates. Undated singletons remain. Both comparison series
use each record's own hedonics: there is no consensus across ties. It yields
27,210 records and 1,834,264 reported units from 27,108 known counts. The old
consensus-based total was 1,817,049; those earlier results remain in the logbook.

Root `make` owns upstream dependencies. Task-local `make` runs from code/ against
prepared input links. Each Make rule owns one output, and SaveData writes its
metadata report as a side effect. The retired confidence and Census-fallback
pipelines are not production inputs. No manual adjudication is needed.
