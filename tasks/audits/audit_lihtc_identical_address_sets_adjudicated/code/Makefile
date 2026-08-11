SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: ../output/audit_summary.md

../output/audit_summary.md: \
		audit_lihtc_identical_address_sets_adjudicated.R \
		../input/lihtc_development_2024_address_round2_adjudicated.parquet \
		../input/lihtc_project_episode_2024_address_round2_adjudicated.parquet \
		../input/lihtc_development_site_2024_address_round2_adjudicated.parquet \
		../input/lihtc_development_2024_identical_address_adjudicated.parquet \
		../input/lihtc_project_episode_2024_identical_address_adjudicated.parquet \
		../input/lihtc_development_site_2024_identical_address_adjudicated.parquet \
		../input/lihtc_identical_address_set_reviews.parquet \
		../input/lihtc_identical_address_set_proposed_member_mapping.parquet \
		../input/lihtc_identical_address_set_members.parquet | ../output
	$(R) $<

../input/lihtc_development_2024_address_round2_adjudicated.parquet: \
		../../../apply_lihtc_cross_development_address_review_round2/output/lihtc_development_2024_address_round2_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_cross_development_address_review_round2/output/lihtc_development_2024_address_round2_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_cross_development_address_review_round2/output/lihtc_development_2024_address_round2_adjudicated.parquet "$@"; \
	fi

../input/lihtc_project_episode_2024_address_round2_adjudicated.parquet: \
		../../../apply_lihtc_cross_development_address_review_round2/output/lihtc_project_episode_2024_address_round2_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_cross_development_address_review_round2/output/lihtc_project_episode_2024_address_round2_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_cross_development_address_review_round2/output/lihtc_project_episode_2024_address_round2_adjudicated.parquet "$@"; \
	fi

../input/lihtc_development_site_2024_address_round2_adjudicated.parquet: \
		../../../apply_lihtc_cross_development_address_review_round2/output/lihtc_development_site_2024_address_round2_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_cross_development_address_review_round2/output/lihtc_development_site_2024_address_round2_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_cross_development_address_review_round2/output/lihtc_development_site_2024_address_round2_adjudicated.parquet "$@"; \
	fi

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

../input/lihtc_identical_address_set_reviews.parquet: \
		../../../review_lihtc_identical_address_sets/output/lihtc_identical_address_set_reviews.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../review_lihtc_identical_address_sets/output/lihtc_identical_address_set_reviews.parquet" ]; then \
		ln -sf ../../../review_lihtc_identical_address_sets/output/lihtc_identical_address_set_reviews.parquet "$@"; \
	fi

../input/lihtc_identical_address_set_proposed_member_mapping.parquet: \
		../../../review_lihtc_identical_address_sets/output/lihtc_identical_address_set_proposed_member_mapping.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../review_lihtc_identical_address_sets/output/lihtc_identical_address_set_proposed_member_mapping.parquet" ]; then \
		ln -sf ../../../review_lihtc_identical_address_sets/output/lihtc_identical_address_set_proposed_member_mapping.parquet "$@"; \
	fi

../input/lihtc_identical_address_set_members.parquet: \
		../../audit_lihtc_identical_address_sets/output/lihtc_identical_address_set_members.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../audit_lihtc_identical_address_sets/output/lihtc_identical_address_set_members.parquet" ]; then \
		ln -sf ../../audit_lihtc_identical_address_sets/output/lihtc_identical_address_set_members.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_development_2024_address_round2_adjudicated.parquet \
	../input/lihtc_project_episode_2024_address_round2_adjudicated.parquet \
	../input/lihtc_development_site_2024_address_round2_adjudicated.parquet \
	../input/lihtc_development_2024_identical_address_adjudicated.parquet \
	../input/lihtc_project_episode_2024_identical_address_adjudicated.parquet \
	../input/lihtc_development_site_2024_identical_address_adjudicated.parquet \
	../input/lihtc_identical_address_set_reviews.parquet \
	../input/lihtc_identical_address_set_proposed_member_mapping.parquet \
	../input/lihtc_identical_address_set_members.parquet

include ../../../generic.make
