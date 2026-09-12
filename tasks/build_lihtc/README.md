# First new-construction locations

Read original HUD new-construction records and archived Census address matches.
Use valid HUD coordinates by default. Census confirmation is not required.
There are no individual corrections or manual adjudications.

- `project_records.csv`: all 29,453 original TYPE=1 records in the 50 states and DC,
  including source fields, address groups, selection flags, and exclusion reasons.
- `projects.csv`: 28,196 first-address choices, including undated records and
  locations whose address could not be standardized for matching.
- `confident_projects.csv`: 25,832 dated records with available primary locations,
  after excluding scattered-site/resyndication flags and conflicting tied locations.
- `review.csv`: excluded records with reasons. The existing filename is retained;
  it is an accounting table, not a manual review queue.

## First-address selection

Keep the earliest new-construction record at each standardized primary address.
A unique record remains when its date or hedonics are missing. A repeated address
with any missing year has uncertain ordering, so no record is selected. Earliest
same-year ties use the smallest HUD ID as a stable label; `source_hud_ids` lists
all tied IDs. Keep a characteristic when its nonmissing source values agree and
otherwise leave it missing. Never sum units across repeated records.

The rule uses placed-in-service year, not download date, and new construction,
not all LIHTC financing. Later phases at the same address are omitted by this
counting definition. Unresolved addresses receive separate HUD-ID keys. Such a
record can retain its HUD point, but is not established as a unique physical
address. `address_resolved` makes that distinction visible. There are no parcel IDs.

## Coordinates and the final sample

`longitude` and `latitude` use HUD when `hud_coordinates_present` passes the
existing numerical checks. If HUD coordinates are absent, an exact Census match
in the reported state can supply the point. An inexact Census point without HUD
coordinates remains provisional. `location_source` identifies the chosen source.
`location_available` records whether the point meets this source rule.

`location_status`, `location_checked`, and `hud_census_distance_m` retain the
Census comparison as diagnostics. A difference above 500 meters does not exclude
an otherwise available HUD point or replace its coordinates. The threshold in
the Makefile is explicitly diagnostic. No numbered address is required for HUD
coordinates. Census fallback points are address-range locations, not rooftops.

`usable_location` requires first selection, available and agreeing coordinates
among tied earliest records, and no scattered-site/resyndication flag.
`confident_first` also requires an observed 1987–2024 placed-in-service year.
`corroborated_first` reproduces the former Census-corroboration rule for comparison;
it does not determine inclusion. The state diagnostics show both samples.

Exclusions are assigned in priority order: uncertain ordering; nonselected later
or same-year record; missing year; resyndication; scattered site; conflicting tied
coordinates; unavailable location. A flag is not a confirmed source error.

## Hedonics and execution

Missing hedonics never remove a location. Reported total units take priority over
the bedroom breakdown. Inconsistent bedrooms and low-income counts become missing;
original values remain in project_records.csv. The final sample retains 249 records
without total units and 6,469 without a consistent bedroom breakdown.

Run root `make` for the full graph, or task-local `make` against prepared inputs.
Every saved dataset writes its deterministic metadata report via SaveData. Reports
are side effects, not Make targets or prerequisites. Current counts: September 12,
2026, following the change to HUD coordinates as the default.
