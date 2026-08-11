# Review Identical Multi-Address Sets

This task records a two-read review of the 98 unresolved identical-address-set
groups retained after excluding the known eight-address Massachusetts and
53-address Baltimore portfolio cross-listings.

The committed group ledger is the source of the review decisions. The R
validator checks that it covers the upstream audit queue exactly, attaches the
frozen internal evidence, and derives a proposed member-level physical-
development mapping. The `apply_lihtc_identical_address_set_review` task
consumes that mapping. This task does not change the cleaned LIHTC data,
aggregate unit counts, delete records, or approve any address for geocoding.

Run `make` from `code/`.
