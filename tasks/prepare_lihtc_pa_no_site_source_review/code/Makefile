SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/lihtc_pa_no_site_phfa_questions.parquet \
	../output/lihtc_pa_no_site_phfa_exact_source_candidates.parquet \
	../output/lihtc_pa_no_site_phfa_screening_summary.csv

../output/lihtc_pa_no_site_phfa_questions.parquet: \
		prepare_lihtc_pa_no_site_source_review.R \
		../input/lihtc_no_site_development_questions.parquet \
		../input/phfa_rental_housing_inventory_2026-08-12_manifest.sha256 \
		../input/dv_adams.pdf \
		../input/dv_allegheny.pdf \
		../input/dv_armstrong.pdf \
		../input/dv_beaver.pdf \
		../input/dv_bedford.pdf \
		../input/dv_berks.pdf \
		../input/dv_blair.pdf \
		../input/dv_bradford.pdf \
		../input/dv_bucks.pdf \
		../input/dv_butler.pdf \
		../input/dv_cambria.pdf \
		../input/dv_cameron.pdf \
		../input/dv_carbon.pdf \
		../input/dv_centre.pdf \
		../input/dv_chester.pdf \
		../input/dv_clarion.pdf \
		../input/dv_clearfield.pdf \
		../input/dv_clinton.pdf \
		../input/dv_columbia.pdf \
		../input/dv_crawford.pdf \
		../input/dv_cumberland.pdf \
		../input/dv_dauphin.pdf \
		../input/dv_delaware.pdf \
		../input/dv_elk.pdf \
		../input/dv_erie.pdf \
		../input/dv_fayette.pdf \
		../input/dv_forest.pdf \
		../input/dv_franklin.pdf \
		../input/dv_fulton.pdf \
		../input/dv_greene.pdf \
		../input/dv_huntingdon.pdf \
		../input/dv_indiana.pdf \
		../input/dv_jefferson.pdf \
		../input/dv_juniata.pdf \
		../input/dv_lackawanna.pdf \
		../input/dv_lancaster.pdf \
		../input/dv_lawrence.pdf \
		../input/dv_lebanon.pdf \
		../input/dv_lehigh.pdf \
		../input/dv_luzerne.pdf \
		../input/dv_lycoming.pdf \
		../input/dv_mcKean.pdf \
		../input/dv_mercer.pdf \
		../input/dv_mifflin.pdf \
		../input/dv_monroe.pdf \
		../input/dv_montgomery.pdf \
		../input/dv_montour.pdf \
		../input/dv_northumberland.pdf \
		../input/dv_perry.pdf \
		../input/dv_philadelphia.pdf \
		../input/dv_pike.pdf \
		../input/dv_potter.pdf \
		../input/dv_schuylkill.pdf \
		../input/dv_snyder.pdf \
		../input/dv_somerset.pdf \
		../input/dv_sullivan.pdf \
		../input/dv_susquehanna.pdf \
		../input/dv_tioga.pdf \
		../input/dv_union.pdf \
		../input/dv_venango.pdf \
		../input/dv_warren.pdf \
		../input/dv_washington.pdf \
		../input/dv_wayne.pdf \
		../input/dv_westmoreland.pdf \
		../input/dv_wyoming.pdf \
		../input/dv_york.pdf \
		../input/phfa_renters.html | ../output
	$(R) $<

../output/lihtc_pa_no_site_phfa_exact_source_candidates.parquet \
	../output/lihtc_pa_no_site_phfa_screening_summary.csv: \
		../output/lihtc_pa_no_site_phfa_questions.parquet
	@test -f "$@"

../input/lihtc_no_site_development_questions.parquet: \
		../../prepare_lihtc_no_site_development_review/output/lihtc_no_site_development_questions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../prepare_lihtc_no_site_development_review/output/lihtc_no_site_development_questions.parquet" ]; then \
		ln -sf ../../prepare_lihtc_no_site_development_review/output/lihtc_no_site_development_questions.parquet "$@"; \
	fi

../input/phfa_rental_housing_inventory_2026-08-12_manifest.sha256: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/manifest.sha256 | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/manifest.sha256" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/manifest.sha256 "$@"; \
	fi

../input/dv_adams.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_adams.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_adams.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_adams.pdf "$@"; \
	fi

../input/dv_allegheny.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_allegheny.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_allegheny.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_allegheny.pdf "$@"; \
	fi

../input/dv_armstrong.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_armstrong.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_armstrong.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_armstrong.pdf "$@"; \
	fi

../input/dv_beaver.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_beaver.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_beaver.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_beaver.pdf "$@"; \
	fi

../input/dv_bedford.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_bedford.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_bedford.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_bedford.pdf "$@"; \
	fi

../input/dv_berks.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_berks.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_berks.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_berks.pdf "$@"; \
	fi

