SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/audit_summary.md \
	../output/lihtc_cross_development_address_groups.parquet \
	../output/lihtc_cross_development_address_members.parquet \
	../output/lihtc_cross_development_pairs.parquet \
	../output/manual_review_sample.csv

../output/audit_summary.md: \
		audit_lihtc_cross_development_addresses.R \
		../input/lihtc_site_geocoding_readiness.parquet \
		../input/lihtc_development_2024_name_adjudicated.parquet \
		../input/lihtc_project_episode_2024_name_adjudicated.parquet | ../output
	$(R) $<

../output/lihtc_cross_development_address_groups.parquet \
../output/lihtc_cross_development_address_members.parquet \
../output/lihtc_cross_development_pairs.parquet \
../output/manual_review_sample.csv: ../output/audit_summary.md
	@test -f $@

../input/lihtc_site_geocoding_readiness.parquet: \
		../../audit_lihtc_geocoding_readiness/output/lihtc_site_geocoding_readiness.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../audit_lihtc_geocoding_readiness/output/lihtc_site_geocoding_readiness.parquet" ]; then \
		ln -sf ../../audit_lihtc_geocoding_readiness/output/lihtc_site_geocoding_readiness.parquet "$@"; \
	fi

../input/lihtc_development_2024_name_adjudicated.parquet: \
		../../../apply_lihtc_name_variant_linkage_review/output/lihtc_development_2024_name_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_name_variant_linkage_review/output/lihtc_development_2024_name_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_name_variant_linkage_review/output/lihtc_development_2024_name_adjudicated.parquet "$@"; \
	fi

../input/lihtc_project_episode_2024_name_adjudicated.parquet: \
		../../../apply_lihtc_name_variant_linkage_review/output/lihtc_project_episode_2024_name_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_name_variant_linkage_review/output/lihtc_project_episode_2024_name_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_name_variant_linkage_review/output/lihtc_project_episode_2024_name_adjudicated.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_site_geocoding_readiness.parquet \
	../input/lihtc_development_2024_name_adjudicated.parquet \
	../input/lihtc_project_episode_2024_name_adjudicated.parquet

include ../../../generic.make
