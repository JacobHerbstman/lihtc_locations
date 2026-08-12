SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: ../output/lihtc_pa_no_site_numeric_candidate_second_read_validated.parquet

../output/lihtc_pa_no_site_numeric_candidate_second_read_validated.parquet: \
		review_lihtc_pa_no_site_source_review.R \
		lihtc_pa_no_site_numeric_candidate_second_read_ledger.csv \
		../input/lihtc_pa_no_site_phfa_exact_source_candidates.parquet \
		../input/pa_no_site_second_reads_2026-08-12_manifest.sha256 \
		../input/pa_no_site_second_reads_2026-08-12_source_manifest.csv \
		../input/chambersburg_townhomes.html \
		../input/community_ventures_projects.html \
		../input/fayette_housing_needs.pdf \
		../input/hill_com_fire_publicsource.html \
		../input/negley_neighbors_hunt.html \
		../input/pha_family_developments.html \
		../input/phfa_newport_2006.pdf \
		../input/philadelphia_inventory_2019.pdf \
		../input/surrey_hill.html \
		../input/towns_governors_contact.html | ../output
	$(R) $<

../input/lihtc_pa_no_site_phfa_exact_source_candidates.parquet: \
		../../prepare_lihtc_pa_no_site_source_review/output/lihtc_pa_no_site_phfa_exact_source_candidates.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../prepare_lihtc_pa_no_site_source_review/output/lihtc_pa_no_site_phfa_exact_source_candidates.parquet" ]; then \
		ln -sf ../../prepare_lihtc_pa_no_site_source_review/output/lihtc_pa_no_site_phfa_exact_source_candidates.parquet "$@"; \
	fi

../input/pa_no_site_second_reads_2026-08-12_manifest.sha256: \
		../../../data_raw/pa_no_site_second_reads/2026-08-12/manifest.sha256 | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/pa_no_site_second_reads/2026-08-12/manifest.sha256" ]; then \
		ln -sf ../../../data_raw/pa_no_site_second_reads/2026-08-12/manifest.sha256 "$@"; \
	fi

../input/pa_no_site_second_reads_2026-08-12_source_manifest.csv: \
		../../../data_raw/pa_no_site_second_reads/2026-08-12/source_manifest.csv | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/pa_no_site_second_reads/2026-08-12/source_manifest.csv" ]; then \
		ln -sf ../../../data_raw/pa_no_site_second_reads/2026-08-12/source_manifest.csv "$@"; \
	fi

../input/chambersburg_townhomes.html: ../../../data_raw/pa_no_site_second_reads/2026-08-12/chambersburg_townhomes.html | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/pa_no_site_second_reads/2026-08-12/chambersburg_townhomes.html" ]; then ln -sf ../../../data_raw/pa_no_site_second_reads/2026-08-12/chambersburg_townhomes.html "$@"; fi

../input/community_ventures_projects.html: ../../../data_raw/pa_no_site_second_reads/2026-08-12/community_ventures_projects.html | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/pa_no_site_second_reads/2026-08-12/community_ventures_projects.html" ]; then ln -sf ../../../data_raw/pa_no_site_second_reads/2026-08-12/community_ventures_projects.html "$@"; fi

../input/fayette_housing_needs.pdf: ../../../data_raw/pa_no_site_second_reads/2026-08-12/fayette_housing_needs.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/pa_no_site_second_reads/2026-08-12/fayette_housing_needs.pdf" ]; then ln -sf ../../../data_raw/pa_no_site_second_reads/2026-08-12/fayette_housing_needs.pdf "$@"; fi

../input/hill_com_fire_publicsource.html: ../../../data_raw/pa_no_site_second_reads/2026-08-12/hill_com_fire_publicsource.html | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/pa_no_site_second_reads/2026-08-12/hill_com_fire_publicsource.html" ]; then ln -sf ../../../data_raw/pa_no_site_second_reads/2026-08-12/hill_com_fire_publicsource.html "$@"; fi

../input/negley_neighbors_hunt.html: ../../../data_raw/pa_no_site_second_reads/2026-08-12/negley_neighbors_hunt.html | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/pa_no_site_second_reads/2026-08-12/negley_neighbors_hunt.html" ]; then ln -sf ../../../data_raw/pa_no_site_second_reads/2026-08-12/negley_neighbors_hunt.html "$@"; fi

../input/pha_family_developments.html: ../../../data_raw/pa_no_site_second_reads/2026-08-12/pha_family_developments.html | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/pa_no_site_second_reads/2026-08-12/pha_family_developments.html" ]; then ln -sf ../../../data_raw/pa_no_site_second_reads/2026-08-12/pha_family_developments.html "$@"; fi

../input/phfa_newport_2006.pdf: ../../../data_raw/pa_no_site_second_reads/2026-08-12/phfa_newport_2006.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/pa_no_site_second_reads/2026-08-12/phfa_newport_2006.pdf" ]; then ln -sf ../../../data_raw/pa_no_site_second_reads/2026-08-12/phfa_newport_2006.pdf "$@"; fi

../input/philadelphia_inventory_2019.pdf: ../../../data_raw/pa_no_site_second_reads/2026-08-12/philadelphia_inventory_2019.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/pa_no_site_second_reads/2026-08-12/philadelphia_inventory_2019.pdf" ]; then ln -sf ../../../data_raw/pa_no_site_second_reads/2026-08-12/philadelphia_inventory_2019.pdf "$@"; fi

../input/surrey_hill.html: ../../../data_raw/pa_no_site_second_reads/2026-08-12/surrey_hill.html | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/pa_no_site_second_reads/2026-08-12/surrey_hill.html" ]; then ln -sf ../../../data_raw/pa_no_site_second_reads/2026-08-12/surrey_hill.html "$@"; fi

../input/towns_governors_contact.html: ../../../data_raw/pa_no_site_second_reads/2026-08-12/towns_governors_contact.html | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/pa_no_site_second_reads/2026-08-12/towns_governors_contact.html" ]; then ln -sf ../../../data_raw/pa_no_site_second_reads/2026-08-12/towns_governors_contact.html "$@"; fi

link-inputs: \
	../input/lihtc_pa_no_site_phfa_exact_source_candidates.parquet \
	../input/pa_no_site_second_reads_2026-08-12_manifest.sha256 \
	../input/pa_no_site_second_reads_2026-08-12_source_manifest.csv \
	../input/chambersburg_townhomes.html \
	../input/community_ventures_projects.html \
	../input/fayette_housing_needs.pdf \
	../input/hill_com_fire_publicsource.html \
	../input/negley_neighbors_hunt.html \
	../input/pha_family_developments.html \
	../input/phfa_newport_2006.pdf \
	../input/philadelphia_inventory_2019.pdf \
	../input/surrey_hill.html \
	../input/towns_governors_contact.html

include ../../generic.make
