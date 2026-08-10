SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/lihtc_cross_development_address_members_round2_adjudicated.parquet \
	../output/lihtc_cross_development_address_groups_round2_adjudicated.parquet \
	../output/lihtc_cross_development_pairs_round2_adjudicated.parquet \
	../output/lihtc_round2_candidate_edge_dispositions.parquet \
	../output/audit_summary.md

../output/lihtc_cross_development_address_members_round2_adjudicated.parquet: \
		audit_lihtc_cross_development_addresses_round2_adjudicated.R \
		../input/lihtc_cross_development_address_members_adjudicated.parquet \
		../input/lihtc_cross_development_pairs_adjudicated.parquet \
		../input/lihtc_development_2024_address_round2_adjudicated.parquet \
		../input/lihtc_project_episode_2024_address_round2_adjudicated.parquet \
		../input/lihtc_development_site_2024_address_round2_adjudicated.parquet \
		../input/lihtc_cross_development_address_question_reviews_round2.parquet \
		../input/lihtc_cross_development_address_member_partitions_round2.parquet | ../output
	$(R) $<

../output/lihtc_cross_development_address_groups_round2_adjudicated.parquet \
../output/lihtc_cross_development_pairs_round2_adjudicated.parquet \
../output/lihtc_round2_candidate_edge_dispositions.parquet \
../output/audit_summary.md: \
		../output/lihtc_cross_development_address_members_round2_adjudicated.parquet
	@test -f $@

../input/lihtc_cross_development_address_members_adjudicated.parquet: \
		../../audit_lihtc_cross_development_addresses_adjudicated/output/lihtc_cross_development_address_members_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../audit_lihtc_cross_development_addresses_adjudicated/output/lihtc_cross_development_address_members_adjudicated.parquet" ]; then \
		ln -sf ../../audit_lihtc_cross_development_addresses_adjudicated/output/lihtc_cross_development_address_members_adjudicated.parquet "$@"; \
	fi

../input/lihtc_cross_development_pairs_adjudicated.parquet: \
		../../audit_lihtc_cross_development_addresses_adjudicated/output/lihtc_cross_development_pairs_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../audit_lihtc_cross_development_addresses_adjudicated/output/lihtc_cross_development_pairs_adjudicated.parquet" ]; then \
		ln -sf ../../audit_lihtc_cross_development_addresses_adjudicated/output/lihtc_cross_development_pairs_adjudicated.parquet "$@"; \
	fi

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

../input/lihtc_cross_development_address_question_reviews_round2.parquet: \
		../../../review_lihtc_cross_development_addresses_round2/output/lihtc_cross_development_address_question_reviews_round2.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../review_lihtc_cross_development_addresses_round2/output/lihtc_cross_development_address_question_reviews_round2.parquet" ]; then \
		ln -sf ../../../review_lihtc_cross_development_addresses_round2/output/lihtc_cross_development_address_question_reviews_round2.parquet "$@"; \
	fi

../input/lihtc_cross_development_address_member_partitions_round2.parquet: \
		../../../review_lihtc_cross_development_addresses_round2/output/lihtc_cross_development_address_member_partitions_round2.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../review_lihtc_cross_development_addresses_round2/output/lihtc_cross_development_address_member_partitions_round2.parquet" ]; then \
		ln -sf ../../../review_lihtc_cross_development_addresses_round2/output/lihtc_cross_development_address_member_partitions_round2.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_cross_development_address_members_adjudicated.parquet \
	../input/lihtc_cross_development_pairs_adjudicated.parquet \
	../input/lihtc_development_2024_address_round2_adjudicated.parquet \
	../input/lihtc_project_episode_2024_address_round2_adjudicated.parquet \
	../input/lihtc_development_site_2024_address_round2_adjudicated.parquet \
	../input/lihtc_cross_development_address_question_reviews_round2.parquet \
	../input/lihtc_cross_development_address_member_partitions_round2.parquet

include ../../../generic.make
