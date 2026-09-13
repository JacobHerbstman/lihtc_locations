# New York placements and prior homeownership

Jacob requested a descriptive comparison of placements through 2002 with later
placements, motivated by his hypothesis that stronger member deference redirected
development away from homeowner neighborhoods. The approved main periods are
1987–2002 and 2003–2022. HUD's incomplete 2023–2024 cohorts are outside this audit;
the national master dataset is unchanged.

The first result is a negative homeowner gradient in both periods, with no clear
strengthening in the relative gradient after 2002. With year effects, ten percentage
points more homeownership corresponds to 34.6% fewer placements earlier and 35.8%
fewer later. The ratio of those rate ratios is 0.982 (95% interval 0.848–1.136).
With borough/year effects the reductions are 31.5% and 29.9%. The same-2000 check
also produces similar period slopes. Absolute rate differences are larger later,
alongside a much greater overall volume of placements; that differs from a change
in the proportional association.

There are 124 dated projects through 2002 and 700 afterward; two later projects
lack a defined prior homeowner share and have zero baseline housing. The rate and
model sample therefore contains 822 projects. Three other NYC records lack dates
and 24 belong to the incomplete 2023–2024 cohorts. The observed project sample
starts in 1990: its absence of retained 1987–1989 records prevents a pre-Morris
comparison. Nothing here establishes that no housing was built then.

These choices were written before estimating the associations:

- One panel row is a native Census tract in one potential placement year. Include
  all tracts in New York City's five counties, including zero-placement tracts.
  The county FIPS codes are 36005, 36047, 36061, 36081 and 36085.
- Place projects by their HUD point and placed-in-service year. Use the existing
  baseline assignment: the latest demographic observation ending strictly before
  that year, with its own geography. This is a prior observation, not an exact
  measure at construction or land-use approval. Do not interpolate or backfill.
- Homeowner share is owner-occupied units divided by occupied units. Rate
  comparisons require that share and positive baseline housing units. Other
  tracts and excluded project records remain in the audit's data and coverage table.
- Compare project placements per 10,000 baseline housing-unit-years in fixed
  ten-percentage-point homeowner bins. Show known LIHTC units separately, retaining
  the number of projects whose unit totals are observed. Annual rates account for
  the different lengths of the two periods.
- Fit Poisson project counts with a log baseline-housing-unit offset, separate
  homeowner slopes before/after 2002, and year effects. A second specification
  allows each borough its own year effect, comparing neighborhoods within the
  same borough/year. Report changes associated with ten percentage points more
  homeownership and the difference between period slopes. Standard errors cluster
  on the eleven-digit tract code across years. Native boundaries change; this is
  a series of tract cross-sections, not a fixed-boundary tract panel. Those errors
  do not resolve geographic discontinuities, spatial confounding, or policy shocks.
- Repeat the comparisons for 2001–2002 versus 2003–2010. Both sides then use the
  same 2000 Census values and tract geography. This separates a within-source
  comparison from the much longer main comparison; its early period is short.
- Plot annual mean prior homeowner shares at project locations and in the
  existing housing stock, and maps whose individual project colors show that
  project's own prior homeowner share. Do not color a whole era's map with one
  arbitrarily chosen Census year.

The [Supreme Court decision](https://www.govinfo.gov/content/pkg/USREPORTS-489/pdf/USREPORTS-489-688.pdf)
was issued March 22, 1989. The [Campaign Finance Board's 2001 report](https://www.nyc.gov/html/records/pdf/govpub/35672001_per_vol.1.pdf)
records that term limits prevented Speaker Vallone's reelection and that Miller
became speaker afterward. The proposed role and timing of member deference remain
Jacob's hypothesis here. A 2002 opening cutoff does not identify an approval date
or measure whether a project required discretionary review. This audit cannot
attribute a change to that mechanism: land availability, subsidies, neighborhood
change, and construction/approval lags are not controlled.

Run root `make`. Task-local Make runs from `code/` against prepared input links.
`project_sample.csv` retains every NYC project and its analysis status;
`tract_years.csv` retains every available NYC tract/year. `coverage.csv`,
`binned_rates.csv`, `annual_summary.csv`, and `models.csv` describe their stated
samples. The figures and `diagnostics.html` are produced from these audit data.

The source observations, HUD sample, and real-dollar methods remain those in
[CENSUS_PLAN.md](../../../CENSUS_PLAN.md). The audit does not acquire new data or
modify national tract assignments.

The [verification record](verification.md) documents fresh builds, unchanged source
inputs, count conservation, and an independent reproduction of the fitted slopes.
