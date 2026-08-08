SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: ../output/lihtc_property_2024_raw_text.parquet

../output/lihtc_property_2024_raw_text.parquet: \
		prepare_lihtc_property.R \
		../temp/LIHTCPUB.xlsx \
		../input/lihtc_property_2024_files.csv | ../output
	$(R) $<

../temp/LIHTCPUB.xlsx: ../input/lihtcpub.zip | ../temp
	unzip -oq $< LIHTCPUB.xlsx -d ../temp
	touch $@

../input/lihtcpub.zip: ../../../data_raw/hud_lihtc_property/2024/lihtcpub.zip | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/hud_lihtc_property/2024/lihtcpub.zip" ]; then \
		ln -sf ../../../data_raw/hud_lihtc_property/2024/lihtcpub.zip "$@"; \
	fi

../input/lihtc_property_2024_files.csv: ../../fetch_lihtc_property/output/lihtc_property_2024_files.csv | ../input
	@if [ "$$(readlink "$@")" != "../../fetch_lihtc_property/output/lihtc_property_2024_files.csv" ]; then \
		ln -sf ../../fetch_lihtc_property/output/lihtc_property_2024_files.csv "$@"; \
	fi

link-inputs: ../input/lihtcpub.zip ../input/lihtc_property_2024_files.csv

include ../../generic.make
