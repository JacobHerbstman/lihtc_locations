SHELL = bash
include ../../../shared/code/shell_functions.make
all: ../output/diagnostics.html

include ../../../shared/code/generic.make

../output/diagnostics.html: write_report.R ../output/state_summary.csv ../output/state_year_counts.csv \
    ../output/type_missing_pct.png ../output/coordinates_missing_pct.png ../output/annual_comparison.png \
    ../output/type_by_year.png ../input/sample_sizes.csv ../input/summary_statistics.csv \
    ../input/category_counts.csv ../output/project_characteristics.png Makefile | ../output
	$(R) $<

../output/project_characteristics.png: plot_characteristics.R ../output/characteristic_distributions.csv Makefile | ../output
	$(R) $<

../output/characteristic_distributions.csv: summarize_characteristics.R ../input/projects.csv \
    ../../../shared/code/save_data.R Makefile | ../output ../report
	$(R) $<

../output/%_pct.png: map_states.R ../output/state_summary.csv ../input/states.zip Makefile | ../output
	$(R) $< $*_pct

../output/annual_comparison.png: plot_years.R ../output/state_year_counts.csv Makefile | ../output
	$(R) $<

../output/type_by_year.png: plot_coverage.R ../output/state_year_counts.csv Makefile | ../output
	$(R) $<

../output/state_summary.csv: compare_states.R ../output/state_year_counts.csv \
    ../../../shared/code/save_data.R Makefile | ../output ../report
	$(R) $<

../output/state_year_counts.csv: summarize_states.R ../input/LIHTCPUB.xlsx ../input/project_records.csv \
    ../input/projects.csv ../../../shared/code/save_data.R Makefile | ../output ../report
	$(R) $<

../input/LIHTCPUB.xlsx: ../../../prepare_lihtc/temp/LIHTCPUB.xlsx | ../input
	ln -sf $< $@

../input/project_records.csv: ../../../build_lihtc/output/project_records.csv | ../input
	ln -sf $< $@

../input/projects.csv: ../../../build_lihtc/output/projects.csv | ../input
	ln -sf $< $@

../input/states.zip: ../../../../data_raw/census_boundaries/2024/cb_2024_us_state_20m.zip | ../input
	ln -sf $< $@

# Download only when the pinned boundary snapshot is absent.
../../../../data_raw/census_boundaries/2024/cb_2024_us_state_20m.zip: | download_states.sh ../temp
	bash download_states.sh

../input/sample_sizes.csv: ../../../build_lihtc/output/sample_sizes.csv | ../input
	ln -sf $< $@

../input/summary_statistics.csv: ../../../build_lihtc/output/summary_statistics.csv | ../input
	ln -sf $< $@

../input/category_counts.csv: ../../../build_lihtc/output/category_counts.csv | ../input
	ln -sf $< $@
