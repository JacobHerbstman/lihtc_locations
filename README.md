# LIHTC Locations

This repository studies where Low-Income Housing Tax Credit developments are
built within US municipalities, with particular attention to whether new
projects are disproportionately located in poorer, renter-heavy neighborhoods.

The workflow is task-based. Each production task lives in
`tasks/<task_name>/` and has its own `code/`, `input/`, and `output/` folders.
Run a task from its `code/` folder with `make`. Concrete file prerequisites in
the task Makefiles form the dependency graph; audits and exploratory checks
live under `tasks/audits/`.

The project is currently constructing and reviewing a national physical-development crosswalk. The first empirical milestone is a national development-by-tract panel that distinguishes within-municipality sorting from differences across municipalities.

The preliminary literature map is in
[`notes/literature_map.md`](notes/literature_map.md). It identifies substantial
prior work on LIHTC neighborhood siting and a narrower opening around the
within-municipality homeownership gradient.

## Running the Project

Check command-line tools and install the declared R packages:

```sh
cd tasks/setup_environment/code
make
```

Build the current paper skeleton from the repository root:

```sh
make
```

Copy the committed data-source ledger to its task output for downstream use:

```sh
make sources
```

Download and validate the pinned 2024 HUD LIHTC release:

```sh
make lihtc-data
```

Convert the published property and multi-address Excel tables to value-preserving raw-text Parquet files:

```sh
make prepare-lihtc-data
```

Run the field-level, row-level, and duplicate-candidate audit:

```sh
make audit-lihtc-data
```

Build the provisional physical-development, HUD-project-episode, and development-site tables, then run their linkage audit:

```sh
make build-lihtc-development
make audit-lihtc-development
```

Validate the committed two-pass linkage decisions, apply them to the three
development tables, and audit the result:

```sh
make adjudicate-lihtc-development
make audit-lihtc-development-linkage
```

Review same-state-ID, same-primary-address blocks whose standardized names
differ, apply the adjudicated name variants, and audit the second pass:

```sh
make adjudicate-lihtc-name-variants
make audit-lihtc-name-variants
```

Run the completely local geocoding-readiness audit for the 50 states and DC:

```sh
make audit-lihtc-geocoding-readiness
```

Audit addresses used by more than one final development, collapsing repeated
addresses to unique development-pair evidence:

```sh
make audit-lihtc-cross-development-addresses
```

Collapse the high-identity-evidence pairs to connected review questions and
carry forward previously completed phase/component decisions:

```sh
make prepare-lihtc-cross-development-address-review
```

Validate the committed two-pass internal and outside-source identity review:

```sh
make review-lihtc-cross-development-addresses
```

Apply the reviewed physical-development identities while preserving every
project episode and every distinct source address, then rebuild the
shared-address audit on the adjudicated identifiers:

```sh
make apply-lihtc-cross-development-address-review
make audit-lihtc-cross-development-addresses-adjudicated
```

Prepare connected second-round questions for the remaining close-name,
timing, and phase/component address pairs:

```sh
make prepare-lihtc-cross-development-address-review-round2
```

Validate and apply the explicit round-two member partition, then rebuild the
shared-address audit on the new physical-development identifiers:

```sh
make review-lihtc-cross-development-addresses-round2
make apply-lihtc-cross-development-address-review-round2
make audit-lihtc-cross-development-addresses-round2-adjudicated
```

Review and apply the unresolved identical multi-address sets, excluding the
known Massachusetts eight-address and Baltimore 53-address portfolio
cross-listings, then audit the application:

```sh
cd tasks/review_lihtc_identical_address_sets/code
make
cd ../../apply_lihtc_identical_address_set_review/code
make
cd ../../audits/audit_lihtc_identical_address_sets_adjudicated/code
make
```

Prepare and audit the remaining identity questions among developments with one
standardized site key, excluding territories and addresses that also contain a
multi-address development:

```sh
cd tasks/prepare_lihtc_single_address_review/code
make
cd ../../audits/audit_lihtc_single_address_review_preparation/code
make
cd ../../../review_lihtc_single_address/code
make
cd ../../apply_lihtc_single_address_review/code
make
cd ../../audits/audit_lihtc_single_address_adjudicated/code
make
```

