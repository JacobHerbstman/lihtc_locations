SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: ../output/lihtc_acceptance_review_routing.parquet ../output/lihtc_acceptance_review_routing_status_counts.parquet

../output/lihtc_acceptance_review_routing.parquet: audit_lihtc_acceptance_review_routing.R \
	../input/lihtc_dataset_acceptance_observations.parquet \
	../input/lihtc_development_2024_low_income_share_adjudicated.parquet \
	../input/lihtc_project_episode_2024_low_income_share_adjudicated.parquet \
	../input/lihtc_development_site_2024_low_income_share_adjudicated.parquet \
	../input/lihtc_shared_site_network_development_members.parquet \
	../input/lihtc_no_site_development_questions.parquet \
	../input/lihtc_site_exception_questions.parquet | ../output
	$(R) $<

../output/lihtc_acceptance_review_routing_status_counts.parquet: ../output/lihtc_acceptance_review_routing.parquet
	@if [ ! -f "$@" ]; then $(R) audit_lihtc_acceptance_review_routing.R; fi

../input/lihtc_dataset_acceptance_observations.parquet: ../../../audits/audit_lihtc_dataset_acceptance/output/lihtc_dataset_acceptance_observations.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../audits/audit_lihtc_dataset_acceptance/output/lihtc_dataset_acceptance_observations.parquet" ]; then ln -sf ../../../audits/audit_lihtc_dataset_acceptance/output/lihtc_dataset_acceptance_observations.parquet "$@"; fi

../input/lihtc_development_2024_low_income_share_adjudicated.parquet: ../../../apply_lihtc_low_income_share_review/output/lihtc_development_2024_low_income_share_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_low_income_share_review/output/lihtc_development_2024_low_income_share_adjudicated.parquet" ]; then ln -sf ../../../apply_lihtc_low_income_share_review/output/lihtc_development_2024_low_income_share_adjudicated.parquet "$@"; fi

../input/lihtc_project_episode_2024_low_income_share_adjudicated.parquet: ../../../apply_lihtc_low_income_share_review/output/lihtc_project_episode_2024_low_income_share_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_low_income_share_review/output/lihtc_project_episode_2024_low_income_share_adjudicated.parquet" ]; then ln -sf ../../../apply_lihtc_low_income_share_review/output/lihtc_project_episode_2024_low_income_share_adjudicated.parquet "$@"; fi

../input/lihtc_development_site_2024_low_income_share_adjudicated.parquet: ../../../apply_lihtc_low_income_share_review/output/lihtc_development_site_2024_low_income_share_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_low_income_share_review/output/lihtc_development_site_2024_low_income_share_adjudicated.parquet" ]; then ln -sf ../../../apply_lihtc_low_income_share_review/output/lihtc_development_site_2024_low_income_share_adjudicated.parquet "$@"; fi

../input/lihtc_shared_site_network_development_members.parquet: ../../../prepare_lihtc_shared_site_network_review/output/lihtc_shared_site_network_development_members.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../prepare_lihtc_shared_site_network_review/output/lihtc_shared_site_network_development_members.parquet" ]; then ln -sf ../../../prepare_lihtc_shared_site_network_review/output/lihtc_shared_site_network_development_members.parquet "$@"; fi

../input/lihtc_no_site_development_questions.parquet: ../../../prepare_lihtc_no_site_development_review/output/lihtc_no_site_development_questions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../prepare_lihtc_no_site_development_review/output/lihtc_no_site_development_questions.parquet" ]; then ln -sf ../../../prepare_lihtc_no_site_development_review/output/lihtc_no_site_development_questions.parquet "$@"; fi

../input/lihtc_site_exception_questions.parquet: ../../../prepare_lihtc_site_exception_review/output/lihtc_site_exception_questions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../prepare_lihtc_site_exception_review/output/lihtc_site_exception_questions.parquet" ]; then ln -sf ../../../prepare_lihtc_site_exception_review/output/lihtc_site_exception_questions.parquet "$@"; fi

link-inputs: ../input/lihtc_dataset_acceptance_observations.parquet ../input/lihtc_development_2024_low_income_share_adjudicated.parquet ../input/lihtc_project_episode_2024_low_income_share_adjudicated.parquet ../input/lihtc_development_site_2024_low_income_share_adjudicated.parquet ../input/lihtc_shared_site_network_development_members.parquet ../input/lihtc_no_site_development_questions.parquet ../input/lihtc_site_exception_questions.parquet

include ../../../generic.make
