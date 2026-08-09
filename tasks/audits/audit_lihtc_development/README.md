# Audit LIHTC Development Construction

This task verifies the three-table physical-development construction against the published property and multi-address sources. It checks primary and foreign-key uniqueness, proves that the project-episode table preserves every source property value, reconciles episode counts to developments, and produces explicit review queues for every provisional cross-HUD linkage and unit aggregation.

The canonical output is `output/audit_summary.md`. Supporting outputs are:

- `development_linkage_groups.csv`: one row per provisional linked development, including the linkage basis, episode history, unit rule, and review category.
- `development_linkage_members.csv`: the HUD records belonging to every provisional linked development.
- `development_site_review.csv`: unit-like addresses and sites with conflicting HUD coordinate pairs.

These outputs do not approve a linkage or correct a source record. They expose the evidence needed for researcher review.

Run from `code/`:

```sh
make
```
