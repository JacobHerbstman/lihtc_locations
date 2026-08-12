# Audit LIHTC Unit-Scope Application

This task independently verifies the unit-scope application. It checks the
50-state-and-DC physical/excluded partition, exact decision coverage,
preservation of HUD episode and site fields, preservation of pre-review
development values, development-level numeric application, and episode-member
roles. It independently reconstructs representative and component arithmetic,
external exact-count contracts, missing-value semantics, and the row-level
exclusion reason for every excluded episode. It also reconstructs the
downstream unit-analysis status from the two final count fields and verifies
that the status propagates exactly to every retained episode and site.

The output contains one row per named invariant and is written only when every
check passes.

The completed audit covers 53,469 physical developments, 54,902 episodes,
131,473 sites, and 443 separately preserved excluded episodes. It verifies
that exactly 400 retained developments are marked for exclusion from the
default downstream unit-analysis sample because both static counts are
missing.
