SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/lihtc_census_geocoding_pilot_input.csv \
	../output/lihtc_census_geocoding_pilot_manifest.parquet \
	../output/pilot_safety_check.md

../output/lihtc_census_geocoding_pilot_input.csv: \
	prepare_lihtc_census_geocoding_pilot.R \
	../input/lihtc_development_2024_unit_scope_adjudicated.parquet \
	../input/lihtc_development_site_2024_unit_scope_adjudicated.parquet \
	../input/lihtc_site_address_component_2024_geocoding_crosswalk.parquet \
	../input/lihtc_geocoding_queries_2024.parquet | ../output
	$(R) $<

../output/lihtc_census_geocoding_pilot_manifest.parquet \
../output/pilot_safety_check.md: ../output/lihtc_census_geocoding_pilot_input.csv
	@test -f $@

../input/lihtc_development_2024_unit_scope_adjudicated.parquet: \
		../../apply_lihtc_unit_scope_review/output/lihtc_development_2024_unit_scope_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_unit_scope_review/output/lihtc_development_2024_unit_scope_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_unit_scope_review/output/lihtc_development_2024_unit_scope_adjudicated.parquet "$@"; \
	fi

../input/lihtc_development_site_2024_unit_scope_adjudicated.parquet: \
		../../apply_lihtc_unit_scope_review/output/lihtc_development_site_2024_unit_scope_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_unit_scope_review/output/lihtc_development_site_2024_unit_scope_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_unit_scope_review/output/lihtc_development_site_2024_unit_scope_adjudicated.parquet "$@"; \
	fi

../input/lihtc_geocoding_queries_2024.parquet: \
		../../build_lihtc_geocoding_query_crosswalk/output/lihtc_geocoding_queries_2024.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../build_lihtc_geocoding_query_crosswalk/output/lihtc_geocoding_queries_2024.parquet" ]; then \
		ln -sf ../../build_lihtc_geocoding_query_crosswalk/output/lihtc_geocoding_queries_2024.parquet "$@"; \
	fi

../input/lihtc_site_address_component_2024_geocoding_crosswalk.parquet: \
		../../build_lihtc_geocoding_query_crosswalk/output/lihtc_site_address_component_2024_geocoding_crosswalk.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../build_lihtc_geocoding_query_crosswalk/output/lihtc_site_address_component_2024_geocoding_crosswalk.parquet" ]; then \
		ln -sf ../../build_lihtc_geocoding_query_crosswalk/output/lihtc_site_address_component_2024_geocoding_crosswalk.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_development_2024_unit_scope_adjudicated.parquet \
	../input/lihtc_development_site_2024_unit_scope_adjudicated.parquet \
	../input/lihtc_site_address_component_2024_geocoding_crosswalk.parquet \
	../input/lihtc_geocoding_queries_2024.parquet

include ../../generic.make
