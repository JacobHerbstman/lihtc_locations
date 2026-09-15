include tasks/shared/code/shell_functions.make
.DEFAULT_GOAL := all
.PHONY: all setup
all: tasks/build_lihtc/output/projects.csv tasks/build_lihtc/output/sample_sizes.csv \
 tasks/build_lihtc/output/summary_statistics.csv tasks/build_lihtc/output/category_counts.csv \
 tasks/audits/state_diagnostics/output/diagnostics.html logbook/logbook.pdf

setup:
	$(MAKE) -C tasks/setup_environment/code

tasks/prepare_lihtc/output/projects.csv: tasks/prepare_lihtc/code/prepare_lihtc.R \
    tasks/prepare_lihtc/code/Makefile data_raw/hud_lihtc_property/2024/lihtcpub.zip \
    tasks/shared/code/save_data.R
	$(MAKE) -C tasks/prepare_lihtc/code ../output/projects.csv

tasks/build_lihtc/output/project_records.csv: tasks/build_lihtc/code/build_lihtc.R \
    tasks/build_lihtc/code/Makefile tasks/prepare_lihtc/output/projects.csv \
    tasks/shared/code/save_data.R
	$(MAKE) -C tasks/build_lihtc/code ../output/project_records.csv

tasks/build_lihtc/output/projects.csv: tasks/build_lihtc/code/select_projects.R \
    tasks/build_lihtc/code/Makefile tasks/build_lihtc/output/project_records.csv \
    tasks/shared/code/save_data.R
	$(MAKE) -C tasks/build_lihtc/code ../output/projects.csv

tasks/build_lihtc/output/sample_sizes.csv: tasks/build_lihtc/code/sample_sizes.R \
    tasks/build_lihtc/code/Makefile tasks/build_lihtc/output/projects.csv tasks/shared/code/save_data.R
	$(MAKE) -C tasks/build_lihtc/code ../output/sample_sizes.csv

tasks/build_lihtc/output/summary_statistics.csv: tasks/build_lihtc/code/summary_statistics.R \
    tasks/build_lihtc/code/Makefile tasks/build_lihtc/output/projects.csv tasks/shared/code/save_data.R
	$(MAKE) -C tasks/build_lihtc/code ../output/summary_statistics.csv

tasks/build_lihtc/output/category_counts.csv: tasks/build_lihtc/code/category_counts.R \
    tasks/build_lihtc/code/Makefile tasks/build_lihtc/output/projects.csv tasks/shared/code/save_data.R
	$(MAKE) -C tasks/build_lihtc/code ../output/category_counts.csv

tasks/build_lihtc/output/summary.tex: tasks/build_lihtc/code/summarize_projects.R \
    tasks/build_lihtc/code/Makefile tasks/build_lihtc/output/project_records.csv \
    tasks/build_lihtc/output/projects.csv tasks/build_lihtc/output/sample_sizes.csv \
    tasks/build_lihtc/output/summary_statistics.csv
	$(MAKE) -C tasks/build_lihtc/code ../output/summary.tex

tasks/prepare_lihtc/temp/LIHTCPUB.xlsx: data_raw/hud_lihtc_property/2024/lihtcpub.zip \
    tasks/prepare_lihtc/code/Makefile
	$(MAKE) -C tasks/prepare_lihtc/code ../temp/LIHTCPUB.xlsx

data_raw/census_boundaries/2024/cb_2024_us_state_20m.zip: | \
    tasks/audits/state_diagnostics/code/download_states.sh
	$(MAKE) -C tasks/audits/state_diagnostics/code ../../../../data_raw/census_boundaries/2024/cb_2024_us_state_20m.zip

tasks/audits/state_diagnostics/output/state_year_counts.csv: \
    tasks/audits/state_diagnostics/code/summarize_states.R tasks/audits/state_diagnostics/code/Makefile \
    tasks/prepare_lihtc/temp/LIHTCPUB.xlsx tasks/build_lihtc/output/project_records.csv \
    tasks/build_lihtc/output/projects.csv tasks/shared/code/save_data.R
	$(MAKE) -C tasks/audits/state_diagnostics/code ../output/state_year_counts.csv

tasks/audits/state_diagnostics/output/state_summary.csv: \
    tasks/audits/state_diagnostics/code/compare_states.R tasks/audits/state_diagnostics/code/Makefile \
    tasks/audits/state_diagnostics/output/state_year_counts.csv tasks/shared/code/save_data.R
	$(MAKE) -C tasks/audits/state_diagnostics/code ../output/state_summary.csv

tasks/audits/state_diagnostics/output/%_pct.png: tasks/audits/state_diagnostics/code/map_states.R \
    tasks/audits/state_diagnostics/code/Makefile tasks/audits/state_diagnostics/output/state_summary.csv \
    data_raw/census_boundaries/2024/cb_2024_us_state_20m.zip
	$(MAKE) -C tasks/audits/state_diagnostics/code ../output/$*_pct.png

tasks/audits/state_diagnostics/output/annual_comparison.png: \
    tasks/audits/state_diagnostics/code/plot_years.R tasks/audits/state_diagnostics/code/Makefile \
    tasks/audits/state_diagnostics/output/state_year_counts.csv
	$(MAKE) -C tasks/audits/state_diagnostics/code ../output/annual_comparison.png

tasks/audits/state_diagnostics/output/type_by_year.png: \
    tasks/audits/state_diagnostics/code/plot_coverage.R tasks/audits/state_diagnostics/code/Makefile \
    tasks/audits/state_diagnostics/output/state_year_counts.csv
	$(MAKE) -C tasks/audits/state_diagnostics/code ../output/type_by_year.png

