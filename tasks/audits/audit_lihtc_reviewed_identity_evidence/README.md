# LIHTC Reviewed Identity Evidence Audit

This read-only audit checks whether the identity and physical-scope decisions
already carried into the final development table retain an independently
inspectable evidence trail. It does not re-adjudicate a source, certify that a
cited source was interpreted correctly, accept a development, or approve a
geocode.

The eight original review ledgers contain 2,387 questions. Only 297 retain two
distinct, non-HUD-like direct source URLs; the other 2,090 require a source
re-read. Of these, 2,036 non-singleton questions preserve an outside read but
no independently inspectable first-source URL, and 51 singleton questions cite
the same document for both source roles. Seven questions have a plausible HUD
or HUD-derived common-mode marker. These categories can overlap.

The frozen final table contains 3,575 explicit, nonblocked identity-review
developments. Their cumulative retained provenance contains 3,703
development-question links to 2,363 of the original questions; the other 24
questions are not retained by this explicit, nonblocked universe. The audit
uses every retained question-ID column rather than only each development's
terminal review route. It finds 115 developments with more than one retained
question, including 108 with questions from more than one ledger. The
retained question subset contains 294 documented-path questions and 2,069
requiring a source re-read. The cumulative development partition remains 257
with documented source paths and 3,318 requiring a source re-read.

The audit also freezes 3,756 question-to-development member mappings. Of the 66
that refer to historical development IDs absent from the final table, 32
resolve uniquely through the retained `pre_*_development_ids` provenance to a
current successor. The remaining 34 require an explicit successor bridge
before historical member propagation is fully auditable. No final development
is lost from the cumulative question-ID lineage, and the evidence status
propagates to all 5,007 physical episodes and 11,542 retained sites descended
from the 3,575 developments.

`pass_documented_source_paths` means only that the ledger retains two distinct
inspectable source paths and no obvious HUD/common-mode marker. It is not a
substantive approval. All downstream work remains frozen.

The development audit Parquet is the canonical Make target. The question,
member-lineage, descendant, and status-count Parquets are same-run supporting
outputs from the same linear audit script.

Run `make` from `code/`.
