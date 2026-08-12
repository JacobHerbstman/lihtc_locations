SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/lihtc_no_site_development_questions.parquet \
	../output/lihtc_no_site_development_episode_members.parquet

../output/lihtc_no_site_development_questions.parquet: \
		prepare_lihtc_no_site_development_review.R \
		../input/lihtc_development_2024_low_income_share_adjudicated.parquet \
		../input/lihtc_project_episode_2024_low_income_share_adjudicated.parquet \
		../input/lihtc_development_site_2024_low_income_share_adjudicated.parquet | ../output
	$(R) $<

../output/lihtc_no_site_development_episode_members.parquet: \
		../output/lihtc_no_site_development_questions.parquet
	@if [ ! -f "$@" ]; then $(R) prepare_lihtc_no_site_development_review.R; fi

../input/lihtc_development_2024_low_income_share_adjudicated.parquet: \
		../../apply_lihtc_low_income_share_review/output/lihtc_development_2024_low_income_share_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_low_income_share_review/output/lihtc_development_2024_low_income_share_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_low_income_share_review/output/lihtc_development_2024_low_income_share_adjudicated.parquet "$@"; \
	fi

../input/lihtc_project_episode_2024_low_income_share_adjudicated.parquet: \
		../../apply_lihtc_low_income_share_review/output/lihtc_project_episode_2024_low_income_share_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_low_income_share_review/output/lihtc_project_episode_2024_low_income_share_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_low_income_share_review/output/lihtc_project_episode_2024_low_income_share_adjudicated.parquet "$@"; \
	fi

../input/lihtc_development_site_2024_low_income_share_adjudicated.parquet: \
		../../apply_lihtc_low_income_share_review/output/lihtc_development_site_2024_low_income_share_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_low_income_share_review/output/lihtc_development_site_2024_low_income_share_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_low_income_share_review/output/lihtc_development_site_2024_low_income_share_adjudicated.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_development_2024_low_income_share_adjudicated.parquet \
	../input/lihtc_project_episode_2024_low_income_share_adjudicated.parquet \
	../input/lihtc_development_site_2024_low_income_share_adjudicated.parquet

include ../../generic.make
