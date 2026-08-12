SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/lihtc_site_address_component_2024_geocoding_crosswalk.parquet \
	../output/lihtc_geocoding_queries_2024.parquet

../output/lihtc_site_address_component_2024_geocoding_crosswalk.parquet: \
		build_lihtc_geocoding_query_crosswalk.R \
		../input/lihtc_site_address_component_2024_compound_adjudicated.parquet \
		../input/lihtc_range_address_reviews.parquet \
		../input/lihtc_final_site_geocoding_readiness.parquet | ../output
	$(R) $<

../output/lihtc_geocoding_queries_2024.parquet: \
		../output/lihtc_site_address_component_2024_geocoding_crosswalk.parquet
	@test -f $@ || $(R) build_lihtc_geocoding_query_crosswalk.R

../input/lihtc_site_address_component_2024_compound_adjudicated.parquet: \
		../../apply_lihtc_compound_address_review/output/lihtc_site_address_component_2024_compound_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_compound_address_review/output/lihtc_site_address_component_2024_compound_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_compound_address_review/output/lihtc_site_address_component_2024_compound_adjudicated.parquet "$@"; \
	fi

../input/lihtc_range_address_reviews.parquet: \
		../../review_lihtc_range_addresses/output/lihtc_range_address_reviews.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../review_lihtc_range_addresses/output/lihtc_range_address_reviews.parquet" ]; then \
		ln -sf ../../review_lihtc_range_addresses/output/lihtc_range_address_reviews.parquet "$@"; \
	fi

../input/lihtc_final_site_geocoding_readiness.parquet: \
		../../audits/audit_lihtc_final_geocoding_readiness/output/lihtc_final_site_geocoding_readiness.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../audits/audit_lihtc_final_geocoding_readiness/output/lihtc_final_site_geocoding_readiness.parquet" ]; then \
		ln -sf ../../audits/audit_lihtc_final_geocoding_readiness/output/lihtc_final_site_geocoding_readiness.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_site_address_component_2024_compound_adjudicated.parquet \
	../input/lihtc_range_address_reviews.parquet \
	../input/lihtc_final_site_geocoding_readiness.parquet

include ../../generic.make
