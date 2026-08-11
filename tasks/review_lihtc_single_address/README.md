# LIHTC Single-Address Identity Review

This task adjudicates the 1,149 questions prepared by
`prepare_lihtc_single_address_review`. Each question contains two or more
current development records that use the same singular street address.

The review has two fixed inputs of judgment:

1. an internal read of names, identifiers, years, units, and source addresses;
2. an outside read of direct public records located by focused web search or
   public housing-directory sitemaps.

The committed question ledger records both reads and the final decision. The
committed member ledger is the operative physical-development partition. The
validator does not rerun a matching rule or infer new links.

The task produces:

- `lihtc_single_address_question_reviews.parquet`;
- `lihtc_single_address_member_partitions.parquet`;
- `review_summary.md`.

This task does not apply the partition to the development, episode, or site
tables. It does not sum unit counts, alter source rows, approve a shared
geocoding query, or call a geocoder.
