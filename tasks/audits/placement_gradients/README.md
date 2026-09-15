# LIHTC placement gradients across cities

Jacob asked whether the prior-homeowner gradient is larger than the racial or income gradient, then requested more cities to explore whether local control might explain differences. The current comparison includes Atlanta, Boston, Chicago, Houston, Los Angeles, New York City, San Francisco and Seattle, selected before inspecting their new model estimates. This audit compares those associations on a common sample. It leaves the HUD master, national Census files and previous NYC homeowner analysis unchanged.

## Definitions chosen for this comparison

- Pool all opening years 1987–2022 separately within each city, following Jacob’s request to pool the comparison. Estimate one slope per characteristic per city, retaining year effects.
- Count HUD new-construction project records whose retained HUD point is inside each 2024 Census place boundary. These are placed-in-service dates, not approval dates. Exclude the incomplete 2023–2024 cohorts from this analysis.
- Keep all native NYC tracts in its five borough counties, exactly as in the previous homeowner audit. For cities other than NYC, select native tracts with positive-area overlap with the 2024 city boundary, including tracts with no projects. Demographics and exposure remain whole-tract values. The interior sensitivity requires at least 99% of tract area inside the city, using the same rule in every city. NYC demographic rows absent from a boundary snapshot remain in the main universe; they cannot enter the interior sensitivity.
- Use the latest Census observation ending strictly before opening, for projects and alternative tracts alike. Openings in 1987–1990 use 1980 Census data, 1991–2000 use 1990, 2001–2010 use 2000, and 2011–2022 use ACS releases ending 2010–2021. No interpolation, field-specific backfilling or static latest-context substitution.
- Homeowner share is owner-occupied housing divided by occupied housing; racial composition is **non-Hispanic Black population share**, matching the earlier racial maps. Income is log median household income in 2024 dollars, using the existing national historical-income price index. This adjusts dollars over time, not across local living costs.
- Require all three characteristics and positive baseline housing for these regressions only. Preserve every project in the audit project file and report losses. Missing unit counts do not exclude a project.
- Estimate Poisson annual project counts with year effects and log baseline housing-unit exposure. Each separate-characteristic regression uses the same rows as the joint model. Each coefficient is constant across the pooled study years. Exclude zero-project years only from model fitting because their intercept has no finite estimate; keep them in the panel, coverage and scale calculations.
- Compare a one-standard-deviation increase, using the full study period within each city and equally weighting eligible tract-years, including zero-project rows. Keep that scale fixed for the boundary sensitivity. Shares remain levels; income is logged. Also report estimates for ten percentage points higher shares and 10% higher income. Do not compare raw income-dollar slopes with share slopes.
- Rank point estimates by absolute standardized log rate changes: doubling and halving have equal proportional strength. This is a descriptive ranking, not a formal test that two estimated gradients differ. Standard errors cluster on tract codes across years. Changing native boundaries and spatial dependence remain limitations.

Separate models describe total associations, which can overlap. The joint model asks how much association remains when comparing tracts with the other two characteristics held fixed. Neither identifies causal effects of neighborhood characteristics or member deference.

## Eight-city comparison, September 15, 2026

The existing specification now runs for six additional cities. `cities.csv` records Census place GEOIDs, not name matches. Tract acquisition within the audit selects states from those places, preserving the previous NYC and Chicago samples. The model and timing rules are unchanged. Earlier two-city logbook exhibits are preserved as dated snapshots.

The main comparison includes all three focal characteristics, prior vacancy and log housing density jointly, with city-specific year effects. For the **same ten-percentage-point increase in homeowner share**, adjusted placement-rate changes are:

| City | Projects | Homeowner change | 95% interval |
| --- | ---: | ---: | ---: |
| New York City | 819 | −36.1% | −40.3% to −31.5% |
| Boston | 86 | −25.2% | −41.8% to −3.8% |
| Seattle | 190 | −19.3% | −37.3% to +4.0% |
| Los Angeles | 410 | −17.6% | −25.2% to −9.2% |
| Chicago | 172 | −12.3% | −25.2% to +2.7% |
| Houston | 99 | −11.2% | −20.3% to −1.1% |
| San Francisco | 112 | −9.6% | −21.0% to +3.5% |
| Atlanta | 135 | −6.6% | −20.9% to +10.4% |

The project count is 2,023 of 2,040 city projects dated 1987–2022. The three demographic requirements and positive housing exposure exclude 17 projects; adding vacancy and density loses no further projects. It removes four zero-project NYC tract-years. The full master remains unchanged. Actual fitted Ns, eligible zero-project rows and ordered exclusions are in the report. All state and city selections were made before reading these new estimates; this is a selected comparison, not a representative national sample.

For comparing **characteristics within a city**, use city-specific standard deviations. Adjusted joint rate ratios per one SD are:

| City | Homeowner share | Non-Hispanic Black share | Income |
| --- | ---: | ---: | ---: |
| New York City | 0.319 | 1.218 | 0.787 |
| Boston | 0.538 | 1.495 | 0.578 |
| Seattle | 0.607 | 1.336 | 0.607 |
| Los Angeles | 0.596 | 0.957 | 0.412 |
| Chicago | 0.733 | 1.100 | 0.618 |
| Houston | 0.740 | 1.531 | 0.656 |
| San Francisco | 0.774 | 1.011 | 0.596 |
| Atlanta | 0.856 | 1.900 | 0.434 |

