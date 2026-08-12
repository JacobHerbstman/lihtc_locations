# Geography attrition audit

This read-only audit reports the non-overlapping flow from final physical developments to sites, address components, and distinct locally prepared query strings. It does not interpret a ready query as a geocoded location.

The task takes the final low-income-share-adjudicated physical-development and
site tables, the post-review address-component crosswalk, and its deduplicated
development-scoped query table. It checks their identifiers and expected counts
before aggregating. A development is counted as having geography coverage when
at least one retained source site has at least one locally ready component
query. It is not counted as geocoded, tract-assigned, or safe for unit-weighted
analysis. Comparability rows report both general unit-analysis eligibility and
the stricter reviewed low-income-share eligibility.

The primary output, `lihtc_geography_attrition.parquet`, is a tidy metric table. Its `level`, `measure`, and `group` columns identify the statistic; its remaining fields contain counts or comparability statistics. It covers the full development/site/component/query flow, mutually exclusive development root blockers, and coverage by state, placed-in-service group, unit size, and multisite status. `geography_attrition_summary.md` is the short human-readable report.

For developments without a ready query, root blockers use this priority: other address/source issue, unresolved range, unresolved compound, nonphysical range description, baseline address issue, no address component, then no source site. This makes the blocker table non-overlapping while giving the most actionable unresolved condition precedence.
