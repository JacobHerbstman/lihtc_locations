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

Run `make` from `code/` after the unit-scope ledgers validate.
