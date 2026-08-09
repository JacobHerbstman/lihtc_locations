# Apply LIHTC Development Linkage Review

This task applies the validated manual linkage crosswalk to the provisional development, project-episode, and development-site tables.

Accepted groups remain one physical development while retaining every HUD row as a project episode. The three rejected HCCI street-only groups are split into ten single-episode developments. Their outside street numbers are not imported into the HUD-derived site data; the resulting coarse sites remain flagged for site review. Unit totals for accepted multi-episode developments remain unresolved.

Run `make` from `code/` to build the adjudicated Parquet files.
