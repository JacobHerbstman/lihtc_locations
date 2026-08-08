# Research Understanding Checklist

## Session Goal

- [ ] Explain why an audit must precede construction of an analysis dataset.
- [ ] Distinguish deterministic anomalies from records that require substantive review.
- [ ] Understand what changed: a read-only audit task was added; no source rows were corrected or removed.

## Stage 1: Problem And Motivation

- [ ] What problem existed? Only archive integrity, row count, and required headers had been checked.
- [ ] Why would trusting column names or apparent Excel types fail?
- [x] Why can repeated addresses, coordinates, or project names be legitimate? They may reflect multiple sites, co-located projects, or financing phases rather than duplicate rows.
- [ ] Mastery status: corrected — bedroom-category counts were initially interpreted as literal bedrooms rather than counts of units by bedroom category.

## Stage 2: Data Provenance And Raw Inputs

- [ ] Primary source: HUD's committed 2024 LIHTC public-data ZIP.
- [x] Raw unit of observation: a HUD database project record, not necessarily a building, allocation, owner, or unique physical site.
- [ ] Sample: 55,345 published property rows covering records reported in the 1987–2024 database.
- [ ] Understand that the workbook and its data dictionary can disagree.
- [ ] Mastery status: restated — the planned dataset is project-level and should retain multiple sites within a project.

## Stage 3: Cleaning And Construction Logic

- [ ] Mechanical checks: raw-text import, missingness, parsing compatibility, documented domains, and cross-field arithmetic.
- [ ] Data-quality flags: impossible coordinates, malformed identifiers, inconsistent unit totals, and unexpected codes.
- [x] Use HUD's reconciled `n_unitsr` and `li_unitr` fields for project-level unit counts; all 439 original low-income-over-total conflicts are resolved by these fields.
- [ ] Treat bedroom-category counts as unreliable where their sum exceeds reconciled total units; do not drop the project row solely for that reason.
- [ ] Substantive decisions: whether a candidate duplicate is the same research object and which record, if any, should represent it.
- [ ] No rows have been excluded and no source values have been overwritten.
- [ ] Mastery status: pending

## Stage 4: Joins, Crosswalks, And Manual Decisions

- [ ] No external data have been joined yet.
- [ ] Duplicate candidates are represented as review groups; no many-to-many merge or automatic collapse occurs.
- [ ] Manual decisions remain unresolved and must eventually carry explicit reason codes.
- [ ] Mastery status: pending

## Stage 5: Analysis, Tables, And Plots

- [ ] No outcome, denominator, aggregation, or plot has been constructed yet.
- [ ] Audit counts are not substantive estimates of LIHTC siting.
- [ ] Mastery status: pending

## Stage 6: Interpretation And Research Claims

- [ ] Safe claim: the audit identifies records that violate documented or internally testable expectations.
- [ ] Unsafe claim: every flagged record is erroneous or should be removed.
- [ ] Understand what evidence would justify a correction or exclusion.
- [ ] Mastery status: pending

## Open Questions

- [x] Main research object: HUD project (`hud_id`), with multiple sites or buildings represented as project components rather than separate analysis rows.
- [ ] Decide how to label distinct HUD projects that share a physical site or development name; do not collapse them automatically.
- [ ] Should later analyses treat resyndications as new allocations, repeated sites, or both in separate specifications?
- [ ] Which external sources should adjudicate unresolved coordinates and project identities?

## Quiz Log

| Date | Stage | Question Type | Result | Follow-up Needed |
|---|---|---|---|---|
| 2026-08-08 | 1 | Researcher restatement requested | Pending | Yes |
| 2026-08-08 | 2 | Project-versus-site distinction | Restated, then corrected | Confirm HUD_ID/BIN relationship |
