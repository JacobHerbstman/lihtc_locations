# Audit HUD LIHTC Property Data

This task audits every column and row in the 2024 HUD LIHTC property workbook before the project constructs an analysis dataset. It analyzes the upstream raw-text Parquet snapshot with R and `data.table`, checks the workbook against HUD's data-dictionary claims, profiles missingness and value distributions, tests cross-field consistency, and writes separate review queues for anomalous rows and potential duplicate projects.

The task does not change the raw workbook, delete rows, choose a canonical record, or produce an analysis-ready dataset. Its duplicate groups and issue flags are evidence for researcher review, not automatic error classifications. Exact coordinates or addresses can legitimately recur when projects share a site, have multiple financing phases, or were resyndicated.

Run the task from `code/`:

```sh
make
```

The canonical output is `output/audit_summary.md`. Supporting outputs are:

- `column_profile.csv`: observed type compatibility, missingness, distinctness, normalization collisions, ranges, and dictionary-domain violations for all 80 columns.
- `top_value_frequencies.csv`: the most common raw values in every column, including missing values.
- `row_issue_summary.csv`: counts and examples for each deterministic issue rule.
- `row_issues.csv`: row-level review queue with source row, HUD identifier, field, observed value, and reason.
- `duplicate_groups.csv`: candidate duplicate groups under several explicit keys.
- `duplicate_members.csv`: the records belonging to each candidate group.
- `workbook_structure.csv`: sheet, formula, error-cell, validation, merge, and cell-storage counts read directly from the XLSX XML.

HUD's `LIHTC Data Dictionary 2024.pdf` is stored inside the committed source ZIP. `code/dictionary_claims.csv` transcribes its type and value-label claims. Three workbook columns (`st2020`, `cnty2020`, and `trct2020`) do not appear in that dictionary and are identified as undocumented rather than assigned inferred definitions.
