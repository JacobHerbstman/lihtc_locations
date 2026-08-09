SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/lihtc_development_2024.parquet \
	../output/lihtc_project_episode_2024.parquet \
	../output/lihtc_development_site_2024.parquet

../output/lihtc_development_2024.parquet: \
		build_lihtc_development.R \
		../input/lihtc_property_2024_raw_text.parquet \
		../input/lihtc_multisite_2024_raw_text.parquet | ../output
	$(R) $<

../output/lihtc_project_episode_2024.parquet \
../output/lihtc_development_site_2024.parquet: \
		../output/lihtc_development_2024.parquet
	@test -f $@

../input/lihtc_property_2024_raw_text.parquet: \
		../../prepare_lihtc_property/output/lihtc_property_2024_raw_text.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../prepare_lihtc_property/output/lihtc_property_2024_raw_text.parquet" ]; then \
		ln -sf ../../prepare_lihtc_property/output/lihtc_property_2024_raw_text.parquet "$@"; \
	fi

../input/lihtc_multisite_2024_raw_text.parquet: \
		../../prepare_lihtc_multisite/output/lihtc_multisite_2024_raw_text.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../prepare_lihtc_multisite/output/lihtc_multisite_2024_raw_text.parquet" ]; then \
		ln -sf ../../prepare_lihtc_multisite/output/lihtc_multisite_2024_raw_text.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_property_2024_raw_text.parquet \
	../input/lihtc_multisite_2024_raw_text.parquet

include ../../generic.make
