include ../../shared/code/shell_functions.make
DISTANCE_REVIEW_METERS := 500
all: ../output/summary.tex ../output/project_records.csv ../output/projects.csv ../output/confident_projects.csv ../output/review.csv ../report/project_records.txt ../report/projects.txt ../report/confident_projects.txt ../report/review.txt

../output/project_records.csv: build_lihtc.R ../input/projects.csv ../input/geocodes.csv Makefile | ../output
	$(R) $< $(DISTANCE_REVIEW_METERS)

../output/projects.csv: select_projects.R ../output/project_records.csv Makefile | ../output
	$(R) $<

../output/confident_projects.csv: select_confident.R ../output/projects.csv Makefile | ../output
	$(R) $<

../output/review.csv: review_projects.R ../output/project_records.csv Makefile | ../output
	$(R) $<

../output/summary.tex: summarize_projects.R ../output/project_records.csv ../output/projects.csv | ../output
	$(R) $<

../report/%.txt: ../output/%.csv ../../shared/code/report.R | ../report
	$(R) ../../shared/code/report.R $< $@

../input/projects.csv: ../../prepare_lihtc/output/projects.csv | ../input
	ln -sf $< $@

../input/geocodes.csv: ../../geocode_lihtc/output/geocodes.csv | ../input
	ln -sf $< $@

link-inputs: ../input/projects.csv ../input/geocodes.csv
include ../../shared/code/generic.make
