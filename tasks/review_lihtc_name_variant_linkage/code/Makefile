SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/lihtc_name_variant_linkage_decisions_2024.parquet \
	../output/lihtc_name_variant_linkage_member_decisions_2024.parquet

../output/lihtc_name_variant_linkage_decisions_2024.parquet: \
		validate_lihtc_name_variant_linkage.R \
		name_variant_linkage_decisions.csv \
		name_variant_linkage_member_decisions.csv \
		../input/lihtc_development_2024_adjudicated.parquet \
		../input/lihtc_project_episode_2024_adjudicated.parquet | ../output
	$(R) $<

../output/lihtc_name_variant_linkage_member_decisions_2024.parquet: \
		../output/lihtc_name_variant_linkage_decisions_2024.parquet
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

link-inputs: \
	../input/lihtc_development_2024_adjudicated.parquet \
	../input/lihtc_project_episode_2024_adjudicated.parquet

include ../../generic.make