tasks/audits/state_diagnostics/output/characteristic_distributions.csv: \
    tasks/audits/state_diagnostics/code/summarize_characteristics.R \
    tasks/audits/state_diagnostics/code/Makefile tasks/build_lihtc/output/projects.csv \
    tasks/shared/code/save_data.R
	$(MAKE) -C tasks/audits/state_diagnostics/code ../output/characteristic_distributions.csv

tasks/audits/state_diagnostics/output/project_characteristics.png: \
    tasks/audits/state_diagnostics/code/plot_characteristics.R \
    tasks/audits/state_diagnostics/code/Makefile \
    tasks/audits/state_diagnostics/output/characteristic_distributions.csv
	$(MAKE) -C tasks/audits/state_diagnostics/code ../output/project_characteristics.png

tasks/audits/state_diagnostics/output/diagnostics.html: \
    tasks/audits/state_diagnostics/code/write_report.R tasks/audits/state_diagnostics/code/Makefile \
    tasks/audits/state_diagnostics/output/state_summary.csv \
    tasks/build_lihtc/output/sample_sizes.csv tasks/build_lihtc/output/summary_statistics.csv \
    tasks/build_lihtc/output/category_counts.csv \
    tasks/audits/state_diagnostics/output/state_year_counts.csv \
    tasks/audits/state_diagnostics/output/type_missing_pct.png \
    tasks/audits/state_diagnostics/output/coordinates_missing_pct.png \
    tasks/audits/state_diagnostics/output/annual_comparison.png \
    tasks/audits/state_diagnostics/output/type_by_year.png \
    tasks/audits/state_diagnostics/output/project_characteristics.png
	$(MAKE) -C tasks/audits/state_diagnostics/code ../output/diagnostics.html

logbook/logbook.pdf: logbook/logbook.tex logbook/reset_summary.tex logbook/corroboration_summary.tex \
    logbook/corroboration_exclusions.png logbook/hud_default_summary.tex \
    logbook/hud_default_exclusions.png logbook/first_address_summary.tex \
    tasks/build_lihtc/output/summary.tex \
    tasks/audits/external_benchmarks/output/checks.txt tasks/audits/external_benchmarks/README.md \
    tasks/audits/state_diagnostics/output/type_missing_pct.png \
    tasks/audits/state_diagnostics/output/coordinates_missing_pct.png \
    tasks/audits/state_diagnostics/output/project_characteristics.png \
    tasks/audits/state_diagnostics/output/state_summary.csv
	$(MAKE) -C logbook

data_raw/hud_lihtc_property/2024/lihtcpub.zip: | tasks/prepare_lihtc/code/download_hud.sh
	$(MAKE) -C tasks/prepare_lihtc/code ../../../data_raw/hud_lihtc_property/2024/lihtcpub.zip

tasks/audits/external_benchmarks/output/checks.txt: tasks/audits/external_benchmarks/code/compare_hud.R \
    tasks/audits/external_benchmarks/code/Makefile tasks/prepare_lihtc/temp/LIHTCPUB.xlsx \
    tasks/build_lihtc/output/project_records.csv
	$(MAKE) -C tasks/audits/external_benchmarks/code ../output/checks.txt

# National Census observations and native geography snapshots.
ACS_YEARS = 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022 2023 2024
TRACT_YEARS = 1980 1990 2000 2010 2020 2024
all: $(addprefix tasks/clean_census/output/acs_,$(addsuffix .csv,$(ACS_YEARS))) \
    $(addprefix tasks/assign_lihtc_tracts/output/lihtc_tracts_,$(addsuffix .csv,$(TRACT_YEARS))) \
    tasks/assign_lihtc_tracts/output/projects_with_tracts.csv \
    tasks/assign_lihtc_tracts/output/tract_lihtc_counts.csv \
    $(addprefix tasks/clean_census/output/tracts_,$(addsuffix .gpkg,$(TRACT_YEARS)))

# Source scripts publish atomically; preserve recorded archives resolved through patterns.
.PRECIOUS: data_raw/census_acs/2026-09-13/acs5_%.tar.gz data_raw/nhgis/2026-09-13/%.zip

data_raw/census_acs/2026-09-13/acs5_%.tar.gz: tasks/fetch_census/code/acs_variables.csv | tasks/fetch_census/code/download_acs.R
	$(MAKE) -C tasks/fetch_census/code ../../../$@

data_raw/nhgis/2026-09-13/%.zip: tasks/fetch_census/code/nhgis_%.json | tasks/fetch_census/code/download_nhgis.R
	$(MAKE) -C tasks/fetch_census/code ../../../$@

data_raw/price_indexes/2026-09-13/annual-index-value_annual-percent-change.xls: | tasks/fetch_census/code/Makefile
	$(MAKE) -C tasks/fetch_census/code ../../../$@

tasks/clean_census/output/price_index.csv: tasks/clean_census/code/clean_price_index.R \
    tasks/clean_census/code/Makefile tasks/shared/code/save_data.R \
    data_raw/price_indexes/2026-09-13/annual-index-value_annual-percent-change.xls
	$(MAKE) -C tasks/clean_census/code ../output/price_index.csv

tasks/clean_census/output/historical_tracts.csv: tasks/clean_census/code/clean_nhgis.R \
    tasks/clean_census/code/Makefile tasks/shared/code/save_data.R data_raw/nhgis/2026-09-13/tables.zip
	$(MAKE) -C tasks/clean_census/code ../output/historical_tracts.csv

