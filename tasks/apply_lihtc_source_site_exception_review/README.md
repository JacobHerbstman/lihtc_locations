# Apply LIHTC Source-Site Exception Review

This task applies only the row changes authorized by
`review_lihtc_source_site_exceptions`. It removes 648 foreign assignments and
28 redundant base-address variants. It also replaces all eight foreign
Mechanic Mill assignments with the reviewed 67 Mechanic Street record in one
transaction.

The task preserves all 54,030 development records and all 55,345 source
episodes. It leaves the 36 unresolved assignments and 52 umbrella-financing
assignments unchanged. The output status fields identify nonphysical financing
umbrellas and portfolio placeholders separately from their physical property
components so unit aggregation can exclude the former without discarding
source episodes.

The task produces:

- `lihtc_development_2024_source_site_repaired.parquet`;
- `lihtc_project_episode_2024_source_site_repaired.parquet`;
- `lihtc_development_site_2024_source_site_repaired.parquet`.

No physical-development identity merge or split occurs here. Unit values are
not changed or aggregated and no geocoding query is approved or sent.

Run `make` from `code/`.
