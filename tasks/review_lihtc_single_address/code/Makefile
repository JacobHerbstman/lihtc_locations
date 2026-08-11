SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/lihtc_single_address_question_reviews.parquet \
	../output/lihtc_single_address_member_partitions.parquet \
	../output/review_summary.md

../output/lihtc_single_address_question_reviews.parquet: \
		validate_lihtc_single_address_review.R \
		single_address_question_reviews.csv \
		single_address_member_partitions.csv \
		../input/lihtc_single_address_identity_questions.parquet \
		../input/lihtc_single_address_identity_question_members.parquet \
		../input/lihtc_single_address_identity_question_pairs.parquet | ../output
	$(R) $<

../output/lihtc_single_address_member_partitions.parquet \
../output/review_summary.md: \
		../output/lihtc_single_address_question_reviews.parquet
	@test -f $@

../input/lihtc_single_address_identity_questions.parquet: \
		../../prepare_lihtc_single_address_review/output/lihtc_single_address_identity_questions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../prepare_lihtc_single_address_review/output/lihtc_single_address_identity_questions.parquet" ]; then \
		ln -sf ../../prepare_lihtc_single_address_review/output/lihtc_single_address_identity_questions.parquet "$@"; \
	fi

../input/lihtc_single_address_identity_question_members.parquet: \
		../../prepare_lihtc_single_address_review/output/lihtc_single_address_identity_question_members.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../prepare_lihtc_single_address_review/output/lihtc_single_address_identity_question_members.parquet" ]; then \
		ln -sf ../../prepare_lihtc_single_address_review/output/lihtc_single_address_identity_question_members.parquet "$@"; \
	fi

../input/lihtc_single_address_identity_question_pairs.parquet: \
		../../prepare_lihtc_single_address_review/output/lihtc_single_address_identity_question_pairs.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../prepare_lihtc_single_address_review/output/lihtc_single_address_identity_question_pairs.parquet" ]; then \
		ln -sf ../../prepare_lihtc_single_address_review/output/lihtc_single_address_identity_question_pairs.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_single_address_identity_questions.parquet \
	../input/lihtc_single_address_identity_question_members.parquet \
	../input/lihtc_single_address_identity_question_pairs.parquet

include ../../generic.make
