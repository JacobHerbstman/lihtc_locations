# LIHTC Unit-Scope Review

This task is the adjudication contract for the questions produced by
`prepare_lihtc_unit_scope_review`. It keeps the internal read, outside read,
final development-level decisions, and episode-level arithmetic in two small
committed CSV ledgers.

The CSV ledgers cover all 1,224 questions and 2,657 episode members: 1,142
multi-episode developments, 80 single-episode source-count problems, and two
external numeric conflicts. Every question has an internal read, an inspected
outside read, final development-level decisions, and episode-level roles. The
validator never converts a candidate, blank, or unresolved label into a final
result.

The validator also reads the prepared prior-evidence table. When a reviewer
reuses an earlier source, the selected URL must have been retained for the same
unit-scope question. This provenance check does not convert an earlier
identity-only read into unit-count evidence.

A use-once value also requires one full-group review row carrying the
duplicate or reporting-variant reason. This prevents a duplicate clue from a
subset from being combined with an unrelated source that happens to cover the
full review group.

The task produces:

- `lihtc_unit_scope_question_decisions.parquet`;
- `lihtc_unit_scope_member_decisions.parquet`.

This task does not apply unit totals to the development table, change HUD
source values, alter physical-development identity, or geocode an address.
