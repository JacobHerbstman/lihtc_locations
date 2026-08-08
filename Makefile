SHELL := /bin/bash
.DEFAULT_GOAL := paper

.PHONY: all paper setup sources lihtc-data

all: paper

paper: tasks/setup_environment/output/system_requirements.txt tasks/setup_environment/output/R_packages.txt
	$(MAKE) -C paper

setup: tasks/setup_environment/output/system_requirements.txt tasks/setup_environment/output/R_packages.txt

sources: tasks/source_registry/output/source_catalog.csv

lihtc-data: tasks/fetch_lihtc_property/output/lihtc_property_2024_files.csv

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
