SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: ../output/nonwi_low_income_share_review_validated.parquet

../output/nonwi_low_income_share_review_validated.parquet: \
		validate_nonwi_low_income_share_review.R \
		nonwi_low_income_share_review.csv \
		../input/lihtc_development_2024_unit_scope_adjudicated.parquet | ../output
	$(R) $<

../input/lihtc_development_2024_unit_scope_adjudicated.parquet: \
		../../apply_lihtc_unit_scope_review/output/lihtc_development_2024_unit_scope_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_unit_scope_review/output/lihtc_development_2024_unit_scope_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_unit_scope_review/output/lihtc_development_2024_unit_scope_adjudicated.parquet "$@"; \
	fi

link-inputs: ../input/lihtc_development_2024_unit_scope_adjudicated.parquet

include ../../generic.make
