# Verification — September 15, 2026

Baseline: `3628269`. This change adds a raw LOCUS assessment and an independent Census metro-fragmentation comparison. It does not change LIHTC cleaning, project geography, demographic timing or any placement model.

## Data and numerical checks

- All eight original LOCUS Parquet SHA-256 values match the recorded publisher inventory. A direct independent Parquet query, joined by shard and one-based source row, reconciles all **24,991** exported observations and original fields. City counts and Unicode character totals also reconcile. Seven selected cities match; Los Angeles city does not.
- Round-trip checks found that the initial `fread` consumer retained doubled embedded quotation marks, and base CSV parsing treated one empty content string as missing. The CSV export itself preserved the original values. Both new text consumers now decode quotes with base CSV parsing and restore the source's empty content string; the producer verifies there are no null source headers/content. The final source-value comparison passes. No shared writer or existing consumer was changed.
- The national government file has **38,736** unique source IDs. Independent comparisons with the original General Purpose sheet match every exported ID, government name, primary county and active status. **1,940** active governments receive one of the eight selected MSA assignments; **36,700** active and **96** dormant governments fall outside those assignments. All eight central-city place codes match the official principal-city list, and their government primary-county MSA agrees with that list.
- County-to-MSA and county-population keys are unique. Every selected MSA county matches its 2021 population. All eight central-city populations in the inventory are dated 2021. Disjoint county populations supply the denominator; government populations are not summed. Independent Python calculations reconcile every count, count per 100,000 and central-city share.
- `metro_comparison.csv` contains **48** unique city/sample/variable rows. Every original model field, coefficient, interval and actual N matches its source row. The original 288-row placement-model file retains MD5 `aa0bd89f1c1cea94e6bc798c76a77ea7`.
- Independent Python calculations using `statistics.correlation` and explicit midranks reproduce **all 162** Pearson/Spearman results and their city Ns to absolute tolerance `1e-12`. Main comparisons use eight cities; all single-city omissions use seven. These numerical checks do not validate a causal interpretation or government counts as a measure of zoning discretion.

## Build behavior

- Root `make`, task-local Make and `make -C paper` run under **GNU Make 3.81**. Root `make setup` records the added DBI/DuckDB dependencies; they were already installed. Analysis installs no packages.
- A disposable fixture copies the actual new task code, shared helpers, city list, model file and public Census sources; the unchanged sibling LOCUS source is read-only. Its root uses the new concrete root rules. A fresh `make -j4` reproduces every audit output and data report byte for byte; the shared Make settings serialize recursive execution as required by the project. A second build rewrites no outputs/reports.
- Removing the actual LOCUS coverage and metro-fragmentation CSVs and their reports rebuilds the datasets, reports and consumers through root Make. Removing reports alone is not a build trigger.
- Changing the fixture's Boston source-name key removes exactly 1,750 raw rows and records missing city text explicitly. Other source-city counts are unchanged. This checks propagation of a research specification, not a production exclusion.
- A deliberately wrong expected LOCUS hash in the fixture fails before replacing its last usable extract. Original raw files are never modified.
- Acquisition retrieves missing public files through four explicit rules and checks SHA-256 before publishing. A fixture changes the principal-city source URL to an absent local file: the transfer fails, and the existing saved Census file remains byte-identical. Source-definition changes therefore reach acquisition without destroying the recorded snapshot on failure.
- Final formatting changes to the generated TeX and task `all` list were rebuilt and checked for incrementality after the fresh-fixture checks. `git diff --check` passes for code and documentation. The original Census population CSV retains publisher CRLF bytes; the full staged check passes with Git's `cr-at-eol` whitespace setting, without rewriting that source.

## Presentation and limits

The standalone scatterplot and logbook entries were rendered and inspected. The logbook compiles to 29 pages; the new entries are pages 28–29. HTML tables and local artifact links were inspected as files. Automated browser inspection of the local-file report was blocked by the browser URL policy, so browser rendering is not claimed as verified.

The substantive limits remain visible in the report: selective LOCUS coverage; uncompleted legal classifications; Census primary-county assignment instead of complete jurisdiction territory; government counts rather than zoning-authority counts; modern institutions versus pooled 1987–2022 central-city placements; eight selected, unequally precise city slopes. The legal extraction and metro comparison are separate outputs. No old phrase score, new legal-score correlation, manual city override or fitted composite enters the results.
