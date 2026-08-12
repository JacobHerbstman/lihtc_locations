SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/lihtc_site_exception_questions.parquet \
	../output/lihtc_site_exception_queued_sites.parquet \
	../output/lihtc_site_exception_all_site_context.parquet \
	../output/lihtc_site_exception_episode_context.parquet

../output/lihtc_site_exception_questions.parquet: \
		prepare_lihtc_site_exception_review.R \
		../input/lihtc_dataset_acceptance_observations.parquet \
		../input/lihtc_development_2024_low_income_share_adjudicated.parquet \
		../input/lihtc_project_episode_2024_low_income_share_adjudicated.parquet \
		../input/lihtc_development_site_2024_low_income_share_adjudicated.parquet | ../output
	$(R) $<

../output/lihtc_site_exception_queued_sites.parquet \
../output/lihtc_site_exception_all_site_context.parquet \
../output/lihtc_site_exception_episode_context.parquet: \
		../output/lihtc_site_exception_questions.parquet
	@if [ ! -f "$@" ]; then $(R) prepare_lihtc_site_exception_review.R; fi

../input/lihtc_dataset_acceptance_observations.parquet: \
		../../audits/audit_lihtc_dataset_acceptance/output/lihtc_dataset_acceptance_observations.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../audits/audit_lihtc_dataset_acceptance/output/lihtc_dataset_acceptance_observations.parquet" ]; then \
		ln -sf ../../audits/audit_lihtc_dataset_acceptance/output/lihtc_dataset_acceptance_observations.parquet "$@"; \
	fi

../input/lihtc_development_2024_low_income_share_adjudicated.parquet: \
		../../apply_lihtc_low_income_share_review/output/lihtc_development_2024_low_income_share_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_low_income_share_review/output/lihtc_development_2024_low_income_share_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_low_income_share_review/output/lihtc_development_2024_low_income_share_adjudicated.parquet "$@"; \
	fi

../input/lihtc_project_episode_2024_low_income_share_adjudicated.parquet: \
		../../apply_lihtc_low_income_share_review/output/lihtc_project_episode_2024_low_income_share_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_low_income_share_review/output/lihtc_project_episode_2024_low_income_share_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_low_income_share_review/output/lihtc_project_episode_2024_low_income_share_adjudicated.parquet "$@"; \
	fi

../input/lihtc_development_site_2024_low_income_share_adjudicated.parquet: \
		../../apply_lihtc_low_income_share_review/output/lihtc_development_site_2024_low_income_share_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_low_income_share_review/output/lihtc_development_site_2024_low_income_share_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_low_income_share_review/output/lihtc_development_site_2024_low_income_share_adjudicated.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_dataset_acceptance_observations.parquet \
	../input/lihtc_development_2024_low_income_share_adjudicated.parquet \
	../input/lihtc_project_episode_2024_low_income_share_adjudicated.parquet \
	../input/lihtc_development_site_2024_low_income_share_adjudicated.parquet

include ../../generic.make
