SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/lihtc_nc_no_site_nchfa_questions.parquet \
	../output/lihtc_nc_no_site_nchfa_exact_source_candidates.parquet \
	../output/lihtc_nc_no_site_nchfa_fuzzy_source_candidates.parquet \
	../output/lihtc_nc_no_site_nchfa_screening_summary.csv

../output/lihtc_nc_no_site_nchfa_questions.parquet: \
		prepare_lihtc_nc_no_site_nchfa_source_review.R \
		../input/lihtc_no_site_development_questions.parquet \
		../input/source_manifest.csv \
		../input/awarded_projects_page_0.html \
		../input/awarded_projects_page_1.html \
		../input/awarded_projects_page_2.html \
		../input/awarded_projects_page_3.html \
		../input/awarded_projects_page_4.html \
		../input/awarded_projects_page_5.html \
		../input/awarded_projects_page_6.html \
		../input/awarded_projects_page_7.html \
		../input/awarded_projects_page_8.html \
		../input/awarded_projects_page_9.html \
		../input/awarded_projects_page_10.html \
		../input/awarded_projects_page_11.html \
		../input/awarded_projects_page_12.html \
		../input/awarded_projects_page_13.html \
		../input/awarded_projects_page_14.html \
		../input/awarded_projects_page_15.html \
		../input/awarded_projects_page_16.html \
		../input/awarded_projects_page_17.html \
		../input/awarded_projects_page_18.html \
		../input/awarded_projects_page_19.html \
		../input/awarded_projects_page_20.html \
		../input/awarded_projects_page_21.html \
		../input/awarded_projects_page_22.html \
		../input/awarded_projects_page_23.html \
		../input/awarded_projects_page_24.html \
		../input/awarded_projects_page_25.html \
		../input/awarded_projects_page_26.html \
		../input/awarded_projects_page_27.html \
		../input/awarded_projects_page_28.html \
		../input/awarded_projects_page_29.html \
		../input/awarded_projects_page_30.html \
		../input/awarded_projects_page_31.html \
		../input/awarded_projects_page_32.html \
		../input/awarded_projects_page_33.html \
		../input/awarded_projects_page_34.html \
		../input/awarded_projects_page_35.html \
		../input/awarded_projects_page_36.html \
		../input/awarded_projects_page_37.html \
		../input/awarded_projects_page_38.html \
		../input/awarded_projects_page_39.html \
		../input/awarded_projects_page_40.html \
		../input/awarded_projects_page_41.html \
		../input/awarded_projects_page_42.html \
		../input/awarded_projects_page_43.html \
		../input/awarded_projects_page_44.html \
		../input/awarded_projects_page_45.html \
		../input/awarded_projects_page_46.html \
		../input/awarded_projects_page_47.html \
		../input/awarded_projects_page_48.html \
		../input/awarded_projects_page_49.html \
		../input/awarded_projects_page_50.html \
		../input/awarded_projects_page_51.html \
		../input/awarded_projects_page_52.html \
		../input/awarded_projects_page_53.html \
		../input/awarded_projects_page_54.html \
		../input/awarded_projects_page_55.html \
		../input/awarded_projects_page_56.html \
		../input/awarded_projects_page_57.html \
		../input/awarded_projects_page_58.html \
		../input/awarded_projects_page_59.html \
		../input/awarded_projects_page_60.html \
		../input/awarded_projects_page_61.html \
		../input/awarded_projects_page_62.html \
		../input/awarded_projects_page_63.html \
		../input/awarded_projects_page_64.html \
		../input/awarded_projects_page_65.html \
		../input/awarded_projects_page_66.html \
		../input/awarded_projects_page_67.html \
		../input/awarded_projects_page_68.html \
		../input/awarded_projects_page_69.html \
		../input/awarded_projects_page_70.html \
		../input/awarded_projects_page_71.html \
		../input/awarded_projects_page_72.html \
		../input/awarded_projects_page_73.html \
		../input/awarded_projects_page_74.html \
		../input/awarded_projects_page_75.html \
		../input/awarded_projects_page_76.html \
		../input/awarded_projects_page_77.html \
		../input/awarded_projects_page_78.html \
		../input/awarded_projects_page_79.html \
		../input/awarded_projects_page_80.html \
		../input/awarded_projects_page_81.html \
		../input/awarded_projects_page_82.html  | ../output
	$(R) $<

../output/lihtc_nc_no_site_nchfa_exact_source_candidates.parquet \
../output/lihtc_nc_no_site_nchfa_fuzzy_source_candidates.parquet \
../output/lihtc_nc_no_site_nchfa_screening_summary.csv: \
		../output/lihtc_nc_no_site_nchfa_questions.parquet
	@test -f "$@"