tasks/clean_census/output/acs_%.csv: tasks/clean_census/code/clean_acs.R \
    tasks/clean_census/code/Makefile tasks/shared/code/save_data.R \
    tasks/fetch_census/code/acs_variables.csv data_raw/census_acs/2026-09-13/acs5_%.tar.gz
	$(MAKE) -C tasks/clean_census/code ../output/acs_$*.csv

tasks/clean_census/output/tract_demographics.csv: tasks/clean_census/code/combine_census.R \
    tasks/clean_census/code/Makefile tasks/shared/code/save_data.R \
    tasks/clean_census/output/historical_tracts.csv tasks/clean_census/output/price_index.csv \
    $(addprefix tasks/clean_census/output/acs_,$(addsuffix .csv,$(ACS_YEARS)))
	$(MAKE) -C tasks/clean_census/code ../output/tract_demographics.csv

tasks/clean_census/output/tracts_%.gpkg: tasks/clean_census/code/prepare_boundaries.R \
    tasks/clean_census/code/Makefile data_raw/nhgis/2026-09-13/tracts_%.zip
	$(MAKE) -C tasks/clean_census/code ../output/tracts_$*.gpkg

tasks/clean_census/output/places_2024.gpkg: tasks/clean_census/code/prepare_boundaries.R \
    tasks/clean_census/code/Makefile data_raw/nhgis/2026-09-13/places_2024.zip
	$(MAKE) -C tasks/clean_census/code ../output/places_2024.gpkg

tasks/assign_lihtc_tracts/output/lihtc_tracts_%.csv: tasks/assign_lihtc_tracts/code/assign_lihtc_tracts.R \
    tasks/assign_lihtc_tracts/code/Makefile tasks/shared/code/save_data.R \
    tasks/build_lihtc/output/projects.csv tasks/clean_census/output/tracts_%.gpkg
	$(MAKE) -C tasks/assign_lihtc_tracts/code ../output/lihtc_tracts_$*.csv

tasks/assign_lihtc_tracts/output/lihtc_places.csv: tasks/assign_lihtc_tracts/code/assign_lihtc_places.R \
    tasks/assign_lihtc_tracts/code/Makefile tasks/shared/code/save_data.R \
    tasks/build_lihtc/output/projects.csv tasks/clean_census/output/places_2024.gpkg
	$(MAKE) -C tasks/assign_lihtc_tracts/code ../output/lihtc_places.csv

tasks/assign_lihtc_tracts/output/projects_with_tracts.csv: tasks/assign_lihtc_tracts/code/join_tract_demographics.R \
    tasks/assign_lihtc_tracts/code/Makefile tasks/shared/code/save_data.R \
    tasks/build_lihtc/output/projects.csv tasks/clean_census/output/tract_demographics.csv \
    tasks/assign_lihtc_tracts/output/lihtc_places.csv \
    $(addprefix tasks/assign_lihtc_tracts/output/lihtc_tracts_,$(addsuffix .csv,$(TRACT_YEARS)))
	$(MAKE) -C tasks/assign_lihtc_tracts/code ../output/projects_with_tracts.csv

tasks/assign_lihtc_tracts/output/tract_lihtc_counts.csv: tasks/assign_lihtc_tracts/code/count_lihtc_tracts.R \
    tasks/assign_lihtc_tracts/code/Makefile tasks/shared/code/save_data.R \
    tasks/clean_census/output/tract_demographics.csv tasks/assign_lihtc_tracts/output/projects_with_tracts.csv
	$(MAKE) -C tasks/assign_lihtc_tracts/code ../output/tract_lihtc_counts.csv

# Coverage and city comparisons use the same national sources and definitions.
all: tasks/audits/census_diagnostics/output/diagnostics.html tasks/audits/census_diagnostics/output/coverage_by_cohort.csv

tasks/audits/census_diagnostics/output/city_tracts.csv: tasks/audits/census_diagnostics/code/city_tracts.R \
    tasks/audits/census_diagnostics/code/Makefile tasks/audits/census_diagnostics/code/cities.csv \
    tasks/assign_lihtc_tracts/output/projects_with_tracts.csv tasks/assign_lihtc_tracts/output/tract_lihtc_counts.csv \
    tasks/clean_census/output/tracts_2024.gpkg tasks/clean_census/output/places_2024.gpkg tasks/shared/code/save_data.R
	$(MAKE) -C tasks/audits/census_diagnostics/code ../output/city_tracts.csv

tasks/audits/census_diagnostics/output/city_income_groups.csv: tasks/audits/census_diagnostics/code/summarize_cities.R \
    tasks/audits/census_diagnostics/code/Makefile tasks/audits/census_diagnostics/output/city_tracts.csv tasks/shared/code/save_data.R
	$(MAKE) -C tasks/audits/census_diagnostics/code ../output/city_income_groups.csv

tasks/audits/census_diagnostics/output/coverage_by_%.csv: tasks/audits/census_diagnostics/code/coverage.R \
    tasks/audits/census_diagnostics/code/Makefile tasks/assign_lihtc_tracts/output/projects_with_tracts.csv \
    tasks/assign_lihtc_tracts/output/tract_lihtc_counts.csv tasks/shared/code/save_data.R
	$(MAKE) -C tasks/audits/census_diagnostics/code ../output/coverage_by_$*.csv

