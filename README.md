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

The fetch task forces HTTP/1.1 because HUD's web application firewall sends
command-line HTTP/2 requests to a browser challenge. It verifies the archive
against a committed SHA-256 checksum before placing it under `data_raw/`.
The repository also tracks the verified 2024 ZIP itself so a clone does not
depend on HUD continuing to serve the same bytes from its rolling URL. The
snapshot was retrieved on August 8, 2026 from
<https://www.huduser.gov/lihtc/lihtcpub.zip>; its release metadata and hashes
are recorded in
[`tasks/fetch_lihtc_property/code/release_manifest.csv`](tasks/fetch_lihtc_property/code/release_manifest.csv).
The Parquet conversions preserve every published cell as text and verify exact round trips. The audits use R and `data.table`; they do not delete rows or silently choose among candidate duplicates. Cross-HUD development links and their candidate unit aggregations remain provisional until reviewed.
