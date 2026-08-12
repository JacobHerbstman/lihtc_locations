SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/lihtc_tx_no_site_tdhca_questions.parquet \
	../output/lihtc_tx_no_site_tdhca_exact_source_candidates.parquet \
	../output/lihtc_tx_no_site_tdhca_fuzzy_source_candidates.parquet \
	../output/lihtc_tx_no_site_tdhca_screening_summary.csv

../output/lihtc_tx_no_site_tdhca_questions.parquet: \
		prepare_lihtc_tx_no_site_tdhca_source_review.R \
		../input/lihtc_no_site_development_questions.parquet \
		../input/HTCPropertyInventory_0.xlsx \
		../input/tdhca_htc_property_inventory_2026-08-12_manifest.sha256 | ../output
	$(R) $<

../output/lihtc_tx_no_site_tdhca_exact_source_candidates.parquet \
../output/lihtc_tx_no_site_tdhca_fuzzy_source_candidates.parquet \
../output/lihtc_tx_no_site_tdhca_screening_summary.csv: \
		../output/lihtc_tx_no_site_tdhca_questions.parquet
	@test -f "$@"

../input/lihtc_no_site_development_questions.parquet: \
		../../prepare_lihtc_no_site_development_review/output/lihtc_no_site_development_questions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../prepare_lihtc_no_site_development_review/output/lihtc_no_site_development_questions.parquet" ]; then \
		ln -sf ../../prepare_lihtc_no_site_development_review/output/lihtc_no_site_development_questions.parquet "$@"; \
	fi

../input/HTCPropertyInventory_0.xlsx: \
		../../../data_raw/tdhca_htc_property_inventory/2026-08-12/HTCPropertyInventory_0.xlsx | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/tdhca_htc_property_inventory/2026-08-12/HTCPropertyInventory_0.xlsx" ]; then \
		ln -sf ../../../data_raw/tdhca_htc_property_inventory/2026-08-12/HTCPropertyInventory_0.xlsx "$@"; \
	fi

../input/tdhca_htc_property_inventory_2026-08-12_manifest.sha256: \
		../../../data_raw/tdhca_htc_property_inventory/2026-08-12/manifest.sha256 | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/tdhca_htc_property_inventory/2026-08-12/manifest.sha256" ]; then \
		ln -sf ../../../data_raw/tdhca_htc_property_inventory/2026-08-12/manifest.sha256 "$@"; \
	fi

link-inputs: \
	../input/lihtc_no_site_development_questions.parquet \
	../input/HTCPropertyInventory_0.xlsx \
	../input/tdhca_htc_property_inventory_2026-08-12_manifest.sha256

include ../../generic.make
