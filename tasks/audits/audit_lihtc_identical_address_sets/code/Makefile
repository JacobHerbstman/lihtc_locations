SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/lihtc_identical_address_set_groups.parquet \
	../output/lihtc_identical_address_set_members.parquet \
	../output/lihtc_identical_address_set_pairs.parquet \
	../output/audit_summary.md

../output/lihtc_identical_address_set_groups.parquet: \
		audit_lihtc_identical_address_sets.R \
		../input/lihtc_development_2024_address_round2_adjudicated.parquet \
		../input/lihtc_development_site_2024_address_round2_adjudicated.parquet \
		../input/lihtc_cross_development_pairs_round2_adjudicated.parquet | ../output
	$(R) $<

../output/lihtc_identical_address_set_members.parquet \
../output/lihtc_identical_address_set_pairs.parquet \
../output/audit_summary.md: \
		../output/lihtc_identical_address_set_groups.parquet
	@test -f $@

../input/lihtc_development_2024_address_round2_adjudicated.parquet: \
		../../../apply_lihtc_cross_development_address_review_round2/output/lihtc_development_2024_address_round2_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_cross_development_address_review_round2/output/lihtc_development_2024_address_round2_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_cross_development_address_review_round2/output/lihtc_development_2024_address_round2_adjudicated.parquet "$@"; \
	fi

../input/lihtc_development_site_2024_address_round2_adjudicated.parquet: \
		../../../apply_lihtc_cross_development_address_review_round2/output/lihtc_development_site_2024_address_round2_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_cross_development_address_review_round2/output/lihtc_development_site_2024_address_round2_adjudicated.parquet" ]; then \
		ln -sf ../../../apply_lihtc_cross_development_address_review_round2/output/lihtc_development_site_2024_address_round2_adjudicated.parquet "$@"; \
	fi

../input/lihtc_cross_development_pairs_round2_adjudicated.parquet: \
		../../audit_lihtc_cross_development_addresses_round2_adjudicated/output/lihtc_cross_development_pairs_round2_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../audit_lihtc_cross_development_addresses_round2_adjudicated/output/lihtc_cross_development_pairs_round2_adjudicated.parquet" ]; then \
		ln -sf ../../audit_lihtc_cross_development_addresses_round2_adjudicated/output/lihtc_cross_development_pairs_round2_adjudicated.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_development_2024_address_round2_adjudicated.parquet \
	../input/lihtc_development_site_2024_address_round2_adjudicated.parquet \
	../input/lihtc_cross_development_pairs_round2_adjudicated.parquet

include ../../../generic.make
