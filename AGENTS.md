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

Keep original HUD IDs and source values. Retain the existing first-address rule:
select the earliest new-construction record at standardized state/city/street,
before requiring coordinates. Earliest-year ties use the smallest HUD ID and
consensus hedonics. Repeated addresses with missing years have unresolved order
and are excluded automatically; undated singletons remain. Unresolved address text
gets a separate HUD-ID key. Addresses are not parcels; later phases are omitted
by this counting definition, not declared errors. Compare with all HUD IDs under
the same coordinate rule by state and year.

Use the representative's HUD coordinates only. No Census fallback, geocoder
confirmation, numbered-address requirement, or scattered-site/resyndication/tied-
coordinate exclusion enters the main dataset. Keep those scope/conflict flags
visible. Missing dates or hedonics do not remove otherwise selected locations.
Keep valid partial bedroom counts; blank only invalid or contradictory fields.
Report variable-specific and joint Ns, plus state/year missingness. Actual analyses
must report their actual Ns; control comparisons should also use a common sample.
No manual adjudication, building-specific overrides, or imputation enter production.
Do not copy scattered-site project totals across sites or sum repeated financing
as if it were established distinct physical construction. HUD points are primary
project locations, not verified building footprints. The main file is
tasks/build_lihtc/output/projects.csv; the old confident_projects.csv is retired.
Census code and raw responses remain a historical audit outside the root build.

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

No neighborhood analysis or complete financing-history reconstruction is part of
this reset. Research logs describe observations, rules, and unresolved questions
without treating a flag as a confirmed error.