tasks/audits/census_diagnostics/output/%.png: tasks/audits/census_diagnostics/code/map_city.R \
    tasks/audits/census_diagnostics/code/Makefile tasks/audits/census_diagnostics/code/cities.csv \
    tasks/audits/census_diagnostics/output/city_tracts.csv tasks/assign_lihtc_tracts/output/projects_with_tracts.csv \
    tasks/clean_census/output/tracts_2024.gpkg tasks/clean_census/output/places_2024.gpkg
	$(MAKE) -C tasks/audits/census_diagnostics/code ../output/$*.png

tasks/audits/census_diagnostics/output/diagnostics.html: tasks/audits/census_diagnostics/code/write_report.R \
    tasks/audits/census_diagnostics/code/cities.csv \
    tasks/audits/census_diagnostics/code/Makefile tasks/audits/census_diagnostics/output/city_income_groups.csv \
    tasks/audits/census_diagnostics/output/city_tracts.csv tasks/assign_lihtc_tracts/output/projects_with_tracts.csv \
    tasks/audits/census_diagnostics/output/coverage_by_state.csv \
    tasks/audits/census_diagnostics/output/coverage_by_vintage.csv \
    tasks/audits/census_diagnostics/output/1714000_income.png tasks/audits/census_diagnostics/output/1714000_race.png \
    tasks/audits/census_diagnostics/output/1714000_homeowners.png tasks/audits/census_diagnostics/output/2622000_income.png \
    tasks/audits/census_diagnostics/output/2622000_race.png tasks/audits/census_diagnostics/output/2622000_homeowners.png \
    tasks/audits/census_diagnostics/output/3651000_income.png tasks/audits/census_diagnostics/output/3651000_race.png \
    tasks/audits/census_diagnostics/output/3651000_homeowners.png
	$(MAKE) -C tasks/audits/census_diagnostics/code ../output/diagnostics.html

tasks/audits/census_diagnostics/output/summary.tex: tasks/audits/census_diagnostics/code/summarize_census.R \
    tasks/audits/census_diagnostics/code/Makefile tasks/audits/census_diagnostics/output/coverage_by_state.csv \
    tasks/audits/census_diagnostics/output/coverage_by_vintage.csv tasks/audits/census_diagnostics/output/city_tracts.csv \
    tasks/assign_lihtc_tracts/output/projects_with_tracts.csv
	$(MAKE) -C tasks/audits/census_diagnostics/code ../output/summary.tex

# Separate affordability source. HUD's download challenge currently blocks this target;
# it is not a prerequisite of the completed Census demographic extension.
data_raw/hud_income_limits/2024/MTSP-Data-FY24.xlsx: | tasks/fetch_hud_income_limits/code/download_limits.R
	$(MAKE) -C tasks/fetch_hud_income_limits/code ../../../$@

logbook/logbook.pdf: tasks/audits/census_diagnostics/output/summary.tex \
    tasks/audits/census_diagnostics/output/1714000_income.png

# NYC timing comparison uses prior homeownership and every native tract/year.
all: tasks/audits/nyc_homeownership/output/diagnostics.html tasks/audits/nyc_homeownership/output/summary.tex

tasks/audits/nyc_homeownership/output/project_sample.csv: tasks/audits/nyc_homeownership/code/project_sample.R \
    tasks/audits/nyc_homeownership/code/periods.csv tasks/audits/nyc_homeownership/code/Makefile \
    tasks/assign_lihtc_tracts/output/projects_with_tracts.csv tasks/shared/code/save_data.R
	$(MAKE) -C tasks/audits/nyc_homeownership/code ../output/project_sample.csv

tasks/audits/nyc_homeownership/output/tract_years.csv: tasks/audits/nyc_homeownership/code/build_panel.R \
    tasks/audits/nyc_homeownership/code/periods.csv tasks/audits/nyc_homeownership/code/Makefile \
    tasks/audits/nyc_homeownership/output/project_sample.csv tasks/clean_census/output/tract_demographics.csv tasks/shared/code/save_data.R
	$(MAKE) -C tasks/audits/nyc_homeownership/code ../output/tract_years.csv

tasks/audits/nyc_homeownership/output/coverage.csv: tasks/audits/nyc_homeownership/code/summarize_coverage.R \
    tasks/audits/nyc_homeownership/code/periods.csv tasks/audits/nyc_homeownership/code/Makefile \
    tasks/audits/nyc_homeownership/output/project_sample.csv tasks/audits/nyc_homeownership/output/tract_years.csv tasks/shared/code/save_data.R
	$(MAKE) -C tasks/audits/nyc_homeownership/code ../output/coverage.csv

tasks/audits/nyc_homeownership/output/binned_rates.csv: tasks/audits/nyc_homeownership/code/summarize_rates.R \
    tasks/audits/nyc_homeownership/code/periods.csv tasks/audits/nyc_homeownership/code/Makefile \
    tasks/audits/nyc_homeownership/output/tract_years.csv tasks/shared/code/save_data.R
	$(MAKE) -C tasks/audits/nyc_homeownership/code ../output/binned_rates.csv

tasks/audits/nyc_homeownership/output/annual_summary.csv: tasks/audits/nyc_homeownership/code/summarize_annual.R \
    tasks/audits/nyc_homeownership/code/Makefile tasks/audits/nyc_homeownership/output/tract_years.csv tasks/shared/code/save_data.R
	$(MAKE) -C tasks/audits/nyc_homeownership/code ../output/annual_summary.csv

tasks/audits/nyc_homeownership/output/models.csv: tasks/audits/nyc_homeownership/code/fit_models.R \
    tasks/audits/nyc_homeownership/code/periods.csv tasks/audits/nyc_homeownership/code/Makefile \
    tasks/audits/nyc_homeownership/output/tract_years.csv tasks/shared/code/save_data.R
	$(MAKE) -C tasks/audits/nyc_homeownership/code ../output/models.csv

