# Audit LIHTC Identical Address Sets

This task recomputes groups of final physical-development records that carry
the same complete standardized site-address list after the round-two address
review. It distinguishes one-address groups from genuinely multi-address
groups and describes the latter using timing, unit-count, name-similarity, and
phase-name signals already present in the upstream audit.

The observable signatures are descriptive review strata. They do not merge
development records, edit site rows, approve shared coordinate queries, or
call a geocoder. Puerto Rico and the other territories are outside the task's
50-state-plus-DC scope.

Run from `code/`:

```sh
make
```
