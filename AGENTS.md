# LIHTC Locations

Apply Jacob's readable-research-code, research-workflow, and simple_explain skills
in /Users/jacobherbstman/.codex/skills. Use remove-ai-slop when auditing existing
complexity. Follow the current conversation's explicit research decisions.

## Research definition

Settle the methods before exploratory analysis. Jacob's request to "lock in" the
dataset refers to these choices, not separate release copies or Git release tags.

The current task is a national dataset of LIHTC new-construction project locations
and basic hedonics. Start from the pinned original HUD workbook, not the retired
physical-development reconstruction. Keep the 50 states and DC and source TYPE=1;
exclude rehabilitation, mixed construction/rehabilitation, and existing buildings.
Assume new construction is correct unless repeated records or concrete conflicting
evidence create a reason to investigate. Do not require universal external review.

The main observation is one unique HUD project ID with TYPE=1 and its own HUD
coordinates. Keep every such ID; do not deduplicate by address, require complete
ordering, combine phases, or replace a record's hedonics with cross-record
consensus. Flag repeated standardized addresses and preserve each record's
scattered-site and resyndication codes. First-address counting is a sensitivity
comparison computed only in the state-diagnostics task. It uses the same cleaned
record values as the main dataset; only the counting rule differs.

Use HUD coordinates only. No Census fallback, geocoder confirmation, numbered-
address requirement, or scope-flag exclusion enters the main dataset. Missing
dates and hedonics do not remove locations. Keep valid partial bedroom counts;
blank invalid or contradictory fields within each source record. Report summary
statistics with variable-specific and joint Ns, plus state/year missingness.
Actual analyses must report actual Ns; control comparisons should also use a
common sample. No manual adjudication, building-specific overrides or imputation
enter production. All source HUD IDs are checked for uniqueness.

Preserve original source values and row-level provenance. Do not copy project
unit totals across scattered sites. Summed units describe HUD-reported project
records, not a verified stock of unique physical housing; repeated financing may
remain. HUD points are primary project locations, not verified footprints. The
main file is tasks/build_lihtc/output/projects.csv. Census geocoder code and responses
remain a historical audit outside the root build; confident_projects.csv is retired.

## Source and build contract

- The immutable 2024 HUD ZIP remains in data_raw; its checksum is in the acquisition
  download script and README. No refresh without an explicit source-vintage change.
- The root Makefile is the concrete end-to-end graph. Run root make after upstream
  changes. Task-local make runs from code/ against prepared inputs.
- Run make in paper/ to check the dataset and compile the paper; do not invoke
  latexmk. The root also builds the logbook from generated task results.
- Shared execution settings, directory rules, and data reports live in
  tasks/shared/code/. Input links are plain ln -sf rules. Do not restore the old
  recursive status checker, guarded links, or manual phase targets.
- Support GNU Make 3.81. Each producing rule owns one output. Only generic.make
  and shell_functions.make are Make includes. Source-specific download scripts
  are called by explicit source targets in the task Makefiles.
- SaveData writes metadata reports alongside dataset saves. Reports and execution
  logs are side effects, never Make targets or prerequisites.
- Root make setup is the environment bootstrap. Analysis must not install packages.
- Validate join keys and cardinality. Do not use many-to-many joins or arbitrary
  post-join deduplication. Keep missingness and substantive field checks explicit.
- Verify affected builds, missing actual outputs, incrementality, and the rendered
  logbook. Inspect reports and use short literal commit messages.

The authorized Census extension fetches all national tracts, combines historical
NHGIS and ACS observations, and assigns projects in assign_lihtc_tracts. Retain
tracts with zero LIHTC projects and all original LIHTC rows. Assign tracts and
cities from the same HUD point; retain supplied HUD tract codes and disagreement
flags. No coordinate replacement or source-ID fallback. Keep source periods,
geography vintages, denominators and dollar years explicit. Chicago is the first
city in a national workflow. Complete financing-history reconstruction remains
out of scope. Research logs describe observations, rules, and unresolved questions
without treating a flag as a confirmed error.
