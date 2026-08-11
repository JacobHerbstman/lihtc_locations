SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/lihtc_source_site_exception_assignments.parquet \
	../output/lihtc_source_site_exception_episodes.parquet

../output/lihtc_source_site_exception_assignments.parquet: \
		prepare_lihtc_source_site_exceptions.R \
		source_exception_evidence_updates.csv \
		../input/lihtc_development_2024_single_address_adjudicated.parquet \
		../input/lihtc_project_episode_2024_single_address_adjudicated.parquet \
		../input/lihtc_development_site_2024_single_address_adjudicated.parquet \
		../input/lihtc_multisite_2024_raw_text.parquet \
		../input/lihtc_identical_address_set_members.parquet \
		../input/lihtc_identical_address_set_reviews.parquet \
		../input/lihtc_cross_development_address_decisions.parquet | ../output
	$(R) $<

../output/lihtc_source_site_exception_episodes.parquet: \
		../output/lihtc_source_site_exception_assignments.parquet
	@test -f $@

../input/lihtc_development_2024_single_address_adjudicated.parquet: \
		../../apply_lihtc_single_address_review/output/lihtc_development_2024_single_address_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_single_address_review/output/lihtc_development_2024_single_address_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_single_address_review/output/lihtc_development_2024_single_address_adjudicated.parquet "$@"; \
	fi

../input/lihtc_project_episode_2024_single_address_adjudicated.parquet: \
		../../apply_lihtc_single_address_review/output/lihtc_project_episode_2024_single_address_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_single_address_review/output/lihtc_project_episode_2024_single_address_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_single_address_review/output/lihtc_project_episode_2024_single_address_adjudicated.parquet "$@"; \
	fi

../input/lihtc_development_site_2024_single_address_adjudicated.parquet: \
		../../apply_lihtc_single_address_review/output/lihtc_development_site_2024_single_address_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_single_address_review/output/lihtc_development_site_2024_single_address_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_single_address_review/output/lihtc_development_site_2024_single_address_adjudicated.parquet "$@"; \
	fi

../input/lihtc_multisite_2024_raw_text.parquet: \
		../../prepare_lihtc_multisite/output/lihtc_multisite_2024_raw_text.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../prepare_lihtc_multisite/output/lihtc_multisite_2024_raw_text.parquet" ]; then \
		ln -sf ../../prepare_lihtc_multisite/output/lihtc_multisite_2024_raw_text.parquet "$@"; \
	fi

../input/lihtc_identical_address_set_members.parquet: \
		../../audits/audit_lihtc_identical_address_sets/output/lihtc_identical_address_set_members.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../audits/audit_lihtc_identical_address_sets/output/lihtc_identical_address_set_members.parquet" ]; then \
		ln -sf ../../audits/audit_lihtc_identical_address_sets/output/lihtc_identical_address_set_members.parquet "$@"; \
	fi

../input/lihtc_identical_address_set_reviews.parquet: \
		../../review_lihtc_identical_address_sets/output/lihtc_identical_address_set_reviews.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../review_lihtc_identical_address_sets/output/lihtc_identical_address_set_reviews.parquet" ]; then \
		ln -sf ../../review_lihtc_identical_address_sets/output/lihtc_identical_address_set_reviews.parquet "$@"; \
	fi

../input/lihtc_cross_development_address_decisions.parquet: \
		../../review_lihtc_cross_development_addresses/output/lihtc_cross_development_address_decisions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../review_lihtc_cross_development_addresses/output/lihtc_cross_development_address_decisions.parquet" ]; then \
		ln -sf ../../review_lihtc_cross_development_addresses/output/lihtc_cross_development_address_decisions.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_development_2024_single_address_adjudicated.parquet \
	../input/lihtc_project_episode_2024_single_address_adjudicated.parquet \
	../input/lihtc_development_site_2024_single_address_adjudicated.parquet \
	../input/lihtc_multisite_2024_raw_text.parquet \
	../input/lihtc_identical_address_set_members.parquet \
	../input/lihtc_identical_address_set_reviews.parquet \
	../input/lihtc_cross_development_address_decisions.parquet

include ../../generic.make
