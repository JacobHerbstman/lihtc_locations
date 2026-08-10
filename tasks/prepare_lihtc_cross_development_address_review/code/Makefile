SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/lihtc_cross_development_identity_questions.parquet \
	../output/lihtc_cross_development_identity_question_members.parquet \
	../output/audit_summary.md

../output/lihtc_cross_development_identity_questions.parquet: \
		prepare_lihtc_cross_development_address_review.R \
		../input/lihtc_cross_development_pairs.parquet \
		../input/lihtc_development_2024_name_adjudicated.parquet \
		../input/lihtc_name_variant_linkage_decisions_2024.parquet | ../output
	$(R) $<

../output/lihtc_cross_development_identity_question_members.parquet \
../output/audit_summary.md: \
		../output/lihtc_cross_development_identity_questions.parquet
	@test -f $@

../input/lihtc_cross_development_pairs.parquet: \
		../../audits/audit_lihtc_cross_development_addresses/output/lihtc_cross_development_pairs.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../audits/audit_lihtc_cross_development_addresses/output/lihtc_cross_development_pairs.parquet" ]; then \
		ln -sf ../../audits/audit_lihtc_cross_development_addresses/output/lihtc_cross_development_pairs.parquet "$@"; \
	fi

../input/lihtc_development_2024_name_adjudicated.parquet: \
		../../apply_lihtc_name_variant_linkage_review/output/lihtc_development_2024_name_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_name_variant_linkage_review/output/lihtc_development_2024_name_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_name_variant_linkage_review/output/lihtc_development_2024_name_adjudicated.parquet "$@"; \
	fi

../input/lihtc_name_variant_linkage_decisions_2024.parquet: \
		../../review_lihtc_name_variant_linkage/output/lihtc_name_variant_linkage_decisions_2024.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../review_lihtc_name_variant_linkage/output/lihtc_name_variant_linkage_decisions_2024.parquet" ]; then \
		ln -sf ../../review_lihtc_name_variant_linkage/output/lihtc_name_variant_linkage_decisions_2024.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_cross_development_pairs.parquet \
	../input/lihtc_development_2024_name_adjudicated.parquet \
	../input/lihtc_name_variant_linkage_decisions_2024.parquet

include ../../generic.make
