SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/lihtc_unit_scope_question_decisions.parquet \
	../output/lihtc_unit_scope_member_decisions.parquet

../output/lihtc_unit_scope_question_decisions.parquet: \
		validate_lihtc_unit_scope_review.R \
		unit_scope_question_decisions.csv \
		unit_scope_member_decisions.csv \
		../input/lihtc_unit_scope_questions.parquet \
		../input/lihtc_unit_scope_question_members.parquet \
		../input/lihtc_unit_scope_prior_evidence.parquet | ../output
	$(R) $<

../output/lihtc_unit_scope_member_decisions.parquet: \
		../output/lihtc_unit_scope_question_decisions.parquet
	@test -f $@

../input/lihtc_unit_scope_questions.parquet: \
		../../prepare_lihtc_unit_scope_review/output/lihtc_unit_scope_questions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../prepare_lihtc_unit_scope_review/output/lihtc_unit_scope_questions.parquet" ]; then \
		ln -sf ../../prepare_lihtc_unit_scope_review/output/lihtc_unit_scope_questions.parquet "$@"; \
	fi

../input/lihtc_unit_scope_question_members.parquet: \
		../../prepare_lihtc_unit_scope_review/output/lihtc_unit_scope_question_members.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../prepare_lihtc_unit_scope_review/output/lihtc_unit_scope_question_members.parquet" ]; then \
		ln -sf ../../prepare_lihtc_unit_scope_review/output/lihtc_unit_scope_question_members.parquet "$@"; \
	fi

../input/lihtc_unit_scope_prior_evidence.parquet: \
		../../prepare_lihtc_unit_scope_review/output/lihtc_unit_scope_prior_evidence.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../prepare_lihtc_unit_scope_review/output/lihtc_unit_scope_prior_evidence.parquet" ]; then \
		ln -sf ../../prepare_lihtc_unit_scope_review/output/lihtc_unit_scope_prior_evidence.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_unit_scope_questions.parquet \
	../input/lihtc_unit_scope_question_members.parquet \
	../input/lihtc_unit_scope_prior_evidence.parquet

include ../../generic.make
