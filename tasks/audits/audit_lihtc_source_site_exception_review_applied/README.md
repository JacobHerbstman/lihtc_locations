# Audit Applied LIHTC Source-Site Exception Review

This audit independently compares the post-single-address tables, the source
review ledgers, and the repaired outputs. It verifies the exact removed and
added site IDs, the Mechanic Mill transaction, preservation of every original
episode value, unchanged development unit values, recalculated site counts,
and the physical versus nonphysical development-scope statuses.

The sole output is
`lihtc_source_site_exception_application_audit.parquet`. A failed invariant
stops the task before a passing audit row is written.

Run `make` from `code/`.
