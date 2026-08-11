SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: ../output/audit_summary.md

../output/audit_summary.md: \
		audit_lihtc_single_address_adjudicated.R \
		../input/lihtc_development_2024_identical_address_adjudicated.parquet \
		../input/lihtc_project_episode_2024_identical_address_adjudicated.parquet \
		../input/lihtc_development_site_2024_identical_address_adjudicated.parquet \
		../input/lihtc_development_2024_single_address_adjudicated.parquet \
		../input/lihtc_project_episode_2024_single_address_adjudicated.parquet \
		../input/lihtc_development_site_2024_single_address_adjudicated.parquet \
		../input/lihtc_multisite_2024_raw_text.parquet \
		../input/lihtc_single_address_question_reviews.parquet \
		../input/lihtc_single_address_member_partitions.parquet | ../output
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

../input/lihtc_development_2024_single_address_adjudicated.parquet: \
		../../../apply_lihtc_single_address_review/output/lihtc_development_2024_single_address_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_single_address_review/output/lihtc_development_2024_single_address_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_single_address_review/output/lihtc_development_2024_single_address_adjudicated.parquet "$@"; \
	fi

../input/lihtc_project_episode_2024_single_address_adjudicated.parquet: \
		../../../apply_lihtc_single_address_review/output/lihtc_project_episode_2024_single_address_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_single_address_review/output/lihtc_project_episode_2024_single_address_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_single_address_review/output/lihtc_project_episode_2024_single_address_adjudicated.parquet "$@"; \
	fi

../input/lihtc_development_site_2024_single_address_adjudicated.parquet: \
		../../../apply_lihtc_single_address_review/output/lihtc_development_site_2024_single_address_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_single_address_review/output/lihtc_development_site_2024_single_address_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_single_address_review/output/lihtc_development_site_2024_single_address_adjudicated.parquet "$@"; \
	fi

../input/lihtc_multisite_2024_raw_text.parquet: \
		../../../prepare_lihtc_multisite/output/lihtc_multisite_2024_raw_text.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../prepare_lihtc_multisite/output/lihtc_multisite_2024_raw_text.parquet" ]; then \
		ln -sf ../../../prepare_lihtc_multisite/output/lihtc_multisite_2024_raw_text.parquet "$@"; \
	fi

../input/lihtc_single_address_question_reviews.parquet: \
		../../../review_lihtc_single_address/output/lihtc_single_address_question_reviews.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../review_lihtc_single_address/output/lihtc_single_address_question_reviews.parquet" ]; then \
		ln -sf ../../../review_lihtc_single_address/output/lihtc_single_address_question_reviews.parquet "$@"; \
	fi

../input/lihtc_single_address_member_partitions.parquet: \
		../../../review_lihtc_single_address/output/lihtc_single_address_member_partitions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../review_lihtc_single_address/output/lihtc_single_address_member_partitions.parquet" ]; then \
		ln -sf ../../../review_lihtc_single_address/output/lihtc_single_address_member_partitions.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_development_2024_identical_address_adjudicated.parquet \
	../input/lihtc_project_episode_2024_identical_address_adjudicated.parquet \
	../input/lihtc_development_site_2024_identical_address_adjudicated.parquet \
	../input/lihtc_development_2024_single_address_adjudicated.parquet \
	../input/lihtc_project_episode_2024_single_address_adjudicated.parquet \
	../input/lihtc_development_site_2024_single_address_adjudicated.parquet \
	../input/lihtc_multisite_2024_raw_text.parquet \
	../input/lihtc_single_address_question_reviews.parquet \
	../input/lihtc_single_address_member_partitions.parquet

include ../../../generic.make
