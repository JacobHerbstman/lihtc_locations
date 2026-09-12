SHELL = bash
include ../../shared/code/shell_functions.make

DISTANCE_DIAGNOSTIC_METERS := 500
all: ../output/project_records.csv ../output/projects.csv ../output/confident_projects.csv \
    ../output/review.csv ../output/summary.tex

include ../../shared/code/generic.make

../output/project_records.csv: build_lihtc.R ../input/projects.csv ../input/geocodes.csv \
    ../../shared/code/save_data.R Makefile | ../output ../report
	$(R) $< $(DISTANCE_DIAGNOSTIC_METERS)

../output/projects.csv: select_projects.R ../output/project_records.csv ../../shared/code/save_data.R \
    Makefile | ../output ../report
	$(R) $<

../output/confident_projects.csv: select_confident.R ../output/projects.csv ../../shared/code/save_data.R \
    Makefile | ../output ../report
	$(R) $<

../output/review.csv: review_projects.R ../output/project_records.csv ../../shared/code/save_data.R \
    Makefile | ../output ../report
	$(R) $<

../output/summary.tex: summarize_projects.R ../output/project_records.csv ../output/projects.csv Makefile \
    | ../output
	$(R) $<

../input/projects.csv: ../../prepare_lihtc/output/projects.csv | ../input
	ln -sf $< $@

../input/geocodes.csv: ../../geocode_lihtc/output/geocodes.csv | ../input
	ln -sf $< $@
