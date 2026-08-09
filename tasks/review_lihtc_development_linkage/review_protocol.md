# LIHTC Development Linkage Review Protocol

## Review unit

The review unit is a provisional cross-HUD development group produced by `build_lihtc_development`. A group exists only when normalized project names agree and the records share either the same standardized primary address or the same complete standardized multi-address set.

The review decides physical-development identity. It does not decide whether repeated or conflicting unit counts should be summed, carried forward, or otherwise reconciled.

## Two independent reads

1. The internal read uses only the HUD project episodes, including names, addresses, state IDs, placed-in-service and allocation years, construction and resyndication fields, unit counts, and data notes. Its result is stored in the `pass1_*` columns.
2. The outside read uses a separate web search for the named property and location. Search-result advertisements and generic results are not evidence. A retained source must identify the reviewed property by name or location. Its result and URLs are stored in the `pass2_*` columns.

The source-type fields distinguish public records, owners or operators, housing press, sector compilations, property listings, and web housing directories. Many directory pages reproduce public housing data and are corroborating evidence, not independent administrative records.

## Decision rules

- `accept`: treat the HUD records as project episodes for one physical development.
- `reject`: do not use the provisional cross-HUD link; retain each HUD episode as a separate physical development.
- `defer`: the internal evidence alone is insufficient. No final decision may remain deferred after the outside read.

The final decision follows the outside read after comparing it with the internal evidence. The accepted records preserve all HUD project episodes. Rejected records are split without importing unverified street numbers or other outside fields into the HUD-derived site table.

## Completed review

The committed review covers all 325 provisional groups and 798 member episodes in the 2024 HUD extract. It accepts 322 groups covering 788 episodes. It rejects three HCCI portfolio groups covering ten episodes because the common HUD address contains only a street name; outside listings show distinct street numbers and unit totals. All accepted multi-episode development unit totals remain unresolved for later review.
