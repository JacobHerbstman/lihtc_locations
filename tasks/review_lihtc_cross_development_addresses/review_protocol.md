# Cross-Development Address Review Protocol

## Unit of review

The review unit is a connected set of current physical-development records
linked by at least one high-evidence shared-address edge. Connected components
are reviewed once so a three-or-more-development question cannot receive
contradictory pairwise decisions.

## Two reads

The internal read uses normalized and published names, non-placeholder state
IDs, primary and complete site sets, allocation and placed-in-service years,
unit scopes, and source-quality flags. No field is assumed correct merely
because of its label, and no single field decides identity.

The outside read uses a direct public property, allocating-agency, housing
authority, municipal, county, or housing-sector source reached through a
separate Google search. Search and direct-source URLs are retained in the
committed ledger. A previously completed two-pass decision is carried forward
with its original source rather than repeated.

## Identity decisions

- `merge` assigns current development records to one physical development. It
  preserves every HUD row as a project episode and every site row. It does not
  sum unit counts.
- `retain_separate` preserves current development identifiers when the evidence
  identifies distinct phases, components, campuses, projects, or source
  collisions.
- `defer` is allowed only for the internal read. No final decision is deferred.

## Address-overlap classes

Identity and address validity are separate. A retained development pair can
share a valid campus address, but it can also appear to overlap because a
portfolio record includes another property's site, because a source copied
sites across unrelated properties, or because a street-only or parcel-style
label is not a physical address. These classes are preserved for later source
repair and compound-address review.

## Geocoding safety

Every shared-query decision remains `not_approved`. The review makes no network
geocoding call, transmits no address, and changes no source row.
