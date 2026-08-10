# Audit LIHTC Geocoding Readiness

This local audit evaluates whether the final LIHTC development-site addresses are ready to become geocoding queries. It does not call a geocoder, transmit an address, or alter a source or production row.

The research scope is the 50 states and the District of Columbia. Puerto Rico and the other territories remain in the source tables and are reported as explicit out-of-scope records.

The audit reconstructs the site-address inputs from the HUD property and multi-address records, checks address forms and repeated-address collisions, evaluates internal coordinate consistency, and creates a local set of proposed query records. It preserves raw address fields, documents format-only ZIP proposals separately, and retains unit and building suffixes for review. Every proposed query remains marked as not approved for submission.

The outputs distinguish provisional one-query mappings from records requiring an address split, source review, address-form review, or repeated-address review. They do not automatically decide that two rows are duplicates, strip building labels, or claim that an internally plausible HUD coordinate belongs to the listed street address.

Run from `code/`:

```sh
make
```
