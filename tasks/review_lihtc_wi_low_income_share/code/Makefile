SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: ../output/lihtc_wi_low_income_share_review.parquet

../output/lihtc_wi_low_income_share_review.parquet: \
		validate_lihtc_wi_low_income_share_review.R \
		wi_low_income_share_reviews.csv \
		../input/lihtc_wi_low_income_share_candidates.parquet \
		../input/lihtc_development_2024_unit_scope_adjudicated.parquet | ../output
	$(R) $<

../input/lihtc_wi_low_income_share_candidates.parquet: \
		../../prepare_lihtc_wi_low_income_share_review/output/lihtc_wi_low_income_share_candidates.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../prepare_lihtc_wi_low_income_share_review/output/lihtc_wi_low_income_share_candidates.parquet" ]; then \
		ln -sf ../../prepare_lihtc_wi_low_income_share_review/output/lihtc_wi_low_income_share_candidates.parquet "$@"; \
	fi

../input/lihtc_development_2024_unit_scope_adjudicated.parquet: \
		../../apply_lihtc_unit_scope_review/output/lihtc_development_2024_unit_scope_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_unit_scope_review/output/lihtc_development_2024_unit_scope_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_unit_scope_review/output/lihtc_development_2024_unit_scope_adjudicated.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_wi_low_income_share_candidates.parquet \
	../input/lihtc_development_2024_unit_scope_adjudicated.parquet

include ../../generic.make
