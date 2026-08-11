# Review LIHTC Source-Site Exceptions

This task reviews the 22 source-exception groups prepared by
`prepare_lihtc_source_site_exceptions`. The committed group ledger accepts or
blocks each prepared disposition. The action contract then expands those
decisions to all 869 current site assignments without rerunning a linkage rule.

The review produces operative decisions for 68 episodes and 869 site
assignments. It also freezes one external replacement record for Mechanic Mill
at 67 Mechanic Street in Attleboro. The eight foreign Mechanic Mill assignments
may be removed only in the same later application transaction that adds this
replacement.

The task produces:

- `lihtc_source_site_group_reviews.parquet`;
- `lihtc_source_site_member_decisions.parquet`;
- `lihtc_source_site_episode_decisions.parquet`;
- `lihtc_source_site_external_replacements.parquet`.

This task does not apply a row change or property merge. It leaves all 36
unresolved site assignments unchanged and keeps every umbrella-financing
property split blocked until an episode-to-property bridge is reviewed. It
does not invent missing Wayne at Bicknell or Orient Heights buildings and does
not approve or call a geocoder.

Run `make` from `code/`.
