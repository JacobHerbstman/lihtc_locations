SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/lihtc_identical_address_set_reviews.parquet \
	../output/lihtc_identical_address_set_proposed_member_mapping.parquet \
	../output/review_summary.md

../output/lihtc_identical_address_set_reviews.parquet: \
		validate_lihtc_identical_address_set_reviews.R \
		lihtc_identical_address_set_reviews.csv \
		../input/lihtc_identical_address_set_groups.parquet \
		../input/lihtc_identical_address_set_members.parquet | ../output
	$(R) $<

../output/lihtc_identical_address_set_proposed_member_mapping.parquet \
../output/review_summary.md: \
		../output/lihtc_identical_address_set_reviews.parquet
	@test -f $@

../input/lihtc_identical_address_set_groups.parquet: \
		../../audits/audit_lihtc_identical_address_sets/output/lihtc_identical_address_set_groups.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../audits/audit_lihtc_identical_address_sets/output/lihtc_identical_address_set_groups.parquet" ]; then \
		ln -sf ../../audits/audit_lihtc_identical_address_sets/output/lihtc_identical_address_set_groups.parquet "$@"; \
	fi

../input/lihtc_identical_address_set_members.parquet: \
		../../audits/audit_lihtc_identical_address_sets/output/lihtc_identical_address_set_members.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../audits/audit_lihtc_identical_address_sets/output/lihtc_identical_address_set_members.parquet" ]; then \
		ln -sf ../../audits/audit_lihtc_identical_address_sets/output/lihtc_identical_address_set_members.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_identical_address_set_groups.parquet \
	../input/lihtc_identical_address_set_members.parquet

include ../../generic.make
