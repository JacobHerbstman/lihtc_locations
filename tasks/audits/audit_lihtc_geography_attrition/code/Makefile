SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/lihtc_geography_attrition.parquet \
	../output/geography_attrition_summary.md

../output/lihtc_geography_attrition.parquet: \
	audit_lihtc_geography_attrition.R \
	../input/lihtc_development_2024_low_income_share_adjudicated.parquet \
	../input/lihtc_development_site_2024_low_income_share_adjudicated.parquet \
	../input/lihtc_site_address_component_2024_geocoding_crosswalk.parquet \
	../input/lihtc_geocoding_queries_2024.parquet | ../output
	$(R) $<

../output/geography_attrition_summary.md: ../output/lihtc_geography_attrition.parquet
	@test -f $@

../input/lihtc_development_2024_low_income_share_adjudicated.parquet: \
		../../../apply_lihtc_low_income_share_review/output/lihtc_development_2024_low_income_share_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_low_income_share_review/output/lihtc_development_2024_low_income_share_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_low_income_share_review/output/lihtc_development_2024_low_income_share_adjudicated.parquet "$@"; \
	fi


../input/lihtc_development_site_2024_low_income_share_adjudicated.parquet: \
		../../../apply_lihtc_low_income_share_review/output/lihtc_development_site_2024_low_income_share_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_low_income_share_review/output/lihtc_development_site_2024_low_income_share_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_low_income_share_review/output/lihtc_development_site_2024_low_income_share_adjudicated.parquet "$@"; \
	fi

../input/lihtc_site_address_component_2024_geocoding_crosswalk.parquet: \
		../../../build_lihtc_geocoding_query_crosswalk/output/lihtc_site_address_component_2024_geocoding_crosswalk.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../build_lihtc_geocoding_query_crosswalk/output/lihtc_site_address_component_2024_geocoding_crosswalk.parquet" ]; then \
		ln -sf ../../../build_lihtc_geocoding_query_crosswalk/output/lihtc_site_address_component_2024_geocoding_crosswalk.parquet "$@"; \
	fi

../input/lihtc_geocoding_queries_2024.parquet: \
		../../../build_lihtc_geocoding_query_crosswalk/output/lihtc_geocoding_queries_2024.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../build_lihtc_geocoding_query_crosswalk/output/lihtc_geocoding_queries_2024.parquet" ]; then \
		ln -sf ../../../build_lihtc_geocoding_query_crosswalk/output/lihtc_geocoding_queries_2024.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_development_2024_low_income_share_adjudicated.parquet \
	../input/lihtc_development_site_2024_low_income_share_adjudicated.parquet \
	../input/lihtc_site_address_component_2024_geocoding_crosswalk.parquet \
	../input/lihtc_geocoding_queries_2024.parquet

include ../../../generic.make
