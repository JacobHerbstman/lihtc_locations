# LIHTC Mixed-Site Identity Review

This task adjudicates the 87 questions prepared by
`prepare_lihtc_mixed_site_identity_review`. Each question contains current
development records connected by at least one shared site, with one member
usually carrying a longer address list.

The review has two fixed inputs of judgment:

1. an internal read of names, HUD and state identifiers, complete site sets,
   years, financing episodes, and source-reported units;
2. an outside read of retained direct public records.

The committed question ledger records both reads and the final decision. The
committed member ledger defines the reviewed partition. The validator checks
that all 87 questions and 195 current development records remain covered and
that none of the frozen source evidence changed.

The task produces:

- `lihtc_mixed_site_identity_question_reviews.parquet`;
- `lihtc_mixed_site_identity_member_partitions.parquet`;
- `review_summary.md`.

This task does not apply the partition, sum unit counts, alter source rows,
approve a shared geocoding query, or call a geocoder. The 340-unit Hobbs/Ciena
record is retained as a nonphysical umbrella episode requiring a later
episode-to-property bridge; the validator does not count it as a final physical
development.
