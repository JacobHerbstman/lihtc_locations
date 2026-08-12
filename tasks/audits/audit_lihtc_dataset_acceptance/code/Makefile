SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/lihtc_dataset_acceptance_observations.parquet \
	../output/lihtc_dataset_acceptance_status_counts.parquet \
	../output/dataset_acceptance_summary.md

../output/lihtc_dataset_acceptance_observations.parquet: \
		audit_lihtc_dataset_acceptance.R \
		../input/lihtc_development_2024_low_income_share_adjudicated.parquet \
		../input/lihtc_project_episode_2024_low_income_share_adjudicated.parquet \
		../input/lihtc_development_site_2024_low_income_share_adjudicated.parquet \
		../input/lihtc_excluded_episode_2024_unit_scope_evidence.parquet \
		../input/lihtc_project_episode_2024_raw_built.parquet \
		../input/lihtc_development_site_2024_raw_built.parquet \
		../input/lihtc_development_site_2024_pre_singleton.parquet \
		../input/lihtc_source_site_member_decisions.parquet \
		../input/lihtc_singleton_identity_scope_site_decisions.parquet \
		../input/lihtc_site_address_component_2024_geocoding_crosswalk.parquet \
		../input/lihtc_geocoding_queries_2024.parquet \
		../input/lihtc_census_geocoding_pilot.parquet \
		../input/lihtc_census_geocoding_pilot_review_queue.parquet | ../output
	$(R) $<

../output/lihtc_dataset_acceptance_status_counts.parquet: \
		../output/lihtc_dataset_acceptance_observations.parquet \
		audit_lihtc_dataset_acceptance.R
	@if [ ! -f "$@" ]; then $(R) audit_lihtc_dataset_acceptance.R; fi

../output/dataset_acceptance_summary.md: \
		../output/lihtc_dataset_acceptance_status_counts.parquet \
		audit_lihtc_dataset_acceptance.R
	@if [ ! -f "$@" ]; then $(R) audit_lihtc_dataset_acceptance.R; fi

../input/lihtc_development_2024_low_income_share_adjudicated.parquet: \
		../../../apply_lihtc_low_income_share_review/output/lihtc_development_2024_low_income_share_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_low_income_share_review/output/lihtc_development_2024_low_income_share_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_low_income_share_review/output/lihtc_development_2024_low_income_share_adjudicated.parquet "$@"; \
	fi

../input/lihtc_project_episode_2024_low_income_share_adjudicated.parquet: \
		../../../apply_lihtc_low_income_share_review/output/lihtc_project_episode_2024_low_income_share_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_low_income_share_review/output/lihtc_project_episode_2024_low_income_share_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_low_income_share_review/output/lihtc_project_episode_2024_low_income_share_adjudicated.parquet "$@"; \
	fi

../input/lihtc_development_site_2024_low_income_share_adjudicated.parquet: \
		../../../apply_lihtc_low_income_share_review/output/lihtc_development_site_2024_low_income_share_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_low_income_share_review/output/lihtc_development_site_2024_low_income_share_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_low_income_share_review/output/lihtc_development_site_2024_low_income_share_adjudicated.parquet "$@"; \
	fi

../input/lihtc_excluded_episode_2024_unit_scope_evidence.parquet: \
		../../../apply_lihtc_unit_scope_review/output/lihtc_excluded_episode_2024_unit_scope_evidence.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_unit_scope_review/output/lihtc_excluded_episode_2024_unit_scope_evidence.parquet" ]; then \
		ln -sf ../../../apply_lihtc_unit_scope_review/output/lihtc_excluded_episode_2024_unit_scope_evidence.parquet "$@"; \
	fi

../input/lihtc_project_episode_2024_raw_built.parquet: \
		../../../build_lihtc_development/output/lihtc_project_episode_2024.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../build_lihtc_development/output/lihtc_project_episode_2024.parquet" ]; then \
		ln -sf ../../../build_lihtc_development/output/lihtc_project_episode_2024.parquet "$@"; \
	fi

../input/lihtc_development_site_2024_raw_built.parquet: \
		../../../build_lihtc_development/output/lihtc_development_site_2024.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../build_lihtc_development/output/lihtc_development_site_2024.parquet" ]; then \
		ln -sf ../../../build_lihtc_development/output/lihtc_development_site_2024.parquet "$@"; \
	fi

../input/lihtc_development_site_2024_pre_singleton.parquet: \
		../../../apply_lihtc_mixed_site_identity_review/output/lihtc_development_site_2024_mixed_site_identity_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_mixed_site_identity_review/output/lihtc_development_site_2024_mixed_site_identity_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_mixed_site_identity_review/output/lihtc_development_site_2024_mixed_site_identity_adjudicated.parquet "$@"; \
	fi

../input/lihtc_source_site_member_decisions.parquet: \
		../../../review_lihtc_source_site_exceptions/output/lihtc_source_site_member_decisions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../review_lihtc_source_site_exceptions/output/lihtc_source_site_member_decisions.parquet" ]; then \
		ln -sf ../../../review_lihtc_source_site_exceptions/output/lihtc_source_site_member_decisions.parquet "$@"; \
	fi

../input/lihtc_singleton_identity_scope_site_decisions.parquet: \
		../../../review_lihtc_singleton_identity_scope/output/lihtc_singleton_identity_scope_site_decisions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../review_lihtc_singleton_identity_scope/output/lihtc_singleton_identity_scope_site_decisions.parquet" ]; then \
		ln -sf ../../../review_lihtc_singleton_identity_scope/output/lihtc_singleton_identity_scope_site_decisions.parquet "$@"; \
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

../input/lihtc_census_geocoding_pilot.parquet: \
		../../../submit_lihtc_census_geocoding_pilot/output/lihtc_census_geocoding_pilot.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../submit_lihtc_census_geocoding_pilot/output/lihtc_census_geocoding_pilot.parquet" ]; then \
		ln -sf ../../../submit_lihtc_census_geocoding_pilot/output/lihtc_census_geocoding_pilot.parquet "$@"; \
	fi

../input/lihtc_census_geocoding_pilot_review_queue.parquet: \
		../../audit_lihtc_census_geocoding_pilot/output/lihtc_census_geocoding_pilot_review_queue.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../audit_lihtc_census_geocoding_pilot/output/lihtc_census_geocoding_pilot_review_queue.parquet" ]; then \
		ln -sf ../../audit_lihtc_census_geocoding_pilot/output/lihtc_census_geocoding_pilot_review_queue.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_development_2024_low_income_share_adjudicated.parquet \
	../input/lihtc_project_episode_2024_low_income_share_adjudicated.parquet \
	../input/lihtc_development_site_2024_low_income_share_adjudicated.parquet \
	../input/lihtc_excluded_episode_2024_unit_scope_evidence.parquet \
	../input/lihtc_project_episode_2024_raw_built.parquet \
	../input/lihtc_development_site_2024_raw_built.parquet \
	../input/lihtc_development_site_2024_pre_singleton.parquet \
	../input/lihtc_source_site_member_decisions.parquet \
	../input/lihtc_singleton_identity_scope_site_decisions.parquet \
	../input/lihtc_site_address_component_2024_geocoding_crosswalk.parquet \
	../input/lihtc_geocoding_queries_2024.parquet \
	../input/lihtc_census_geocoding_pilot.parquet \
	../input/lihtc_census_geocoding_pilot_review_queue.parquet

include ../../../generic.make
