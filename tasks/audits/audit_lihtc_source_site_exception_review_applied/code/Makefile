SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: ../output/lihtc_source_site_exception_application_audit.parquet

../output/lihtc_source_site_exception_application_audit.parquet: \
		audit_lihtc_source_site_exception_review_applied.R \
		../input/lihtc_development_2024_single_address_adjudicated.parquet \
		../input/lihtc_project_episode_2024_single_address_adjudicated.parquet \
		../input/lihtc_development_site_2024_single_address_adjudicated.parquet \
		../input/lihtc_source_site_member_decisions.parquet \
		../input/lihtc_source_site_episode_decisions.parquet \
		../input/lihtc_source_site_external_replacements.parquet \
		../input/lihtc_development_2024_source_site_repaired.parquet \
		../input/lihtc_project_episode_2024_source_site_repaired.parquet \
		../input/lihtc_development_site_2024_source_site_repaired.parquet | ../output
	$(R) $<

../input/lihtc_development_2024_single_address_adjudicated.parquet: \
		../../../apply_lihtc_single_address_review/output/lihtc_development_2024_single_address_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_single_address_review/output/lihtc_development_2024_single_address_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_single_address_review/output/lihtc_development_2024_single_address_adjudicated.parquet "$@"; \
	fi

../input/lihtc_project_episode_2024_single_address_adjudicated.parquet: \
		../../../apply_lihtc_single_address_review/output/lihtc_project_episode_2024_single_address_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_single_address_review/output/lihtc_project_episode_2024_single_address_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_single_address_review/output/lihtc_project_episode_2024_single_address_adjudicated.parquet "$@"; \
	fi

../input/lihtc_development_site_2024_single_address_adjudicated.parquet: \
		../../../apply_lihtc_single_address_review/output/lihtc_development_site_2024_single_address_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_single_address_review/output/lihtc_development_site_2024_single_address_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_single_address_review/output/lihtc_development_site_2024_single_address_adjudicated.parquet "$@"; \
	fi

../input/lihtc_source_site_member_decisions.parquet: \
		../../../review_lihtc_source_site_exceptions/output/lihtc_source_site_member_decisions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../review_lihtc_source_site_exceptions/output/lihtc_source_site_member_decisions.parquet" ]; then \
		ln -sf ../../../review_lihtc_source_site_exceptions/output/lihtc_source_site_member_decisions.parquet "$@"; \
	fi

../input/lihtc_source_site_episode_decisions.parquet: \
		../../../review_lihtc_source_site_exceptions/output/lihtc_source_site_episode_decisions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../review_lihtc_source_site_exceptions/output/lihtc_source_site_episode_decisions.parquet" ]; then \
		ln -sf ../../../review_lihtc_source_site_exceptions/output/lihtc_source_site_episode_decisions.parquet "$@"; \
	fi

../input/lihtc_source_site_external_replacements.parquet: \
		../../../review_lihtc_source_site_exceptions/output/lihtc_source_site_external_replacements.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../review_lihtc_source_site_exceptions/output/lihtc_source_site_external_replacements.parquet" ]; then \
		ln -sf ../../../review_lihtc_source_site_exceptions/output/lihtc_source_site_external_replacements.parquet "$@"; \
	fi

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

link-inputs: \
	../input/lihtc_development_2024_single_address_adjudicated.parquet \
	../input/lihtc_project_episode_2024_single_address_adjudicated.parquet \
	../input/lihtc_development_site_2024_single_address_adjudicated.parquet \
	../input/lihtc_source_site_member_decisions.parquet \
	../input/lihtc_source_site_episode_decisions.parquet \
	../input/lihtc_source_site_external_replacements.parquet \
	../input/lihtc_development_2024_source_site_repaired.parquet \
	../input/lihtc_project_episode_2024_source_site_repaired.parquet \
	../input/lihtc_development_site_2024_source_site_repaired.parquet

include ../../../generic.make
