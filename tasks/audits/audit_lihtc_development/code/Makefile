SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/audit_summary.md \
	../output/development_linkage_groups.csv \
	../output/development_linkage_members.csv \
	../output/development_site_review.csv

../output/audit_summary.md: \
		audit_lihtc_development.R \
		../input/lihtc_development_2024.parquet \
		../input/lihtc_project_episode_2024.parquet \
		../input/lihtc_development_site_2024.parquet \
		../input/lihtc_property_2024_raw_text.parquet \
		../input/lihtc_multisite_2024_raw_text.parquet | ../output
	$(R) $<

../output/development_linkage_groups.csv \
../output/development_linkage_members.csv \
../output/development_site_review.csv: ../output/audit_summary.md
	@test -f $@

../input/lihtc_development_2024.parquet: \
		../../../build_lihtc_development/output/lihtc_development_2024.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../build_lihtc_development/output/lihtc_development_2024.parquet" ]; then \
		ln -sf ../../../build_lihtc_development/output/lihtc_development_2024.parquet "$@"; \
	fi

../input/lihtc_project_episode_2024.parquet: \
		../../../build_lihtc_development/output/lihtc_project_episode_2024.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../build_lihtc_development/output/lihtc_project_episode_2024.parquet" ]; then \
		ln -sf ../../../build_lihtc_development/output/lihtc_project_episode_2024.parquet "$@"; \
	fi

../input/lihtc_development_site_2024.parquet: \
		../../../build_lihtc_development/output/lihtc_development_site_2024.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../build_lihtc_development/output/lihtc_development_site_2024.parquet" ]; then \
		ln -sf ../../../build_lihtc_development/output/lihtc_development_site_2024.parquet "$@"; \
	fi

../input/lihtc_property_2024_raw_text.parquet: \
		../../../prepare_lihtc_property/output/lihtc_property_2024_raw_text.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../prepare_lihtc_property/output/lihtc_property_2024_raw_text.parquet" ]; then \
		ln -sf ../../../prepare_lihtc_property/output/lihtc_property_2024_raw_text.parquet "$@"; \
	fi

../input/lihtc_multisite_2024_raw_text.parquet: \
		../../../prepare_lihtc_multisite/output/lihtc_multisite_2024_raw_text.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../prepare_lihtc_multisite/output/lihtc_multisite_2024_raw_text.parquet" ]; then \
		ln -sf ../../../prepare_lihtc_multisite/output/lihtc_multisite_2024_raw_text.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_development_2024.parquet \
	../input/lihtc_project_episode_2024.parquet \
	../input/lihtc_development_site_2024.parquet \
	../input/lihtc_property_2024_raw_text.parquet \
	../input/lihtc_multisite_2024_raw_text.parquet

include ../../../generic.make
