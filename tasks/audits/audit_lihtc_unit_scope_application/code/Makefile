SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: ../output/lihtc_unit_scope_application_audit.parquet

../output/lihtc_unit_scope_application_audit.parquet: \
		audit_lihtc_unit_scope_application.R \
		../input/lihtc_development_2024_singleton_identity_scope_adjudicated.parquet \
		../input/lihtc_project_episode_2024_singleton_identity_scope_adjudicated.parquet \
		../input/lihtc_development_site_2024_singleton_identity_scope_adjudicated.parquet \
		../input/lihtc_development_2024_unit_scope_adjudicated.parquet \
		../input/lihtc_project_episode_2024_unit_scope_adjudicated.parquet \
		../input/lihtc_development_site_2024_unit_scope_adjudicated.parquet \
		../input/lihtc_excluded_episode_2024_unit_scope_evidence.parquet \
		../input/lihtc_unit_scope_question_decisions.parquet \
		../input/lihtc_unit_scope_member_decisions.parquet | ../output
	$(R) $<

../input/lihtc_development_2024_singleton_identity_scope_adjudicated.parquet: \
		../../../apply_lihtc_singleton_identity_scope_review/output/lihtc_development_2024_singleton_identity_scope_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_singleton_identity_scope_review/output/lihtc_development_2024_singleton_identity_scope_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_singleton_identity_scope_review/output/lihtc_development_2024_singleton_identity_scope_adjudicated.parquet "$@"; \
	fi

../input/lihtc_project_episode_2024_singleton_identity_scope_adjudicated.parquet: \
		../../../apply_lihtc_singleton_identity_scope_review/output/lihtc_project_episode_2024_singleton_identity_scope_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_singleton_identity_scope_review/output/lihtc_project_episode_2024_singleton_identity_scope_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_singleton_identity_scope_review/output/lihtc_project_episode_2024_singleton_identity_scope_adjudicated.parquet "$@"; \
	fi

../input/lihtc_development_site_2024_singleton_identity_scope_adjudicated.parquet: \
		../../../apply_lihtc_singleton_identity_scope_review/output/lihtc_development_site_2024_singleton_identity_scope_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_singleton_identity_scope_review/output/lihtc_development_site_2024_singleton_identity_scope_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_singleton_identity_scope_review/output/lihtc_development_site_2024_singleton_identity_scope_adjudicated.parquet "$@"; \
	fi

../input/lihtc_development_2024_unit_scope_adjudicated.parquet: \
		../../../apply_lihtc_unit_scope_review/output/lihtc_development_2024_unit_scope_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_unit_scope_review/output/lihtc_development_2024_unit_scope_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_unit_scope_review/output/lihtc_development_2024_unit_scope_adjudicated.parquet "$@"; \
	fi

../input/lihtc_project_episode_2024_unit_scope_adjudicated.parquet: \
		../../../apply_lihtc_unit_scope_review/output/lihtc_project_episode_2024_unit_scope_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_unit_scope_review/output/lihtc_project_episode_2024_unit_scope_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_unit_scope_review/output/lihtc_project_episode_2024_unit_scope_adjudicated.parquet "$@"; \
	fi

../input/lihtc_development_site_2024_unit_scope_adjudicated.parquet: \
		../../../apply_lihtc_unit_scope_review/output/lihtc_development_site_2024_unit_scope_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_unit_scope_review/output/lihtc_development_site_2024_unit_scope_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_unit_scope_review/output/lihtc_development_site_2024_unit_scope_adjudicated.parquet "$@"; \
	fi

../input/lihtc_excluded_episode_2024_unit_scope_evidence.parquet: \
		../../../apply_lihtc_unit_scope_review/output/lihtc_excluded_episode_2024_unit_scope_evidence.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_unit_scope_review/output/lihtc_excluded_episode_2024_unit_scope_evidence.parquet" ]; then \
		ln -sf ../../../apply_lihtc_unit_scope_review/output/lihtc_excluded_episode_2024_unit_scope_evidence.parquet "$@"; \
	fi

../input/lihtc_unit_scope_question_decisions.parquet: \
		../../../review_lihtc_unit_scope/output/lihtc_unit_scope_question_decisions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../review_lihtc_unit_scope/output/lihtc_unit_scope_question_decisions.parquet" ]; then \
		ln -sf ../../../review_lihtc_unit_scope/output/lihtc_unit_scope_question_decisions.parquet "$@"; \
	fi

../input/lihtc_unit_scope_member_decisions.parquet: \
		../../../review_lihtc_unit_scope/output/lihtc_unit_scope_member_decisions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../review_lihtc_unit_scope/output/lihtc_unit_scope_member_decisions.parquet" ]; then \
		ln -sf ../../../review_lihtc_unit_scope/output/lihtc_unit_scope_member_decisions.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_development_2024_singleton_identity_scope_adjudicated.parquet \
	../input/lihtc_project_episode_2024_singleton_identity_scope_adjudicated.parquet \
	../input/lihtc_development_site_2024_singleton_identity_scope_adjudicated.parquet \
	../input/lihtc_development_2024_unit_scope_adjudicated.parquet \
	../input/lihtc_project_episode_2024_unit_scope_adjudicated.parquet \
	../input/lihtc_development_site_2024_unit_scope_adjudicated.parquet \
	../input/lihtc_excluded_episode_2024_unit_scope_evidence.parquet \
	../input/lihtc_unit_scope_question_decisions.parquet \
	../input/lihtc_unit_scope_member_decisions.parquet

include ../../../generic.make
