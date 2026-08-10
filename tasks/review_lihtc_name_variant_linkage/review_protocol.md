# LIHTC Name-Variant Linkage Review Protocol

## Review queue

This second linkage pass begins from current developments that share a state ID passing the existing missing-value screen and the same standardized primary address but have different normalized names. These fields define a review block, not an automatic link. The queue contains 163 blocks and 327 representative HUD rows, one for each current development in the queue. The application maps every episode already assigned to those current developments, affecting 336 episodes in total.

The blocks are reviewed in three evidence classes: 120 with identical allocation year, placed-in-service year, reconciled total units, and reconciled low-income units; 11 with identical reconciled unit counts but different timing; and 32 with different timing or unit counts.

## Two reads

The internal read uses HUD names, state IDs, addresses, years, reconciled units, construction and resyndication codes, and data notes. The outside read uses a property-specific public record, owner or operator page, housing-sector source, listing, or directory result reached through a separate web search. The direct source and search URLs are retained in the group ledger.

## Decisions

- `merge` assigns the current development IDs to one physical development while retaining every HUD row as a project episode.
- `retain_separate` preserves the current development IDs because outside evidence and the HUD unit scopes indicate distinct phases, components, or projects using the same primary address.
- `defer` is allowed only for the internal read. No final decision may remain deferred.

Name broadening is manual and block-specific. It covers abbreviations, punctuation, typographical errors, site or location suffixes, address labels, former names, and other documented reporting variants. No edit-distance threshold or fuzzy-name rule creates links outside the 163 reviewed blocks.

This identity review does not resolve development-level unit totals. Merged multi-episode developments retain missing final unit totals and an explicit candidate aggregation rule.
