SHELL := /bin/bash
.DEFAULT_GOAL := paper

.PHONY: all paper setup sources lihtc-data prepare-lihtc-data audit-lihtc-data

all: paper

paper: tasks/setup_environment/output/system_requirements.txt tasks/setup_environment/output/R_packages.txt
	$(MAKE) -C paper

setup: tasks/setup_environment/output/system_requirements.txt tasks/setup_environment/output/R_packages.txt

sources: tasks/source_registry/output/source_catalog.csv

lihtc-data: tasks/fetch_lihtc_property/output/lihtc_property_2024_files.csv

prepare-lihtc-data: tasks/prepare_lihtc_property/output/lihtc_property_2024_raw_text.parquet

audit-lihtc-data: tasks/audits/audit_lihtc_property/output/audit_summary.md

tasks/setup_environment/output/system_requirements.txt: tasks/setup_environment/code/system_requirements.sh
	$(MAKE) -C tasks/setup_environment/code ../output/system_requirements.txt

tasks/setup_environment/output/R_packages.txt: tasks/setup_environment/code/packages.R tasks/setup_environment/output/system_requirements.txt
	$(MAKE) -C tasks/setup_environment/code ../output/R_packages.txt

tasks/source_registry/output/source_catalog.csv: tasks/source_registry/code/source_catalog.csv
	$(MAKE) -C tasks/source_registry/code ../output/source_catalog.csv

tasks/fetch_lihtc_property/output/lihtc_property_2024_files.csv: \
		tasks/fetch_lihtc_property/code/fetch_lihtc_property.py \
		tasks/fetch_lihtc_property/code/validate_lihtc_property.py \
		tasks/fetch_lihtc_property/code/release_manifest.csv \
		tasks/source_registry/output/source_catalog.csv
	$(MAKE) -C tasks/fetch_lihtc_property/code ../output/lihtc_property_2024_files.csv

tasks/prepare_lihtc_property/output/lihtc_property_2024_raw_text.parquet: \
		tasks/prepare_lihtc_property/code/prepare_lihtc_property.R \
		tasks/fetch_lihtc_property/output/lihtc_property_2024_files.csv \
		data_raw/hud_lihtc_property/2024/lihtcpub.zip
	$(MAKE) -C tasks/prepare_lihtc_property/code ../output/lihtc_property_2024_raw_text.parquet

tasks/audits/audit_lihtc_property/output/audit_summary.md: \
		tasks/audits/audit_lihtc_property/code/audit_lihtc_property.R \
		tasks/audits/audit_lihtc_property/code/dictionary_claims.csv \
		tasks/audits/audit_lihtc_property/code/inspect_workbook_xml.py \
		tasks/fetch_lihtc_property/output/lihtc_property_2024_files.csv \
		tasks/prepare_lihtc_property/output/lihtc_property_2024_raw_text.parquet \
		data_raw/hud_lihtc_property/2024/lihtcpub.zip
	$(MAKE) -C tasks/audits/audit_lihtc_property/code ../output/audit_summary.md