../input/dv_blair.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_blair.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_blair.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_blair.pdf "$@"; \
	fi

../input/dv_bradford.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_bradford.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_bradford.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_bradford.pdf "$@"; \
	fi

../input/dv_bucks.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_bucks.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_bucks.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_bucks.pdf "$@"; \
	fi

../input/dv_butler.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_butler.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_butler.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_butler.pdf "$@"; \
	fi

../input/dv_cambria.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_cambria.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_cambria.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_cambria.pdf "$@"; \
	fi

../input/dv_cameron.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_cameron.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_cameron.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_cameron.pdf "$@"; \
	fi

../input/dv_carbon.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_carbon.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_carbon.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_carbon.pdf "$@"; \
	fi

../input/dv_centre.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_centre.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_centre.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_centre.pdf "$@"; \
	fi

../input/dv_chester.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_chester.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_chester.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_chester.pdf "$@"; \
	fi

../input/dv_clarion.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_clarion.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_clarion.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_clarion.pdf "$@"; \
	fi

../input/dv_clearfield.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_clearfield.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_clearfield.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_clearfield.pdf "$@"; \
	fi

../input/dv_clinton.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_clinton.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_clinton.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_clinton.pdf "$@"; \
	fi

../input/dv_columbia.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_columbia.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_columbia.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_columbia.pdf "$@"; \
	fi

../input/dv_crawford.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_crawford.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_crawford.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_crawford.pdf "$@"; \
	fi

../input/dv_cumberland.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_cumberland.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_cumberland.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_cumberland.pdf "$@"; \
	fi

../input/dv_dauphin.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_dauphin.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_dauphin.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_dauphin.pdf "$@"; \
	fi

../input/dv_delaware.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_delaware.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_delaware.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_delaware.pdf "$@"; \
	fi

../input/dv_elk.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_elk.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_elk.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_elk.pdf "$@"; \
	fi

../input/dv_erie.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_erie.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_erie.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_erie.pdf "$@"; \
	fi

../input/dv_fayette.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_fayette.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_fayette.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_fayette.pdf "$@"; \
	fi

../input/dv_forest.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_forest.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_forest.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_forest.pdf "$@"; \
	fi

../input/dv_franklin.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_franklin.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_franklin.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_franklin.pdf "$@"; \
	fi

../input/dv_fulton.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_fulton.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_fulton.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_fulton.pdf "$@"; \
	fi

../input/dv_greene.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_greene.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_greene.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_greene.pdf "$@"; \
	fi

../input/dv_huntingdon.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_huntingdon.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_huntingdon.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_huntingdon.pdf "$@"; \
	fi

../input/dv_indiana.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_indiana.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_indiana.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_indiana.pdf "$@"; \
	fi

../input/dv_jefferson.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_jefferson.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_jefferson.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_jefferson.pdf "$@"; \
	fi

../input/dv_juniata.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_juniata.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_juniata.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_juniata.pdf "$@"; \
	fi

../input/dv_lackawanna.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_lackawanna.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_lackawanna.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_lackawanna.pdf "$@"; \
	fi

../input/dv_lancaster.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_lancaster.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_lancaster.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_lancaster.pdf "$@"; \
	fi

../input/dv_lawrence.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_lawrence.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_lawrence.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_lawrence.pdf "$@"; \
	fi

../input/dv_lebanon.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_lebanon.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_lebanon.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_lebanon.pdf "$@"; \
	fi

../input/dv_lehigh.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_lehigh.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_lehigh.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_lehigh.pdf "$@"; \
	fi

../input/dv_luzerne.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_luzerne.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_luzerne.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_luzerne.pdf "$@"; \
	fi

../input/dv_lycoming.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_lycoming.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_lycoming.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_lycoming.pdf "$@"; \
	fi

../input/dv_mcKean.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_mcKean.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_mcKean.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_mcKean.pdf "$@"; \
	fi

../input/dv_mercer.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_mercer.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_mercer.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_mercer.pdf "$@"; \
	fi

../input/dv_mifflin.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_mifflin.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_mifflin.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_mifflin.pdf "$@"; \
	fi

../input/dv_monroe.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_monroe.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_monroe.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_monroe.pdf "$@"; \
	fi

../input/dv_montgomery.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_montgomery.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_montgomery.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_montgomery.pdf "$@"; \
	fi

../input/dv_montour.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_montour.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_montour.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_montour.pdf "$@"; \
	fi

../input/dv_northumberland.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_northumberland.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_northumberland.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_northumberland.pdf "$@"; \
	fi

../input/dv_perry.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_perry.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_perry.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_perry.pdf "$@"; \
	fi

../input/dv_philadelphia.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_philadelphia.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_philadelphia.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_philadelphia.pdf "$@"; \
	fi

../input/dv_pike.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_pike.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_pike.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_pike.pdf "$@"; \
	fi

