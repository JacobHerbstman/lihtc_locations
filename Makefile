include tasks/shared/code/shell_functions.make
.DEFAULT_GOAL := all
.PHONY: all setup
all: tasks/build_lihtc/output/projects.csv tasks/build_lihtc/output/confident_projects.csv \
 tasks/build_lihtc/output/review.csv tasks/audits/state_diagnostics/output/diagnostics.html logbook/logbook.pdf

setup:
	$(MAKE) -C tasks/setup_environment/code

tasks/prepare_lihtc/output/projects.csv: tasks/prepare_lihtc/code/prepare_lihtc.R \
    tasks/prepare_lihtc/code/Makefile data_raw/hud_lihtc_property/2024/lihtcpub.zip \
    tasks/shared/code/save_data.R
	$(MAKE) -C tasks/prepare_lihtc/code ../output/projects.csv

tasks/geocode_lihtc/temp/request_%.csv: tasks/geocode_lihtc/code/prepare_batch.R \
    tasks/geocode_lihtc/code/Makefile tasks/prepare_lihtc/output/projects.csv
	$(MAKE) -C tasks/geocode_lihtc/code ../temp/request_$*.csv

data_raw/census_geocoder/2026-09-11/response_%.csv: | tasks/geocode_lihtc/temp/request_%.csv
	$(MAKE) -C tasks/geocode_lihtc/code ../../../data_raw/census_geocoder/2026-09-11/response_$*.csv

tasks/geocode_lihtc/output/geocodes.csv: tasks/geocode_lihtc/code/parse_responses.R \
    tasks/geocode_lihtc/code/Makefile data_raw/census_geocoder/2026-09-11/sha256.txt \
    tasks/prepare_lihtc/output/projects.csv data_raw/census_geocoder/2026-09-11/response_1.csv \
    data_raw/census_geocoder/2026-09-11/response_2.csv data_raw/census_geocoder/2026-09-11/response_3.csv \
    tasks/shared/code/save_data.R
	$(MAKE) -C tasks/geocode_lihtc/code ../output/geocodes.csv

tasks/build_lihtc/output/project_records.csv: tasks/build_lihtc/code/build_lihtc.R \
    tasks/build_lihtc/code/Makefile tasks/prepare_lihtc/output/projects.csv \
    tasks/geocode_lihtc/output/geocodes.csv tasks/shared/code/save_data.R
	$(MAKE) -C tasks/build_lihtc/code ../output/project_records.csv

tasks/build_lihtc/output/projects.csv: tasks/build_lihtc/code/select_projects.R \
    tasks/build_lihtc/code/Makefile tasks/build_lihtc/output/project_records.csv \
    tasks/shared/code/save_data.R
	$(MAKE) -C tasks/build_lihtc/code ../output/projects.csv

tasks/build_lihtc/output/confident_projects.csv: tasks/build_lihtc/code/select_confident.R \
    tasks/build_lihtc/code/Makefile tasks/build_lihtc/output/projects.csv tasks/shared/code/save_data.R
	$(MAKE) -C tasks/build_lihtc/code ../output/confident_projects.csv

tasks/build_lihtc/output/review.csv: tasks/build_lihtc/code/review_projects.R \
    tasks/build_lihtc/code/Makefile tasks/build_lihtc/output/project_records.csv \
    tasks/shared/code/save_data.R
	$(MAKE) -C tasks/build_lihtc/code ../output/review.csv

tasks/build_lihtc/output/summary.tex: tasks/build_lihtc/code/summarize_projects.R \
    tasks/build_lihtc/code/Makefile tasks/build_lihtc/output/project_records.csv \
    tasks/build_lihtc/output/projects.csv
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

tasks/audits/state_diagnostics/output/diagnostics.html: \
    tasks/audits/state_diagnostics/code/write_report.R tasks/audits/state_diagnostics/code/Makefile \
    tasks/audits/state_diagnostics/output/state_summary.csv \
    tasks/audits/state_diagnostics/output/state_year_counts.csv \
    tasks/audits/state_diagnostics/output/type_missing_pct.png \
    tasks/audits/state_diagnostics/output/confidence_loss_pct.png \
    tasks/audits/state_diagnostics/output/annual_comparison.png \
    tasks/audits/state_diagnostics/output/type_by_year.png
	$(MAKE) -C tasks/audits/state_diagnostics/code ../output/diagnostics.html

logbook/logbook.pdf: logbook/logbook.tex logbook/reset_summary.tex logbook/corroboration_summary.tex \
    logbook/corroboration_exclusions.png tasks/build_lihtc/output/summary.tex \
    tasks/audits/external_benchmarks/output/checks.txt tasks/audits/external_benchmarks/README.md \
    tasks/audits/state_diagnostics/output/type_missing_pct.png \
    tasks/audits/state_diagnostics/output/confidence_loss_pct.png \
    tasks/audits/state_diagnostics/output/state_summary.csv
	$(MAKE) -C logbook

data_raw/hud_lihtc_property/2024/lihtcpub.zip: | tasks/prepare_lihtc/code/download_hud.sh
	$(MAKE) -C tasks/prepare_lihtc/code ../../../data_raw/hud_lihtc_property/2024/lihtcpub.zip

tasks/audits/external_benchmarks/output/checks.txt: tasks/audits/external_benchmarks/code/compare_hud.R \
    tasks/audits/external_benchmarks/code/Makefile tasks/prepare_lihtc/temp/LIHTCPUB.xlsx \
    tasks/build_lihtc/output/project_records.csv
	$(MAKE) -C tasks/audits/external_benchmarks/code ../output/checks.txt
.PRECIOUS: tasks/geocode_lihtc/temp/request_%.csv
