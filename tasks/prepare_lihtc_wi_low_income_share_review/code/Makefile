SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: ../output/lihtc_wi_low_income_share_candidates.parquet

../output/lihtc_wi_low_income_share_candidates.parquet: \
		prepare_lihtc_wi_low_income_share_review.R \
		../input/lihtc_development_2024_unit_scope_adjudicated.parquet \
		../input/lihtc_development_site_2024_unit_scope_adjudicated.parquet \
		../input/wheda_monitored_htc_projects_2026-08-12.html | ../output
	$(R) $<

../input/lihtc_development_2024_unit_scope_adjudicated.parquet: \
		../../apply_lihtc_unit_scope_review/output/lihtc_development_2024_unit_scope_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_unit_scope_review/output/lihtc_development_2024_unit_scope_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_unit_scope_review/output/lihtc_development_2024_unit_scope_adjudicated.parquet "$@"; \
	fi

../input/lihtc_development_site_2024_unit_scope_adjudicated.parquet: \
		../../apply_lihtc_unit_scope_review/output/lihtc_development_site_2024_unit_scope_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_unit_scope_review/output/lihtc_development_site_2024_unit_scope_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_unit_scope_review/output/lihtc_development_site_2024_unit_scope_adjudicated.parquet "$@"; \
	fi

../input/wheda_monitored_htc_projects_2026-08-12.html: \
		../../../data_raw/wheda_monitored_htc/2026-08-12/wheda_monitored_htc_projects.html | ../input
	@if [ "$$(readlink "$@")" != "../../../data_raw/wheda_monitored_htc/2026-08-12/wheda_monitored_htc_projects.html" ]; then \
		ln -sf ../../../data_raw/wheda_monitored_htc/2026-08-12/wheda_monitored_htc_projects.html "$@"; \
	fi

link-inputs: \
	../input/lihtc_development_2024_unit_scope_adjudicated.parquet \
	../input/lihtc_development_site_2024_unit_scope_adjudicated.parquet \
	../input/wheda_monitored_htc_projects_2026-08-12.html

include ../../generic.make
