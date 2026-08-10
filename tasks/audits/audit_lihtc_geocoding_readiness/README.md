# Audit LIHTC Geocoding Readiness

This local audit evaluates whether the final LIHTC development-site addresses are ready to become geocoding queries. It does not call a geocoder, transmit an address, or alter a source or production row.

The research scope is the 50 states and the District of Columbia. Puerto Rico and the other territories remain in the source tables and are reported as explicit out-of-scope records.

The audit reconstructs the site-address inputs from the HUD property and multi-address records, checks address forms and repeated-address collisions, evaluates internal coordinate consistency, and creates a local set of proposed query records. It preserves raw address fields and documents format-only ZIP proposals separately. Within one established development, rows that differ only by a trailing building, unit, apartment, suite, floor, or room suffix may share one base-address query when city, state, and ZIP also agree. Addresses shared across different developments remain blocked for review. Every proposed query remains marked as not approved for submission.

The outputs distinguish provisional one-query mappings from records requiring an address split, source review, address-form review, or repeated-address review. They do not automatically decide that two rows are duplicates, alter a published site address, or claim that an internally plausible HUD coordinate belongs to the listed street address.

Run from `code/`:

```sh
make
```
