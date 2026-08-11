# Apply LIHTC Identical Address-Set Review

This task applies the committed review of 98 unresolved identical
multi-address sets to the current physical-development, project-episode, and
development-site tables. It merges the 85 approved physical-development
groups and retains the 13 reviewed distinct groups.

Every HUD row remains a project episode. The site output preserves every
distinct mapped development/address key and collapses only keys that become
exact duplicates within an approved physical development. Newly merged
development-level unit totals remain missing until unit scope is reviewed.
No source address is changed and no geocoding query is approved.

The `audits/audit_lihtc_identical_address_sets_adjudicated` task verifies the
result against the input tables and committed mapping.

Run `make` from `code/`.
