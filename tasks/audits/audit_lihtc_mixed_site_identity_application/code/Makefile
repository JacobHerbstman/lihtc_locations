SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: ../output/audit_summary.md

../output/audit_summary.md: \
		audit_lihtc_mixed_site_identity_application.R \
		../input/lihtc_development_2024_source_site_repaired.parquet \
		../input/lihtc_project_episode_2024_source_site_repaired.parquet \
		../input/lihtc_development_site_2024_source_site_repaired.parquet \
		../input/lihtc_development_2024_mixed_site_identity_adjudicated.parquet \
		../input/lihtc_project_episode_2024_mixed_site_identity_adjudicated.parquet \
		../input/lihtc_development_site_2024_mixed_site_identity_adjudicated.parquet \
		../input/lihtc_mixed_site_identity_member_partitions.parquet | ../output
	$(R) $<

../input/lihtc_development_2024_source_site_repaired.parquet: \
		../../../apply_lihtc_source_site_exception_review/output/lihtc_development_2024_source_site_repaired.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_source_site_exception_review/output/lihtc_development_2024_source_site_repaired.parquet" ]; then \
		ln -sf ../../../apply_lihtc_source_site_exception_review/output/lihtc_development_2024_source_site_repaired.parquet "$@"; \
	fi

../input/lihtc_project_episode_2024_source_site_repaired.parquet: \
		../../../apply_lihtc_source_site_exception_review/output/lihtc_project_episode_2024_source_site_repaired.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_source_site_exception_review/output/lihtc_project_episode_2024_source_site_repaired.parquet" ]; then \
		ln -sf ../../../apply_lihtc_source_site_exception_review/output/lihtc_project_episode_2024_source_site_repaired.parquet "$@"; \
	fi

../input/lihtc_development_site_2024_source_site_repaired.parquet: \
		../../../apply_lihtc_source_site_exception_review/output/lihtc_development_site_2024_source_site_repaired.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_source_site_exception_review/output/lihtc_development_site_2024_source_site_repaired.parquet" ]; then \
		ln -sf ../../../apply_lihtc_source_site_exception_review/output/lihtc_development_site_2024_source_site_repaired.parquet "$@"; \
	fi

../input/lihtc_development_2024_mixed_site_identity_adjudicated.parquet: \
		../../../apply_lihtc_mixed_site_identity_review/output/lihtc_development_2024_mixed_site_identity_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_mixed_site_identity_review/output/lihtc_development_2024_mixed_site_identity_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_mixed_site_identity_review/output/lihtc_development_2024_mixed_site_identity_adjudicated.parquet "$@"; \
	fi

../input/lihtc_project_episode_2024_mixed_site_identity_adjudicated.parquet: \
		../../../apply_lihtc_mixed_site_identity_review/output/lihtc_project_episode_2024_mixed_site_identity_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_mixed_site_identity_review/output/lihtc_project_episode_2024_mixed_site_identity_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_mixed_site_identity_review/output/lihtc_project_episode_2024_mixed_site_identity_adjudicated.parquet "$@"; \
	fi

../input/lihtc_development_site_2024_mixed_site_identity_adjudicated.parquet: \
		../../../apply_lihtc_mixed_site_identity_review/output/lihtc_development_site_2024_mixed_site_identity_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_mixed_site_identity_review/output/lihtc_development_site_2024_mixed_site_identity_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_mixed_site_identity_review/output/lihtc_development_site_2024_mixed_site_identity_adjudicated.parquet "$@"; \
	fi

../input/lihtc_mixed_site_identity_member_partitions.parquet: \
		../../../review_lihtc_mixed_site_identity/output/lihtc_mixed_site_identity_member_partitions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../review_lihtc_mixed_site_identity/output/lihtc_mixed_site_identity_member_partitions.parquet" ]; then \
		ln -sf ../../../review_lihtc_mixed_site_identity/output/lihtc_mixed_site_identity_member_partitions.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_development_2024_source_site_repaired.parquet \
	../input/lihtc_project_episode_2024_source_site_repaired.parquet \
	../input/lihtc_development_site_2024_source_site_repaired.parquet \
	../input/lihtc_development_2024_mixed_site_identity_adjudicated.parquet \
	../input/lihtc_project_episode_2024_mixed_site_identity_adjudicated.parquet \
	../input/lihtc_development_site_2024_mixed_site_identity_adjudicated.parquet \
	../input/lihtc_mixed_site_identity_member_partitions.parquet

include ../../../generic.make
