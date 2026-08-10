SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/lihtc_development_2024_address_round2_adjudicated.parquet \
	../output/lihtc_project_episode_2024_address_round2_adjudicated.parquet \
	../output/lihtc_development_site_2024_address_round2_adjudicated.parquet \
	../output/application_summary.md

../output/lihtc_development_2024_address_round2_adjudicated.parquet: \
		apply_lihtc_cross_development_address_review_round2.R \
		../input/lihtc_development_2024_address_adjudicated.parquet \
		../input/lihtc_project_episode_2024_address_adjudicated.parquet \
		../input/lihtc_development_site_2024_address_adjudicated.parquet \
		../input/lihtc_multisite_2024_raw_text.parquet \
		../input/lihtc_cross_development_address_question_reviews_round2.parquet \
		../input/lihtc_cross_development_address_member_partitions_round2.parquet | ../output
	$(R) $<

../output/lihtc_project_episode_2024_address_round2_adjudicated.parquet \
../output/lihtc_development_site_2024_address_round2_adjudicated.parquet \
../output/application_summary.md: \
		../output/lihtc_development_2024_address_round2_adjudicated.parquet
	@test -f $@

../input/lihtc_development_2024_address_adjudicated.parquet: \
		../../apply_lihtc_cross_development_address_review/output/lihtc_development_2024_address_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_cross_development_address_review/output/lihtc_development_2024_address_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_cross_development_address_review/output/lihtc_development_2024_address_adjudicated.parquet "$@"; \
	fi

../input/lihtc_project_episode_2024_address_adjudicated.parquet: \
		../../apply_lihtc_cross_development_address_review/output/lihtc_project_episode_2024_address_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_cross_development_address_review/output/lihtc_project_episode_2024_address_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_cross_development_address_review/output/lihtc_project_episode_2024_address_adjudicated.parquet "$@"; \
	fi

../input/lihtc_development_site_2024_address_adjudicated.parquet: \
		../../apply_lihtc_cross_development_address_review/output/lihtc_development_site_2024_address_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_cross_development_address_review/output/lihtc_development_site_2024_address_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_cross_development_address_review/output/lihtc_development_site_2024_address_adjudicated.parquet "$@"; \
	fi

../input/lihtc_multisite_2024_raw_text.parquet: \
		../../prepare_lihtc_multisite/output/lihtc_multisite_2024_raw_text.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../prepare_lihtc_multisite/output/lihtc_multisite_2024_raw_text.parquet" ]; then \
		ln -sf ../../prepare_lihtc_multisite/output/lihtc_multisite_2024_raw_text.parquet "$@"; \
	fi

../input/lihtc_cross_development_address_question_reviews_round2.parquet: \
		../../review_lihtc_cross_development_addresses_round2/output/lihtc_cross_development_address_question_reviews_round2.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../review_lihtc_cross_development_addresses_round2/output/lihtc_cross_development_address_question_reviews_round2.parquet" ]; then \
		ln -sf ../../review_lihtc_cross_development_addresses_round2/output/lihtc_cross_development_address_question_reviews_round2.parquet "$@"; \
	fi

../input/lihtc_cross_development_address_member_partitions_round2.parquet: \
		../../review_lihtc_cross_development_addresses_round2/output/lihtc_cross_development_address_member_partitions_round2.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../review_lihtc_cross_development_addresses_round2/output/lihtc_cross_development_address_member_partitions_round2.parquet" ]; then \
		ln -sf ../../review_lihtc_cross_development_addresses_round2/output/lihtc_cross_development_address_member_partitions_round2.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_development_2024_address_adjudicated.parquet \
	../input/lihtc_project_episode_2024_address_adjudicated.parquet \
	../input/lihtc_development_site_2024_address_adjudicated.parquet \
	../input/lihtc_multisite_2024_raw_text.parquet \
	../input/lihtc_cross_development_address_question_reviews_round2.parquet \
	../input/lihtc_cross_development_address_member_partitions_round2.parquet

include ../../generic.make
