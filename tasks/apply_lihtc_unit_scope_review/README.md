# Apply LIHTC Unit-Scope Review

This task applies validated development-level unit decisions to the corrected
physical-development data. It never changes HUD episode fields. The physical
development table retains the pre-review development values, records separate
total and low-income actions, and replaces the canonical development values
only with validator-approved results.

The final analysis tables contain 53,469 physical developments, 54,902
episodes, and 131,473 sites in the 50 states and DC. The separate evidence
Parquet preserves 443 excluded episodes: 26 from nonphysical development
scope and 417 outside the 50 states and DC.

All three physical tables carry a downstream unit-analysis status. The default
quantitative sample excludes the 400 developments missing both a defensible
static total-unit count and low-income-unit count. Those developments and all
of their episodes and sites remain in the master tables. The status separately
identifies 52,919 developments with both counts, 132 with total units only,
and 18 with low-income units only so measure-specific analyses can apply the
appropriate complete-case rule.

Run `make` from `code/` after the unit-scope ledgers validate.
