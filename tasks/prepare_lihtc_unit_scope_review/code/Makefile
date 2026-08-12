SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/lihtc_unit_scope_questions.parquet \
	../output/lihtc_unit_scope_question_members.parquet \
	../output/lihtc_unit_scope_prior_evidence.parquet

../output/lihtc_unit_scope_questions.parquet: \
		prepare_lihtc_unit_scope_review.R \
		unit_scope_external_conflicts.csv \
		../input/lihtc_development_2024_singleton_identity_scope_adjudicated.parquet \
		../input/lihtc_project_episode_2024_singleton_identity_scope_adjudicated.parquet \
		../input/lihtc_development_linkage_decisions_2024.parquet \
		../input/lihtc_name_variant_linkage_decisions_2024.parquet \
		../input/lihtc_cross_development_address_decisions.parquet \
		../input/lihtc_cross_development_address_question_reviews_round2.parquet \
		../input/lihtc_identical_address_set_reviews.parquet \
		../input/lihtc_single_address_question_reviews.parquet \
		../input/lihtc_source_site_episode_decisions.parquet \
		../input/lihtc_mixed_site_identity_question_reviews.parquet \
		../input/lihtc_singleton_identity_scope_member_partitions.parquet | ../output
	$(R) $<

../output/lihtc_unit_scope_question_members.parquet: \
		../output/lihtc_unit_scope_questions.parquet
	@test -f $@

../output/lihtc_unit_scope_prior_evidence.parquet: \
		../output/lihtc_unit_scope_questions.parquet
	@test -f $@

../input/lihtc_development_2024_singleton_identity_scope_adjudicated.parquet: \
		../../apply_lihtc_singleton_identity_scope_review/output/lihtc_development_2024_singleton_identity_scope_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_singleton_identity_scope_review/output/lihtc_development_2024_singleton_identity_scope_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_singleton_identity_scope_review/output/lihtc_development_2024_singleton_identity_scope_adjudicated.parquet "$@"; \
	fi

../input/lihtc_project_episode_2024_singleton_identity_scope_adjudicated.parquet: \
		../../apply_lihtc_singleton_identity_scope_review/output/lihtc_project_episode_2024_singleton_identity_scope_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_singleton_identity_scope_review/output/lihtc_project_episode_2024_singleton_identity_scope_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_singleton_identity_scope_review/output/lihtc_project_episode_2024_singleton_identity_scope_adjudicated.parquet "$@"; \
	fi

../input/lihtc_development_linkage_decisions_2024.parquet: \
		../../review_lihtc_development_linkage/output/lihtc_development_linkage_decisions_2024.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../review_lihtc_development_linkage/output/lihtc_development_linkage_decisions_2024.parquet" ]; then \
		ln -sf ../../review_lihtc_development_linkage/output/lihtc_development_linkage_decisions_2024.parquet "$@"; \
	fi

../input/lihtc_name_variant_linkage_decisions_2024.parquet: \
		../../review_lihtc_name_variant_linkage/output/lihtc_name_variant_linkage_decisions_2024.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../review_lihtc_name_variant_linkage/output/lihtc_name_variant_linkage_decisions_2024.parquet" ]; then \
		ln -sf ../../review_lihtc_name_variant_linkage/output/lihtc_name_variant_linkage_decisions_2024.parquet "$@"; \
	fi

../input/lihtc_cross_development_address_decisions.parquet: \
		../../review_lihtc_cross_development_addresses/output/lihtc_cross_development_address_decisions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../review_lihtc_cross_development_addresses/output/lihtc_cross_development_address_decisions.parquet" ]; then \
		ln -sf ../../review_lihtc_cross_development_addresses/output/lihtc_cross_development_address_decisions.parquet "$@"; \
	fi

../input/lihtc_cross_development_address_question_reviews_round2.parquet: \
		../../review_lihtc_cross_development_addresses_round2/output/lihtc_cross_development_address_question_reviews_round2.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../review_lihtc_cross_development_addresses_round2/output/lihtc_cross_development_address_question_reviews_round2.parquet" ]; then \
		ln -sf ../../review_lihtc_cross_development_addresses_round2/output/lihtc_cross_development_address_question_reviews_round2.parquet "$@"; \
	fi

../input/lihtc_identical_address_set_reviews.parquet: \
		../../review_lihtc_identical_address_sets/output/lihtc_identical_address_set_reviews.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../review_lihtc_identical_address_sets/output/lihtc_identical_address_set_reviews.parquet" ]; then \
		ln -sf ../../review_lihtc_identical_address_sets/output/lihtc_identical_address_set_reviews.parquet "$@"; \
	fi

../input/lihtc_single_address_question_reviews.parquet: \
		../../review_lihtc_single_address/output/lihtc_single_address_question_reviews.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../review_lihtc_single_address/output/lihtc_single_address_question_reviews.parquet" ]; then \
		ln -sf ../../review_lihtc_single_address/output/lihtc_single_address_question_reviews.parquet "$@"; \
	fi

../input/lihtc_source_site_episode_decisions.parquet: \
		../../review_lihtc_source_site_exceptions/output/lihtc_source_site_episode_decisions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../review_lihtc_source_site_exceptions/output/lihtc_source_site_episode_decisions.parquet" ]; then \
		ln -sf ../../review_lihtc_source_site_exceptions/output/lihtc_source_site_episode_decisions.parquet "$@"; \
	fi

../input/lihtc_mixed_site_identity_question_reviews.parquet: \
		../../review_lihtc_mixed_site_identity/output/lihtc_mixed_site_identity_question_reviews.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../review_lihtc_mixed_site_identity/output/lihtc_mixed_site_identity_question_reviews.parquet" ]; then \
		ln -sf ../../review_lihtc_mixed_site_identity/output/lihtc_mixed_site_identity_question_reviews.parquet "$@"; \
	fi

../input/lihtc_singleton_identity_scope_member_partitions.parquet: \
		../../review_lihtc_singleton_identity_scope/output/lihtc_singleton_identity_scope_member_partitions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../review_lihtc_singleton_identity_scope/output/lihtc_singleton_identity_scope_member_partitions.parquet" ]; then \
		ln -sf ../../review_lihtc_singleton_identity_scope/output/lihtc_singleton_identity_scope_member_partitions.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_development_2024_singleton_identity_scope_adjudicated.parquet \
	../input/lihtc_project_episode_2024_singleton_identity_scope_adjudicated.parquet \
	../input/lihtc_development_linkage_decisions_2024.parquet \
	../input/lihtc_name_variant_linkage_decisions_2024.parquet \
	../input/lihtc_cross_development_address_decisions.parquet \
	../input/lihtc_cross_development_address_question_reviews_round2.parquet \
	../input/lihtc_identical_address_set_reviews.parquet \
	../input/lihtc_single_address_question_reviews.parquet \
	../input/lihtc_source_site_episode_decisions.parquet \
	../input/lihtc_mixed_site_identity_question_reviews.parquet \
	../input/lihtc_singleton_identity_scope_member_partitions.parquet

include ../../generic.make
