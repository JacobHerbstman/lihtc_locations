SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/lihtc_source_site_member_decisions.parquet \
	../output/lihtc_source_site_group_reviews.parquet \
	../output/lihtc_source_site_episode_decisions.parquet \
	../output/lihtc_source_site_external_replacements.parquet

../output/lihtc_source_site_member_decisions.parquet: \
		validate_lihtc_source_site_exceptions.R \
		source_site_group_reviews.csv \
		source_site_action_contract.csv \
		external_site_replacements.csv \
		../input/lihtc_source_site_exception_assignments.parquet \
		../input/lihtc_source_site_exception_episodes.parquet | ../output
	$(R) $<

../output/lihtc_source_site_group_reviews.parquet \
../output/lihtc_source_site_episode_decisions.parquet \
../output/lihtc_source_site_external_replacements.parquet: \
		../output/lihtc_source_site_member_decisions.parquet
	@test -f $@

../input/lihtc_source_site_exception_assignments.parquet: \
		../../prepare_lihtc_source_site_exceptions/output/lihtc_source_site_exception_assignments.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../prepare_lihtc_source_site_exceptions/output/lihtc_source_site_exception_assignments.parquet" ]; then \
		ln -sf ../../prepare_lihtc_source_site_exceptions/output/lihtc_source_site_exception_assignments.parquet "$@"; \
	fi

../input/lihtc_source_site_exception_episodes.parquet: \
		../../prepare_lihtc_source_site_exceptions/output/lihtc_source_site_exception_episodes.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../prepare_lihtc_source_site_exceptions/output/lihtc_source_site_exception_episodes.parquet" ]; then \
		ln -sf ../../prepare_lihtc_source_site_exceptions/output/lihtc_source_site_exception_episodes.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_source_site_exception_assignments.parquet \
	../input/lihtc_source_site_exception_episodes.parquet

include ../../generic.make
