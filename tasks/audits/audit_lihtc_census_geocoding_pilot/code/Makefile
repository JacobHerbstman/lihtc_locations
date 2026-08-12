SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/lihtc_census_geocoding_pilot_audit.parquet \
	../output/lihtc_census_geocoding_pilot_review_queue.parquet \
	../output/census_geocoding_pilot_summary.md

../output/lihtc_census_geocoding_pilot_audit.parquet: \
	audit_lihtc_census_geocoding_pilot.R \
	../input/lihtc_census_geocoding_pilot.parquet \
	../input/lihtc_census_geocoding_pilot_manifest.parquet \
	../../../../data_raw/census_geocoder/2026-08-12/attempt_02/lihtc_census_geocoding_pilot_input.csv \
	../../../../data_raw/census_geocoder/2026-08-12/attempt_02/lihtc_census_geocoding_pilot_response.csv \
	../../../../data_raw/census_geocoder/2026-08-12/attempt_02/lihtc_census_geocoding_pilot_retrieval.csv | ../output
	$(R) $<

../output/lihtc_census_geocoding_pilot_review_queue.parquet \
../output/census_geocoding_pilot_summary.md: ../output/lihtc_census_geocoding_pilot_audit.parquet
	@test -f $@

../input/lihtc_census_geocoding_pilot.parquet: \
		../../../submit_lihtc_census_geocoding_pilot/output/lihtc_census_geocoding_pilot.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../submit_lihtc_census_geocoding_pilot/output/lihtc_census_geocoding_pilot.parquet" ]; then \
		ln -sf ../../../submit_lihtc_census_geocoding_pilot/output/lihtc_census_geocoding_pilot.parquet "$@"; \
	fi

../input/lihtc_census_geocoding_pilot_manifest.parquet: \
		../../../prepare_lihtc_census_geocoding_pilot/output/lihtc_census_geocoding_pilot_manifest.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../prepare_lihtc_census_geocoding_pilot/output/lihtc_census_geocoding_pilot_manifest.parquet" ]; then \
		ln -sf ../../../prepare_lihtc_census_geocoding_pilot/output/lihtc_census_geocoding_pilot_manifest.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_census_geocoding_pilot.parquet \
	../input/lihtc_census_geocoding_pilot_manifest.parquet

include ../../../generic.make
