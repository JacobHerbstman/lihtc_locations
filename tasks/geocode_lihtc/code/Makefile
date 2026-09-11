include ../../shared/code/shell_functions.make
all: ../output/geocodes.csv ../report/geocodes.txt

../output/geocodes.csv: parse_responses.R ../input/response_1.csv ../input/response_2.csv ../input/response_3.csv ../input/projects.csv ../../../data_raw/census_geocoder/2026-09-11/sha256.txt census_request.make Makefile | ../output
	(cd ../../../data_raw/census_geocoder/2026-09-11 && shasum -a 256 -c sha256.txt)
	$(R) $<

../report/geocodes.txt: ../output/geocodes.csv ../../shared/code/report.R | ../report
	$(R) ../../shared/code/report.R $< $@

../temp/request_%.csv: prepare_batch.R ../input/projects.csv Makefile | ../temp
	$(R) $< $*

../input/projects.csv: ../../prepare_lihtc/output/projects.csv | ../input
	ln -sf $< $@

../input/response_%.csv: ../../../data_raw/census_geocoder/2026-09-11/response_%.csv | ../input
	ln -sf $< $@

link-inputs: ../input/projects.csv ../input/response_1.csv ../input/response_2.csv ../input/response_3.csv
include census_request.make
include ../../shared/code/generic.make
.PRECIOUS: ../temp/request_%.csv
