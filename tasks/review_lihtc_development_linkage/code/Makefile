SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/lihtc_development_linkage_decisions_2024.parquet \
	../output/lihtc_development_linkage_member_decisions_2024.parquet

../output/lihtc_development_linkage_decisions_2024.parquet: \
		validate_lihtc_development_linkage.R \
		development_linkage_decisions.csv \
		development_linkage_member_decisions.csv \
		../input/lihtc_development_2024.parquet \
		../input/lihtc_project_episode_2024.parquet | ../output
	$(R) $<

../output/lihtc_development_linkage_member_decisions_2024.parquet: \
		../output/lihtc_development_linkage_decisions_2024.parquet
	@test -f $@

../input/lihtc_development_2024.parquet: \
		../../build_lihtc_development/output/lihtc_development_2024.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../build_lihtc_development/output/lihtc_development_2024.parquet" ]; then \
		ln -sf ../../build_lihtc_development/output/lihtc_development_2024.parquet "$@"; \
	fi

../input/lihtc_project_episode_2024.parquet: \
		../../build_lihtc_development/output/lihtc_project_episode_2024.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../build_lihtc_development/output/lihtc_project_episode_2024.parquet" ]; then \
		ln -sf ../../build_lihtc_development/output/lihtc_project_episode_2024.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_development_2024.parquet \
	../input/lihtc_project_episode_2024.parquet

include ../../generic.make
