SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/lihtc_development_2024_low_income_share_adjudicated.parquet \
	../output/lihtc_project_episode_2024_low_income_share_adjudicated.parquet \
	../output/lihtc_development_site_2024_low_income_share_adjudicated.parquet

../output/lihtc_development_2024_low_income_share_adjudicated.parquet: \
		apply_lihtc_low_income_share_review.R \
		../input/lihtc_development_2024_unit_scope_adjudicated.parquet \
		../input/lihtc_project_episode_2024_unit_scope_adjudicated.parquet \
		../input/lihtc_development_site_2024_unit_scope_adjudicated.parquet \
		../input/lihtc_wi_low_income_share_review.parquet \
		../input/nonwi_low_income_share_review_validated.parquet | ../output
	$(R) $<

../output/lihtc_project_episode_2024_low_income_share_adjudicated.parquet \
../output/lihtc_development_site_2024_low_income_share_adjudicated.parquet: \
		../output/lihtc_development_2024_low_income_share_adjudicated.parquet
	@test -f $@

../input/lihtc_development_2024_unit_scope_adjudicated.parquet: \
		../../apply_lihtc_unit_scope_review/output/lihtc_development_2024_unit_scope_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_unit_scope_review/output/lihtc_development_2024_unit_scope_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_unit_scope_review/output/lihtc_development_2024_unit_scope_adjudicated.parquet "$@"; \
	fi

../input/lihtc_project_episode_2024_unit_scope_adjudicated.parquet: \
		../../apply_lihtc_unit_scope_review/output/lihtc_project_episode_2024_unit_scope_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_unit_scope_review/output/lihtc_project_episode_2024_unit_scope_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_unit_scope_review/output/lihtc_project_episode_2024_unit_scope_adjudicated.parquet "$@"; \
	fi

../input/lihtc_development_site_2024_unit_scope_adjudicated.parquet: \
		../../apply_lihtc_unit_scope_review/output/lihtc_development_site_2024_unit_scope_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_unit_scope_review/output/lihtc_development_site_2024_unit_scope_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_unit_scope_review/output/lihtc_development_site_2024_unit_scope_adjudicated.parquet "$@"; \
	fi

../input/lihtc_wi_low_income_share_review.parquet: \
		../../review_lihtc_wi_low_income_share/output/lihtc_wi_low_income_share_review.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../review_lihtc_wi_low_income_share/output/lihtc_wi_low_income_share_review.parquet" ]; then \
		ln -sf ../../review_lihtc_wi_low_income_share/output/lihtc_wi_low_income_share_review.parquet "$@"; \
	fi

../input/nonwi_low_income_share_review_validated.parquet: \
		../../review_lihtc_non_wi_low_income_share/output/nonwi_low_income_share_review_validated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../review_lihtc_non_wi_low_income_share/output/nonwi_low_income_share_review_validated.parquet" ]; then \
		ln -sf ../../review_lihtc_non_wi_low_income_share/output/nonwi_low_income_share_review_validated.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_development_2024_unit_scope_adjudicated.parquet \
	../input/lihtc_project_episode_2024_unit_scope_adjudicated.parquet \
	../input/lihtc_development_site_2024_unit_scope_adjudicated.parquet \
	../input/lihtc_wi_low_income_share_review.parquet \
	../input/nonwi_low_income_share_review_validated.parquet

include ../../generic.make
