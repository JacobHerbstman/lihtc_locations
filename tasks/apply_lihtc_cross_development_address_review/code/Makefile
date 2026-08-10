SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/lihtc_development_2024_address_adjudicated.parquet \
	../output/lihtc_project_episode_2024_address_adjudicated.parquet \
	../output/lihtc_development_site_2024_address_adjudicated.parquet \
	../output/application_summary.md

../output/lihtc_development_2024_address_adjudicated.parquet: \
		apply_lihtc_cross_development_address_review.R \
		../input/lihtc_development_2024_name_adjudicated.parquet \
		../input/lihtc_project_episode_2024_name_adjudicated.parquet \
		../input/lihtc_development_site_2024_name_adjudicated.parquet \
		../input/lihtc_multisite_2024_raw_text.parquet \
		../input/lihtc_cross_development_address_decisions.parquet \
		../input/lihtc_cross_development_address_member_decisions.parquet | ../output
	$(R) $<

../output/lihtc_project_episode_2024_address_adjudicated.parquet \
../output/lihtc_development_site_2024_address_adjudicated.parquet \
../output/application_summary.md: \
		../output/lihtc_development_2024_address_adjudicated.parquet
	@test -f $@

../input/lihtc_development_2024_name_adjudicated.parquet: \
		../../apply_lihtc_name_variant_linkage_review/output/lihtc_development_2024_name_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_name_variant_linkage_review/output/lihtc_development_2024_name_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_name_variant_linkage_review/output/lihtc_development_2024_name_adjudicated.parquet "$@"; \
	fi

../input/lihtc_project_episode_2024_name_adjudicated.parquet: \
		../../apply_lihtc_name_variant_linkage_review/output/lihtc_project_episode_2024_name_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_name_variant_linkage_review/output/lihtc_project_episode_2024_name_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_name_variant_linkage_review/output/lihtc_project_episode_2024_name_adjudicated.parquet "$@"; \
	fi

../input/lihtc_development_site_2024_name_adjudicated.parquet: \
		../../apply_lihtc_name_variant_linkage_review/output/lihtc_development_site_2024_name_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_name_variant_linkage_review/output/lihtc_development_site_2024_name_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_name_variant_linkage_review/output/lihtc_development_site_2024_name_adjudicated.parquet "$@"; \
	fi

../input/lihtc_multisite_2024_raw_text.parquet: \
		../../prepare_lihtc_multisite/output/lihtc_multisite_2024_raw_text.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../prepare_lihtc_multisite/output/lihtc_multisite_2024_raw_text.parquet" ]; then \
		ln -sf ../../prepare_lihtc_multisite/output/lihtc_multisite_2024_raw_text.parquet "$@"; \
	fi

../input/lihtc_cross_development_address_decisions.parquet: \
		../../review_lihtc_cross_development_addresses/output/lihtc_cross_development_address_decisions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../review_lihtc_cross_development_addresses/output/lihtc_cross_development_address_decisions.parquet" ]; then \
		ln -sf ../../review_lihtc_cross_development_addresses/output/lihtc_cross_development_address_decisions.parquet "$@"; \
	fi

../input/lihtc_cross_development_address_member_decisions.parquet: \
		../../review_lihtc_cross_development_addresses/output/lihtc_cross_development_address_member_decisions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../review_lihtc_cross_development_addresses/output/lihtc_cross_development_address_member_decisions.parquet" ]; then \
		ln -sf ../../review_lihtc_cross_development_addresses/output/lihtc_cross_development_address_member_decisions.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_development_2024_name_adjudicated.parquet \
	../input/lihtc_project_episode_2024_name_adjudicated.parquet \
	../input/lihtc_development_site_2024_name_adjudicated.parquet \
	../input/lihtc_multisite_2024_raw_text.parquet \
	../input/lihtc_cross_development_address_decisions.parquet \
	../input/lihtc_cross_development_address_member_decisions.parquet

include ../../generic.make
