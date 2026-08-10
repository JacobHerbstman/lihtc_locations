SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/lihtc_development_2024_name_adjudicated.parquet \
	../output/lihtc_project_episode_2024_name_adjudicated.parquet \
	../output/lihtc_development_site_2024_name_adjudicated.parquet

../output/lihtc_development_2024_name_adjudicated.parquet: \
		apply_lihtc_name_variant_linkage_review.R \
		../input/lihtc_development_2024_adjudicated.parquet \
		../input/lihtc_project_episode_2024_adjudicated.parquet \
		../input/lihtc_development_site_2024_adjudicated.parquet \
		../input/lihtc_multisite_2024_raw_text.parquet \
		../input/lihtc_name_variant_linkage_decisions_2024.parquet \
		../input/lihtc_name_variant_linkage_member_decisions_2024.parquet | ../output
	$(R) $<

../output/lihtc_project_episode_2024_name_adjudicated.parquet \
../output/lihtc_development_site_2024_name_adjudicated.parquet: \
		../output/lihtc_development_2024_name_adjudicated.parquet
	@test -f $@

../input/lihtc_development_2024_adjudicated.parquet: \
		../../apply_lihtc_development_linkage_review/output/lihtc_development_2024_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_development_linkage_review/output/lihtc_development_2024_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_development_linkage_review/output/lihtc_development_2024_adjudicated.parquet "$@"; \
	fi

../input/lihtc_project_episode_2024_adjudicated.parquet: \
		../../apply_lihtc_development_linkage_review/output/lihtc_project_episode_2024_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_development_linkage_review/output/lihtc_project_episode_2024_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_development_linkage_review/output/lihtc_project_episode_2024_adjudicated.parquet "$@"; \
	fi

../input/lihtc_development_site_2024_adjudicated.parquet: \
		../../apply_lihtc_development_linkage_review/output/lihtc_development_site_2024_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_development_linkage_review/output/lihtc_development_site_2024_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_development_linkage_review/output/lihtc_development_site_2024_adjudicated.parquet "$@"; \
	fi

../input/lihtc_multisite_2024_raw_text.parquet: \
		../../prepare_lihtc_multisite/output/lihtc_multisite_2024_raw_text.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../prepare_lihtc_multisite/output/lihtc_multisite_2024_raw_text.parquet" ]; then \
		ln -sf ../../prepare_lihtc_multisite/output/lihtc_multisite_2024_raw_text.parquet "$@"; \
	fi

../input/lihtc_name_variant_linkage_decisions_2024.parquet: \
		../../review_lihtc_name_variant_linkage/output/lihtc_name_variant_linkage_decisions_2024.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../review_lihtc_name_variant_linkage/output/lihtc_name_variant_linkage_decisions_2024.parquet" ]; then \
		ln -sf ../../review_lihtc_name_variant_linkage/output/lihtc_name_variant_linkage_decisions_2024.parquet "$@"; \
	fi

../input/lihtc_name_variant_linkage_member_decisions_2024.parquet: \
		../../review_lihtc_name_variant_linkage/output/lihtc_name_variant_linkage_member_decisions_2024.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../review_lihtc_name_variant_linkage/output/lihtc_name_variant_linkage_member_decisions_2024.parquet" ]; then \
		ln -sf ../../review_lihtc_name_variant_linkage/output/lihtc_name_variant_linkage_member_decisions_2024.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_development_2024_adjudicated.parquet \
	../input/lihtc_project_episode_2024_adjudicated.parquet \
	../input/lihtc_development_site_2024_adjudicated.parquet \
	../input/lihtc_multisite_2024_raw_text.parquet \
	../input/lihtc_name_variant_linkage_decisions_2024.parquet \
	../input/lihtc_name_variant_linkage_member_decisions_2024.parquet

include ../../generic.make
