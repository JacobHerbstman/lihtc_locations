# Prepare LIHTC No-Site Development Review

This task freezes every final physical development with no retained site row.
The current queue contains 797 developments and their 797 source financing
episodes. Each development has exactly one episode.

The development output preserves the current name, state, city, timing, unit,
identity-linkage, and source-site statuses. The episode output preserves the
published project and primary-address fields, state identifier, timing, raw
HUD coordinates and unit counts, and the prior review lineage needed for two
independent outside reads.

This is preparation only. Both outputs mark every row `not_adjudicated` and
every geocoding decision `not_approved`. The task does not infer a missing
site, alter a development or episode, call a geocoder, or authorize downstream
geography work.

Run `make` from `code/`.
