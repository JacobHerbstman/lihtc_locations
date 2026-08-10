# Review LIHTC Cross-Development Addresses, Round 2

This task validates the committed two-read review of 372 remaining
name/timing and phase/component questions. The questions contain 834 current
physical-development records.

The result is an explicit member-level partition: 566 physical-development
clusters. It merges 489 records into 221 multi-member clusters and retains 345
records as their own development. The partition is necessary because some
questions contain duplicate reporting within one phase and distinct phases at
the same address. A single yes/no decision would lose that distinction.

Nine clusters connect records across six pairs of prepared questions. Those
links are explicit in the member ledger; they are not inferred during
application.

The outside read records the Google search used and the direct public record
retained for each question. Most direct records are public property-directory
pages; allocating-agency, housing-authority, municipal, county, developer, and
housing-sector records replace weak or missing directory matches. These
sources corroborate identity decisions but do not make the source addresses
geocoding-ready.

No decision edits a source row, sums unit counts, approves a coordinate query,
or calls a geocoder.

Run from `code/`:

```sh
make
```