Homeownership has the largest absolute standardized log association in New York and Boston, and is effectively tied with income in Seattle. Income is strongest in Los Angeles, San Francisco, Chicago and Atlanta. Houston's Black-share and income associations are close, both larger than homeownership. These are point-estimate comparisons, not formal tests of ordering. The natural-scale figure uses 10 points for either share and 10% for income; those different increments should not rank the three characteristics.

Restricting to tracts at least 99% inside the city preserves all eight negative homeowner point estimates but changes Atlanta from −6.6% to −17.5% (135 to 113 projects), and San Francisco from −9.6% to −5.0% (112 to 86). Atlanta's magnitude is particularly sensitive to this geography choice. The report retains both samples and their intervals, without choosing the stronger result after inspection.

### What this says about local control

NYC stands out, but these estimates do not form a simple coastal-city pattern: San Francisco's homeowner gradient is small and uncertain after controls. We have not assigned cities subjective NIMBY labels or treated the slopes as measures of local control.

An external source check downloaded the [author-posted January 2020 Wharton regulation file](https://fnce.wharton.upenn.edu/profile/gyourko/) on September 15, 2026. It contains **no exact state/place-code matches for these eight city governments**. The [Gyourko–Hartley–Krimmel paper](https://realestate.wharton.upenn.edu/wp-content/uploads/2022/04/w835.pdf) explains that respondents are overwhelmingly suburban jurisdictions. Metropolitan averages therefore cannot substitute for our central cities' governments. This source is a read-only coverage investigation, not an input to the analysis; its URL, checksum and reproducible check are in `verification.md`.

A direct local-control comparison still requires a dated, independently defined city-government measure of discretionary review, neighborhood vetoes or council-member control. The pooled descriptive gradients cannot establish that mechanism and also reflect state allocation rules, land availability and other city differences. We make no cross-city causal claim and have not selected a regulatory classification using the results.

## Earlier two-city findings: pooled 1987–2022

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
6. `fit_models.R` estimates separate and joint models, including the interior-tract check. `models.csv` contains 288 pooled focal estimates: eight cities × two geographic samples × three adjustment specifications × two model types × three variables.
7. `plot_gradients.R` and `summarize_results.R` show separate and joint pooled associations without housing controls. `plot_housing_controls.R` and `summarize_housing_controls.R` compare the added controls on identical samples. `plot_cross_city.R` and `summarize_cross_city.R` show the adjusted joint estimates for fixed natural increments across cities. `write_report.R` combines them in the self-contained HTML report.

The root and local Makefiles explicitly list inputs and outputs. Every saved CSV writes its standard report through `SaveData`; reports are side effects rather than build targets.

## Housing controls introduced in the earlier two-city comparison

Jacob requested the neighborhood-housing-control comparison. **All specifications already included year fixed effects, estimated separately within each city.** The new specifications retain them, as well as the housing-unit offset, 1987–2022 pooling, tract-code-clustered intervals and original standardization scales.

Two additional controls enter together:

- `vacancy_share`: `(housing_units - occupied_units) / housing_units` from the same prior demographic observation as the other characteristics. It enters linearly, scaled in ten-percentage-point units.
- `log_housing_density`: log of `housing_units / (tract_area / 1e6)`. `tract_area` is the full native polygon's area in square meters, already computed in equal-area EPSG:6933 by `city_tracts.R`. It enters scaled by `log(2)`, so its coefficient corresponds to doubling density. These rescalings do not alter the fitted model.

The density denominator is **mapped tract area**, not Census land-only area or developable land. [NHGIS's GIS documentation](https://www.nhgis.org/gis-files) describes clipping coastal and Great Lakes waters, while [NHGIS staff clarify that polygon areas retain inland water](https://forum.ipums.org/t/land-area-variable-for-1990-census-tracts/3836). This consistent mapped-area definition uses the existing recorded sources across all native vintages. No newer area's value fills a missing historical polygon. The housing counts and vacancy share continue to end strictly before opening.

`controls_included` requires the original common sample and both controls. `adjustment = baseline` reproduces the original pooled model; `same_sample` repeats it on this controls sample; `housing_controls` adds vacancy and density on those exact rows. Both the one-characteristic and joint models receive this comparison. The geographic sensitivity retains the existing 99%-inside rule.

No project is lost. Chicago retains 172 projects and all 31,818 eligible tract-years. NYC retains 819 projects and 77,137 of 77,141 eligible tract-years; four zero-project rows have no historical polygon area. No eligible row lacks vacancy. The master, all previous panel fields, original scales, 24 original estimates, original figure and original table remain unchanged.

With all three focal characteristics together, the rate ratios for one standard deviation higher characteristic are:

| City | Characteristic | Before housing controls, same sample | Add vacancy and density |
| --- | --- | ---: | ---: |
| New York | Homeowner share | 0.479 | 0.319 |
| New York | Black share | 1.285 | 1.218 |
| New York | Income | 0.725 | 0.787 |
| Chicago | Homeowner share | 0.930 | 0.733 |
| Chicago | Black share | 1.217 | 1.100 |
| Chicago | Income | 0.495 | 0.618 |

NYC's homeowner association becomes more negative after adjustment. Chicago's also becomes more negative, but its adjusted 95% interval is 0.504–1.065, including one. NYC's adjusted homeowner interval is 0.268–0.380. The income associations remain negative in both cities and the Black-share associations are smaller. These comparisons do not test whether a coefficient change is statistically significant and do not establish causality. Density and vacancy describe existing housing conditions; they do not measure actual development capacity, zoning or discretionary review.
