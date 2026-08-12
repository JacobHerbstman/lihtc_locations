SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/lihtc_compound_address_question_reviews.parquet \
	../output/lihtc_compound_address_component_reviews.parquet

../output/lihtc_compound_address_question_reviews.parquet: \
		validate_lihtc_compound_address_review.R \
		compound_address_question_reviews.csv \
		compound_address_component_reviews.csv \
		../input/lihtc_compound_address_questions.parquet \
		../input/lihtc_compound_address_parse_proposals.parquet | ../output
	$(R) $<

../output/lihtc_compound_address_component_reviews.parquet: \
		../output/lihtc_compound_address_question_reviews.parquet
	@test -f $@ || $(R) validate_lihtc_compound_address_review.R

../input/lihtc_compound_address_questions.parquet: \
		../../prepare_lihtc_compound_address_review/output/lihtc_compound_address_questions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../prepare_lihtc_compound_address_review/output/lihtc_compound_address_questions.parquet" ]; then \
		ln -sf ../../prepare_lihtc_compound_address_review/output/lihtc_compound_address_questions.parquet "$@"; \
	fi

../input/lihtc_compound_address_parse_proposals.parquet: \
		../../prepare_lihtc_compound_address_review/output/lihtc_compound_address_parse_proposals.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../prepare_lihtc_compound_address_review/output/lihtc_compound_address_parse_proposals.parquet" ]; then \
		ln -sf ../../prepare_lihtc_compound_address_review/output/lihtc_compound_address_parse_proposals.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_compound_address_questions.parquet \
	../input/lihtc_compound_address_parse_proposals.parquet

include ../../generic.make
