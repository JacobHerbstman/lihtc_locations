include ../../../shared/code/shell_functions.make
.DEFAULT_GOAL := all
all: ../output/city_tracts.csv ../output/project_sample.csv ../output/tract_years.csv \
    ../output/coverage.csv ../output/scales.csv ../output/models.csv \
    ../output/gradients.png ../output/summary.tex ../output/diagnostics.html \
    ../output/housing_controls.png ../output/housing_controls.tex \
    ../output/cross_city.png ../output/cross_city.tex

include ../../../shared/code/generic.make

../output/city_tracts.csv: city_tracts.R cities.csv ../input/places_2024.gpkg \
    ../input/tracts_1980.gpkg ../input/tracts_1990.gpkg ../input/tracts_2000.gpkg \
    ../input/tracts_2010.gpkg ../input/tracts_2020.gpkg \
    ../../../shared/code/save_data.R Makefile | ../output ../report
	$(R) $<

../output/project_sample.csv: project_sample.R cities.csv periods.csv ../input/projects_with_tracts.csv \
    ../output/city_tracts.csv ../../../shared/code/save_data.R Makefile | ../output ../report
	$(R) $<

../output/tract_years.csv: build_panel.R periods.csv ../input/tract_demographics.csv \
    ../output/city_tracts.csv ../output/project_sample.csv \
    ../../../shared/code/save_data.R Makefile | ../output ../report
	$(R) $<

../output/coverage.csv: summarize_coverage.R ../output/tract_years.csv ../output/project_sample.csv \
    ../../../shared/code/save_data.R Makefile | ../output ../report
	$(R) $<

../output/scales.csv: scales.R ../output/tract_years.csv \
    ../../../shared/code/save_data.R Makefile | ../output ../report
	$(R) $<

../output/models.csv: fit_models.R periods.csv ../output/tract_years.csv ../output/scales.csv \
    ../../../shared/code/save_data.R Makefile | ../output ../report
	$(R) $<

../output/gradients.png: plot_gradients.R periods.csv ../output/models.csv Makefile | ../output
	$(R) $<

../output/summary.tex: summarize_results.R ../output/models.csv ../output/coverage.csv Makefile | ../output
	$(R) $<

../output/housing_controls.png: plot_housing_controls.R periods.csv ../output/models.csv Makefile | ../output
	$(R) $<

../output/housing_controls.tex: summarize_housing_controls.R ../output/models.csv ../output/coverage.csv Makefile | ../output
	$(R) $<

../output/diagnostics.html: write_report.R periods.csv ../output/models.csv ../output/coverage.csv \
    ../output/scales.csv ../output/project_sample.csv ../output/gradients.png \
    ../output/housing_controls.png ../output/cross_city.png Makefile | ../output
	$(R) $<

../output/cross_city.png: plot_cross_city.R periods.csv ../output/models.csv Makefile | ../output
	$(R) $<

../output/cross_city.tex: summarize_cross_city.R ../output/models.csv Makefile | ../output
	$(R) $<

../input/projects_with_tracts.csv: ../../../assign_lihtc_tracts/output/projects_with_tracts.csv | ../input
	ln -sf $< $@

../input/tract_demographics.csv: ../../../clean_census/output/tract_demographics.csv | ../input
	ln -sf $< $@

../input/places_2024.gpkg: ../../../clean_census/output/places_2024.gpkg | ../input
	ln -sf $< $@

../input/tracts_%.gpkg: ../../../clean_census/output/tracts_%.gpkg | ../input
	ln -sf $< $@