Apply the final project/community identity and source-site corrections, then
audit every retained, removed, collapsed, and externally added site:

```sh
make adjudicate-lihtc-singleton-identity-scope
make audit-lihtc-singleton-identity-scope
```

Adjudicate development-level unit counts while preserving every financing
episode, restrict the analytic tables to physical developments in the 50
states and DC, and run the independent application audit:

```sh
make adjudicate-lihtc-unit-scope
make audit-lihtc-unit-scope
```

Rebuild address readiness from the final physical-development, episode, and
site tables without calling a geocoder:

```sh
make audit-lihtc-final-geocoding-readiness
```

Prepare, review, and apply compound-address components; review apparent ranges
without expanding endpoints; then build and independently audit the local
geocoding-query crosswalk:

```sh
make prepare-lihtc-compound-address-review
make review-lihtc-compound-addresses
make apply-lihtc-compound-address-review
make prepare-lihtc-range-address-review
make review-lihtc-range-addresses
make build-lihtc-geocoding-query-crosswalk
make audit-lihtc-geocoding-query-crosswalk
```

The earlier readiness audit calls no geocoder and transmits no address or
coordinate. It keeps Puerto Rico and the other territories as explicit
out-of-scope records,
preserves raw address fields, and marks every locally proposed query as
`not_approved`. The cross-development audit separately preserves one row per
shared address, address-development member, and unique development pair. Its
review strata do not merge a development or approve a shared query.
The review-preparation task also makes no new decision; it prevents a
three-or-more-development question from being decided inconsistently as
separate pairs. The review ledger merges only physical-development identities,
preserves every project episode and distinct site key, and approves no
geocoding query. The adjudicated audit maps the prior local readiness evidence
to the new identifiers, records completed retain-separate reviews, and leaves
all other identity and address decisions unresolved. The second-round
preparation contains 372 connected questions with 834 development members and
supports partitions within a connected question; it makes no linkage decision
and approves no geocoding query. The committed round-two review resolves those
834 records into 566 physical-development clusters. Applying the partition
reduces the physical-development count from 54,612 to 54,344 while preserving
all 55,345 project episodes. The site count falls from 134,646 to 134,232 only
because 414 development/address keys become exact duplicates inside a reviewed
physical development.

The post-application audit confirms that all 587 prepared candidate edges are
resolved: 359 end within one physical development and 228 end between reviewed
distinct developments. It also makes the remaining scope explicit rather than
calling the address problem solved. There are 5,987 residual development pairs
sharing at least one address, including 2,435 pairs with the same complete
address set and 662 pairs sharing a primary address that were outside the
round-two queue. These are still blocked from geocoding and need subsequent
address-set, portfolio/campus, and source-contamination review.

The subsequent identical multi-address-set review covers 98 groups and 199
development records. Applying its 85 merge decisions and 13 retain-separate
decisions produces 54,257 physical developments, 55,345 project episodes, and
133,551 unique development/address keys. The application removes no HUD
episode, approves no geocoding query, and leaves unit totals unresolved for
the newly merged developments. The two excluded copied portfolio lists and
eight reviewed contaminated or administrative address sets remain explicit
site-level repair cases.

The single-address preparation starts from that applied layer. Of 42,030
in-scope developments with one standardized site key, 38,191 use an otherwise
unique address. Another 177 groups with street-only, nonphysical, compound,
range, portfolio, or multiple-address evidence are deferred for later address
repair. The resulting review queue contains 1,149 shared-address identity
questions with 2,463 development members and 1,617 unresolved pairs. Six fully
prior-reviewed groups are not reopened, and one prior retain-separate pair
decision remains an explicit constraint. The queue contains no territory or
multi-address development and makes no identity, address, unit, coordinate, or
geocoding decision.

