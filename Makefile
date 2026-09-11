include tasks/shared/code/shell_functions.make
.DEFAULT_GOAL := all
.PHONY: all setup
all: tasks/build_lihtc/output/projects.csv tasks/build_lihtc/output/review.csv tasks/prepare_lihtc/report/projects.txt tasks/geocode_lihtc/report/geocodes.txt tasks/build_lihtc/report/project_records.txt tasks/build_lihtc/report/projects.txt tasks/build_lihtc/report/review.txt logbook/logbook.pdf

setup:
	$(MAKE) -C tasks/setup_environment/code

tasks/prepare_lihtc/output/projects.csv: tasks/prepare_lihtc/code/prepare_lihtc.R tasks/prepare_lihtc/code/Makefile tasks/prepare_lihtc/code/source.make data_raw/hud_lihtc_property/2024/lihtcpub.zip
	$(MAKE) -C tasks/prepare_lihtc/code ../output/projects.csv

tasks/geocode_lihtc/temp/request_%.csv: tasks/geocode_lihtc/code/prepare_batch.R tasks/geocode_lihtc/code/Makefile tasks/prepare_lihtc/output/projects.csv
	$(MAKE) -C tasks/geocode_lihtc/code ../temp/request_$*.csv

data_raw/census_geocoder/2026-09-11/response_%.csv: | tasks/geocode_lihtc/temp/request_%.csv
	$(MAKE) -C tasks/geocode_lihtc/code ../../../data_raw/census_geocoder/2026-09-11/response_$*.csv

tasks/geocode_lihtc/output/geocodes.csv: tasks/geocode_lihtc/code/parse_responses.R tasks/geocode_lihtc/code/Makefile tasks/geocode_lihtc/code/census_request.make data_raw/census_geocoder/2026-09-11/sha256.txt tasks/prepare_lihtc/output/projects.csv data_raw/census_geocoder/2026-09-11/response_1.csv data_raw/census_geocoder/2026-09-11/response_2.csv data_raw/census_geocoder/2026-09-11/response_3.csv
	$(MAKE) -C tasks/geocode_lihtc/code ../output/geocodes.csv

tasks/build_lihtc/output/project_records.csv: tasks/build_lihtc/code/build_lihtc.R tasks/build_lihtc/code/Makefile tasks/prepare_lihtc/output/projects.csv tasks/geocode_lihtc/output/geocodes.csv
	$(MAKE) -C tasks/build_lihtc/code ../output/project_records.csv

tasks/build_lihtc/output/projects.csv: tasks/build_lihtc/code/select_projects.R tasks/build_lihtc/code/Makefile tasks/build_lihtc/output/project_records.csv
	$(MAKE) -C tasks/build_lihtc/code ../output/projects.csv

tasks/build_lihtc/output/review.csv: tasks/build_lihtc/code/review_projects.R tasks/build_lihtc/code/Makefile tasks/build_lihtc/output/project_records.csv
	$(MAKE) -C tasks/build_lihtc/code ../output/review.csv

tasks/build_lihtc/output/summary.tex: tasks/build_lihtc/code/summarize_projects.R tasks/build_lihtc/output/project_records.csv
	$(MAKE) -C tasks/build_lihtc/code ../output/summary.tex

tasks/prepare_lihtc/report/projects.txt: tasks/prepare_lihtc/output/projects.csv tasks/shared/code/report.R
	$(MAKE) -C tasks/prepare_lihtc/code ../report/projects.txt

tasks/geocode_lihtc/report/geocodes.txt: tasks/geocode_lihtc/output/geocodes.csv tasks/shared/code/report.R
	$(MAKE) -C tasks/geocode_lihtc/code ../report/geocodes.txt

tasks/build_lihtc/report/project_records.txt: tasks/build_lihtc/output/project_records.csv tasks/shared/code/report.R
	$(MAKE) -C tasks/build_lihtc/code ../report/project_records.txt

tasks/build_lihtc/report/projects.txt: tasks/build_lihtc/output/projects.csv tasks/shared/code/report.R
	$(MAKE) -C tasks/build_lihtc/code ../report/projects.txt

tasks/build_lihtc/report/review.txt: tasks/build_lihtc/output/review.csv tasks/shared/code/report.R
	$(MAKE) -C tasks/build_lihtc/code ../report/review.txt

logbook/logbook.pdf: logbook/logbook.tex tasks/build_lihtc/output/summary.tex
	$(MAKE) -C logbook

include tasks/prepare_lihtc/code/source.make
.PRECIOUS: tasks/geocode_lihtc/temp/request_%.csv
