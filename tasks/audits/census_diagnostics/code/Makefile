include ../../../shared/code/shell_functions.make
.DEFAULT_GOAL := all
all: ../output/city_tracts.csv ../output/city_income_groups.csv \
    ../output/coverage_by_state.csv ../output/coverage_by_cohort.csv ../output/coverage_by_vintage.csv \
    ../output/1714000_income.png ../output/1714000_race.png ../output/1714000_homeowners.png \
    ../output/2622000_income.png ../output/2622000_race.png ../output/2622000_homeowners.png \
    ../output/3651000_income.png ../output/3651000_race.png ../output/3651000_homeowners.png \
    ../output/diagnostics.html ../output/summary.tex

include ../../../shared/code/generic.make

../output/city_tracts.csv: city_tracts.R cities.csv ../input/tracts_2024.gpkg \
    ../input/places_2024.gpkg ../input/tract_lihtc_counts.csv ../input/projects_with_tracts.csv \
    ../../../shared/code/save_data.R Makefile | ../output ../report
	$(R) $<

../output/city_income_groups.csv: summarize_cities.R ../output/city_tracts.csv \
    ../../../shared/code/save_data.R Makefile | ../output ../report
	$(R) $<

../output/coverage_by_%.csv: coverage.R ../input/projects_with_tracts.csv ../input/tract_lihtc_counts.csv \
    ../../../shared/code/save_data.R Makefile | ../output ../report
	$(R) coverage.R $*

../output/%_income.png: map_city.R cities.csv ../output/city_tracts.csv \
    ../input/projects_with_tracts.csv ../input/tracts_2024.gpkg ../input/places_2024.gpkg Makefile | ../output
	$(R) map_city.R $* income

../output/%_race.png: map_city.R cities.csv ../output/city_tracts.csv \
    ../input/projects_with_tracts.csv ../input/tracts_2024.gpkg ../input/places_2024.gpkg Makefile | ../output
	$(R) map_city.R $* race

../output/%_homeowners.png: map_city.R cities.csv ../output/city_tracts.csv \
    ../input/projects_with_tracts.csv ../input/tracts_2024.gpkg ../input/places_2024.gpkg Makefile | ../output
	$(R) map_city.R $* homeowners

../output/diagnostics.html: write_report.R cities.csv ../output/city_income_groups.csv ../output/city_tracts.csv \
    ../input/projects_with_tracts.csv ../output/coverage_by_state.csv ../output/coverage_by_vintage.csv \
    ../output/1714000_income.png ../output/1714000_race.png ../output/1714000_homeowners.png \
    ../output/2622000_income.png ../output/2622000_race.png ../output/2622000_homeowners.png \
    ../output/3651000_income.png ../output/3651000_race.png ../output/3651000_homeowners.png Makefile | ../output
	$(R) $<

../output/summary.tex: summarize_census.R ../output/coverage_by_state.csv ../output/coverage_by_vintage.csv \
    ../output/city_tracts.csv ../input/projects_with_tracts.csv Makefile | ../output
	$(R) $<

../input/projects_with_tracts.csv: ../../../assign_lihtc_tracts/output/projects_with_tracts.csv | ../input
	ln -sf $< $@

../input/tract_lihtc_counts.csv: ../../../assign_lihtc_tracts/output/tract_lihtc_counts.csv | ../input
	ln -sf $< $@

../input/tracts_2024.gpkg: ../../../clean_census/output/tracts_2024.gpkg | ../input
	ln -sf $< $@

../input/places_2024.gpkg: ../../../clean_census/output/places_2024.gpkg | ../input
	ln -sf $< $@
