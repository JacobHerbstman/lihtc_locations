include ../../../shared/code/shell_functions.make
.DEFAULT_GOAL := all
all: ../output/project_sample.csv ../output/tract_years.csv ../output/coverage.csv \
    ../output/binned_rates.csv ../output/annual_summary.csv ../output/models.csv \
    ../output/rates_main.png ../output/rates_same_2000.png ../output/annual_homeownership.png \
    ../output/placement_maps.png ../output/summary.tex ../output/diagnostics.html

include ../../../shared/code/generic.make

../output/project_sample.csv: project_sample.R periods.csv ../input/projects_with_tracts.csv \
    ../../../shared/code/save_data.R Makefile | ../output ../report
	$(R) $<

../output/tract_years.csv: build_panel.R periods.csv ../input/tract_demographics.csv \
    ../output/project_sample.csv ../../../shared/code/save_data.R Makefile | ../output ../report
	$(R) $<

../output/coverage.csv: summarize_coverage.R periods.csv ../output/project_sample.csv \
    ../output/tract_years.csv ../../../shared/code/save_data.R Makefile | ../output ../report
	$(R) $<

../output/binned_rates.csv: summarize_rates.R periods.csv ../output/tract_years.csv \
    ../../../shared/code/save_data.R Makefile | ../output ../report
	$(R) $<

../output/annual_summary.csv: summarize_annual.R ../output/tract_years.csv \
    ../../../shared/code/save_data.R Makefile | ../output ../report
	$(R) $<

../output/models.csv: fit_models.R periods.csv ../output/tract_years.csv \
    ../../../shared/code/save_data.R Makefile | ../output ../report
	$(R) $<

../output/rates_%.png: plot_rates.R periods.csv ../output/binned_rates.csv Makefile | ../output
	$(R) plot_rates.R $*

../output/annual_homeownership.png: plot_annual.R periods.csv ../output/annual_summary.csv Makefile | ../output
	$(R) $<

../output/placement_maps.png: plot_maps.R periods.csv ../output/project_sample.csv ../input/places_2024.gpkg Makefile | ../output
	$(R) $<

../output/summary.tex: summarize_results.R ../output/coverage.csv ../output/models.csv Makefile | ../output
	$(R) $<

../output/diagnostics.html: write_report.R ../output/coverage.csv ../output/models.csv ../output/project_sample.csv \
    ../output/annual_summary.csv \
    ../output/rates_main.png ../output/rates_same_2000.png ../output/annual_homeownership.png \
    ../output/placement_maps.png Makefile | ../output
	$(R) $<

../input/projects_with_tracts.csv: ../../../assign_lihtc_tracts/output/projects_with_tracts.csv | ../input
	ln -sf $< $@

../input/tract_demographics.csv: ../../../clean_census/output/tract_demographics.csv | ../input
	ln -sf $< $@

../input/places_2024.gpkg: ../../../clean_census/output/places_2024.gpkg | ../input
	ln -sf $< $@
