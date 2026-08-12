SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: ../output/lihtc_geocoding_query_crosswalk_audit.parquet

../output/lihtc_geocoding_query_crosswalk_audit.parquet: \
		audit_lihtc_geocoding_query_crosswalk.R \
		../input/lihtc_final_site_geocoding_readiness.parquet \
		../input/lihtc_compound_address_questions.parquet \
		../input/lihtc_compound_address_question_reviews.parquet \
		../input/lihtc_compound_address_component_reviews.parquet \
		../input/lihtc_site_address_component_2024_compound_adjudicated.parquet \
		../input/lihtc_range_address_questions.parquet \
		../input/lihtc_range_address_reviews.parquet \
		../input/lihtc_site_address_component_2024_geocoding_crosswalk.parquet \
		../input/lihtc_geocoding_queries_2024.parquet | ../output
	$(R) $<

../input/lihtc_final_site_geocoding_readiness.parquet: \
		../../audit_lihtc_final_geocoding_readiness/output/lihtc_final_site_geocoding_readiness.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../audit_lihtc_final_geocoding_readiness/output/lihtc_final_site_geocoding_readiness.parquet" ]; then \
		ln -sf ../../audit_lihtc_final_geocoding_readiness/output/lihtc_final_site_geocoding_readiness.parquet "$@"; \
	fi

../input/lihtc_compound_address_questions.parquet: \
		../../../prepare_lihtc_compound_address_review/output/lihtc_compound_address_questions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../prepare_lihtc_compound_address_review/output/lihtc_compound_address_questions.parquet" ]; then \
		ln -sf ../../../prepare_lihtc_compound_address_review/output/lihtc_compound_address_questions.parquet "$@"; \
	fi

../input/lihtc_compound_address_question_reviews.parquet: \
		../../../review_lihtc_compound_addresses/output/lihtc_compound_address_question_reviews.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../review_lihtc_compound_addresses/output/lihtc_compound_address_question_reviews.parquet" ]; then \
		ln -sf ../../../review_lihtc_compound_addresses/output/lihtc_compound_address_question_reviews.parquet "$@"; \
	fi

../input/lihtc_compound_address_component_reviews.parquet: \
		../../../review_lihtc_compound_addresses/output/lihtc_compound_address_component_reviews.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../review_lihtc_compound_addresses/output/lihtc_compound_address_component_reviews.parquet" ]; then \
		ln -sf ../../../review_lihtc_compound_addresses/output/lihtc_compound_address_component_reviews.parquet "$@"; \
	fi

../input/lihtc_site_address_component_2024_compound_adjudicated.parquet: \
		../../../apply_lihtc_compound_address_review/output/lihtc_site_address_component_2024_compound_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_compound_address_review/output/lihtc_site_address_component_2024_compound_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_compound_address_review/output/lihtc_site_address_component_2024_compound_adjudicated.parquet "$@"; \
	fi

../input/lihtc_range_address_questions.parquet: \
		../../../prepare_lihtc_range_address_review/output/lihtc_range_address_questions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../prepare_lihtc_range_address_review/output/lihtc_range_address_questions.parquet" ]; then \
		ln -sf ../../../prepare_lihtc_range_address_review/output/lihtc_range_address_questions.parquet "$@"; \
	fi

../input/lihtc_range_address_reviews.parquet: \
		../../../review_lihtc_range_addresses/output/lihtc_range_address_reviews.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../review_lihtc_range_addresses/output/lihtc_range_address_reviews.parquet" ]; then \
		ln -sf ../../../review_lihtc_range_addresses/output/lihtc_range_address_reviews.parquet "$@"; \
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
	../input/lihtc_final_site_geocoding_readiness.parquet \
	../input/lihtc_compound_address_questions.parquet \
	../input/lihtc_compound_address_question_reviews.parquet \
	../input/lihtc_compound_address_component_reviews.parquet \
	../input/lihtc_site_address_component_2024_compound_adjudicated.parquet \
	../input/lihtc_range_address_questions.parquet \
	../input/lihtc_range_address_reviews.parquet \
	../input/lihtc_site_address_component_2024_geocoding_crosswalk.parquet \
	../input/lihtc_geocoding_queries_2024.parquet

include ../../../generic.make