tasks/audits/nyc_homeownership/output/rates_%.png: tasks/audits/nyc_homeownership/code/plot_rates.R \
    tasks/audits/nyc_homeownership/code/periods.csv tasks/audits/nyc_homeownership/code/Makefile \
    tasks/audits/nyc_homeownership/output/binned_rates.csv
	$(MAKE) -C tasks/audits/nyc_homeownership/code ../output/rates_$*.png

tasks/audits/nyc_homeownership/output/annual_homeownership.png: tasks/audits/nyc_homeownership/code/plot_annual.R \
    tasks/audits/nyc_homeownership/code/periods.csv \
    tasks/audits/nyc_homeownership/code/Makefile tasks/audits/nyc_homeownership/output/annual_summary.csv
	$(MAKE) -C tasks/audits/nyc_homeownership/code ../output/annual_homeownership.png

tasks/audits/nyc_homeownership/output/placement_maps.png: tasks/audits/nyc_homeownership/code/plot_maps.R \
    tasks/audits/nyc_homeownership/code/periods.csv \
    tasks/audits/nyc_homeownership/code/Makefile tasks/audits/nyc_homeownership/output/project_sample.csv \
    tasks/clean_census/output/places_2024.gpkg
	$(MAKE) -C tasks/audits/nyc_homeownership/code ../output/placement_maps.png

tasks/audits/nyc_homeownership/output/summary.tex: tasks/audits/nyc_homeownership/code/summarize_results.R \
    tasks/audits/nyc_homeownership/code/Makefile tasks/audits/nyc_homeownership/output/coverage.csv \
    tasks/audits/nyc_homeownership/output/models.csv
	$(MAKE) -C tasks/audits/nyc_homeownership/code ../output/summary.tex

tasks/audits/nyc_homeownership/output/diagnostics.html: tasks/audits/nyc_homeownership/code/write_report.R \
    tasks/audits/nyc_homeownership/output/annual_summary.csv \
    tasks/audits/nyc_homeownership/code/Makefile tasks/audits/nyc_homeownership/output/coverage.csv \
    tasks/audits/nyc_homeownership/output/models.csv tasks/audits/nyc_homeownership/output/project_sample.csv \
    tasks/audits/nyc_homeownership/output/rates_main.png tasks/audits/nyc_homeownership/output/rates_same_2000.png \
    tasks/audits/nyc_homeownership/output/annual_homeownership.png tasks/audits/nyc_homeownership/output/placement_maps.png
	$(MAKE) -C tasks/audits/nyc_homeownership/code ../output/diagnostics.html

logbook/logbook.pdf: tasks/audits/nyc_homeownership/output/summary.tex \
    tasks/audits/nyc_homeownership/output/rates_main.png \
    tasks/audits/nyc_homeownership/output/rates_same_2000.png \
    tasks/audits/nyc_homeownership/output/placement_maps.png

# Compare prior homeownership, race and income across the selected cities.
all: tasks/audits/placement_gradients/output/diagnostics.html tasks/audits/placement_gradients/output/summary.tex \
    tasks/audits/placement_gradients/output/housing_controls.tex tasks/audits/placement_gradients/output/cross_city.tex

tasks/audits/placement_gradients/output/city_tracts.csv: tasks/audits/placement_gradients/code/city_tracts.R \
    tasks/audits/placement_gradients/code/Makefile \
    tasks/audits/placement_gradients/code/cities.csv \
    tasks/clean_census/output/places_2024.gpkg \
    tasks/clean_census/output/tracts_1980.gpkg \
    tasks/clean_census/output/tracts_1990.gpkg \
    tasks/clean_census/output/tracts_2000.gpkg \
    tasks/clean_census/output/tracts_2010.gpkg \
    tasks/clean_census/output/tracts_2020.gpkg \
    tasks/shared/code/save_data.R
	$(MAKE) -C tasks/audits/placement_gradients/code ../output/city_tracts.csv

tasks/audits/placement_gradients/output/project_sample.csv: tasks/audits/placement_gradients/code/project_sample.R \
    tasks/audits/placement_gradients/code/Makefile \
    tasks/audits/placement_gradients/code/cities.csv \
    tasks/audits/placement_gradients/code/periods.csv \
    tasks/audits/placement_gradients/output/city_tracts.csv \
    tasks/assign_lihtc_tracts/output/projects_with_tracts.csv \
    tasks/shared/code/save_data.R
	$(MAKE) -C tasks/audits/placement_gradients/code ../output/project_sample.csv

tasks/audits/placement_gradients/output/tract_years.csv: tasks/audits/placement_gradients/code/build_panel.R \
    tasks/audits/placement_gradients/code/Makefile \
    tasks/audits/placement_gradients/code/periods.csv \
    tasks/audits/placement_gradients/output/city_tracts.csv \
    tasks/audits/placement_gradients/output/project_sample.csv \
    tasks/clean_census/output/tract_demographics.csv \
    tasks/shared/code/save_data.R
	$(MAKE) -C tasks/audits/placement_gradients/code ../output/tract_years.csv

tasks/audits/placement_gradients/output/coverage.csv: tasks/audits/placement_gradients/code/summarize_coverage.R \
    tasks/audits/placement_gradients/code/Makefile \
    tasks/audits/placement_gradients/output/tract_years.csv \
    tasks/audits/placement_gradients/output/project_sample.csv \
    tasks/shared/code/save_data.R
	$(MAKE) -C tasks/audits/placement_gradients/code ../output/coverage.csv

