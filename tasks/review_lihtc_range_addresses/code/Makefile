SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: ../output/lihtc_range_address_reviews.parquet

../output/lihtc_range_address_reviews.parquet: \
		validate_lihtc_range_address_review.R \
		range_address_reviews.csv \
		../input/lihtc_range_address_questions.parquet | ../output
	$(R) $<

../input/lihtc_range_address_questions.parquet: \
		../../prepare_lihtc_range_address_review/output/lihtc_range_address_questions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../prepare_lihtc_range_address_review/output/lihtc_range_address_questions.parquet" ]; then \
		ln -sf ../../prepare_lihtc_range_address_review/output/lihtc_range_address_questions.parquet "$@"; \
	fi

link-inputs: ../input/lihtc_range_address_questions.parquet

include ../../generic.make
