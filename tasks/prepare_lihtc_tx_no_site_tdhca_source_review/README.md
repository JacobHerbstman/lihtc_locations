# Prepare Texas No-Site TDHCA Source Review

This task screens the 91 Texas developments in the final no-retained-site
queue against TDHCA's frozen 2026-08-12 HTC Property Inventory workbook.
TDHCA is the state allocating agency and this published statewide HTC
inventory is an official allocating-agency bulk source for candidate
screening.

It records two deliberately conservative candidate ledgers:

- exact normalized development-name matches; and
- non-exact names only where normalized TDHCA city and total units both agree
  and Levenshtein distance is at most 0.25 of the longer normalized name.

The second screen is a typo/near-name screen, not a linkage rule. All outputs
remain `not_adjudicated` and `not_approved`. The task does not create a site,
accept an address or coordinate, approve a geocoding query, or change final
LIHTC data. A row-level review with independent evidence is required before
any candidate address can be used. In particular, a workbook address may be a
current, administrative, or management address; it does not establish
exhaustive physical-site scope.

The script verifies the frozen SHA-256 digest, row count, required source
columns, and output counts before writing. Run `make` from `code/`.
