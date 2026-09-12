include ../../../shared/code/shell_functions.make
all: ../output/diagnostics.html ../report/state_year_counts.txt ../report/state_summary.txt

../output/diagnostics.html: write_report.R ../output/state_summary.csv ../output/state_year_counts.csv ../output/type_missing_pct.png ../output/confidence_loss_pct.png ../output/annual_comparison.png ../output/type_by_year.png Makefile | ../output
	$(R) $<

../output/%_pct.png: map_states.R ../output/state_summary.csv ../input/states.zip Makefile | ../output
	$(R) $< $*_pct

../output/annual_comparison.png: plot_years.R ../output/state_year_counts.csv Makefile | ../output
	$(R) $<

../output/type_by_year.png: plot_coverage.R ../output/state_year_counts.csv Makefile | ../output
	$(R) $<

../output/state_summary.csv: compare_states.R ../output/state_year_counts.csv Makefile | ../output
	$(R) $<

../output/state_year_counts.csv: summarize_states.R ../input/LIHTCPUB.xlsx ../input/project_records.csv ../input/projects.csv Makefile | ../output
	$(R) $<

../report/state_year_counts.txt: ../output/state_year_counts.csv ../../../shared/code/report.R | ../report
	$(R) ../../../shared/code/report.R $< $@ state year

../report/state_summary.txt: ../output/state_summary.csv ../../../shared/code/report.R | ../report
	$(R) ../../../shared/code/report.R $< $@ state

../input/LIHTCPUB.xlsx: ../../../prepare_lihtc/temp/LIHTCPUB.xlsx | ../input
	ln -sf $< $@

../input/project_records.csv: ../../../build_lihtc/output/project_records.csv | ../input
	ln -sf $< $@

../input/projects.csv: ../../../build_lihtc/output/projects.csv | ../input
	ln -sf $< $@

../input/states.zip: ../../../../data_raw/census_boundaries/2024/cb_2024_us_state_20m.zip | ../input
	ln -sf $< $@

link-inputs: ../input/LIHTCPUB.xlsx ../input/project_records.csv ../input/projects.csv ../input/states.zip
include source.make
include ../../../shared/code/generic.make
