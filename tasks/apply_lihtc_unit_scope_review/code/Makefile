SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/lihtc_development_2024_unit_scope_adjudicated.parquet \
	../output/lihtc_project_episode_2024_unit_scope_adjudicated.parquet \
	../output/lihtc_development_site_2024_unit_scope_adjudicated.parquet \
	../output/lihtc_excluded_episode_2024_unit_scope_evidence.parquet

../output/lihtc_development_2024_unit_scope_adjudicated.parquet: \
		apply_lihtc_unit_scope_review.R \
		../input/lihtc_development_2024_singleton_identity_scope_adjudicated.parquet \
		../input/lihtc_project_episode_2024_singleton_identity_scope_adjudicated.parquet \
		../input/lihtc_development_site_2024_singleton_identity_scope_adjudicated.parquet \
		../input/lihtc_unit_scope_question_decisions.parquet \
		../input/lihtc_unit_scope_member_decisions.parquet | ../output
	$(R) $<

../output/lihtc_project_episode_2024_unit_scope_adjudicated.parquet: \
		../output/lihtc_development_2024_unit_scope_adjudicated.parquet
	@test -f $@

../output/lihtc_development_site_2024_unit_scope_adjudicated.parquet: \
		../output/lihtc_development_2024_unit_scope_adjudicated.parquet
	@test -f $@

../output/lihtc_excluded_episode_2024_unit_scope_evidence.parquet: \
		../output/lihtc_development_2024_unit_scope_adjudicated.parquet
	@test -f $@

../input/lihtc_development_2024_singleton_identity_scope_adjudicated.parquet: \
		../../apply_lihtc_singleton_identity_scope_review/output/lihtc_development_2024_singleton_identity_scope_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_singleton_identity_scope_review/output/lihtc_development_2024_singleton_identity_scope_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_singleton_identity_scope_review/output/lihtc_development_2024_singleton_identity_scope_adjudicated.parquet "$@"; \
	fi

../input/lihtc_project_episode_2024_singleton_identity_scope_adjudicated.parquet: \
		../../apply_lihtc_singleton_identity_scope_review/output/lihtc_project_episode_2024_singleton_identity_scope_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_singleton_identity_scope_review/output/lihtc_project_episode_2024_singleton_identity_scope_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_singleton_identity_scope_review/output/lihtc_project_episode_2024_singleton_identity_scope_adjudicated.parquet "$@"; \
	fi

../input/lihtc_development_site_2024_singleton_identity_scope_adjudicated.parquet: \
		../../apply_lihtc_singleton_identity_scope_review/output/lihtc_development_site_2024_singleton_identity_scope_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_singleton_identity_scope_review/output/lihtc_development_site_2024_singleton_identity_scope_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_singleton_identity_scope_review/output/lihtc_development_site_2024_singleton_identity_scope_adjudicated.parquet "$@"; \
	fi

../input/lihtc_unit_scope_question_decisions.parquet: \
		../../review_lihtc_unit_scope/output/lihtc_unit_scope_question_decisions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../review_lihtc_unit_scope/output/lihtc_unit_scope_question_decisions.parquet" ]; then \
		ln -sf ../../review_lihtc_unit_scope/output/lihtc_unit_scope_question_decisions.parquet "$@"; \
	fi

../input/lihtc_unit_scope_member_decisions.parquet: \
		../../review_lihtc_unit_scope/output/lihtc_unit_scope_member_decisions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../review_lihtc_unit_scope/output/lihtc_unit_scope_member_decisions.parquet" ]; then \
		ln -sf ../../review_lihtc_unit_scope/output/lihtc_unit_scope_member_decisions.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_development_2024_singleton_identity_scope_adjudicated.parquet \
	../input/lihtc_project_episode_2024_singleton_identity_scope_adjudicated.parquet \
	../input/lihtc_development_site_2024_singleton_identity_scope_adjudicated.parquet \
	../input/lihtc_unit_scope_question_decisions.parquet \
	../input/lihtc_unit_scope_member_decisions.parquet

include ../../generic.make
