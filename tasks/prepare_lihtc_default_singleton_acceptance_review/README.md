# Default singleton acceptance review preparation

This preparation-only task defines the review frame from the canonical
acceptance-routing table.  Its universe is precisely the three canonical
`default_singleton_*` routes: 28,701 one-primary-site developments, 9,214
one-nonprimary-site developments, and 7,705 multisite developments.  It does
not reconstruct these exclusions from site flags.  In particular, Mechanic
Mill (`DEV_MAB20191004`) remains in the nonprimary default route because its
identity evidence is rule-based; its prior resolved source-site repair is
retained only as an annotation.

The task creates one not-yet-adjudicated question per default-route
development, diagnostic strata for possible missed identity or source-membership
problems, and a deterministic two-reader sample. Name-state, state-ID,
primary-address, exact-site-set, and overlapping-site diagnostics compare each
default-route development with the complete final universe of 53,469
developments, 54,902 episodes, and 131,473 retained sites, including
counterparts already routed elsewhere. State IDs containing `99-99`,
`UNKNOWN`, or `N/A`, and all-nine identifiers are excluded from the
non-placeholder state-ID diagnostic, consistent with the project's established
identity-review rule.

All 45,620 questions are asserted to retain
`rule_based_singleton_not_individually_reviewed` identity evidence and
`not_accepted_dataset_frozen` acceptance status. All output review decisions
are `not_adjudicated`, including the separate reader-1, reader-2, and
disagreement-adjudication fields; all geocoding approvals are `not_approved`;
and every row is labeled `prepared_for_independent_review_not_accepted`. This task is a
review preparation artifact. It never accepts a development, searches,
adjudicates, alters source membership, or approves geocoding.

The 3,305-row sample first takes the union of all 2,105 developments with a
non-placeholder state-ID signal, a normalized-name-and-state signal, or a
unit/timing anomaly. This mandatory union is based on the raw flags, regardless
of which mutually exclusive diagnostic stratum has priority. It therefore
includes the two unit/timing anomalies whose exclusive stratum is multisite,
including `DEV_GAA20090103`. The sample additionally draws 600 deterministic
random rows from the structural multisite stratum and 600 from the no-signal
stratum, with the latter allocated by largest remainder across the primary and
nonprimary queues (449 and 151). The current deterministic multisite draw does
not overlap the mandatory union; the preparation script nevertheless
deduplicates any overlap and records every selection component. Each cell is
sorted by development ID before seeded sampling, so the draw does not depend on
inherited input row order. Each sampled row has independent randomized orders
for reader 1 and reader 2. Readers assess
only a missed identity or source-membership problem, never whether a row is
generally clean. A disagreement receives a third blinded adjudication.

Escalation is precommitted: one confirmed missed identity or source-membership
defect freezes automatic acceptance for the affected diagnostic-stratum and
routing-status cell.  The rest of that cell must be moved to an explicit review
queue, after which this preparation frame and sample are rebuilt.  If a
600-row simple random sample has zero confirmed defects, its exact one-sided
95 percent binomial upper bound is `1 - 0.05^(1/600) = 0.498%` for that
stratum.
