# Cross-Development Address Review Protocol, Round 2

## Unit of review

The prepared questions are connected components of the remaining high-value
name/timing and phase/component pair edges. The final unit of adjudication is
the member-level physical-development partition. That partition can cross a
prepared question boundary when the broader shared-address evidence reveals
duplicate records that the candidate-edge graph did not connect.

## Two reads

The internal read compares normalized and published names, non-placeholder
state IDs, primary and complete address sets, allocation and placed-in-service
years, unit scopes, episode histories, and source-quality flags. No labeled
field and no shared address is assumed correct or dispositive.

The outside read begins with a separate Google search and retains a direct
public property, allocating-agency, housing-authority, municipal, county,
developer, or housing-sector record. Search URLs and direct-source URLs are
committed. Public property directories are treated as corroborating records,
not independent proof that the underlying HUD address is accurate.

## Partition decisions

- `merge_all` assigns every member of the question to one physical
  development.
- `retain_each` preserves every member as a distinct physical development.
- `partition` applies an explicit mixed member partition within the question.
- `cross_question_partition` links duplicate members across prepared question
  boundaries while retaining distinct phases or components.

Only the committed member ledger implements these decisions. A merge changes
the physical-development identifier while preserving every HUD row as a
project episode and every source address as evidence. Development-level unit
totals are not inferred from records with unresolved episode scope.

## Identity is not a coordinate decision

Several distinct buildings or financing phases may legitimately use a common
street address, and one physical development may have several addresses. The
identity partition therefore does not approve a shared coordinate query. Every
query decision remains `not_approved`; the task makes no network geocoding call
and transmits no address to a geocoder.
