SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/lihtc_development_2024_singleton_identity_scope_adjudicated.parquet \
	../output/lihtc_project_episode_2024_singleton_identity_scope_adjudicated.parquet \
	../output/lihtc_development_site_2024_singleton_identity_scope_adjudicated.parquet

../output/lihtc_development_2024_singleton_identity_scope_adjudicated.parquet: \
		apply_lihtc_singleton_identity_scope_review.R \
		../input/lihtc_development_2024_mixed_site_identity_adjudicated.parquet \
		../input/lihtc_project_episode_2024_mixed_site_identity_adjudicated.parquet \
		../input/lihtc_development_site_2024_mixed_site_identity_adjudicated.parquet \
		../input/lihtc_singleton_identity_scope_question_reviews.parquet \
		../input/lihtc_singleton_identity_scope_member_partitions.parquet \
		../input/lihtc_singleton_identity_scope_site_decisions.parquet \
		../input/lihtc_singleton_identity_scope_site_additions.parquet | ../output
	$(R) $<

../output/lihtc_project_episode_2024_singleton_identity_scope_adjudicated.parquet \
../output/lihtc_development_site_2024_singleton_identity_scope_adjudicated.parquet: \
		../output/lihtc_development_2024_singleton_identity_scope_adjudicated.parquet
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

../input/lihtc_singleton_identity_scope_question_reviews.parquet: \
		../../review_lihtc_singleton_identity_scope/output/lihtc_singleton_identity_scope_question_reviews.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../review_lihtc_singleton_identity_scope/output/lihtc_singleton_identity_scope_question_reviews.parquet" ]; then \
		ln -sf ../../review_lihtc_singleton_identity_scope/output/lihtc_singleton_identity_scope_question_reviews.parquet "$@"; \
	fi

../input/lihtc_singleton_identity_scope_member_partitions.parquet: \
		../../review_lihtc_singleton_identity_scope/output/lihtc_singleton_identity_scope_member_partitions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../review_lihtc_singleton_identity_scope/output/lihtc_singleton_identity_scope_member_partitions.parquet" ]; then \
		ln -sf ../../review_lihtc_singleton_identity_scope/output/lihtc_singleton_identity_scope_member_partitions.parquet "$@"; \
	fi

../input/lihtc_singleton_identity_scope_site_decisions.parquet: \
		../../review_lihtc_singleton_identity_scope/output/lihtc_singleton_identity_scope_site_decisions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../review_lihtc_singleton_identity_scope/output/lihtc_singleton_identity_scope_site_decisions.parquet" ]; then \
		ln -sf ../../review_lihtc_singleton_identity_scope/output/lihtc_singleton_identity_scope_site_decisions.parquet "$@"; \
	fi

../input/lihtc_singleton_identity_scope_site_additions.parquet: \
		../../review_lihtc_singleton_identity_scope/output/lihtc_singleton_identity_scope_site_additions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../review_lihtc_singleton_identity_scope/output/lihtc_singleton_identity_scope_site_additions.parquet" ]; then \
		ln -sf ../../review_lihtc_singleton_identity_scope/output/lihtc_singleton_identity_scope_site_additions.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_development_2024_mixed_site_identity_adjudicated.parquet \
	../input/lihtc_project_episode_2024_mixed_site_identity_adjudicated.parquet \
	../input/lihtc_development_site_2024_mixed_site_identity_adjudicated.parquet \
	../input/lihtc_singleton_identity_scope_question_reviews.parquet \
	../input/lihtc_singleton_identity_scope_member_partitions.parquet \
	../input/lihtc_singleton_identity_scope_site_decisions.parquet \
	../input/lihtc_singleton_identity_scope_site_additions.parquet

include ../../generic.make
