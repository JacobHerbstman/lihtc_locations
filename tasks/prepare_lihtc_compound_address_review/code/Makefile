SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/lihtc_compound_address_questions.parquet \
	../output/lihtc_compound_address_parse_proposals.parquet

../output/lihtc_compound_address_questions.parquet: \
		prepare_lihtc_compound_address_review.R \
		../input/lihtc_final_site_geocoding_readiness.parquet | ../output
	$(R) $<

../output/lihtc_compound_address_parse_proposals.parquet: \
		../output/lihtc_compound_address_questions.parquet
	@test -f $@ || $(R) prepare_lihtc_compound_address_review.R

../input/lihtc_final_site_geocoding_readiness.parquet: \
		../../audits/audit_lihtc_final_geocoding_readiness/output/lihtc_final_site_geocoding_readiness.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../audits/audit_lihtc_final_geocoding_readiness/output/lihtc_final_site_geocoding_readiness.parquet" ]; then \
		ln -sf ../../audits/audit_lihtc_final_geocoding_readiness/output/lihtc_final_site_geocoding_readiness.parquet "$@"; \
	fi

link-inputs: ../input/lihtc_final_site_geocoding_readiness.parquet

include ../../generic.make
