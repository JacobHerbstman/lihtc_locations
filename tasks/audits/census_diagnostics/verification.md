# Census extension verification

Checked September 12, 2026 (September 13 UTC), against the recorded source
snapshots described in [CENSUS_PLAN.md](../../../CENSUS_PLAN.md).

The extension preserves all 28,456 HUD IDs and all 31 pre-extension project
fields exactly. The main project file adds the income-ceiling and source-geography
fields; the tract join does not change the sample. There are 28,439 latest tract
matches, 12 points without a unique polygon assignment, and five assigned tracts
absent from the latest demographic release. Before placed-in-service, 27,075 of
27,513 projects with known years have a matched observation. Missing context stays
in the project file.

## Data checks

- Project IDs and tract/release keys are unique. All 18 demographic observations
  contain the 50 states and DC. Every source tract observation survives into the
  tract-count file, including observations with zero projects.
- The selected baseline independently matches the latest observation ending
  strictly before placed-in-service. Unknown project years remain without a baseline.
- Dollar factors match the original price workbook and the source dollar year.
  Income and housing use their separate historical reference years. Real values
  equal nominal values times the corresponding factor. Annotated median bounds
  are missing as exact dollar estimates.
- National latest and baseline tract counts sum to the corresponding matched
  project counts. The 2024 observation's unobserved future siting counts are
  missing. Current cumulative counts are zero in tracts with no matched project.
- City counts conserve points selected by official place GEOIDs: Chicago has
  179 projects and Detroit, Michigan has 118. Chicago retains 801 intersecting
  tracts, including 693 without a matched project inside the city.
- A scan using the existing private credentials found no key values in shareable
  source code, configuration, or reports. Public acquisition records omit keys.

## Build checks

A separate temporary checkout started without task inputs, outputs, reports, or
temporary files, but with the recorded raw snapshots. A full root `make -j3`
completed without source acquisition. All 41 CSV outputs from the LIHTC,
Census, assignment, and audit tasks, and all six city maps, matched the working
build byte for byte. The CSV data reports were regenerated.

Deleting the actual cohort-coverage CSV and its report in that checkout caused
Make to regenerate both, with the same CSV hash. Changing the 1979 dollar factor
there propagated through the tract demographics and final project join, changing
the joined output without rerunning spatial assignment. Those changes were
confined to the temporary checkout.

A simulated interrupted ACS transfer used the actual downloader and left the
existing annual raw archive unchanged. The separate HUD MTSP downloader rejected
the live HTTP 202/empty response and published no workbook. That external source
remains unavailable; dollar eligibility benchmarks are not part of the completed
Census outputs.

Root `make`, `make -C paper`, subsequent idle dry runs, and `git diff --check`
passed. The generated maps and the new logbook pages were visually inspected.
These checks establish reproducibility and count consistency; they do not verify
each HUD coordinate or resolve historical changes in Census definitions.
