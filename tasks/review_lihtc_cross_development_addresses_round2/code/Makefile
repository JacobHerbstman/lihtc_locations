SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/lihtc_cross_development_address_question_reviews_round2.parquet \
	../output/lihtc_cross_development_address_member_partitions_round2.parquet \
	../output/review_summary.md

../output/lihtc_cross_development_address_question_reviews_round2.parquet: \
		validate_lihtc_cross_development_addresses_round2.R \
		cross_development_address_question_reviews_round2.csv \
		cross_development_address_member_partitions_round2.csv \
		../input/lihtc_cross_development_identity_questions_round2.parquet \
		../input/lihtc_cross_development_identity_question_members_round2.parquet | ../output
	$(R) $<

../output/lihtc_cross_development_address_member_partitions_round2.parquet \
../output/review_summary.md: \
		../output/lihtc_cross_development_address_question_reviews_round2.parquet
	@test -f $@

../input/lihtc_cross_development_identity_questions_round2.parquet: \
		../../prepare_lihtc_cross_development_address_review_round2/output/lihtc_cross_development_identity_questions_round2.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../prepare_lihtc_cross_development_address_review_round2/output/lihtc_cross_development_identity_questions_round2.parquet" ]; then \
		ln -sf ../../prepare_lihtc_cross_development_address_review_round2/output/lihtc_cross_development_identity_questions_round2.parquet "$@"; \
	fi

../input/lihtc_cross_development_identity_question_members_round2.parquet: \
		../../prepare_lihtc_cross_development_address_review_round2/output/lihtc_cross_development_identity_question_members_round2.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../prepare_lihtc_cross_development_address_review_round2/output/lihtc_cross_development_identity_question_members_round2.parquet" ]; then \
		ln -sf ../../prepare_lihtc_cross_development_address_review_round2/output/lihtc_cross_development_identity_question_members_round2.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_cross_development_identity_questions_round2.parquet \
	../input/lihtc_cross_development_identity_question_members_round2.parquet

include ../../generic.make
