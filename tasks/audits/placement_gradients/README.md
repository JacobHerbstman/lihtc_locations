# New York and Chicago placement gradients

Jacob asked whether the prior-homeowner gradient is larger than the racial or income gradient, and requested the same comparison for Chicago. This audit compares those associations on a common sample. It leaves the HUD master, national Census files and previous NYC homeowner analysis unchanged.

## Definitions chosen for this comparison

- Keep the existing 1987–2002 versus 2003–2022 opening-year split. Chicago uses the same descriptive periods; the cutoff is not an identified Chicago institutional change.
- Count HUD new-construction project records whose retained HUD point is inside each 2024 Census place boundary. These are placed-in-service dates, not approval dates. Exclude the incomplete 2023–2024 cohorts from this analysis.
- Keep all native NYC tracts in its five borough counties, exactly as in the previous homeowner audit. For Chicago, select native tracts with positive-area overlap with the 2024 city boundary, including tracts with no projects. Demographics and exposure remain whole-tract values. The interior sensitivity requires at least 99% of tract area inside the city, using the same rule in both cities. NYC demographic rows absent from a boundary snapshot remain in the main universe; they cannot enter the interior sensitivity.
- Use the latest Census observation ending strictly before opening, for projects and alternative tracts alike. Openings in 1987–1990 use 1980 Census data, 1991–2000 use 1990, 2001–2010 use 2000, and 2011–2022 use ACS releases ending 2010–2021. No interpolation, field-specific backfilling or static latest-context substitution.
- Homeowner share is owner-occupied housing divided by occupied housing; racial composition is **non-Hispanic Black population share**, matching the earlier racial maps. Income is log median household income in 2024 dollars, using the existing national historical-income price index. This adjusts dollars over time, not across local living costs.
- Require all three characteristics and positive baseline housing for these regressions only. Preserve every project in the audit project file and report losses. Missing unit counts do not exclude a project.
- Estimate Poisson annual project counts with year effects and log baseline housing-unit exposure. Each separate-characteristic regression uses the same rows as the joint model. Each coefficient can differ across the two periods. Exclude zero-project years only from model fitting because their intercept has no finite estimate; keep them in the panel, coverage and scale calculations.
- Compare a one-standard-deviation increase, pooling both periods within each city and equally weighting eligible tract-years, including zero-project rows. Keep that scale fixed across periods and the boundary sensitivity. Shares remain levels; income is logged. Also report estimates for ten percentage points higher shares and 10% higher income. Do not compare raw income-dollar slopes with share slopes.
- Rank point estimates by absolute standardized log rate changes: doubling and halving have equal proportional strength. This is a descriptive ranking, not a formal test that two estimated gradients differ. Standard errors cluster on tract codes across years. Changing native boundaries and spatial dependence remain limitations.

Separate models describe total associations, which can overlap. The joint model asks how much association remains when comparing tracts with the other two characteristics held fixed. Neither identifies causal effects of neighborhood characteristics or member deference.

## Findings

The common sample has 819 NYC projects (124 through 2002, 695 afterward) and 172 Chicago projects (46 and 126). NYC's original 79,523 tract-year rows and their homeowner, housing and project fields match the prior audit exactly; requiring income removes three projects from its 822-project homeowner sample. Chicago has 174 dated projects in the study years, of which one lacks income and one lacks positive baseline housing and defined shares. The panel includes 76,449 eligible zero-project tract-years in NYC and 31,671 in Chicago.

For one standard deviation higher characteristic, separate-model rate ratios are:

| City | Period | Homeowner share | Black share | Income |
| --- | --- | ---: | ---: | ---: |
| New York | Through 2002 | 0.338 | 1.249 | 0.568 |
| New York | After 2002 | 0.321 | 1.559 | 0.478 |
| Chicago | Through 2002 | 0.594 | 1.958 | 0.484 |
| Chicago | After 2002 | 0.418 | 1.896 | 0.410 |

New York's homeowner association is largest in both periods. Chicago's income and Black-share associations are similar early and larger than homeownership; later its homeowner and income associations are similar and larger than Black share. The 99%-inside sensitivity preserves this broad ordering.

With all three characteristics together, New York's homeowner ratios remain 0.413 and 0.488. Chicago's become 1.004 and 0.893, both with intervals including one, while its income ratios remain 0.586 and 0.465. That difference shows substantial overlap between Chicago's homeowner and other neighborhood characteristics. It does not identify a causal channel.

The separate homeowner gradient is more negative later in Chicago, but the later/earlier ratio of 0.704 has a 95% interval of 0.381–1.302. NYC's is 0.949 (0.653–1.379). Neither shows clear strengthening of the relative homeowner gradient. The HTML report gives every coefficient, interval, natural-scale conversion and sample count.

## Inputs and execution order

The pinned national sources are prepared upstream: the original 2024 HUD workbook, NHGIS 1980/1990/2000 demographic tables and native boundaries, recorded ACS releases and 2024 place boundaries. This task downloads no data and reads no credentials.

Run root `make`. With upstream inputs prepared, `make -C tasks/audits/placement_gradients/code` runs the same audit:

1. `city_tracts.R` reads the five native boundary snapshots and 2024 places, writes tract membership and area fractions.
2. `project_sample.R` reads `projects_with_tracts.csv` and membership, preserving all city project records and exclusion reasons.
3. `build_panel.R` reads national `tract_demographics.csv`, membership and project records. It builds one row per city, opening year and native tract, with zero counts where appropriate.
4. `summarize_coverage.R` reports project and tract-year coverage by city and period. Missing-variable counts overlap; they are not additive.
5. `scales.R` records each city's fixed means, standard deviations and natural-unit conversions.
6. `fit_models.R` estimates separate and joint models, including the interior-tract check. `models.csv` contains 72 coefficient contrasts: two cities × two geographic samples × two model types × three variables × three period contrasts.
7. `plot_gradients.R`, `summarize_results.R` and `write_report.R` make the figure, logbook table and self-contained HTML report from those outputs.

The root and local Makefiles explicitly list inputs and outputs. Every saved CSV writes its standard report through `SaveData`; reports are side effects rather than build targets.
