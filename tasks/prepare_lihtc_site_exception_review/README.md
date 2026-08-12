# Prepare LIHTC Site Exception Review

This task prepares the complete retained-site exception queue recorded in the
dataset-acceptance inventory. The queue is mutually exclusive:

- 59 sites retained unresolved by the source-site review;
- 74 sites retained unresolved by the singleton-scope review; and
- 1,804 inherited site rows that still carry a review flag.

Together these are 1,937 queued sites belonging to 211 physical developments.
The outputs also preserve all 2,776 final site rows and all 243 financing
episodes for those developments. This makes the complete property context
visible when a reviewer evaluates one flagged site. Exact site keys used by
more than one final development are identified locally, but no shared-address
or physical-development decision is made.

Review order is deterministic. Explicit unresolved source-site rows come
first, followed by explicit unresolved singleton-site rows and then inherited
flags. Within each class, developments with the largest complete site
portfolios come first. The development output also records the global site
portfolio size rank.

This is preparation only. Every output row is marked `not_adjudicated`, and
every geocoding decision is `not_approved`. The task does not remove, retain,
reassign, add, or infer a site; change development identity; call a geocoder;
or authorize downstream geography work.

Run `make` from `code/`.