../input/lihtc_no_site_development_questions.parquet: \
		../../prepare_lihtc_no_site_development_review/output/lihtc_no_site_development_questions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../prepare_lihtc_no_site_development_review/output/lihtc_no_site_development_questions.parquet" ]; then \
		ln -sf ../../prepare_lihtc_no_site_development_review/output/lihtc_no_site_development_questions.parquet "$@"; \
	fi

../input/source_manifest.csv: \
		../../../data_raw/nchfa_funded_rental_projects/2026-08-12/source_manifest.csv | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/nchfa_funded_rental_projects/2026-08-12/source_manifest.csv" ]; then \
		ln -sf ../../../data_raw/nchfa_funded_rental_projects/2026-08-12/source_manifest.csv "$@"; \
	fi

../input/awarded_projects_page_%.html: \
		../../../data_raw/nchfa_funded_rental_projects/2026-08-12/pages/awarded_projects_page_%.html | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/nchfa_funded_rental_projects/2026-08-12/pages/awarded_projects_page_$*.html" ]; then \
		ln -sf ../../../data_raw/nchfa_funded_rental_projects/2026-08-12/pages/awarded_projects_page_$*.html "$@"; \
	fi

link-inputs: \
	../input/lihtc_no_site_development_questions.parquet \
	../input/source_manifest.csv \
	../input/awarded_projects_page_0.html \
	../input/awarded_projects_page_1.html \
	../input/awarded_projects_page_2.html \
	../input/awarded_projects_page_3.html \
	../input/awarded_projects_page_4.html \
	../input/awarded_projects_page_5.html \
	../input/awarded_projects_page_6.html \
	../input/awarded_projects_page_7.html \
	../input/awarded_projects_page_8.html \
	../input/awarded_projects_page_9.html \
	../input/awarded_projects_page_10.html \
	../input/awarded_projects_page_11.html \
	../input/awarded_projects_page_12.html \
	../input/awarded_projects_page_13.html \
	../input/awarded_projects_page_14.html \
	../input/awarded_projects_page_15.html \
	../input/awarded_projects_page_16.html \
	../input/awarded_projects_page_17.html \
	../input/awarded_projects_page_18.html \
	../input/awarded_projects_page_19.html \
	../input/awarded_projects_page_20.html \
	../input/awarded_projects_page_21.html \
	../input/awarded_projects_page_22.html \
	../input/awarded_projects_page_23.html \
	../input/awarded_projects_page_24.html \
	../input/awarded_projects_page_25.html \
	../input/awarded_projects_page_26.html \
	../input/awarded_projects_page_27.html \
	../input/awarded_projects_page_28.html \
	../input/awarded_projects_page_29.html \
	../input/awarded_projects_page_30.html \
	../input/awarded_projects_page_31.html \
	../input/awarded_projects_page_32.html \
	../input/awarded_projects_page_33.html \
	../input/awarded_projects_page_34.html \
	../input/awarded_projects_page_35.html \
	../input/awarded_projects_page_36.html \
	../input/awarded_projects_page_37.html \
	../input/awarded_projects_page_38.html \
	../input/awarded_projects_page_39.html \
	../input/awarded_projects_page_40.html \
	../input/awarded_projects_page_41.html \
	../input/awarded_projects_page_42.html \
	../input/awarded_projects_page_43.html \
	../input/awarded_projects_page_44.html \
	../input/awarded_projects_page_45.html \
	../input/awarded_projects_page_46.html \
	../input/awarded_projects_page_47.html \
	../input/awarded_projects_page_48.html \
	../input/awarded_projects_page_49.html \
	../input/awarded_projects_page_50.html \
	../input/awarded_projects_page_51.html \
	../input/awarded_projects_page_52.html \
	../input/awarded_projects_page_53.html \
	../input/awarded_projects_page_54.html \
	../input/awarded_projects_page_55.html \
	../input/awarded_projects_page_56.html \
	../input/awarded_projects_page_57.html \
	../input/awarded_projects_page_58.html \
	../input/awarded_projects_page_59.html \
	../input/awarded_projects_page_60.html \
	../input/awarded_projects_page_61.html \
	../input/awarded_projects_page_62.html \
	../input/awarded_projects_page_63.html \
	../input/awarded_projects_page_64.html \
	../input/awarded_projects_page_65.html \
	../input/awarded_projects_page_66.html \
	../input/awarded_projects_page_67.html \
	../input/awarded_projects_page_68.html \
	../input/awarded_projects_page_69.html \
	../input/awarded_projects_page_70.html \
	../input/awarded_projects_page_71.html \
	../input/awarded_projects_page_72.html \
	../input/awarded_projects_page_73.html \
	../input/awarded_projects_page_74.html \
	../input/awarded_projects_page_75.html \
	../input/awarded_projects_page_76.html \
	../input/awarded_projects_page_77.html \
	../input/awarded_projects_page_78.html \
	../input/awarded_projects_page_79.html \
	../input/awarded_projects_page_80.html \
	../input/awarded_projects_page_81.html \
	../input/awarded_projects_page_82.html

include ../../generic.make
