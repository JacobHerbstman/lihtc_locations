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

tasks/audits/state_diagnostics/output/diagnostics.html: \
    tasks/audits/state_diagnostics/code/write_report.R tasks/audits/state_diagnostics/code/Makefile \
    tasks/audits/state_diagnostics/output/state_summary.csv \
    tasks/build_lihtc/output/sample_sizes.csv tasks/build_lihtc/output/summary_statistics.csv \
    tasks/build_lihtc/output/category_counts.csv \
    tasks/audits/state_diagnostics/output/state_year_counts.csv \
    tasks/audits/state_diagnostics/output/type_missing_pct.png \
    tasks/audits/state_diagnostics/output/coordinates_missing_pct.png \
    tasks/audits/state_diagnostics/output/annual_comparison.png \
    tasks/audits/state_diagnostics/output/type_by_year.png
	$(MAKE) -C tasks/audits/state_diagnostics/code ../output/diagnostics.html

logbook/logbook.pdf: logbook/logbook.tex logbook/reset_summary.tex logbook/corroboration_summary.tex \
    logbook/corroboration_exclusions.png logbook/hud_default_summary.tex \
    logbook/hud_default_exclusions.png logbook/first_address_summary.tex \
    tasks/build_lihtc/output/summary.tex \
    tasks/audits/external_benchmarks/output/checks.txt tasks/audits/external_benchmarks/README.md \
    tasks/audits/state_diagnostics/output/type_missing_pct.png \
    tasks/audits/state_diagnostics/output/coordinates_missing_pct.png \
    tasks/audits/state_diagnostics/output/state_summary.csv
	$(MAKE) -C logbook

data_raw/hud_lihtc_property/2024/lihtcpub.zip: | tasks/prepare_lihtc/code/download_hud.sh
	$(MAKE) -C tasks/prepare_lihtc/code ../../../data_raw/hud_lihtc_property/2024/lihtcpub.zip

tasks/audits/external_benchmarks/output/checks.txt: tasks/audits/external_benchmarks/code/compare_hud.R \
    tasks/audits/external_benchmarks/code/Makefile tasks/prepare_lihtc/temp/LIHTCPUB.xlsx \
    tasks/build_lihtc/output/project_records.csv
	$(MAKE) -C tasks/audits/external_benchmarks/code ../output/checks.txt
