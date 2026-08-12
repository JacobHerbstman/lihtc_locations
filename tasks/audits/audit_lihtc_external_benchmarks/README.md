# Audit LIHTC External Benchmarks

This audit compares the final 50-state-and-DC LIHTC physical-development and
financing-episode tables with published HUD and Soltas statistics. Its purpose
is to detect broad construction or unit-field failures before geography work,
not to force the current data to equal an older release.

The primary benchmark is HUD's 1995-1998 project report. Physical-development
size and low-income share use the final one-row-per-development table.
Construction, credit, and bedroom comparisons use financing-episode fields
because those source attributes remain episode-level. Those rows are labeled
as near comparisons rather than direct project replications.

Soltas studies competitive 9-percent applications rather than HUD financing
episodes or completed physical developments. His 2005-2019 statistics are
therefore retained only as scale checks. The output records this difference in
`comparability` and `audit_role`. The same unconditioned local statistic is
repeated beside each published Soltas subgroup solely to show scale; these rows
are not local winner/loser or matched/unmatched estimates.

Published values and citations are frozen in
`code/external_benchmarks.csv`; every linked source was read on 2026-08-12.
The canonical output is
`output/lihtc_external_benchmark_audit.parquet`; the Markdown summary is a
supporting report from the same run.

Run from `code/`:

```sh
make
```
