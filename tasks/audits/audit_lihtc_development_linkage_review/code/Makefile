SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/audit_summary.md \
	../output/rejected_linkage_members.csv

../output/audit_summary.md: \
		audit_lihtc_development_linkage_review.R \
		../input/lihtc_development_2024_adjudicated.parquet \
		../input/lihtc_project_episode_2024_adjudicated.parquet \
		../input/lihtc_development_site_2024_adjudicated.parquet \
		../input/lihtc_project_episode_2024.parquet \
		../input/lihtc_development_linkage_decisions_2024.parquet \
		../input/lihtc_development_linkage_member_decisions_2024.parquet | ../output
	$(R) $<

../output/rejected_linkage_members.csv: ../output/audit_summary.md
	@test -f $@

../input/lihtc_development_2024_adjudicated.parquet: \
		../../../apply_lihtc_development_linkage_review/output/lihtc_development_2024_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_development_linkage_review/output/lihtc_development_2024_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_development_linkage_review/output/lihtc_development_2024_adjudicated.parquet "$@"; \
	fi

../input/lihtc_project_episode_2024_adjudicated.parquet: \
		../../../apply_lihtc_development_linkage_review/output/lihtc_project_episode_2024_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_development_linkage_review/output/lihtc_project_episode_2024_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_development_linkage_review/output/lihtc_project_episode_2024_adjudicated.parquet "$@"; \
	fi

../input/lihtc_development_site_2024_adjudicated.parquet: \
		../../../apply_lihtc_development_linkage_review/output/lihtc_development_site_2024_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_development_linkage_review/output/lihtc_development_site_2024_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_development_linkage_review/output/lihtc_development_site_2024_adjudicated.parquet "$@"; \
	fi

../input/lihtc_project_episode_2024.parquet: \
		../../../build_lihtc_development/output/lihtc_project_episode_2024.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../build_lihtc_development/output/lihtc_project_episode_2024.parquet" ]; then \
		ln -sf ../../../build_lihtc_development/output/lihtc_project_episode_2024.parquet "$@"; \
	fi

../input/lihtc_development_linkage_decisions_2024.parquet: \
		../../../review_lihtc_development_linkage/output/lihtc_development_linkage_decisions_2024.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../review_lihtc_development_linkage/output/lihtc_development_linkage_decisions_2024.parquet" ]; then \
		ln -sf ../../../review_lihtc_development_linkage/output/lihtc_development_linkage_decisions_2024.parquet "$@"; \
	fi

../input/lihtc_development_linkage_member_decisions_2024.parquet: \
		../../../review_lihtc_development_linkage/output/lihtc_development_linkage_member_decisions_2024.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../review_lihtc_development_linkage/output/lihtc_development_linkage_member_decisions_2024.parquet" ]; then \
		ln -sf ../../../review_lihtc_development_linkage/output/lihtc_development_linkage_member_decisions_2024.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_development_2024_adjudicated.parquet \
	../input/lihtc_project_episode_2024_adjudicated.parquet \
	../input/lihtc_development_site_2024_adjudicated.parquet \
	../input/lihtc_project_episode_2024.parquet \
	../input/lihtc_development_linkage_decisions_2024.parquet \
	../input/lihtc_development_linkage_member_decisions_2024.parquet

include ../../../generic.make