../input/dv_potter.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_potter.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_potter.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_potter.pdf "$@"; \
	fi

../input/dv_schuylkill.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_schuylkill.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_schuylkill.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_schuylkill.pdf "$@"; \
	fi

../input/dv_snyder.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_snyder.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_snyder.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_snyder.pdf "$@"; \
	fi

../input/dv_somerset.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_somerset.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_somerset.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_somerset.pdf "$@"; \
	fi

../input/dv_sullivan.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_sullivan.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_sullivan.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_sullivan.pdf "$@"; \
	fi

../input/dv_susquehanna.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_susquehanna.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_susquehanna.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_susquehanna.pdf "$@"; \
	fi

../input/dv_tioga.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_tioga.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_tioga.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_tioga.pdf "$@"; \
	fi

../input/dv_union.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_union.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_union.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_union.pdf "$@"; \
	fi

../input/dv_venango.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_venango.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_venango.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_venango.pdf "$@"; \
	fi

../input/dv_warren.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_warren.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_warren.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_warren.pdf "$@"; \
	fi

../input/dv_washington.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_washington.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_washington.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_washington.pdf "$@"; \
	fi

../input/dv_wayne.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_wayne.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_wayne.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_wayne.pdf "$@"; \
	fi

../input/dv_westmoreland.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_westmoreland.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_westmoreland.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_westmoreland.pdf "$@"; \
	fi

../input/dv_wyoming.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_wyoming.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_wyoming.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_wyoming.pdf "$@"; \
	fi

../input/dv_york.pdf: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_york.pdf | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_york.pdf" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/dv_york.pdf "$@"; \
	fi

../input/phfa_renters.html: \
		../../../data_raw/phfa_rental_housing_inventory/2026-08-12/phfa_renters.html | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/phfa_rental_housing_inventory/2026-08-12/phfa_renters.html" ]; then \
		ln -sf ../../../data_raw/phfa_rental_housing_inventory/2026-08-12/phfa_renters.html "$@"; \
	fi

link-inputs: \
	../input/lihtc_no_site_development_questions.parquet \
	../input/phfa_rental_housing_inventory_2026-08-12_manifest.sha256 \
	../input/dv_adams.pdf \
	../input/dv_allegheny.pdf \
	../input/dv_armstrong.pdf \
	../input/dv_beaver.pdf \
	../input/dv_bedford.pdf \
	../input/dv_berks.pdf \
	../input/dv_blair.pdf \
	../input/dv_bradford.pdf \
	../input/dv_bucks.pdf \
	../input/dv_butler.pdf \
	../input/dv_cambria.pdf \
	../input/dv_cameron.pdf \
	../input/dv_carbon.pdf \
	../input/dv_centre.pdf \
	../input/dv_chester.pdf \
	../input/dv_clarion.pdf \
	../input/dv_clearfield.pdf \
	../input/dv_clinton.pdf \
	../input/dv_columbia.pdf \
	../input/dv_crawford.pdf \
	../input/dv_cumberland.pdf \
	../input/dv_dauphin.pdf \
	../input/dv_delaware.pdf \
	../input/dv_elk.pdf \
	../input/dv_erie.pdf \
	../input/dv_fayette.pdf \
	../input/dv_forest.pdf \
	../input/dv_franklin.pdf \
	../input/dv_fulton.pdf \
	../input/dv_greene.pdf \
	../input/dv_huntingdon.pdf \
	../input/dv_indiana.pdf \
	../input/dv_jefferson.pdf \
	../input/dv_juniata.pdf \
	../input/dv_lackawanna.pdf \
	../input/dv_lancaster.pdf \
	../input/dv_lawrence.pdf \
	../input/dv_lebanon.pdf \
	../input/dv_lehigh.pdf \
	../input/dv_luzerne.pdf \
	../input/dv_lycoming.pdf \
	../input/dv_mcKean.pdf \
	../input/dv_mercer.pdf \
	../input/dv_mifflin.pdf \
	../input/dv_monroe.pdf \
	../input/dv_montgomery.pdf \
	../input/dv_montour.pdf \
	../input/dv_northumberland.pdf \
	../input/dv_perry.pdf \
	../input/dv_philadelphia.pdf \
	../input/dv_pike.pdf \
	../input/dv_potter.pdf \
	../input/dv_schuylkill.pdf \
	../input/dv_snyder.pdf \
	../input/dv_somerset.pdf \
	../input/dv_sullivan.pdf \
	../input/dv_susquehanna.pdf \
	../input/dv_tioga.pdf \
	../input/dv_union.pdf \
	../input/dv_venango.pdf \
	../input/dv_warren.pdf \
	../input/dv_washington.pdf \
	../input/dv_wayne.pdf \
	../input/dv_westmoreland.pdf \
	../input/dv_wyoming.pdf \
	../input/dv_york.pdf \
	../input/phfa_renters.html

include ../../generic.make
