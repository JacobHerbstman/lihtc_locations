SHELL = bash
include ../../shared/code/shell_functions.make

all: ../output/project_records.csv ../output/projects.csv ../output/sample_sizes.csv \
    ../output/summary_statistics.csv ../output/category_counts.csv ../output/summary.tex

include ../../shared/code/generic.make

../output/project_records.csv: build_lihtc.R ../input/projects.csv \
    ../../shared/code/save_data.R Makefile | ../output ../report
	$(R) $<

../output/projects.csv: select_projects.R ../output/project_records.csv \
    ../../shared/code/save_data.R Makefile | ../output ../report
	$(R) $<

../output/sample_sizes.csv: sample_sizes.R ../output/projects.csv \
    ../../shared/code/save_data.R Makefile | ../output ../report
	$(R) $<

../output/summary_statistics.csv: summary_statistics.R ../output/projects.csv \
    ../../shared/code/save_data.R Makefile | ../output ../report
	$(R) $<

../output/category_counts.csv: category_counts.R ../output/projects.csv \
    ../../shared/code/save_data.R Makefile | ../output ../report
	$(R) $<

../output/summary.tex: summarize_projects.R ../output/project_records.csv \
    ../output/projects.csv ../output/sample_sizes.csv ../output/summary_statistics.csv Makefile | ../output
	$(R) $<

../input/projects.csv: ../../prepare_lihtc/output/projects.csv | ../input
	ln -sf $< $@
