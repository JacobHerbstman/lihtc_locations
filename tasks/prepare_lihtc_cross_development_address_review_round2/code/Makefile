SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/lihtc_cross_development_identity_questions_round2.parquet \
	../output/lihtc_cross_development_identity_question_members_round2.parquet \
	../output/audit_summary.md

../output/lihtc_cross_development_identity_questions_round2.parquet: \
		prepare_lihtc_cross_development_address_review_round2.R \
		../input/lihtc_cross_development_pairs_adjudicated.parquet \
		../input/lihtc_development_2024_address_adjudicated.parquet | ../output
	$(R) $<

../output/lihtc_cross_development_identity_question_members_round2.parquet \
../output/audit_summary.md: \
		../output/lihtc_cross_development_identity_questions_round2.parquet
	@test -f $@

../input/lihtc_cross_development_pairs_adjudicated.parquet: \
		../../audits/audit_lihtc_cross_development_addresses_adjudicated/output/lihtc_cross_development_pairs_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../audits/audit_lihtc_cross_development_addresses_adjudicated/output/lihtc_cross_development_pairs_adjudicated.parquet" ]; then \
		ln -sf ../../audits/audit_lihtc_cross_development_addresses_adjudicated/output/lihtc_cross_development_pairs_adjudicated.parquet "$@"; \
	fi

../input/lihtc_development_2024_address_adjudicated.parquet: \
		../../apply_lihtc_cross_development_address_review/output/lihtc_development_2024_address_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_cross_development_address_review/output/lihtc_development_2024_address_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_cross_development_address_review/output/lihtc_development_2024_address_adjudicated.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_cross_development_pairs_adjudicated.parquet \
	../input/lihtc_development_2024_address_adjudicated.parquet

include ../../generic.make
