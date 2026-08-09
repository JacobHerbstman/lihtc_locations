# Review LIHTC Development Linkage

This task validates the committed manual adjudication of every provisional cross-HUD development link. The CSV files in `code/` are research data: they preserve the internal read, outside read, source URLs, final group decision, and episode-level implementation crosswalk.

Run `make` from `code/`. The task checks exact coverage of the provisional groups, all join keys, decision consistency, source requirements, and the implied development partition before writing validated Parquet files.

See `review_protocol.md` for the review rules and interpretation.