tasks/audits/placement_gradients/output/scales.csv: tasks/audits/placement_gradients/code/scales.R \
    tasks/audits/placement_gradients/code/Makefile \
    tasks/audits/placement_gradients/output/tract_years.csv \
    tasks/shared/code/save_data.R
	$(MAKE) -C tasks/audits/placement_gradients/code ../output/scales.csv

tasks/audits/placement_gradients/output/models.csv: tasks/audits/placement_gradients/code/fit_models.R \
    tasks/audits/placement_gradients/code/Makefile \
    tasks/audits/placement_gradients/code/periods.csv \
    tasks/audits/placement_gradients/output/tract_years.csv \
    tasks/audits/placement_gradients/output/scales.csv \
    tasks/shared/code/save_data.R
	$(MAKE) -C tasks/audits/placement_gradients/code ../output/models.csv

tasks/audits/placement_gradients/output/gradients.png: tasks/audits/placement_gradients/code/plot_gradients.R \
    tasks/audits/placement_gradients/code/Makefile \
    tasks/audits/placement_gradients/code/periods.csv \
    tasks/audits/placement_gradients/output/models.csv
	$(MAKE) -C tasks/audits/placement_gradients/code ../output/gradients.png

tasks/audits/placement_gradients/output/summary.tex: tasks/audits/placement_gradients/code/summarize_results.R \
    tasks/audits/placement_gradients/code/Makefile \
    tasks/audits/placement_gradients/output/models.csv \
    tasks/audits/placement_gradients/output/coverage.csv
	$(MAKE) -C tasks/audits/placement_gradients/code ../output/summary.tex

tasks/audits/placement_gradients/output/housing_controls.png: tasks/audits/placement_gradients/code/plot_housing_controls.R \
    tasks/audits/placement_gradients/code/Makefile tasks/audits/placement_gradients/code/periods.csv \
    tasks/audits/placement_gradients/output/models.csv
	$(MAKE) -C tasks/audits/placement_gradients/code ../output/housing_controls.png

tasks/audits/placement_gradients/output/housing_controls.tex: tasks/audits/placement_gradients/code/summarize_housing_controls.R \
    tasks/audits/placement_gradients/code/Makefile tasks/audits/placement_gradients/output/models.csv \
    tasks/audits/placement_gradients/output/coverage.csv
	$(MAKE) -C tasks/audits/placement_gradients/code ../output/housing_controls.tex

tasks/audits/placement_gradients/output/diagnostics.html: tasks/audits/placement_gradients/code/write_report.R \
    tasks/audits/placement_gradients/code/Makefile \
    tasks/audits/placement_gradients/code/periods.csv \
    tasks/audits/placement_gradients/output/models.csv \
    tasks/audits/placement_gradients/output/coverage.csv \
    tasks/audits/placement_gradients/output/scales.csv \
    tasks/audits/placement_gradients/output/project_sample.csv \
    tasks/audits/placement_gradients/output/gradients.png \
    tasks/audits/placement_gradients/output/housing_controls.png tasks/audits/placement_gradients/output/cross_city.png
	$(MAKE) -C tasks/audits/placement_gradients/code ../output/diagnostics.html

tasks/audits/placement_gradients/output/cross_city.png: tasks/audits/placement_gradients/code/plot_cross_city.R \
    tasks/audits/placement_gradients/code/Makefile tasks/audits/placement_gradients/code/periods.csv \
    tasks/audits/placement_gradients/output/models.csv
	$(MAKE) -C tasks/audits/placement_gradients/code ../output/cross_city.png

tasks/audits/placement_gradients/output/cross_city.tex: tasks/audits/placement_gradients/code/summarize_cross_city.R \
    tasks/audits/placement_gradients/code/Makefile tasks/audits/placement_gradients/output/models.csv
	$(MAKE) -C tasks/audits/placement_gradients/code ../output/cross_city.tex

logbook/logbook.pdf: tasks/audits/placement_gradients/output/cross_city.tex \
    tasks/audits/placement_gradients/output/cross_city.png \
    logbook/placement_gradients_pooled_summary.tex logbook/placement_gradients_pooled.png \
    logbook/placement_gradients_housing_controls.tex logbook/placement_gradients_housing_controls.png \
    logbook/placement_gradients_split_summary.tex logbook/placement_gradients_split.png

# Reuse the unchanged LOCUS raw files from the sibling project; start the measurement here.
all: tasks/audits/local_control/output/diagnostics.html

tasks/audits/local_control/output/locus_city_text.csv: tasks/audits/local_control/code/extract_locus.R \
    tasks/audits/local_control/code/Makefile tasks/audits/local_control/code/city_keys.csv \
    tasks/audits/local_control/code/source_hashes.csv tasks/audits/placement_gradients/code/cities.csv \
    ../local_laws/data_raw/locus_v1/20260507/train-00000-of-00008.parquet \
    ../local_laws/data_raw/locus_v1/20260507/train-00001-of-00008.parquet \
    ../local_laws/data_raw/locus_v1/20260507/train-00002-of-00008.parquet \
    ../local_laws/data_raw/locus_v1/20260507/train-00003-of-00008.parquet \
    ../local_laws/data_raw/locus_v1/20260507/train-00004-of-00008.parquet \
    ../local_laws/data_raw/locus_v1/20260507/train-00005-of-00008.parquet \
    ../local_laws/data_raw/locus_v1/20260507/train-00006-of-00008.parquet \
    ../local_laws/data_raw/locus_v1/20260507/train-00007-of-00008.parquet tasks/shared/code/save_data.R
	$(MAKE) -C tasks/audits/local_control/code ../output/locus_city_text.csv

