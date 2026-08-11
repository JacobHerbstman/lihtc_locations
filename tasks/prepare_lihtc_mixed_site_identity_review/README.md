# Prepare LIHTC Mixed-Site Identity Review

This task prepares the remaining high-value identity questions in which a
one-site development and a multi-site development share a standardized site
key. It reads the post-single-address development, episode, and site tables.

The complete scope contains 813 shared site keys and 1,014 one-site/multi-site
pairs. Most are only address overlaps. A pair enters the review queue when it
has one of two evidence patterns:

- `strong_identity_evidence`: the normalized names match, a non-placeholder
  state ID overlaps, or high name similarity and equal unit maxima occur within
  two placed-in-service years.
- `moderate_identity_evidence`: high name similarity, or equal unit maxima
  greater than two occur within two placed-in-service years.

The greater-than-two guard prevents four one- or two-unit records from entering
the queue solely because their small unit counts match. The task reconstructs
79 prior reviewed-distinct pair constraints. Seventy-eight remain hard
constraints. One pair, Plaza Residences I and Plaza Residences, is reopened in
a separately labeled question because later NYC Council and Department of
Finance records describe the five addresses as one project on BBL 3036280001.
The official evidence is frozen in
`code/mixed_site_prior_decision_reopenings.csv` and carried into the pair
output; no identity decision is made here.

Questions are connected components of all cross-type address edges containing
at least one candidate edge. This keeps the member partition internally
consistent while excluding components supported only by a shared address.
Preparation does not adjudicate an identity, change a source row, approve a
geocoding query, or infer development-level unit totals.
