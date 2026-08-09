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
- [x] The supplementary multi-address/BIN file contains address records nested within HUD projects: 161,715 rows for 22,764 HUD IDs. Its `BIN` is HFA-supplied and is not a nationally unique building key.
- [ ] Sample: 55,345 published property rows covering records reported in the 1987–2024 database.
- [ ] Understand that the workbook and its data dictionary can disagree.
- [x] Mastery status: confirmed — the planned hierarchy is physical development, HUD project episode, and development site.

## Stage 3: Cleaning And Construction Logic

- [ ] Mechanical checks: raw-text import, missingness, parsing compatibility, documented domains, and cross-field arithmetic.
- [ ] Data-quality flags: impossible coordinates, malformed identifiers, inconsistent unit totals, and unexpected codes.
- [x] Use HUD's reconciled `n_unitsr` and `li_unitr` fields for project-level unit counts; all 439 original low-income-over-total conflicts are resolved by these fields.
- [ ] Treat bedroom-category counts as unreliable where their sum exceeds reconciled total units; do not drop the project row solely for that reason.
- [ ] Substantive decisions: whether a candidate duplicate is the same research object and which record, if any, should represent it.
- [x] Multiple multi-address/BIN rows within one HUD ID remain project components and should aggregate to one project row without summing repeated project-level unit totals.
- [x] Development-level unit totals remain missing for every provisional cross-HUD linkage; candidate aggregation rules are review aids rather than accepted totals.
- [x] No HUD project episodes have been excluded and no protected source values have been overwritten by linkage adjudication.
- [ ] Mastery status: pending

## Stage 4: Joins, Crosswalks, And Manual Decisions

- [x] Outside sources have been recorded as review evidence, but no outside address or unit field has been imported into the HUD-derived tables.
- [x] Conservative cross-HUD links produced 325 provisional development groups covering 798 HUD episodes without dropping any episode.
- [x] Matching normalized names plus a standardized primary address or identical complete multi-address set creates a provisional link; the next step is adjudication, not rerunning the same linkage rule.
- [x] A shared normalized address and project name is a useful cross-HUD-ID review signal, but the full address-set overlap, years, construction type, unit counts, state IDs, and data notes must be checked before collapse.
- [x] Every provisional group received an internal HUD-only read and a separate outside-source read, with notes, source URLs, and explicit reason codes committed as research data.
- [x] Final adjudication accepts 322 groups covering 788 episodes and rejects three coarse-address HCCI groups covering ten episodes.
- [x] The rejected groups are split into episode-level developments; all accepted multi-episode unit totals remain unresolved.
- [ ] Mastery status: implementation confirmed; interpretation check remains pending

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

- [x] Main research object: underlying physical development, with HUD IDs retained as project episodes and addresses retained as development sites.
- [x] Distinct HUD records linked only by a coarse street-level portfolio address are separated when outside evidence identifies distinct properties.
- [ ] Should later analyses treat resyndications as new allocations, repeated sites, or both in separate specifications?
- [x] Property identity review records public-agency, owner/operator, housing-press, property-listing, sector-compilation, or property-specific directory sources and preserves the source tier.

## Quiz Log

| Date | Stage | Question Type | Result | Follow-up Needed |
|---|---|---|---|---|
| 2026-08-08 | 1 | Researcher restatement requested | Pending | Yes |
| 2026-08-08 | 2 | Project-versus-site distinction | Restated, then corrected | Confirm HUD_ID/BIN relationship |
| 2026-08-08 | 4 | Cross-HUD linkage signal | Shared address and name proposed | Refine with full address-set and project-history evidence |
| 2026-08-09 | 4 | Final hierarchy | Physical development, project episode, development site confirmed | Review provisional linked developments |
| 2026-08-09 | 4 | Linkage sequence | Proposed linking matched records | Corrected: records are already provisionally linked; accept, reject, or split next |
| 2026-08-09 | 4 | Adjudication standard | Requested two distinct reads and outside research | Complete for all 325 provisional groups |
