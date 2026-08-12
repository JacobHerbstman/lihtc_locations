SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: ../output/lihtc_tx_no_site_second_read_validated.parquet

../output/lihtc_tx_no_site_second_read_validated.parquet: \
		review_lihtc_tx_no_site_source_review.R \
		lihtc_tx_no_site_second_read_ledger.csv \
		lihtc_tx_no_site_second_read_evidence.csv \
		../input/lihtc_tx_no_site_tdhca_exact_source_candidates.parquet \
		../input/lihtc_tx_no_site_tdhca_fuzzy_source_candidates.parquet \
		../input/tx_no_site_second_reads_2026-08-12_manifest.csv \
		../input/constitution_court_municipal.html \
		../input/floral_gardens_manager.html \
		../input/guadalupe_crossing_tx_puc.html \
		../input/heights_corral_tamuk.pdf \
		../input/heights_corral_tdhca_2008_log.pdf \
		../input/hillsboro_tdhca_2000_log.pdf \
		../input/hillsboro_tdhca_board_2018.pdf \
		../input/justice_park_houston_2012.pdf \
		../input/justice_park_houston_2024.pdf \
		../input/maeghan_pointe_tejas.html \
		../input/park_ridge_txhf.html \
		../input/san_antonio_2020_council.html \
		../input/sunrise_terrace_manager.html \
		../input/tierra_pointe_merced.html | ../output
	$(R) $<

../input/lihtc_tx_no_site_tdhca_exact_source_candidates.parquet: \
		../../prepare_lihtc_tx_no_site_tdhca_source_review/output/lihtc_tx_no_site_tdhca_exact_source_candidates.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../prepare_lihtc_tx_no_site_tdhca_source_review/output/lihtc_tx_no_site_tdhca_exact_source_candidates.parquet" ]; then \
		ln -sf ../../prepare_lihtc_tx_no_site_tdhca_source_review/output/lihtc_tx_no_site_tdhca_exact_source_candidates.parquet "$@"; \
	fi

../input/lihtc_tx_no_site_tdhca_fuzzy_source_candidates.parquet: \
		../../prepare_lihtc_tx_no_site_tdhca_source_review/output/lihtc_tx_no_site_tdhca_fuzzy_source_candidates.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../prepare_lihtc_tx_no_site_tdhca_source_review/output/lihtc_tx_no_site_tdhca_fuzzy_source_candidates.parquet" ]; then \
		ln -sf ../../prepare_lihtc_tx_no_site_tdhca_source_review/output/lihtc_tx_no_site_tdhca_fuzzy_source_candidates.parquet "$@"; \
	fi

../input/tx_no_site_second_reads_2026-08-12_manifest.csv: \
		../../../data_raw/tx_no_site_second_reads/2026-08-12/manifest.csv | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/tx_no_site_second_reads/2026-08-12/manifest.csv" ]; then \
		ln -sf ../../../data_raw/tx_no_site_second_reads/2026-08-12/manifest.csv "$@"; \
	fi

../input/constitution_court_municipal.html: \
		../../../data_raw/tx_no_site_second_reads/2026-08-12/constitution_court_municipal.html | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/tx_no_site_second_reads/2026-08-12/constitution_court_municipal.html" ]; then \
		ln -sf ../../../data_raw/tx_no_site_second_reads/2026-08-12/constitution_court_municipal.html "$@"; \
	fi

../input/floral_gardens_manager.html: \
		../../../data_raw/tx_no_site_second_reads/2026-08-12/floral_gardens_manager.html | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/tx_no_site_second_reads/2026-08-12/floral_gardens_manager.html" ]; then \
		ln -sf ../../../data_raw/tx_no_site_second_reads/2026-08-12/floral_gardens_manager.html "$@"; \
	fi

../input/guadalupe_crossing_tx_puc.html: \
		../../../data_raw/tx_no_site_second_reads/2026-08-12/guadalupe_crossing_tx_puc.html | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/tx_no_site_second_reads/2026-08-12/guadalupe_crossing_tx_puc.html" ]; then \
		ln -sf ../../../data_raw/tx_no_site_second_reads/2026-08-12/guadalupe_crossing_tx_puc.html "$@"; \
	fi

../input/heights_corral_tamuk.pdf: \
		../../../data_raw/tx_no_site_second_reads/2026-08-12/heights_corral_tamuk.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/tx_no_site_second_reads/2026-08-12/heights_corral_tamuk.pdf" ]; then \
		ln -sf ../../../data_raw/tx_no_site_second_reads/2026-08-12/heights_corral_tamuk.pdf "$@"; \
	fi

../input/heights_corral_tdhca_2008_log.pdf: \
		../../../data_raw/tx_no_site_second_reads/2026-08-12/heights_corral_tdhca_2008_log.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/tx_no_site_second_reads/2026-08-12/heights_corral_tdhca_2008_log.pdf" ]; then \
		ln -sf ../../../data_raw/tx_no_site_second_reads/2026-08-12/heights_corral_tdhca_2008_log.pdf "$@"; \
	fi