The committed two-read single-address review resolves the 2,463 development
records into 2,236 physical-development clusters. Applying that partition
produces 54,030 physical developments, preserves all 55,345 HUD project
episodes, and produces 133,324 distinct development/address keys. The
independent application audit verifies that no protected episode field,
unmerged site record, source row, or territory development changed. The 215
newly merged developments retain missing development-level unit totals, and
1,052 developments remain explicitly flagged for the separate unit-scope
review. No address is repaired and no geocoding query is approved.

The later identity and site-scope pass resolves 56 review questions covering
88 source development records. It preserves all 55,345 HUD episodes, produces
53,909 all-scope development rows and 132,513 sites, and keeps 23 nonphysical
portfolio, bad-source, or synthetic rows explicit. One official TDHCA address
is added through a separate reviewed transaction rather than represented as a
HUD-derived site. No site is approved for geocoding.

The unit-scope review covers 1,224 developments and 2,657 financing episodes.
Total-unit decisions use one repeated value for 743 developments, sum 18
documented component sets, use 45 direct property values, and leave 418
without a defensible static value. Low-income-unit decisions use one repeated
value for 655 developments, sum 18 component sets, use 19 direct values, retain
one episode-specific case without a static value, and leave 531 unavailable.
The final analytic layer contains 53,469 physical developments, 54,902
episodes, and 131,473 sites in the 50 states and DC. A separate evidence table
preserves 443 excluded episodes: 26 nonphysical and 417 territorial.
The master tables retain the 400 developments missing both static count
measures and mark them for exclusion from the default downstream quantitative
sample; no development, episode, or site is deleted to impose that sample.

The final local address audit maps 83,720 site rows to 77,648 unique proposed
queries, all explicitly unapproved. It leaves 47,753 site rows blocked for an
address split, source or site-inventory review, address-form review,
shared-address review, or because the listed text is not safely geocodable.
The audit does not transmit an address or use the unit-analysis exclusion to
discard a site.

The compound-address review covers all 5,114 flagged source cells. Two
independent reads agree on 3,309 strict splits producing 9,091 explicit
address components and on 37 single fractional civic addresses; 1,768 cells
remain blocked. The range review covers all 8,815 apparent ranges. Two reads,
with a third read for disagreements, retain 665 complete literal ranges,
normalize 103 ordinal-street false positives, exclude two nonphysical block
descriptions, and leave 8,045 unresolved. No endpoint is expanded. The final
component crosswalk preserves all 131,473 source sites through 137,255 address
components and maps 89,809 components from 86,419 source sites to 83,734
development-scoped queries. All queries remain `not_approved`; the independent
application audit passes all 30 checks.

The fetch task forces HTTP/1.1 because HUD's web application firewall sends
command-line HTTP/2 requests to a browser challenge. It verifies the archive
against a committed SHA-256 checksum before placing it under `data_raw/`.
The repository also tracks the verified 2024 ZIP itself so a clone does not
depend on HUD continuing to serve the same bytes from its rolling URL. The
snapshot was retrieved on August 8, 2026 from
<https://www.huduser.gov/lihtc/lihtcpub.zip>; its release metadata and hashes
are recorded in
[`tasks/fetch_lihtc_property/code/release_manifest.csv`](tasks/fetch_lihtc_property/code/release_manifest.csv).
The Parquet conversions preserve every published cell as text and verify exact
round trips. The audits use R and `data.table`; they do not delete source rows
or silently choose among candidate duplicates. The committed linkage review
gives all 325 provisional cross-HUD groups an internal HUD-only read and a
separate outside-source read. It accepts 322 groups and rejects three HCCI
portfolio groups whose HUD addresses contain only a street name. Accepted
groups retain every HUD project episode and unresolved development-level unit
totals; rejected groups are split without importing outside addresses into the
HUD-derived site table.

The second linkage ledger covers all 163 same-state-ID,
same-standardized-primary-address blocks with different standardized names.
Each received a HUD-only read and a separate outside-source read. The review
merges 154 blocks, including all 120 exact timing-and-unit matches, and retains
nine phase, component, or common-address groups as separate developments. The
result contains 54,725 physical developments, 55,345 HUD project episodes, and
134,823 development sites. All merged development-level unit totals remain
unresolved pending a separate aggregation review.
