SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/audit_summary.md \
	../output/lihtc_site_geocoding_readiness.parquet \
	../output/proposed_address_queries.parquet \
	../output/manual_review_sample.csv

../output/audit_summary.md: \
		audit_lihtc_geocoding_readiness.R \
		../input/lihtc_project_episode_2024_name_adjudicated.parquet \
		../input/lihtc_development_site_2024_name_adjudicated.parquet \
		../input/lihtc_multisite_2024_raw_text.parquet | ../output
	$(R) $<

../output/lihtc_site_geocoding_readiness.parquet \
../output/proposed_address_queries.parquet \
../output/manual_review_sample.csv: ../output/audit_summary.md
	@test -f $@

../input/lihtc_project_episode_2024_name_adjudicated.parquet: \
		../../../apply_lihtc_name_variant_linkage_review/output/lihtc_project_episode_2024_name_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_name_variant_linkage_review/output/lihtc_project_episode_2024_name_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_name_variant_linkage_review/output/lihtc_project_episode_2024_name_adjudicated.parquet "$@"; \
	fi

../input/lihtc_development_site_2024_name_adjudicated.parquet: \
		../../../apply_lihtc_name_variant_linkage_review/output/lihtc_development_site_2024_name_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_name_variant_linkage_review/output/lihtc_development_site_2024_name_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_name_variant_linkage_review/output/lihtc_development_site_2024_name_adjudicated.parquet "$@"; \
	fi

../input/lihtc_multisite_2024_raw_text.parquet: \
		../../../prepare_lihtc_multisite/output/lihtc_multisite_2024_raw_text.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../prepare_lihtc_multisite/output/lihtc_multisite_2024_raw_text.parquet" ]; then \
		ln -sf ../../../prepare_lihtc_multisite/output/lihtc_multisite_2024_raw_text.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_project_episode_2024_name_adjudicated.parquet \
	../input/lihtc_development_site_2024_name_adjudicated.parquet \
	../input/lihtc_multisite_2024_raw_text.parquet

include ../../../generic.make
