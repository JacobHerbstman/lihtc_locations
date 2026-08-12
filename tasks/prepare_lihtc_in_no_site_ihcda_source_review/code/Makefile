SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/lihtc_in_no_site_ihcda_source_access_blocker.parquet \
	../output/lihtc_in_no_site_ihcda_source_access_summary.csv

../output/lihtc_in_no_site_ihcda_source_access_blocker.parquet: \
		prepare_lihtc_in_no_site_ihcda_source_review.R \
		../input/lihtc_no_site_development_questions.parquet \
		../input/source_manifest.csv \
		../input/ihcda_lihtc_landing_page.html | ../output
	$(R) $<

../output/lihtc_in_no_site_ihcda_source_access_summary.csv: \
		../output/lihtc_in_no_site_ihcda_source_access_blocker.parquet
	@test -f $@

../input/lihtc_no_site_development_questions.parquet: \
		../../prepare_lihtc_no_site_development_review/output/lihtc_no_site_development_questions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../prepare_lihtc_no_site_development_review/output/lihtc_no_site_development_questions.parquet" ]; then \
		ln -sf ../../prepare_lihtc_no_site_development_review/output/lihtc_no_site_development_questions.parquet "$@"; \
	fi

../input/source_manifest.csv: \
		../../../data_raw/ihcda_existing_lihtc_properties/2026-08-12/source_manifest.csv | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/ihcda_existing_lihtc_properties/2026-08-12/source_manifest.csv" ]; then \
		ln -sf ../../../data_raw/ihcda_existing_lihtc_properties/2026-08-12/source_manifest.csv "$@"; \
	fi

../input/ihcda_lihtc_landing_page.html: \
		../../../data_raw/ihcda_existing_lihtc_properties/2026-08-12/ihcda_lihtc_landing_page.html | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/ihcda_existing_lihtc_properties/2026-08-12/ihcda_lihtc_landing_page.html" ]; then \
		ln -sf ../../../data_raw/ihcda_existing_lihtc_properties/2026-08-12/ihcda_lihtc_landing_page.html "$@"; \
	fi

link-inputs: \
	../input/lihtc_no_site_development_questions.parquet \
	../input/source_manifest.csv \
	../input/ihcda_lihtc_landing_page.html

include ../../generic.make
