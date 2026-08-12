SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/lihtc_final_site_geocoding_readiness.parquet \
	../output/proposed_address_queries.parquet \
	../output/manual_review_sample.csv \
	../output/audit_summary.md

../output/lihtc_final_site_geocoding_readiness.parquet: \
		audit_lihtc_final_geocoding_readiness.R \
		../input/lihtc_development_2024_unit_scope_adjudicated.parquet \
		../input/lihtc_project_episode_2024_unit_scope_adjudicated.parquet \
		../input/lihtc_development_site_2024_unit_scope_adjudicated.parquet | ../output
	$(R) $<

../output/proposed_address_queries.parquet \
../output/manual_review_sample.csv \
../output/audit_summary.md: ../output/lihtc_final_site_geocoding_readiness.parquet
	@test -f $@

../input/lihtc_development_2024_unit_scope_adjudicated.parquet: \
		../../../apply_lihtc_unit_scope_review/output/lihtc_development_2024_unit_scope_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_unit_scope_review/output/lihtc_development_2024_unit_scope_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_unit_scope_review/output/lihtc_development_2024_unit_scope_adjudicated.parquet "$@"; \
	fi

../input/lihtc_project_episode_2024_unit_scope_adjudicated.parquet: \
		../../../apply_lihtc_unit_scope_review/output/lihtc_project_episode_2024_unit_scope_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_unit_scope_review/output/lihtc_project_episode_2024_unit_scope_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_unit_scope_review/output/lihtc_project_episode_2024_unit_scope_adjudicated.parquet "$@"; \
	fi

../input/lihtc_development_site_2024_unit_scope_adjudicated.parquet: \
		../../../apply_lihtc_unit_scope_review/output/lihtc_development_site_2024_unit_scope_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_unit_scope_review/output/lihtc_development_site_2024_unit_scope_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_unit_scope_review/output/lihtc_development_site_2024_unit_scope_adjudicated.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_development_2024_unit_scope_adjudicated.parquet \
	../input/lihtc_project_episode_2024_unit_scope_adjudicated.parquet \
	../input/lihtc_development_site_2024_unit_scope_adjudicated.parquet

include ../../../generic.make