tasks/audits/local_control/output/locus_city_coverage.csv: tasks/audits/local_control/code/summarize_coverage.R \
    tasks/audits/local_control/code/Makefile tasks/audits/placement_gradients/code/cities.csv \
    tasks/audits/local_control/output/locus_city_text.csv tasks/shared/code/save_data.R
	$(MAKE) -C tasks/audits/local_control/code ../output/locus_city_coverage.csv

tasks/audits/local_control/output/coverage.tex: tasks/audits/local_control/code/summarize_coverage_tex.R \
    tasks/audits/local_control/code/Makefile tasks/audits/local_control/output/locus_city_coverage.csv
	$(MAKE) -C tasks/audits/local_control/code ../output/coverage.tex

tasks/audits/local_control/output/diagnostics.html: tasks/audits/local_control/code/write_report.R \
    tasks/audits/local_control/code/Makefile tasks/audits/local_control/README.md \
    tasks/audits/local_control/MEASUREMENT_PLAN.md tasks/audits/local_control/output/locus_city_coverage.csv \
    tasks/audits/local_control/output/locus_city_text.csv
	$(MAKE) -C tasks/audits/local_control/code ../output/diagnostics.html

logbook/logbook.pdf: tasks/audits/local_control/output/coverage.tex

# Census government inventory and fixed metro/population definitions.

data_raw/census_governments/2026-09-15/govt_units_2022.ZIP: tasks/fetch_local_governments/code/Makefile
	$(MAKE) -C tasks/fetch_local_governments/code ../../../data_raw/census_governments/2026-09-15/govt_units_2022.ZIP

data_raw/census_governments/2026-09-15/list1_2020.xls: tasks/fetch_local_governments/code/Makefile
	$(MAKE) -C tasks/fetch_local_governments/code ../../../data_raw/census_governments/2026-09-15/list1_2020.xls

data_raw/census_governments/2026-09-15/list2_2020.xls: tasks/fetch_local_governments/code/Makefile
	$(MAKE) -C tasks/fetch_local_governments/code ../../../data_raw/census_governments/2026-09-15/list2_2020.xls

data_raw/census_governments/2026-09-15/co-est2021-alldata.csv: tasks/fetch_local_governments/code/Makefile
	$(MAKE) -C tasks/fetch_local_governments/code ../../../data_raw/census_governments/2026-09-15/co-est2021-alldata.csv

all: tasks/fetch_local_governments/output/source_inventory.csv tasks/audits/local_control/output/metro_fragmentation.csv

tasks/fetch_local_governments/output/source_inventory.csv: tasks/fetch_local_governments/code/report_sources.R \
    tasks/fetch_local_governments/code/Makefile tasks/shared/code/save_data.R \
    data_raw/census_governments/2026-09-15/govt_units_2022.ZIP \
    data_raw/census_governments/2026-09-15/list1_2020.xls \
    data_raw/census_governments/2026-09-15/list2_2020.xls \
    data_raw/census_governments/2026-09-15/co-est2021-alldata.csv
	$(MAKE) -C tasks/fetch_local_governments/code ../output/source_inventory.csv

tasks/audits/local_control/output/governments.csv: tasks/audits/local_control/code/build_metro_governments.R \
    tasks/audits/local_control/code/Makefile tasks/shared/code/save_data.R \
    tasks/audits/placement_gradients/code/cities.csv \
    data_raw/census_governments/2026-09-15/govt_units_2022.ZIP \
    data_raw/census_governments/2026-09-15/list1_2020.xls data_raw/census_governments/2026-09-15/list2_2020.xls
	$(MAKE) -C tasks/audits/local_control/code ../output/governments.csv

tasks/audits/local_control/output/metro_fragmentation.csv: tasks/audits/local_control/code/summarize_metros.R \
    tasks/audits/local_control/code/Makefile tasks/shared/code/save_data.R \
    tasks/audits/placement_gradients/code/cities.csv tasks/audits/local_control/output/governments.csv \
    data_raw/census_governments/2026-09-15/list1_2020.xls data_raw/census_governments/2026-09-15/co-est2021-alldata.csv
	$(MAKE) -C tasks/audits/local_control/code ../output/metro_fragmentation.csv

all: tasks/audits/local_control/output/metro_correlations.csv tasks/audits/local_control/output/metro_gradients.png

tasks/audits/local_control/output/metro_comparison.csv: tasks/audits/local_control/code/compare_metros.R \
    tasks/audits/local_control/code/Makefile tasks/shared/code/save_data.R \
    tasks/audits/local_control/output/metro_fragmentation.csv tasks/audits/placement_gradients/output/models.csv
	$(MAKE) -C tasks/audits/local_control/code ../output/metro_comparison.csv

tasks/audits/local_control/output/metro_correlations.csv: tasks/audits/local_control/code/correlate_metros.R \
    tasks/audits/local_control/code/Makefile tasks/shared/code/save_data.R tasks/audits/local_control/output/metro_comparison.csv
	$(MAKE) -C tasks/audits/local_control/code ../output/metro_correlations.csv

tasks/audits/local_control/output/metro_gradients.png: tasks/audits/local_control/code/plot_metros.R \
    tasks/audits/local_control/code/Makefile tasks/audits/local_control/output/metro_comparison.csv
	$(MAKE) -C tasks/audits/local_control/code ../output/metro_gradients.png

all: tasks/audits/local_control/output/metro_diagnostics.html

