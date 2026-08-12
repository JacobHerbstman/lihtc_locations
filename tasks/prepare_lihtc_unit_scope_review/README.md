# Prepare LIHTC Unit-Scope Review

This task freezes the unit-count review universe after physical-development
identity adjudication. It includes every physical development with more than
one observed HUD episode and every single-episode physical development with a
missing or invalid reconciled unit count. Episode membership is counted from
the episode table and checked against the inherited development summary.

The question file records mechanical count patterns and prior identity-review
reason codes. Candidate actions are prompts for two-read adjudication, not
decisions. Equal episode counts do not establish duplicate reporting, and
multiple financing episodes are not summed without property-specific evidence.
The member file preserves every HUD episode and its identity lineage so mixed
component-and-duplicate histories can be adjudicated explicitly.

The prior-evidence file freezes source records from every completed identity
stage. Each row retains the prior review key, source title, type, URL, notes,
and the HUD episodes it covered. A prior note that deferred unit aggregation
remains labeled as identity-only evidence. The preparation never promotes a
linkage source into unit-count evidence.

The current queue contains 1,224 questions and 2,657 episode members: 1,142
multi-episode developments, 80 single-episode source-count problems, and two
external numeric conflicts. The main universe is limited to the 50 states and
DC. Preparation verifies, but does not duplicate, the final apply task's
excluded-episode evidence for 26 nonphysical and 417 territory episodes.
The completed Stage 2 inputs yield 53,469 physical developments, 54,902
episodes, and 131,473 sites. The preparation preserves the same
50-state-and-DC scope contract.

Run `make` from `code/`.
