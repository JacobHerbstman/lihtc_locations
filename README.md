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

This audit calls no geocoder and transmits no address or coordinate. It keeps
Puerto Rico and the other territories as explicit out-of-scope records,
preserves raw address fields, and marks every locally proposed query as
`not_approved`.

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
