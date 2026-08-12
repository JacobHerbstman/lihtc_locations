SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/lihtc_no_site_source_review_progress.parquet \
	../output/lihtc_no_site_source_review_progress_counts.csv

../output/lihtc_no_site_source_review_progress.parquet: \
		audit_lihtc_no_site_source_review_progress.R \
		../input/lihtc_no_site_development_questions.parquet \
		../input/lihtc_pa_no_site_phfa_questions.parquet \
		../input/lihtc_pa_no_site_numeric_candidate_second_read_validated.parquet \
		../input/lihtc_tx_no_site_tdhca_questions.parquet \
		../input/lihtc_tx_no_site_second_read_validated.parquet \
		../input/lihtc_nc_no_site_nchfa_questions.parquet \
		../input/lihtc_ga_no_site_dca_source_access_blocker.parquet \
		../input/lihtc_me_no_site_mainehousing_questions.parquet \
		../input/lihtc_in_no_site_ihcda_source_access_blocker.parquet | ../output
	$(R) $<

../output/lihtc_no_site_source_review_progress_counts.csv: \
		../output/lihtc_no_site_source_review_progress.parquet
	@test -f $@

../input/lihtc_no_site_development_questions.parquet: \
		../../../prepare_lihtc_no_site_development_review/output/lihtc_no_site_development_questions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../prepare_lihtc_no_site_development_review/output/lihtc_no_site_development_questions.parquet" ]; then ln -sf ../../../prepare_lihtc_no_site_development_review/output/lihtc_no_site_development_questions.parquet "$@"; fi

../input/lihtc_pa_no_site_phfa_questions.parquet: \
		../../../prepare_lihtc_pa_no_site_source_review/output/lihtc_pa_no_site_phfa_questions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../prepare_lihtc_pa_no_site_source_review/output/lihtc_pa_no_site_phfa_questions.parquet" ]; then ln -sf ../../../prepare_lihtc_pa_no_site_source_review/output/lihtc_pa_no_site_phfa_questions.parquet "$@"; fi

../input/lihtc_pa_no_site_numeric_candidate_second_read_validated.parquet: \
		../../../review_lihtc_pa_no_site_source_review/output/lihtc_pa_no_site_numeric_candidate_second_read_validated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../review_lihtc_pa_no_site_source_review/output/lihtc_pa_no_site_numeric_candidate_second_read_validated.parquet" ]; then ln -sf ../../../review_lihtc_pa_no_site_source_review/output/lihtc_pa_no_site_numeric_candidate_second_read_validated.parquet "$@"; fi

../input/lihtc_tx_no_site_tdhca_questions.parquet: \
		../../../prepare_lihtc_tx_no_site_tdhca_source_review/output/lihtc_tx_no_site_tdhca_questions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../prepare_lihtc_tx_no_site_tdhca_source_review/output/lihtc_tx_no_site_tdhca_questions.parquet" ]; then ln -sf ../../../prepare_lihtc_tx_no_site_tdhca_source_review/output/lihtc_tx_no_site_tdhca_questions.parquet "$@"; fi

../input/lihtc_tx_no_site_second_read_validated.parquet: \
		../../../review_lihtc_tx_no_site_source_review/output/lihtc_tx_no_site_second_read_validated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../review_lihtc_tx_no_site_source_review/output/lihtc_tx_no_site_second_read_validated.parquet" ]; then ln -sf ../../../review_lihtc_tx_no_site_source_review/output/lihtc_tx_no_site_second_read_validated.parquet "$@"; fi

../input/lihtc_nc_no_site_nchfa_questions.parquet: \
		../../../prepare_lihtc_nc_no_site_nchfa_source_review/output/lihtc_nc_no_site_nchfa_questions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../prepare_lihtc_nc_no_site_nchfa_source_review/output/lihtc_nc_no_site_nchfa_questions.parquet" ]; then ln -sf ../../../prepare_lihtc_nc_no_site_nchfa_source_review/output/lihtc_nc_no_site_nchfa_questions.parquet "$@"; fi

../input/lihtc_ga_no_site_dca_source_access_blocker.parquet: \
		../../../prepare_lihtc_ga_no_site_dca_source_review/output/lihtc_ga_no_site_dca_source_access_blocker.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../prepare_lihtc_ga_no_site_dca_source_review/output/lihtc_ga_no_site_dca_source_access_blocker.parquet" ]; then ln -sf ../../../prepare_lihtc_ga_no_site_dca_source_review/output/lihtc_ga_no_site_dca_source_access_blocker.parquet "$@"; fi

../input/lihtc_me_no_site_mainehousing_questions.parquet: \
		../../../prepare_lihtc_me_no_site_mainehousing_source_review/output/lihtc_me_no_site_mainehousing_questions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../prepare_lihtc_me_no_site_mainehousing_source_review/output/lihtc_me_no_site_mainehousing_questions.parquet" ]; then ln -sf ../../../prepare_lihtc_me_no_site_mainehousing_source_review/output/lihtc_me_no_site_mainehousing_questions.parquet "$@"; fi

../input/lihtc_in_no_site_ihcda_source_access_blocker.parquet: \
		../../../prepare_lihtc_in_no_site_ihcda_source_review/output/lihtc_in_no_site_ihcda_source_access_blocker.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../prepare_lihtc_in_no_site_ihcda_source_review/output/lihtc_in_no_site_ihcda_source_access_blocker.parquet" ]; then ln -sf ../../../prepare_lihtc_in_no_site_ihcda_source_review/output/lihtc_in_no_site_ihcda_source_access_blocker.parquet "$@"; fi

link-inputs: \
	../input/lihtc_no_site_development_questions.parquet \
	../input/lihtc_pa_no_site_phfa_questions.parquet \
	../input/lihtc_pa_no_site_numeric_candidate_second_read_validated.parquet \
	../input/lihtc_tx_no_site_tdhca_questions.parquet \
	../input/lihtc_tx_no_site_second_read_validated.parquet \
	../input/lihtc_nc_no_site_nchfa_questions.parquet \
	../input/lihtc_ga_no_site_dca_source_access_blocker.parquet \
	../input/lihtc_me_no_site_mainehousing_questions.parquet \
	../input/lihtc_in_no_site_ihcda_source_access_blocker.parquet

include ../../../generic.make
