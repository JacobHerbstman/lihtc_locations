# Release verification, September 12, 2026

The release changes no sample decisions, rows, values, or ordering relative to
revision `3bba0c8`. The four build datasets were compared field by field as text;
all were identical after renaming `bedrooms_4plus` to `bedrooms_4`. That correction
matches the pinned HUD dictionary's label. The four affected metadata reports
change only that column name and their saved-file fingerprints.

Checks completed on the recorded local R/macOS environment and GNU Make 3.81:

- Root `make -j3` rebuilt affected outputs successfully. The root and all three
  data-task Makefiles reported nothing to rerun on a second invocation.
- A disposable fresh copy, with all generated inputs, intermediates, outputs, and
  data reports absent, rebuilt successfully with network requests forbidden.
  Prepared data, parsed geocodes, all-record and selected data, state/year tables,
  and the existing map/HTML outputs had identical SHA-256 fingerprints. A second
  build did nothing. The fixture used `OMP_NUM_THREADS=1`; the working-directory
  build used its ordinary environment.
- Removing only the final dataset's metadata report in that fixture caused no
  rebuild. Removing the actual final CSV regenerated the identical CSV and report.
- HUD IDs were complete and unique. Row counts reconciled at 29,453 source
  new-construction records, 28,196 first-address choices, and 25,832 dated records.
  All dated rows had a year and coordinates. Every HUD point took priority; every
  used Census fallback lacked HUD coordinates and was exact and in the reported
  state. No manual overrides were added.
- The dated sample retained 249 missing total-unit counts and 6,469 incomplete
  or inconsistent bedroom breakdowns. Every retained nonmissing bedroom breakdown
  summed to the reported total. Reported total units summed to 1,730,065.
- The 51 state rows and 2,040 state/year rows had unique keys and reconciled to
  national totals. Primary exclusion reasons added to the losses in each state.
  The historical corroboration comparison still contained 21,380 projects.
- Every one of the 41 release columns was documented exactly once in the codebook.
  Source category definitions were checked against the dictionary inside the
  pinned HUD ZIP. The workbook's published record/unit totals and all ten annual
  2015–2024 benchmarks continued to match in the existing external audit.
- `make` in `paper/` checked the dataset. Root Make compiled the new logbook entry;
  its rendered page was inspected. No new exploratory plot was introduced.
- Frozen CSVs and reports are exact copies of their producing task's outputs.
  Release-file and source/output SHA-256 checks pass. `git diff --check` passes.

Source acquisition and the Make dependency graph were unchanged. Their earlier
changed-input, failed-download, checksum-rejection, and snapshot-preservation
checks remain documented with the preceding work; those network/acquisition
scenarios were not repeated for this formatting and release change. No source was
refreshed. Existing diagnostics were regenerated, but browser interaction with
the HTML report was not retested. This verifies the recorded build and selection
rules, not every source record's construction classification or geographic accuracy.

Runtime versions are recorded, not packaged into an executable environment.
On another runtime, compare the rebuilt files with `rebuild.sha256` rather than
assuming byte-for-byte reproduction. The saved release itself is independent of
whether a future machine can run the R pipeline.