tasks/audits/local_control/output/metro_diagnostics.html: tasks/audits/local_control/code/write_metro_report.R \
    tasks/audits/local_control/code/Makefile tasks/audits/local_control/output/metro_fragmentation.csv \
    tasks/audits/local_control/output/metro_comparison.csv tasks/audits/local_control/output/metro_correlations.csv \
    tasks/audits/local_control/output/metro_gradients.png
	$(MAKE) -C tasks/audits/local_control/code ../output/metro_diagnostics.html

tasks/audits/local_control/output/metro_summary.tex: tasks/audits/local_control/code/summarize_metros_tex.R \
    tasks/audits/local_control/code/Makefile tasks/audits/local_control/output/metro_fragmentation.csv \
    tasks/audits/local_control/output/metro_correlations.csv
	$(MAKE) -C tasks/audits/local_control/code ../output/metro_summary.tex

logbook/logbook.pdf: tasks/audits/local_control/output/metro_summary.tex

# Within-city approval-route pilot; separate from metro counts.
all: tasks/audits/within_city_discretion/output/diagnostics.html

data_raw/approval_rules/2026-09-15/sf_hcd_2023.pdf:
	$(MAKE) -C tasks/audits/within_city_discretion/code ../../../../data_raw/approval_rules/2026-09-15/sf_hcd_2023.pdf

data_raw/approval_rules/2026-09-15/seattle_ord126741.pdf:
	$(MAKE) -C tasks/audits/within_city_discretion/code ../../../../data_raw/approval_rules/2026-09-15/seattle_ord126741.pdf

data_raw/approval_rules/2026-09-15/boston_article80_proposal_2025.pdf:
	$(MAKE) -C tasks/audits/within_city_discretion/code ../../../../data_raw/approval_rules/2026-09-15/boston_article80_proposal_2025.pdf

tasks/audits/within_city_discretion/output/evidence.csv: tasks/audits/within_city_discretion/code/build_evidence.R \
    tasks/audits/within_city_discretion/code/evidence_notes.csv \
    tasks/audits/within_city_discretion/code/sources.csv \
    tasks/audits/local_control/output/locus_city_text.csv \
    tasks/audits/within_city_discretion/code/evidence/boston_board_2022_web.txt \
    tasks/audits/within_city_discretion/code/evidence/haa_court_web.txt \
    tasks/audits/within_city_discretion/code/evidence/la_site_plan_web.txt \
    tasks/audits/within_city_discretion/code/evidence/nyc_handbook_web.txt \
    tasks/audits/within_city_discretion/code/evidence/seattle_2025_web.txt \
    data_raw/approval_rules/2026-09-15/sf_hcd_2023.pdf \
    data_raw/approval_rules/2026-09-15/seattle_ord126741.pdf \
    data_raw/approval_rules/2026-09-15/boston_article80_proposal_2025.pdf \
    tasks/shared/code/save_data.R \
    tasks/audits/within_city_discretion/code/Makefile
	$(MAKE) -C tasks/audits/within_city_discretion/code ../output/evidence.csv

tasks/audits/within_city_discretion/output/approval_routes.csv: tasks/audits/within_city_discretion/code/build_routes.R \
    tasks/audits/within_city_discretion/code/route_coding.csv \
    tasks/audits/within_city_discretion/code/city_coding.csv \
    tasks/audits/placement_gradients/code/cities.csv \
    tasks/audits/within_city_discretion/output/evidence.csv \
    tasks/shared/code/save_data.R \
    tasks/audits/within_city_discretion/code/Makefile
	$(MAKE) -C tasks/audits/within_city_discretion/code ../output/approval_routes.csv

tasks/audits/within_city_discretion/output/city_comparison.csv: tasks/audits/within_city_discretion/code/compare_cities.R \
    tasks/audits/within_city_discretion/code/city_coding.csv \
    tasks/audits/placement_gradients/output/models.csv \
    tasks/shared/code/save_data.R \
    tasks/audits/within_city_discretion/code/Makefile
	$(MAKE) -C tasks/audits/within_city_discretion/code ../output/city_comparison.csv

tasks/audits/within_city_discretion/output/city_comparison.png: tasks/audits/within_city_discretion/code/plot_comparison.R \
    tasks/audits/within_city_discretion/output/city_comparison.csv \
    tasks/audits/within_city_discretion/code/Makefile
	$(MAKE) -C tasks/audits/within_city_discretion/code ../output/city_comparison.png

tasks/audits/within_city_discretion/output/diagnostics.html: tasks/audits/within_city_discretion/code/write_report.R \
    tasks/audits/within_city_discretion/output/approval_routes.csv \
    tasks/audits/within_city_discretion/output/city_comparison.csv \
    tasks/audits/within_city_discretion/output/evidence.csv \
    tasks/audits/within_city_discretion/output/city_comparison.png \
    tasks/audits/within_city_discretion/README.md \
    tasks/audits/within_city_discretion/code/Makefile
	$(MAKE) -C tasks/audits/within_city_discretion/code ../output/diagnostics.html

tasks/audits/within_city_discretion/output/summary.tex: tasks/audits/within_city_discretion/code/summarize_tex.R \
    tasks/audits/within_city_discretion/output/city_comparison.csv \
    tasks/audits/within_city_discretion/code/Makefile
	$(MAKE) -C tasks/audits/within_city_discretion/code ../output/summary.tex

logbook/logbook.pdf: tasks/audits/within_city_discretion/output/summary.tex tasks/audits/within_city_discretion/output/city_comparison.png
