SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: ../output/lihtc_census_geocoding_pilot.parquet

../output/lihtc_census_geocoding_pilot.parquet: \
	submit_lihtc_census_geocoding_pilot.R \
	../input/lihtc_census_geocoding_pilot_input.csv \
	../input/lihtc_census_geocoding_pilot_manifest.parquet \
	../../../data_raw/census_geocoder/2026-08-12/attempt_01/lihtc_census_geocoding_pilot_input.csv \
	../../../data_raw/census_geocoder/2026-08-12/attempt_01/lihtc_census_geocoding_pilot_response.csv \
	../../../data_raw/census_geocoder/2026-08-12/attempt_01/lihtc_census_geocoding_pilot_retrieval.csv \
	../../../data_raw/census_geocoder/2026-08-12/attempt_02/lihtc_census_geocoding_pilot_input.csv \
	../../../data_raw/census_geocoder/2026-08-12/attempt_02/lihtc_census_geocoding_pilot_response.csv \
	../../../data_raw/census_geocoder/2026-08-12/attempt_02/lihtc_census_geocoding_pilot_retrieval.csv | ../output
	$(R) $<

../input/lihtc_census_geocoding_pilot_input.csv: \
		../../prepare_lihtc_census_geocoding_pilot/output/lihtc_census_geocoding_pilot_input.csv | ../input
	@if [ "$$(readlink "$@")" != "../../prepare_lihtc_census_geocoding_pilot/output/lihtc_census_geocoding_pilot_input.csv" ]; then \
		ln -sf ../../prepare_lihtc_census_geocoding_pilot/output/lihtc_census_geocoding_pilot_input.csv "$@"; \
	fi

../input/lihtc_census_geocoding_pilot_manifest.parquet: \
		../../prepare_lihtc_census_geocoding_pilot/output/lihtc_census_geocoding_pilot_manifest.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../prepare_lihtc_census_geocoding_pilot/output/lihtc_census_geocoding_pilot_manifest.parquet" ]; then \
		ln -sf ../../prepare_lihtc_census_geocoding_pilot/output/lihtc_census_geocoding_pilot_manifest.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_census_geocoding_pilot_input.csv \
	../input/lihtc_census_geocoding_pilot_manifest.parquet

include ../../generic.make
