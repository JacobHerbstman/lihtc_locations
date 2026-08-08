SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/audit_summary.md \
	../output/column_profile.csv \
	../output/top_value_frequencies.csv \
	../output/row_issue_summary.csv \
	../output/row_issues.csv \
	../output/duplicate_groups.csv \
	../output/duplicate_members.csv \
	../output/workbook_structure.csv

../output/audit_summary.md: \
		audit_lihtc_property.R \
		dictionary_claims.csv \
		../input/lihtc_property_2024_raw_text.parquet \
		../input/lihtc_property_2024_files.csv \
		../output/workbook_structure.csv | ../output
	$(R) $<

../output/column_profile.csv \
../output/top_value_frequencies.csv \
../output/row_issue_summary.csv \
../output/row_issues.csv \
../output/duplicate_groups.csv \
../output/duplicate_members.csv: ../output/audit_summary.md
	@test -f $@

../output/workbook_structure.csv: inspect_workbook_xml.py ../temp/LIHTCPUB.xlsx | ../output
	python3 $<

../temp/LIHTCPUB.xlsx: ../input/lihtcpub.zip | ../temp
	unzip -oq $< LIHTCPUB.xlsx -d ../temp
	touch $@

../input/lihtcpub.zip: ../../../../data_raw/hud_lihtc_property/2024/lihtcpub.zip | ../input
	@if [ "$$(readlink "$@")" != "../../../../data_raw/hud_lihtc_property/2024/lihtcpub.zip" ]; then \
		ln -sf ../../../../data_raw/hud_lihtc_property/2024/lihtcpub.zip "$@"; \
	fi

../input/lihtc_property_2024_files.csv: ../../../fetch_lihtc_property/output/lihtc_property_2024_files.csv | ../input
	@if [ "$$(readlink "$@")" != "../../../fetch_lihtc_property/output/lihtc_property_2024_files.csv" ]; then \
		ln -sf ../../../fetch_lihtc_property/output/lihtc_property_2024_files.csv "$@"; \
	fi

../input/lihtc_property_2024_raw_text.parquet: \
		../../../prepare_lihtc_property/output/lihtc_property_2024_raw_text.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../prepare_lihtc_property/output/lihtc_property_2024_raw_text.parquet" ]; then \
		ln -sf ../../../prepare_lihtc_property/output/lihtc_property_2024_raw_text.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtcpub.zip \
	../input/lihtc_property_2024_files.csv \
	../input/lihtc_property_2024_raw_text.parquet

include ../../../generic.make
