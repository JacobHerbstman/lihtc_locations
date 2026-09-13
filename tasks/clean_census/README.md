# Clean national tract observations

Run from root make. Task-local make uses symlinked source archives and the ACS
variable list. `clean_nhgis.R` produces the three historical observations;
`clean_acs.R YEAR` produces each ACS release. `clean_price_index.R` prepares the
national conversion factors. `combine_census.R` keeps native observation keys,
constructs shares from explicit denominators and adds 2024-dollar values and MOEs.
`prepare_boundaries.R KIND YEAR` writes each separate tract/place geography.

`tract_demographics.csv` is unique by source, period_end and tract_geoid; each row
is an observed tract, including areas with no LIHTC. It is not a fixed-boundary
tract panel. Source fields, dates, universes, negative-code handling and historical
comparability limitations are described in [the Census methods](../../CENSUS_PLAN.md).
