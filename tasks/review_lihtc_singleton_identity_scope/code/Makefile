SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/lihtc_singleton_identity_scope_question_reviews.parquet \
	../output/lihtc_singleton_identity_scope_member_partitions.parquet \
	../output/lihtc_singleton_identity_scope_site_decisions.parquet \
	../output/lihtc_singleton_identity_scope_site_additions.parquet

../output/lihtc_singleton_identity_scope_question_reviews.parquet: \
		validate_lihtc_singleton_identity_scope_review.R \
		singleton_identity_scope_reviews.csv \
		singleton_identity_scope_site_decisions.csv \
		singleton_identity_scope_site_additions.csv \
		../input/lihtc_development_2024_mixed_site_identity_adjudicated.parquet \
		../input/lihtc_project_episode_2024_mixed_site_identity_adjudicated.parquet \
		../input/lihtc_development_site_2024_mixed_site_identity_adjudicated.parquet | ../output
	$(R) $<

../output/lihtc_singleton_identity_scope_member_partitions.parquet \
../output/lihtc_singleton_identity_scope_site_decisions.parquet \
../output/lihtc_singleton_identity_scope_site_additions.parquet: \
		../output/lihtc_singleton_identity_scope_question_reviews.parquet
	@test -f $@

../input/lihtc_development_2024_mixed_site_identity_adjudicated.parquet: \
		../../apply_lihtc_mixed_site_identity_review/output/lihtc_development_2024_mixed_site_identity_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_mixed_site_identity_review/output/lihtc_development_2024_mixed_site_identity_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_mixed_site_identity_review/output/lihtc_development_2024_mixed_site_identity_adjudicated.parquet "$@"; \
	fi

../input/lihtc_project_episode_2024_mixed_site_identity_adjudicated.parquet: \
		../../apply_lihtc_mixed_site_identity_review/output/lihtc_project_episode_2024_mixed_site_identity_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_mixed_site_identity_review/output/lihtc_project_episode_2024_mixed_site_identity_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_mixed_site_identity_review/output/lihtc_project_episode_2024_mixed_site_identity_adjudicated.parquet "$@"; \
	fi

../input/lihtc_development_site_2024_mixed_site_identity_adjudicated.parquet: \
		../../apply_lihtc_mixed_site_identity_review/output/lihtc_development_site_2024_mixed_site_identity_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_mixed_site_identity_review/output/lihtc_development_site_2024_mixed_site_identity_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_mixed_site_identity_review/output/lihtc_development_site_2024_mixed_site_identity_adjudicated.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_development_2024_mixed_site_identity_adjudicated.parquet \
	../input/lihtc_project_episode_2024_mixed_site_identity_adjudicated.parquet \
	../input/lihtc_development_site_2024_mixed_site_identity_adjudicated.parquet

include ../../generic.make
