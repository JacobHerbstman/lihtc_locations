# Apply LIHTC Cross-Development Address Review, Round 2

This task applies the committed 566-cluster member partition to the current
physical-development, project-episode, and development-site datasets.

It changes only physical-development grouping and derived aggregates. All
55,345 HUD rows remain project episodes. The site output preserves every
distinct mapped development/address key and collapses only exact duplicate keys
created by a reviewed identity merge. Newly merged developments keep maximum
and summed episode counts as diagnostics, but their final and candidate unit
totals remain missing until unit scope is reviewed separately.

No source row is edited and no geocoding query is approved or submitted.

Run from `code/`:

```sh
make
```
