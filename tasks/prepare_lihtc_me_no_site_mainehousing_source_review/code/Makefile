SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/lihtc_me_no_site_mainehousing_questions.parquet \
	../output/lihtc_me_no_site_mainehousing_exact_source_candidates.parquet \
	../output/lihtc_me_no_site_mainehousing_fuzzy_source_candidates.parquet \
	../output/lihtc_me_no_site_mainehousing_screening_summary.csv

../output/lihtc_me_no_site_mainehousing_questions.parquet: \
		prepare_lihtc_me_no_site_mainehousing_source_review.R \
		../input/lihtc_no_site_development_questions.parquet \
		../input/source_manifest.csv \
		../input/mainehousing_subsidized_housing.html \
		../input/androscoggin.pdf \
		../input/aroostook.pdf \
		../input/cumberland.pdf \
		../input/franklin.pdf \
		../input/hancock.pdf \
		../input/kennebec.pdf \
		../input/knox.pdf \
		../input/lincoln.pdf \
		../input/oxford.pdf \
		../input/penobscot.pdf \
		../input/piscataquis.pdf \
		../input/sagadahoc.pdf \
		../input/somerset.pdf \
		../input/waldo.pdf \
		../input/washington.pdf \
		../input/york.pdf | ../output
	$(R) $<

../output/lihtc_me_no_site_mainehousing_exact_source_candidates.parquet \
../output/lihtc_me_no_site_mainehousing_fuzzy_source_candidates.parquet \
../output/lihtc_me_no_site_mainehousing_screening_summary.csv: \
		../output/lihtc_me_no_site_mainehousing_questions.parquet
	@test -f "$@"

../input/lihtc_no_site_development_questions.parquet: \
		../../prepare_lihtc_no_site_development_review/output/lihtc_no_site_development_questions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../prepare_lihtc_no_site_development_review/output/lihtc_no_site_development_questions.parquet" ]; then \
		ln -sf ../../prepare_lihtc_no_site_development_review/output/lihtc_no_site_development_questions.parquet "$@"; \
	fi

../input/source_manifest.csv: \
		../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/source_manifest.csv | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/source_manifest.csv" ]; then \
		ln -sf ../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/source_manifest.csv "$@"; \
	fi

../input/mainehousing_subsidized_housing.html: \
		../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/mainehousing_subsidized_housing.html | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/mainehousing_subsidized_housing.html" ]; then \
		ln -sf ../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/mainehousing_subsidized_housing.html "$@"; \
	fi

../input/androscoggin.pdf: ../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/androscoggin.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/androscoggin.pdf" ]; then ln -sf ../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/androscoggin.pdf "$@"; fi

../input/aroostook.pdf: ../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/aroostook.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/aroostook.pdf" ]; then ln -sf ../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/aroostook.pdf "$@"; fi

../input/cumberland.pdf: ../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/cumberland.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/cumberland.pdf" ]; then ln -sf ../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/cumberland.pdf "$@"; fi

../input/franklin.pdf: ../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/franklin.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/franklin.pdf" ]; then ln -sf ../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/franklin.pdf "$@"; fi

../input/hancock.pdf: ../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/hancock.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/hancock.pdf" ]; then ln -sf ../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/hancock.pdf "$@"; fi

../input/kennebec.pdf: ../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/kennebec.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/kennebec.pdf" ]; then ln -sf ../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/kennebec.pdf "$@"; fi

../input/knox.pdf: ../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/knox.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/knox.pdf" ]; then ln -sf ../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/knox.pdf "$@"; fi

../input/lincoln.pdf: ../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/lincoln.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/lincoln.pdf" ]; then ln -sf ../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/lincoln.pdf "$@"; fi

../input/oxford.pdf: ../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/oxford.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/oxford.pdf" ]; then ln -sf ../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/oxford.pdf "$@"; fi

../input/penobscot.pdf: ../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/penobscot.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/penobscot.pdf" ]; then ln -sf ../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/penobscot.pdf "$@"; fi

../input/piscataquis.pdf: ../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/piscataquis.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/piscataquis.pdf" ]; then ln -sf ../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/piscataquis.pdf "$@"; fi

../input/sagadahoc.pdf: ../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/sagadahoc.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/sagadahoc.pdf" ]; then ln -sf ../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/sagadahoc.pdf "$@"; fi

../input/somerset.pdf: ../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/somerset.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/somerset.pdf" ]; then ln -sf ../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/somerset.pdf "$@"; fi

../input/waldo.pdf: ../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/waldo.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/waldo.pdf" ]; then ln -sf ../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/waldo.pdf "$@"; fi

../input/washington.pdf: ../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/washington.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/washington.pdf" ]; then ln -sf ../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/washington.pdf "$@"; fi

../input/york.pdf: ../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/york.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/york.pdf" ]; then ln -sf ../../../data_raw/mainehousing_subsidized_apartment_listings/2026-08-12/york.pdf "$@"; fi

link-inputs: \
	../input/lihtc_no_site_development_questions.parquet \
	../input/source_manifest.csv \
	../input/mainehousing_subsidized_housing.html \
	../input/androscoggin.pdf \
	../input/aroostook.pdf \
	../input/cumberland.pdf \
	../input/franklin.pdf \
	../input/hancock.pdf \
	../input/kennebec.pdf \
	../input/knox.pdf \
	../input/lincoln.pdf \
	../input/oxford.pdf \
	../input/penobscot.pdf \
	../input/piscataquis.pdf \
	../input/sagadahoc.pdf \
	../input/somerset.pdf \
	../input/waldo.pdf \
	../input/washington.pdf \
	../input/york.pdf

include ../../generic.make
