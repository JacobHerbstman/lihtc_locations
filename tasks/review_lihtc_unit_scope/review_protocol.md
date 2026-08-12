# LIHTC Unit-Scope Review Protocol

## Review unit

The question is whether one physical development has a defensible static
total-unit count and low-income-unit count. A physical development can have
several financing episodes. Those episodes may repeat a whole-property count,
describe distinct components, record a changed configuration, or contain a
bad source value. Identity alone does not determine unit scope.

The current review universe contains 1,224 questions and 2,657 episode
members. It covers 1,142 multi-episode developments, 80 single-episode
source-count problems, and two external numeric conflicts in the 50 states
and DC.

## First read

The internal read considers every HUD episode together. It reads project and
state identifiers, names, timing, resyndication and construction fields,
original and reconciled unit fields, bedroom counts, data notes, and the full
identity-review lineage. Equal counts are only a pattern. They do not prove
duplicate reporting. Likewise, two 4-percent and 9-percent financing records
are not summed merely because their labels differ.

The first read records separate candidate actions for total units and
low-income units. A candidate may remain deferred to the outside read.

First-read actions use the following reason codes:

- `equal_counts_with_repeat_lineage`;
- `equal_counts_without_scope_evidence`;
- `component_lineage_nonoverlap_unconfirmed`;
- `changed_counts_current_configuration_unconfirmed`;
- `original_hud_count_may_resolve_reconciliation`;
- `bad_or_missing_episode_count`;
- `mixed_component_and_repeat_lineage`;
- `ambiguous_identity_scope_lineage`;
- `internal_evidence_insufficient`;
- `changed_counts_episode_specific_unconfirmed`.

Use-once candidates take one of the two equal-count reasons. Component sums
take `component_lineage_nonoverlap_unconfirmed`. Selected episodes take a
current-configuration or original-HUD reconciliation reason. External-value
candidates take a bad-count, mixed-lineage, ambiguous-lineage, or insufficient-
evidence reason. Episode-specific candidates take a changed-count or ambiguous-
lineage reason. A deferred read can use any unresolved scope reason. The
validator enforces these pairings.

For a use-once or selected-episode candidate, the first read marks one
candidate representative. A sum candidate marks at least two candidate
components. Other first-read actions leave episode roles as evidence or
pending the outside read. These roles record the internal interpretation;
only the final roles carry arithmetic source fields.

## Second read

Every question receives a separate outside read. Preferred sources are
allocating-agency awards, housing-authority or municipal records, owner or
developer property records, regulatory documents, and other direct public
records. Public property directories can corroborate names and locations but
do not independently establish unit scope. Search and direct-source URLs,
source type, coverage, published counts, and notes are retained.

The two published-count fields are reserved for development-wide counts. Put
component-specific figures in the source notes. An external-value decision
must equal the corresponding published development count. A selected-episode
or component-sum decision is reconstructed from the member ledger. An outside
record may establish property or component structure, but duplicate reporting
is established only by the adjudicated lineage attached to that same full
review group. A directory can corroborate identity only.

Coverage distinguishes a source reporting both development totals, total units
only, affordable units only, component structure only, partial component
counts, identity only, or no reliable evidence. Published counts are also
labeled as exact, lower bound, upper bound, or not reported. A bound is retained
as evidence but cannot become an exact external property value. Total and
affordable decisions remain independent; one may be numeric when the other is
unavailable.

A total-only source may support a low-income component sum only when the total
decision is also a component sum, the total equals the exact published total,
and the total and low-income decisions include the same episode components.
It cannot support a low-income sum when an external property total overrides
the episode component total.

The preparation also retains sources from earlier identity reviews. A reviewer
may reopen one of those URLs and record `prior_review_source` as the search
method. The validator checks that the URL was actually frozen for the same
question. Earlier identity notes that deferred unit aggregation remain
identity-only evidence; their existence does not establish a unit count.

A source that states only a property-wide total does not establish the
low-income-unit count. A component-level source does not establish a
development-wide sum unless all components and duplicate episodes are
accounted for.

## Final actions

Total and low-income counts are adjudicated independently using these actions:

- `use_once_reporting_value`: several episodes repeat one whole-property
  value; exactly one episode is the arithmetic representative.
- `sum_selected_components`: specifically selected, nonoverlapping episode
  components sum to the development value. Duplicate episodes are excluded.
- `select_current_episode_value`: one documented episode describes the
  applicable physical configuration and older configurations are superseded.
- `use_external_property_value`: a direct source supplies the property-wide
  value and episode rows are evidence only.
- `retain_episode_specific_no_static_value`: the count genuinely varies by
  episode, so no time-invariant development value is asserted.
- `unavailable_after_review`: the two reads do not yield a defensible value.

The last two actions are completed decisions, not unresolved placeholders.
They require a missing final numeric value and a written explanation.
`unavailable_after_review` means that no defensible static
physical-development value was found. It does not discard or invalidate the
episode-specific HUD values, which remain in the member data.
The episode-specific action is unavailable to a one-episode question.
Final reason codes are restricted to `duplicate_reporting_use_once`,
`distinct_components_sum`, `current_configuration_selected`,
`direct_source_property_value`, `episode_specific_no_static_value`,
`unavailable_after_search`, and `singleton_source_value_recovered`.

## Member roles and arithmetic

The member ledger covers every HUD episode exactly once for both measures.
Value-bearing roles are `select_representative` and `include_component`.
Non-value-bearing roles are `exclude_duplicate`, `exclude_superseded`, and
`evidence_only`. A value-bearing role must name either the reconciled episode
field or the original HUD field as its source.

The validator independently reconstructs each selected or summed value from
the prepared member data. It requires one representative for a use-once or
selected-episode decision, at least two included components for a sum, and no
episode contribution for an external, episode-specific, or unavailable
decision. It also enforces nonnegative low-income units, positive total units,
and low-income units no greater than total units whenever both final values
exist.

## Research boundary

The review does not overwrite HUD fields. It creates development-level
interpretations while preserving every episode value and its lineage. It does
not change identity, addresses, sites, or geocoding status.
