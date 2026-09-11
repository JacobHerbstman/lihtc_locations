# LIHTC Locations

Apply Jacob's readable-research-code, research-workflow, and simple_explain skills
in /Users/jacobherbstman/.codex/skills. Use remove-ai-slop when auditing existing
complexity. Follow the current conversation's explicit research decisions.

## Research definition

The current task is a national dataset of LIHTC new-construction project locations
and basic hedonics. Start from the pinned original HUD workbook, not the retired
physical-development reconstruction. Keep the 50 states and DC and source TYPE=1;
exclude rehabilitation, mixed construction/rehabilitation, and existing buildings.
Assume new construction is correct unless repeated records or concrete conflicting
evidence create a reason to investigate. Do not require universal external review.

Keep original HUD IDs and source values. The initial siting rule keeps the earliest
new-construction record at the same standardized primary address. Addresses are
not parcels; retain later records and unresolved ties for review. Missing dates,
unit counts, or bedrooms must not silently remove otherwise useful locations.
Census matches are address-range points, not verified building footprints. Keep
location disagreements and scattered-site scope explicit. Do not copy project
unit totals across sites or sum repeated financing records.

## Source and build contract

- The immutable 2024 HUD ZIP remains in data_raw; its checksum is in the acquisition
  recipe and README. No refresh without an explicit source-vintage change.
- The root Makefile is the concrete end-to-end graph. Run root make after upstream
  changes. Task-local make runs from code/ against prepared inputs.
- Run make in paper/ to check the dataset and compile the paper; do not invoke
  latexmk. The root also builds the logbook from generated task results.
- Shared execution settings, directory rules, and data reports live in
  tasks/shared/code/. Input links are plain ln -sf rules. Do not restore the old
  recursive status checker, guarded links, or manual phase targets.
- Support GNU Make 3.81. Each producing rule owns one output; derived reports and
  selected/review tables have their own explicit dependencies.
- Root make setup is the environment bootstrap. Analysis must not install packages.
- Validate join keys and cardinality. Do not use many-to-many joins or arbitrary
  post-join deduplication. Keep missingness and substantive field checks explicit.
- Verify affected builds, missing outputs/reports, incrementality, and the rendered
  logbook. Inspect reports and use short literal commit messages.

No neighborhood analysis or complete financing-history reconstruction is part of
this reset. Research logs describe observations, rules, and unresolved questions
without treating a flag as a confirmed error.
