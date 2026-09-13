# Census and city diagnostics

The task reads national tract/project outputs and 2024 tract/place polygons through
plain symlinks. `cities.csv` selects Chicago and Detroit; it is the only city-specific
input. Add the desired official place ID and corresponding map targets to show another
city. Acquisition and cleaning remain national.

`coverage.R` produces state, state/cohort and vintage tables with explicit denominators.
`city_tracts.R` retains every positive-area overlapping tract, flags edge tracts and
counts only project points inside the city. `summarize_cities.R` compares latest income
quintiles for all/interior tracts, including zero-project tracts and known-unit Ns.
The denominator of its rates is current housing units, not baseline housing units.
The national tract file separately contains counts/rates after each prior observation.

`map_city.R` maps income, non-Hispanic Black share and homeownership with all retained
city project points. Medians and counts describe whole tracts; map clipping does not
clip populations. `write_report.R` creates a self-contained HTML report;
`summarize_census.R` supplies the generated logbook table. All data saves write reports.

See [the Census methods](../../../CENSUS_PLAN.md) for variable and timing definitions.
The [verification record](verification.md) documents the fresh build, unchanged
HUD sample, count checks, and remaining source limitation.
