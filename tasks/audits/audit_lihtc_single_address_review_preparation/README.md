# Audit LIHTC Single-Address Review Preparation

This task verifies the prepared single-address identity queue against the
current physical-development, project-episode, and development-site tables. It
checks scope, complete pair construction, prior reviewed-distinct constraints,
and the exclusion of territories, multi-address developments, and address
forms deferred for later repair.

The audit makes no identity or address decision and approves no geocoding
query.

Run `make` from `code/`.
