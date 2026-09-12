SHELL = bash
include ../../shared/code/shell_functions.make

all: ../output/geocodes.csv

include ../../shared/code/generic.make

../output/geocodes.csv: parse_responses.R ../input/response_1.csv ../input/response_2.csv \
    ../input/response_3.csv ../input/projects.csv ../../../data_raw/census_geocoder/2026-09-11/sha256.txt \
    ../../shared/code/save_data.R Makefile | ../output ../report
	(cd ../../../data_raw/census_geocoder/2026-09-11 && shasum -a 256 -c sha256.txt)
	$(R) $<

../temp/request_%.csv: prepare_batch.R ../input/projects.csv Makefile | ../temp
	$(R) $< $*

# Saved responses are immutable; parsing also checks they match the input addresses.
../../../data_raw/census_geocoder/2026-09-11/response_%.csv: | ../temp/request_%.csv request_census.sh \
    validate_response.R ../temp
	bash request_census.sh $*

../input/projects.csv: ../../prepare_lihtc/output/projects.csv | ../input
	ln -sf $< $@

../input/response_%.csv: ../../../data_raw/census_geocoder/2026-09-11/response_%.csv | ../input
	ln -sf $< $@

.PRECIOUS: ../temp/request_%.csv
