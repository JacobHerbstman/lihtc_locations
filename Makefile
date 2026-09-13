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
    tasks/audits/census_diagnostics/code/Makefile tasks/audits/census_diagnostics/output/city_income_groups.csv \
    tasks/audits/census_diagnostics/output/city_tracts.csv tasks/assign_lihtc_tracts/output/projects_with_tracts.csv \
    tasks/audits/census_diagnostics/output/coverage_by_state.csv \
    tasks/audits/census_diagnostics/output/coverage_by_vintage.csv \
    tasks/audits/census_diagnostics/output/1714000_income.png tasks/audits/census_diagnostics/output/1714000_race.png \
    tasks/audits/census_diagnostics/output/1714000_homeowners.png tasks/audits/census_diagnostics/output/2622000_income.png \
    tasks/audits/census_diagnostics/output/2622000_race.png tasks/audits/census_diagnostics/output/2622000_homeowners.png
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
