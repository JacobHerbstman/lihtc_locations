# Prepare LIHTC Source-Site Exceptions

This task freezes the 57 current development records and 869 current site
assignments already identified by committed review ledgers as copied,
cross-listed, administrative, portfolio-wide, or otherwise contaminated. It
keeps the original episode and site records intact and attaches a proposed
source-site disposition to every row.

The output distinguishes a foreign source row from a redundant representation
of the same building, a nonphysical placeholder, a legitimate umbrella
financing assignment, and a case that still needs outside evidence. It also
flags financing episodes that span several physical properties. Plaza
Residences is separately identified as one physical property after a later
official New York City record tied all five addresses to one tax lot.

The frozen universe is the disjoint union of:

- 16 developments and 578 sites in excluded identical sets `IAS0670` and
  `IAS0687`;
- 13 developments and 65 sites whose identical-set assessment is
  `administrative_or_parcel_descriptions`,
  `copied_across_distinct_developments`, or `contains_unrelated_addresses`;
- 28 developments and 226 sites whose cross-address reason is
  `bad_or_placeholder_shared_source_address`,
  `distinct_developments_source_cross_listing`,
  `portfolio_episode_overlaps_distinct_development`, or
  `portfolio_or_phase_overlaps_distinct_development`.

The site output reconstructs source BINs and episode IDs directly from the raw
multisite file and records matching primary-address episode evidence. The
episode output preserves all 68 source episodes and attaches the proposed
property-scope action.

This is a preparation task. It does not delete, add, or rewrite a site; change
a physical-development identifier; aggregate units; call a geocoder; or
approve a query. A later reviewed ledger must decide and apply every repair.

Run `make` from `code/`.