../input/hillsboro_tdhca_2000_log.pdf: \
		../../../data_raw/tx_no_site_second_reads/2026-08-12/hillsboro_tdhca_2000_log.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/tx_no_site_second_reads/2026-08-12/hillsboro_tdhca_2000_log.pdf" ]; then \
		ln -sf ../../../data_raw/tx_no_site_second_reads/2026-08-12/hillsboro_tdhca_2000_log.pdf "$@"; \
	fi

../input/hillsboro_tdhca_board_2018.pdf: \
		../../../data_raw/tx_no_site_second_reads/2026-08-12/hillsboro_tdhca_board_2018.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/tx_no_site_second_reads/2026-08-12/hillsboro_tdhca_board_2018.pdf" ]; then \
		ln -sf ../../../data_raw/tx_no_site_second_reads/2026-08-12/hillsboro_tdhca_board_2018.pdf "$@"; \
	fi

../input/justice_park_houston_2012.pdf: \
		../../../data_raw/tx_no_site_second_reads/2026-08-12/justice_park_houston_2012.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/tx_no_site_second_reads/2026-08-12/justice_park_houston_2012.pdf" ]; then \
		ln -sf ../../../data_raw/tx_no_site_second_reads/2026-08-12/justice_park_houston_2012.pdf "$@"; \
	fi

../input/justice_park_houston_2024.pdf: \
		../../../data_raw/tx_no_site_second_reads/2026-08-12/justice_park_houston_2024.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/tx_no_site_second_reads/2026-08-12/justice_park_houston_2024.pdf" ]; then \
		ln -sf ../../../data_raw/tx_no_site_second_reads/2026-08-12/justice_park_houston_2024.pdf "$@"; \
	fi

../input/maeghan_pointe_tejas.html: \
		../../../data_raw/tx_no_site_second_reads/2026-08-12/maeghan_pointe_tejas.html | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/tx_no_site_second_reads/2026-08-12/maeghan_pointe_tejas.html" ]; then \
		ln -sf ../../../data_raw/tx_no_site_second_reads/2026-08-12/maeghan_pointe_tejas.html "$@"; \
	fi

../input/park_ridge_txhf.html: \
		../../../data_raw/tx_no_site_second_reads/2026-08-12/park_ridge_txhf.html | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/tx_no_site_second_reads/2026-08-12/park_ridge_txhf.html" ]; then \
		ln -sf ../../../data_raw/tx_no_site_second_reads/2026-08-12/park_ridge_txhf.html "$@"; \
	fi

../input/san_antonio_2020_council.html: \
		../../../data_raw/tx_no_site_second_reads/2026-08-12/san_antonio_2020_council.html | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/tx_no_site_second_reads/2026-08-12/san_antonio_2020_council.html" ]; then \
		ln -sf ../../../data_raw/tx_no_site_second_reads/2026-08-12/san_antonio_2020_council.html "$@"; \
	fi

../input/sunrise_terrace_manager.html: \
		../../../data_raw/tx_no_site_second_reads/2026-08-12/sunrise_terrace_manager.html | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/tx_no_site_second_reads/2026-08-12/sunrise_terrace_manager.html" ]; then \
		ln -sf ../../../data_raw/tx_no_site_second_reads/2026-08-12/sunrise_terrace_manager.html "$@"; \
	fi

../input/tierra_pointe_merced.html: \
		../../../data_raw/tx_no_site_second_reads/2026-08-12/tierra_pointe_merced.html | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/tx_no_site_second_reads/2026-08-12/tierra_pointe_merced.html" ]; then \
		ln -sf ../../../data_raw/tx_no_site_second_reads/2026-08-12/tierra_pointe_merced.html "$@"; \
	fi

link-inputs: \
	../input/lihtc_tx_no_site_tdhca_exact_source_candidates.parquet \
	../input/lihtc_tx_no_site_tdhca_fuzzy_source_candidates.parquet \
	../input/tx_no_site_second_reads_2026-08-12_manifest.csv \
	../input/constitution_court_municipal.html \
	../input/floral_gardens_manager.html \
	../input/guadalupe_crossing_tx_puc.html \
	../input/heights_corral_tamuk.pdf \
	../input/heights_corral_tdhca_2008_log.pdf \
	../input/hillsboro_tdhca_2000_log.pdf \
	../input/hillsboro_tdhca_board_2018.pdf \
	../input/justice_park_houston_2012.pdf \
	../input/justice_park_houston_2024.pdf \
	../input/maeghan_pointe_tejas.html \
	../input/park_ridge_txhf.html \
	../input/san_antonio_2020_council.html \
	../input/sunrise_terrace_manager.html \
	../input/tierra_pointe_merced.html

include ../../generic.make
