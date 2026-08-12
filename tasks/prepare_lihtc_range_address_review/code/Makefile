SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: ../output/lihtc_range_address_questions.parquet

../output/lihtc_range_address_questions.parquet: \
		prepare_lihtc_range_address_review.R \
		../input/lihtc_site_address_component_2024_compound_adjudicated.parquet \
		../input/lihtc_final_site_geocoding_readiness.parquet | ../output
	$(R) $<

../input/lihtc_site_address_component_2024_compound_adjudicated.parquet: \
		../../apply_lihtc_compound_address_review/output/lihtc_site_address_component_2024_compound_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_compound_address_review/output/lihtc_site_address_component_2024_compound_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_compound_address_review/output/lihtc_site_address_component_2024_compound_adjudicated.parquet "$@"; \
	fi

../input/lihtc_final_site_geocoding_readiness.parquet: \
		../../audits/audit_lihtc_final_geocoding_readiness/output/lihtc_final_site_geocoding_readiness.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../audits/audit_lihtc_final_geocoding_readiness/output/lihtc_final_site_geocoding_readiness.parquet" ]; then \
		ln -sf ../../audits/audit_lihtc_final_geocoding_readiness/output/lihtc_final_site_geocoding_readiness.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_site_address_component_2024_compound_adjudicated.parquet \
	../input/lihtc_final_site_geocoding_readiness.parquet

include ../../generic.make
