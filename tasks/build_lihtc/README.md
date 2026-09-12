# First new-construction locations

Read original HUD new-construction records and archived Census address matches.
There are no individual corrections or manual adjudications in this build.

- `project_records.csv`: all 29,453 original TYPE=1 records in the 50 states and DC,
 with source values, address groups, selection flags, and exclusion reasons.
- `projects.csv`: 28,196 first-address choices, including provisional locations and
 unique records with missing years. This is the broad comparison sample.
- `confident_projects.csv`: 21,380 first-address records with usable addresses,
 valid placed-in-service years, and checked primary locations.
- `review.csv`: excluded records and their reasons. The existing filename is kept
 for compatibility; it is an accounting table, not a manual review queue.

## Selection

Keep the earliest new-construction record at each standardized primary address.
A unique record remains when dates or hedonics are missing. A repeated address
with any missing year has uncertain order, so no record is selected. Earliest-year
ties use the smallest HUD ID as a stable label; `source_hud_ids` preserves every
tied earliest ID. For each characteristic, keep the unique nonmissing value when
sources agree and otherwise leave it missing. Name or hedonic disagreement does
not invalidate the address. Never add units across repeated records.

This is first new construction, not first LIHTC financing. There are no parcel IDs.
Later phases at the same address are omitted by this definition, even if they
represent additional construction. Unusable addresses receive separate unresolved
keys, so their singleton rows remain in the broad table but fail confidence checks.

## Confidence checks

`usable_location` requires first-address selection, a usable address, a checked
location for every tied earliest record, agreement among their selected coordinates,
and no scattered-site or resyndication flag. `confident_first` additionally requires
an observed placed-in-service year from 1987 through 2024. A repeated address alone
is not an extra exclusion. Missing hedonics never remove a location.

Census must match the reported state. With HUD coordinates, a separation of at most
500 meters passes; without HUD coordinates, an exact Census match is required.
HUD-only points remain in the broader table as unconfirmed. Census points are
address-range matches, not building footprints. Scattered projects retain their
primary point in the broader table without claiming coverage of all their sites.

`exclusion_reason` counts the first applicable reason: uncertain ordering,
nonselected later/same-year record, unresolved address, missing year, resyndication,
scattered site, disagreement among tied coordinates, or another location problem.
These are reasons for exclusion under our rules, not confirmed source errors.

## Hedonics

Keep reported total units even when the bedroom breakdown disagrees. Set an
incomplete or inconsistent bedroom breakdown to missing; set low-income units to
missing when they exceed total units. Disagreement among tied earliest records
makes the affected field missing. Original values remain in project_records.csv.
The confidence sample retains 210 records without total units and 5,204 without a
consistent bedroom breakdown. No building-specific exception is applied.

The state diagnostics task compares record counts, observed unit sums, missingness,
and exclusion reasons by state and year. Root `make` updates the full graph;
task-local `make` uses prepared inputs. Current counts are dated September 12, 2026.
