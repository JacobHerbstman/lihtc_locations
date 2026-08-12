# LIHTC dataset acceptance audit

This task freezes downstream geography work and inventories every observation
in the current LIHTC pipeline. It does not repair, approve, geocode, assign a
tract, or declare the dataset analysis-ready.

The primary output contains one row for each current physical development,
source financing episode, raw episode-site membership or external site
addition, retained final site, derived address component, and proposed query.
The statuses distinguish an affirmative review from a default rule, a known
unresolved issue, a documented exclusion, and an unapproved downstream
candidate.

The audit reconstructs raw site membership from the immutable built site
table, then verifies every disappearance against the territory/nonphysical,
source-site, or singleton-site review ledgers. The retained-site inventory
separately identifies rows that received explicit site review and the much
larger group inherited without an individual site decision.

`lihtc_dataset_acceptance_status_counts.parquet` summarizes the inventory.
`dataset_acceptance_summary.md` records the main acceptance blockers. These are
audit outputs, not a cleaned replacement dataset.

The exact row and status counts are intentional frozen-baseline contracts for
the 2024 release and the review ledgers dated through August 12, 2026. A
legitimate upstream revision should stop this task until the changed universe
and every affected disposition have been explicitly re-audited; the guards are
not generic expectations for later HUD releases.
