SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/lihtc_external_benchmark_audit.parquet \
	../output/benchmark_summary.md

../output/lihtc_external_benchmark_audit.parquet: \
		audit_lihtc_external_benchmarks.R \
		external_benchmarks.csv \
		../input/lihtc_development_2024_low_income_share_adjudicated.parquet \
		../input/lihtc_project_episode_2024_low_income_share_adjudicated.parquet | ../output
	$(R) $<

../output/benchmark_summary.md: ../output/lihtc_external_benchmark_audit.parquet
	@test -f $@

../input/lihtc_development_2024_low_income_share_adjudicated.parquet: \
		../../../apply_lihtc_low_income_share_review/output/lihtc_development_2024_low_income_share_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_low_income_share_review/output/lihtc_development_2024_low_income_share_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_low_income_share_review/output/lihtc_development_2024_low_income_share_adjudicated.parquet "$@"; \
	fi

../input/lihtc_project_episode_2024_low_income_share_adjudicated.parquet: \
		../../../apply_lihtc_low_income_share_review/output/lihtc_project_episode_2024_low_income_share_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_low_income_share_review/output/lihtc_project_episode_2024_low_income_share_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_low_income_share_review/output/lihtc_project_episode_2024_low_income_share_adjudicated.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_development_2024_low_income_share_adjudicated.parquet \
	../input/lihtc_project_episode_2024_low_income_share_adjudicated.parquet

include ../../../generic.make
