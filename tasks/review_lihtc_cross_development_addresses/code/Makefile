SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/lihtc_cross_development_address_decisions.parquet \
	../output/lihtc_cross_development_address_member_decisions.parquet \
	../output/review_summary.md

../output/lihtc_cross_development_address_decisions.parquet: \
		validate_lihtc_cross_development_addresses.R \
		cross_development_address_decisions.csv \
		../input/lihtc_cross_development_identity_questions.parquet \
		../input/lihtc_cross_development_identity_question_members.parquet | ../output
	$(R) $<

../output/lihtc_cross_development_address_member_decisions.parquet \
../output/review_summary.md: \
		../output/lihtc_cross_development_address_decisions.parquet
	@test -f $@

../input/lihtc_cross_development_identity_questions.parquet: \
		../../prepare_lihtc_cross_development_address_review/output/lihtc_cross_development_identity_questions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../prepare_lihtc_cross_development_address_review/output/lihtc_cross_development_identity_questions.parquet" ]; then \
		ln -sf ../../prepare_lihtc_cross_development_address_review/output/lihtc_cross_development_identity_questions.parquet "$@"; \
	fi

../input/lihtc_cross_development_identity_question_members.parquet: \
		../../prepare_lihtc_cross_development_address_review/output/lihtc_cross_development_identity_question_members.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../prepare_lihtc_cross_development_address_review/output/lihtc_cross_development_identity_question_members.parquet" ]; then \
		ln -sf ../../prepare_lihtc_cross_development_address_review/output/lihtc_cross_development_identity_question_members.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_cross_development_identity_questions.parquet \
	../input/lihtc_cross_development_identity_question_members.parquet

include ../../generic.make
