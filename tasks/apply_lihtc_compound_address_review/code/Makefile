SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: ../output/lihtc_site_address_component_2024_compound_adjudicated.parquet

../output/lihtc_site_address_component_2024_compound_adjudicated.parquet: \
		apply_lihtc_compound_address_review.R \
		../input/lihtc_final_site_geocoding_readiness.parquet \
		../input/lihtc_compound_address_question_reviews.parquet \
		../input/lihtc_compound_address_component_reviews.parquet | ../output
	$(R) $<

../input/lihtc_final_site_geocoding_readiness.parquet: \
		../../audits/audit_lihtc_final_geocoding_readiness/output/lihtc_final_site_geocoding_readiness.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../audits/audit_lihtc_final_geocoding_readiness/output/lihtc_final_site_geocoding_readiness.parquet" ]; then \
		ln -sf ../../audits/audit_lihtc_final_geocoding_readiness/output/lihtc_final_site_geocoding_readiness.parquet "$@"; \
	fi

../input/lihtc_compound_address_question_reviews.parquet: \
		../../review_lihtc_compound_addresses/output/lihtc_compound_address_question_reviews.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../review_lihtc_compound_addresses/output/lihtc_compound_address_question_reviews.parquet" ]; then \
		ln -sf ../../review_lihtc_compound_addresses/output/lihtc_compound_address_question_reviews.parquet "$@"; \
	fi

../input/lihtc_compound_address_component_reviews.parquet: \
		../../review_lihtc_compound_addresses/output/lihtc_compound_address_component_reviews.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../review_lihtc_compound_addresses/output/lihtc_compound_address_component_reviews.parquet" ]; then \
		ln -sf ../../review_lihtc_compound_addresses/output/lihtc_compound_address_component_reviews.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_final_site_geocoding_readiness.parquet \
	../input/lihtc_compound_address_question_reviews.parquet \
	../input/lihtc_compound_address_component_reviews.parquet

include ../../generic.make
