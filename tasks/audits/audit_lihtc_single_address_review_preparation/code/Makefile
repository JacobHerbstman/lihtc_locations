SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: ../output/audit_summary.md

../output/audit_summary.md: \
		audit_lihtc_single_address_review_preparation.R \
		../input/lihtc_development_2024_identical_address_adjudicated.parquet \
		../input/lihtc_project_episode_2024_identical_address_adjudicated.parquet \
		../input/lihtc_development_site_2024_identical_address_adjudicated.parquet \
		../input/lihtc_single_address_identity_questions.parquet \
		../input/lihtc_single_address_identity_question_members.parquet \
		../input/lihtc_single_address_identity_question_pairs.parquet | ../output
	$(R) $<

../input/lihtc_development_2024_identical_address_adjudicated.parquet: \
		../../../apply_lihtc_identical_address_set_review/output/lihtc_development_2024_identical_address_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_identical_address_set_review/output/lihtc_development_2024_identical_address_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_identical_address_set_review/output/lihtc_development_2024_identical_address_adjudicated.parquet "$@"; \
	fi

../input/lihtc_project_episode_2024_identical_address_adjudicated.parquet: \
		../../../apply_lihtc_identical_address_set_review/output/lihtc_project_episode_2024_identical_address_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_identical_address_set_review/output/lihtc_project_episode_2024_identical_address_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_identical_address_set_review/output/lihtc_project_episode_2024_identical_address_adjudicated.parquet "$@"; \
	fi

../input/lihtc_development_site_2024_identical_address_adjudicated.parquet: \
		../../../apply_lihtc_identical_address_set_review/output/lihtc_development_site_2024_identical_address_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_identical_address_set_review/output/lihtc_development_site_2024_identical_address_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_identical_address_set_review/output/lihtc_development_site_2024_identical_address_adjudicated.parquet "$@"; \
	fi

../input/lihtc_single_address_identity_questions.parquet: \
		../../../prepare_lihtc_single_address_review/output/lihtc_single_address_identity_questions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../prepare_lihtc_single_address_review/output/lihtc_single_address_identity_questions.parquet" ]; then \
		ln -sf ../../../prepare_lihtc_single_address_review/output/lihtc_single_address_identity_questions.parquet "$@"; \
	fi

../input/lihtc_single_address_identity_question_members.parquet: \
		../../../prepare_lihtc_single_address_review/output/lihtc_single_address_identity_question_members.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../prepare_lihtc_single_address_review/output/lihtc_single_address_identity_question_members.parquet" ]; then \
		ln -sf ../../../prepare_lihtc_single_address_review/output/lihtc_single_address_identity_question_members.parquet "$@"; \
	fi

../input/lihtc_single_address_identity_question_pairs.parquet: \
		../../../prepare_lihtc_single_address_review/output/lihtc_single_address_identity_question_pairs.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../prepare_lihtc_single_address_review/output/lihtc_single_address_identity_question_pairs.parquet" ]; then \
		ln -sf ../../../prepare_lihtc_single_address_review/output/lihtc_single_address_identity_question_pairs.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_development_2024_identical_address_adjudicated.parquet \
	../input/lihtc_project_episode_2024_identical_address_adjudicated.parquet \
	../input/lihtc_development_site_2024_identical_address_adjudicated.parquet \
	../input/lihtc_single_address_identity_questions.parquet \
	../input/lihtc_single_address_identity_question_members.parquet \
	../input/lihtc_single_address_identity_question_pairs.parquet

include ../../../generic.make
