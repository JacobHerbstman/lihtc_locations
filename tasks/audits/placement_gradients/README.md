# New York and Chicago placement gradients

Jacob asked whether the prior-homeowner gradient is larger than the racial or income gradient, and requested the same comparison for Chicago. This audit compares those associations on a common sample. It leaves the HUD master, national Census files and previous NYC homeowner analysis unchanged.

## Definitions chosen for this comparison

- Pool all opening years 1987–2022 separately within each city, as Jacob subsequently requested for both cities. Estimate one slope per characteristic per city, retaining year effects.
- Count HUD new-construction project records whose retained HUD point is inside each 2024 Census place boundary. These are placed-in-service dates, not approval dates. Exclude the incomplete 2023–2024 cohorts from this analysis.
- Keep all native NYC tracts in its five borough counties, exactly as in the previous homeowner audit. For Chicago, select native tracts with positive-area overlap with the 2024 city boundary, including tracts with no projects. Demographics and exposure remain whole-tract values. The interior sensitivity requires at least 99% of tract area inside the city, using the same rule in both cities. NYC demographic rows absent from a boundary snapshot remain in the main universe; they cannot enter the interior sensitivity.
- Use the latest Census observation ending strictly before opening, for projects and alternative tracts alike. Openings in 1987–1990 use 1980 Census data, 1991–2000 use 1990, 2001–2010 use 2000, and 2011–2022 use ACS releases ending 2010–2021. No interpolation, field-specific backfilling or static latest-context substitution.
- Homeowner share is owner-occupied housing divided by occupied housing; racial composition is **non-Hispanic Black population share**, matching the earlier racial maps. Income is log median household income in 2024 dollars, using the existing national historical-income price index. This adjusts dollars over time, not across local living costs.
- Require all three characteristics and positive baseline housing for these regressions only. Preserve every project in the audit project file and report losses. Missing unit counts do not exclude a project.
- Estimate Poisson annual project counts with year effects and log baseline housing-unit exposure. Each separate-characteristic regression uses the same rows as the joint model. Each coefficient is constant across the pooled study years. Exclude zero-project years only from model fitting because their intercept has no finite estimate; keep them in the panel, coverage and scale calculations.
- Compare a one-standard-deviation increase, using the full study period within each city and equally weighting eligible tract-years, including zero-project rows. Keep that scale fixed for the boundary sensitivity. Shares remain levels; income is logged. Also report estimates for ten percentage points higher shares and 10% higher income. Do not compare raw income-dollar slopes with share slopes.
- Rank point estimates by absolute standardized log rate changes: doubling and halving have equal proportional strength. This is a descriptive ranking, not a formal test that two estimated gradients differ. Standard errors cluster on tract codes across years. Changing native boundaries and spatial dependence remain limitations.

Separate models describe total associations, which can overlap. The joint model asks how much association remains when comparing tracts with the other two characteristics held fixed. Neither identifies causal effects of neighborhood characteristics or member deference.

## Findings: pooled 1987–2022

The common sample remains 819 NYC projects and 172 Chicago projects. NYC's original 79,523 tract-year rows and their homeowner, housing and project fields still match the prior homeowner audit exactly. Pooling changes the slope specification, not the projects, characteristics, baseline years, denominators or standardization scales.

For one standard deviation higher characteristic, separate-model rate ratios are:

| City | Homeowner share | Black share | Income |
| --- | ---: | ---: | ---: |
| New York | 0.323 | 1.504 | 0.491 |
| Chicago | 0.467 | 1.913 | 0.429 |

New York's homeowner association is largest. Chicago's income association is somewhat larger than homeownership, with Black share somewhat smaller; these are descriptive point-estimate ranks, not formal tests of ordering.

With all three characteristics together, New York's homeowner ratio is 0.479 (95% interval 0.390–0.590). Chicago's is 0.930 (0.676–1.282), while its income ratio is 0.495 (0.368–0.666). Chicago's homeowner pattern therefore overlaps considerably with its other neighborhood characteristics. This does not identify a causal mechanism.

This pooled specification supersedes the initial split-period version recorded in revision `efa6c1a`. The logbook retains that dated comparison with snapshots of its table and figure and adds the current pooled results. The separate earlier NYC timing task remains available as a distinct exercise.

## Inputs and execution order

The pinned national sources are prepared upstream: the original 2024 HUD workbook, NHGIS 1980/1990/2000 demographic tables and native boundaries, recorded ACS releases and 2024 place boundaries. This task downloads no data and reads no credentials.

Run root `make`. With upstream inputs prepared, `make -C tasks/audits/placement_gradients/code` runs the same audit:

1. `city_tracts.R` reads the five native boundary snapshots and 2024 places, writes tract membership and area fractions.
2. `project_sample.R` reads `projects_with_tracts.csv` and membership, preserving all city project records and exclusion reasons.
3. `build_panel.R` reads national `tract_demographics.csv`, membership and project records. It builds one row per city, opening year and native tract, with zero counts where appropriate.
4. `summarize_coverage.R` reports project and tract-year coverage by city over the full study period. Missing-variable counts overlap; they are not additive.
5. `scales.R` records each city's fixed means, standard deviations and natural-unit conversions.
6. `fit_models.R` estimates separate and joint models, including the interior-tract check. `models.csv` contains 24 pooled coefficient estimates: two cities × two geographic samples × two model types × three variables.
7. `plot_gradients.R`, `summarize_results.R` and `write_report.R` make the figure, logbook table and self-contained HTML report from those outputs.

The root and local Makefiles explicitly list inputs and outputs. Every saved CSV writes its standard report through `SaveData`; reports are side effects rather than build targets.
