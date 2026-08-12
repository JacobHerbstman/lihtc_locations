SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/lihtc_default_singleton_acceptance_questions.parquet \
	../output/lihtc_default_singleton_acceptance_diagnostic_counts.parquet \
	../output/lihtc_default_singleton_acceptance_diagnostic_strata.parquet \
	../output/lihtc_default_singleton_acceptance_sample_allocation.parquet \
	../output/lihtc_default_singleton_acceptance_two_read_sample.parquet

../output/lihtc_default_singleton_acceptance_questions.parquet: \
	prepare_lihtc_default_singleton_acceptance_review.R \
	../input/lihtc_acceptance_review_routing.parquet \
	../input/lihtc_development_2024_low_income_share_adjudicated.parquet \
	../input/lihtc_project_episode_2024_low_income_share_adjudicated.parquet \
	../input/lihtc_development_site_2024_low_income_share_adjudicated.parquet | ../output
	$(R) $<

../output/lihtc_default_singleton_acceptance_diagnostic_strata.parquet: ../output/lihtc_default_singleton_acceptance_questions.parquet
	@test -f $@

../output/lihtc_default_singleton_acceptance_diagnostic_counts.parquet: ../output/lihtc_default_singleton_acceptance_questions.parquet
	@test -f $@

../output/lihtc_default_singleton_acceptance_sample_allocation.parquet: ../output/lihtc_default_singleton_acceptance_questions.parquet
	@test -f $@

../output/lihtc_default_singleton_acceptance_two_read_sample.parquet: ../output/lihtc_default_singleton_acceptance_questions.parquet
	@test -f $@

../input/lihtc_acceptance_review_routing.parquet: ../../audits/audit_lihtc_acceptance_review_routing/output/lihtc_acceptance_review_routing.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../audits/audit_lihtc_acceptance_review_routing/output/lihtc_acceptance_review_routing.parquet" ]; then \
		ln -sf ../../audits/audit_lihtc_acceptance_review_routing/output/lihtc_acceptance_review_routing.parquet "$@"; \
	fi

../input/lihtc_development_2024_low_income_share_adjudicated.parquet: ../../apply_lihtc_low_income_share_review/output/lihtc_development_2024_low_income_share_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_low_income_share_review/output/lihtc_development_2024_low_income_share_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_low_income_share_review/output/lihtc_development_2024_low_income_share_adjudicated.parquet "$@"; \
	fi

../input/lihtc_project_episode_2024_low_income_share_adjudicated.parquet: ../../apply_lihtc_low_income_share_review/output/lihtc_project_episode_2024_low_income_share_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_low_income_share_review/output/lihtc_project_episode_2024_low_income_share_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_low_income_share_review/output/lihtc_project_episode_2024_low_income_share_adjudicated.parquet "$@"; \
	fi

../input/lihtc_development_site_2024_low_income_share_adjudicated.parquet: ../../apply_lihtc_low_income_share_review/output/lihtc_development_site_2024_low_income_share_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_low_income_share_review/output/lihtc_development_site_2024_low_income_share_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_low_income_share_review/output/lihtc_development_site_2024_low_income_share_adjudicated.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_acceptance_review_routing.parquet \
	../input/lihtc_development_2024_low_income_share_adjudicated.parquet \
	../input/lihtc_project_episode_2024_low_income_share_adjudicated.parquet \
	../input/lihtc_development_site_2024_low_income_share_adjudicated.parquet

include ../../generic.make
