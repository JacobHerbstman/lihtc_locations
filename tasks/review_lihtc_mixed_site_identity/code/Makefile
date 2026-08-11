SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/lihtc_mixed_site_identity_question_reviews.parquet \
	../output/lihtc_mixed_site_identity_member_partitions.parquet \
	../output/review_summary.md

../output/lihtc_mixed_site_identity_question_reviews.parquet: \
		validate_lihtc_mixed_site_identity_review.R \
		mixed_site_identity_question_reviews.csv \
		mixed_site_identity_member_partitions.csv \
		../input/lihtc_mixed_site_identity_questions.parquet \
		../input/lihtc_mixed_site_identity_question_members.parquet \
		../input/lihtc_mixed_site_identity_question_pairs.parquet | ../output
	$(R) $<

../output/lihtc_mixed_site_identity_member_partitions.parquet \
../output/review_summary.md: \
		../output/lihtc_mixed_site_identity_question_reviews.parquet
	@test -f $@

../input/lihtc_mixed_site_identity_questions.parquet: \
		../../prepare_lihtc_mixed_site_identity_review/output/lihtc_mixed_site_identity_questions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../prepare_lihtc_mixed_site_identity_review/output/lihtc_mixed_site_identity_questions.parquet" ]; then \
		ln -sf ../../prepare_lihtc_mixed_site_identity_review/output/lihtc_mixed_site_identity_questions.parquet "$@"; \
	fi

../input/lihtc_mixed_site_identity_question_members.parquet: \
		../../prepare_lihtc_mixed_site_identity_review/output/lihtc_mixed_site_identity_question_members.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../prepare_lihtc_mixed_site_identity_review/output/lihtc_mixed_site_identity_question_members.parquet" ]; then \
		ln -sf ../../prepare_lihtc_mixed_site_identity_review/output/lihtc_mixed_site_identity_question_members.parquet "$@"; \
	fi

../input/lihtc_mixed_site_identity_question_pairs.parquet: \
		../../prepare_lihtc_mixed_site_identity_review/output/lihtc_mixed_site_identity_question_pairs.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../prepare_lihtc_mixed_site_identity_review/output/lihtc_mixed_site_identity_question_pairs.parquet" ]; then \
		ln -sf ../../prepare_lihtc_mixed_site_identity_review/output/lihtc_mixed_site_identity_question_pairs.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_mixed_site_identity_questions.parquet \
	../input/lihtc_mixed_site_identity_question_members.parquet \
	../input/lihtc_mixed_site_identity_question_pairs.parquet

include ../../generic.make
