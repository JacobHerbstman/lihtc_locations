# Audit Final LIHTC Geocoding Readiness

This local audit evaluates whether the post-adjudication LIHTC development
sites are ready to become geocoding queries. It reads the final physical
development, financing-episode, and site tables. It does not call a geocoder,
transmit an address, or alter a source or production row.

This task is deliberately separate from `audit_lihtc_geocoding_readiness`.
That earlier audit is an upstream input to the identity reviews and cannot also
depend on their final outputs without creating a circular dependency.

The input contains 53,469 physical developments, 54,902 financing episodes,
and 131,473 sites in the 50 states and District of Columbia. The 400
developments missing both static unit measures remain in the address audit;
unit-analysis eligibility does not determine geocoding readiness.

The audit preserves every final site field and classifies each site as ready as
written, ready after a deterministic formatting repair, requiring an address
split, requiring address review, requiring shared-address review, requiring
source or site-inventory review, or not safely geocodable. Within one
development, rows may share a base-address query only when every difference is
an approved trailing subpremise suffix and city, state, and ZIP agree. A base
address used by more than one development remains blocked.

The canonical output is
`output/lihtc_final_site_geocoding_readiness.parquet`. The proposed-query
Parquet contains 77,648 unique local queries covering 83,720 sites; every query
is marked `not_approved`. The manual-review sample and Markdown audit summary
are supporting outputs from the same run.

Run from `code/`:

```sh
make
```
