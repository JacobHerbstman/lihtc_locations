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
   address, attach basic characteristics and locations, and retain a review list.

Start with `tasks/build_lihtc/output/projects.csv`. `usable_location` identifies
selected records with checked primary locations and no unresolved repeat or
resyndication question. The full table includes provisional first-address choices
and unconfirmed HUD locations with explicit status. Dates and hedonics can remain
missing independently. This is a project/address dataset, not one building or lot
per row, and Census matches are address-range points rather than rooftop checks.

`project_records.csv` preserves all 29,453 source new-construction rows and their
selection results. `review.csv` contains all records with repeated-address or
location questions. Later phases are preserved, not reclassified as errors.
Shareable reports in each task's report/ describe the saved data and fingerprints.
The logbook records the reset and its results. The paper remains a research sketch.

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
