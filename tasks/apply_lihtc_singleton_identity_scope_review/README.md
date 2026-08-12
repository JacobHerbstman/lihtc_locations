# Apply singleton identity and scope review

This task applies the frozen outside review of physical-development identities
that were discovered after the mixed-site application. It preserves every HUD
episode, marks financing portfolios as nonphysical bridge rows, merges only
reviewed physical developments, and carries the reviewed site union forward.

The task does not aggregate units. Every newly merged development remains in
unit-scope review. A reviewed physical target whose frozen status defers units
also returns to unit review even when it contains only one source member; HUD
episode values remain unchanged.

One output development row represents one documented property or community.
It may contain multiple buildings or sites when the outside source treats them
as one development. Financing and phase records remain separate project
episodes, and individual addresses, buildings, or lots remain separate
development-site rows. Financing portfolios that cover separately named
properties stay nonphysical and require a later property bridge.

When reviewed members carry the same final site key, the application retains
one deterministic site row and unions the contributing episode, coordinate,
BIN, and source lineage. An unresolved physical site or nonphysical bridge site
is always marked as requiring site review. No site is approved for geocoding in
this task.
