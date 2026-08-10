SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/audit_summary.md \
	../output/lihtc_cross_development_address_groups_adjudicated.parquet \
	../output/lihtc_cross_development_address_members_adjudicated.parquet \
	../output/lihtc_cross_development_pairs_adjudicated.parquet \
	../output/manual_review_sample.csv

../output/audit_summary.md: \
		audit_lihtc_cross_development_addresses_adjudicated.R \
		../input/lihtc_site_geocoding_readiness.parquet \
		../input/lihtc_development_2024_address_adjudicated.parquet \
		../input/lihtc_project_episode_2024_address_adjudicated.parquet \
		../input/lihtc_development_site_2024_address_adjudicated.parquet \
		../input/lihtc_cross_development_address_member_decisions.parquet | ../output
	$(R) $<

../output/lihtc_cross_development_address_groups_adjudicated.parquet \
../output/lihtc_cross_development_address_members_adjudicated.parquet \
../output/lihtc_cross_development_pairs_adjudicated.parquet \
../output/manual_review_sample.csv: ../output/audit_summary.md
	@test -f $@

../input/lihtc_site_geocoding_readiness.parquet: \
		../../audit_lihtc_geocoding_readiness/output/lihtc_site_geocoding_readiness.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../audit_lihtc_geocoding_readiness/output/lihtc_site_geocoding_readiness.parquet" ]; then \
		ln -sf ../../audit_lihtc_geocoding_readiness/output/lihtc_site_geocoding_readiness.parquet "$@"; \
	fi

../input/lihtc_development_2024_address_adjudicated.parquet: \
		../../../apply_lihtc_cross_development_address_review/output/lihtc_development_2024_address_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_cross_development_address_review/output/lihtc_development_2024_address_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_cross_development_address_review/output/lihtc_development_2024_address_adjudicated.parquet "$@"; \
	fi

../input/lihtc_project_episode_2024_address_adjudicated.parquet: \
		../../../apply_lihtc_cross_development_address_review/output/lihtc_project_episode_2024_address_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_cross_development_address_review/output/lihtc_project_episode_2024_address_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_cross_development_address_review/output/lihtc_project_episode_2024_address_adjudicated.parquet "$@"; \
	fi

../input/lihtc_development_site_2024_address_adjudicated.parquet: \
		../../../apply_lihtc_cross_development_address_review/output/lihtc_development_site_2024_address_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_cross_development_address_review/output/lihtc_development_site_2024_address_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_cross_development_address_review/output/lihtc_development_site_2024_address_adjudicated.parquet "$@"; \
	fi

../input/lihtc_cross_development_address_member_decisions.parquet: \
		../../../review_lihtc_cross_development_addresses/output/lihtc_cross_development_address_member_decisions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../review_lihtc_cross_development_addresses/output/lihtc_cross_development_address_member_decisions.parquet" ]; then \
		ln -sf ../../../review_lihtc_cross_development_addresses/output/lihtc_cross_development_address_member_decisions.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_site_geocoding_readiness.parquet \
	../input/lihtc_development_2024_address_adjudicated.parquet \
	../input/lihtc_project_episode_2024_address_adjudicated.parquet \
	../input/lihtc_development_site_2024_address_adjudicated.parquet \
	../input/lihtc_cross_development_address_member_decisions.parquet

include ../../../generic.make
