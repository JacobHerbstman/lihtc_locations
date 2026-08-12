SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/lihtc_ga_no_site_dca_source_access_blocker.parquet \
	../output/lihtc_ga_no_site_dca_source_access_summary.csv

../output/lihtc_ga_no_site_dca_source_access_blocker.parquet: \
		prepare_lihtc_ga_no_site_dca_source_review.R \
		../input/lihtc_no_site_development_questions.parquet \
		../input/manifest.csv \
		../input/experience_configuration.json \
		../input/web_map_configuration.json \
		../input/layer_metadata.json | ../output
	$(R) $<

../output/lihtc_ga_no_site_dca_source_access_summary.csv: \
		../output/lihtc_ga_no_site_dca_source_access_blocker.parquet
	@test -f "$@"

../input/lihtc_no_site_development_questions.parquet: \
		../../prepare_lihtc_no_site_development_review/output/lihtc_no_site_development_questions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../prepare_lihtc_no_site_development_review/output/lihtc_no_site_development_questions.parquet" ]; then \
		ln -sf ../../prepare_lihtc_no_site_development_review/output/lihtc_no_site_development_questions.parquet "$@"; \
	fi

../input/manifest.csv: \
		../../../data_raw/ga_dca_lihtc_map/2026-08-12/manifest.csv | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/ga_dca_lihtc_map/2026-08-12/manifest.csv" ]; then \
		ln -sf ../../../data_raw/ga_dca_lihtc_map/2026-08-12/manifest.csv "$@"; \
	fi

../input/experience_configuration.json: \
		../../../data_raw/ga_dca_lihtc_map/2026-08-12/experience_configuration.json | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/ga_dca_lihtc_map/2026-08-12/experience_configuration.json" ]; then \
		ln -sf ../../../data_raw/ga_dca_lihtc_map/2026-08-12/experience_configuration.json "$@"; \
	fi

../input/web_map_configuration.json: \
		../../../data_raw/ga_dca_lihtc_map/2026-08-12/web_map_configuration.json | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/ga_dca_lihtc_map/2026-08-12/web_map_configuration.json" ]; then \
		ln -sf ../../../data_raw/ga_dca_lihtc_map/2026-08-12/web_map_configuration.json "$@"; \
	fi

../input/layer_metadata.json: \
		../../../data_raw/ga_dca_lihtc_map/2026-08-12/layer_metadata.json | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/ga_dca_lihtc_map/2026-08-12/layer_metadata.json" ]; then \
		ln -sf ../../../data_raw/ga_dca_lihtc_map/2026-08-12/layer_metadata.json "$@"; \
	fi

link-inputs: \
	../input/lihtc_no_site_development_questions.parquet \
	../input/manifest.csv \
	../input/experience_configuration.json \
	../input/web_map_configuration.json \
	../input/layer_metadata.json

include ../../generic.make
