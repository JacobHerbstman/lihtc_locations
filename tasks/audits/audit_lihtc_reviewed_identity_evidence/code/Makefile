SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/lihtc_reviewed_identity_development_evidence_audit.parquet \
	../output/lihtc_reviewed_identity_question_evidence_audit.parquet \
	../output/lihtc_reviewed_identity_member_lineage_audit.parquet \
	../output/lihtc_reviewed_identity_descendant_propagation_audit.parquet \
	../output/lihtc_reviewed_identity_evidence_status_counts.parquet

../output/lihtc_reviewed_identity_development_evidence_audit.parquet: audit_lihtc_reviewed_identity_evidence.R \
	../input/lihtc_development_2024_low_income_share_adjudicated.parquet \
	../input/lihtc_project_episode_2024_low_income_share_adjudicated.parquet \
	../input/lihtc_development_site_2024_low_income_share_adjudicated.parquet \
	../input/lihtc_development_linkage_decisions_2024.parquet \
	../input/lihtc_development_linkage_member_decisions_2024.parquet \
	../input/lihtc_name_variant_linkage_decisions_2024.parquet \
	../input/lihtc_name_variant_linkage_member_decisions_2024.parquet \
	../input/lihtc_single_address_question_reviews.parquet \
	../input/lihtc_single_address_member_partitions.parquet \
	../input/lihtc_identical_address_set_reviews.parquet \
	../input/lihtc_identical_address_set_proposed_member_mapping.parquet \
	../input/lihtc_mixed_site_identity_question_reviews.parquet \
	../input/lihtc_mixed_site_identity_member_partitions.parquet \
	../input/lihtc_cross_development_address_decisions.parquet \
	../input/lihtc_cross_development_address_member_decisions.parquet \
	../input/lihtc_cross_development_address_question_reviews_round2.parquet \
	../input/lihtc_cross_development_address_member_partitions_round2.parquet \
	../input/lihtc_singleton_identity_scope_question_reviews.parquet \
	../input/lihtc_singleton_identity_scope_member_partitions.parquet | ../output
	$(R) $<

../output/lihtc_reviewed_identity_question_evidence_audit.parquet \
../output/lihtc_reviewed_identity_member_lineage_audit.parquet \
../output/lihtc_reviewed_identity_descendant_propagation_audit.parquet \
../output/lihtc_reviewed_identity_evidence_status_counts.parquet: ../output/lihtc_reviewed_identity_development_evidence_audit.parquet
	@test -f $@

../input/lihtc_development_2024_low_income_share_adjudicated.parquet: ../../../apply_lihtc_low_income_share_review/output/lihtc_development_2024_low_income_share_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_low_income_share_review/output/lihtc_development_2024_low_income_share_adjudicated.parquet" ]; then ln -sf ../../../apply_lihtc_low_income_share_review/output/lihtc_development_2024_low_income_share_adjudicated.parquet "$@"; fi

../input/lihtc_project_episode_2024_low_income_share_adjudicated.parquet: ../../../apply_lihtc_low_income_share_review/output/lihtc_project_episode_2024_low_income_share_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_low_income_share_review/output/lihtc_project_episode_2024_low_income_share_adjudicated.parquet" ]; then ln -sf ../../../apply_lihtc_low_income_share_review/output/lihtc_project_episode_2024_low_income_share_adjudicated.parquet "$@"; fi

../input/lihtc_development_site_2024_low_income_share_adjudicated.parquet: ../../../apply_lihtc_low_income_share_review/output/lihtc_development_site_2024_low_income_share_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../apply_lihtc_low_income_share_review/output/lihtc_development_site_2024_low_income_share_adjudicated.parquet" ]; then ln -sf ../../../apply_lihtc_low_income_share_review/output/lihtc_development_site_2024_low_income_share_adjudicated.parquet "$@"; fi

../input/lihtc_development_linkage_decisions_2024.parquet: ../../../review_lihtc_development_linkage/output/lihtc_development_linkage_decisions_2024.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../review_lihtc_development_linkage/output/lihtc_development_linkage_decisions_2024.parquet" ]; then ln -sf ../../../review_lihtc_development_linkage/output/lihtc_development_linkage_decisions_2024.parquet "$@"; fi

../input/lihtc_development_linkage_member_decisions_2024.parquet: ../../../review_lihtc_development_linkage/output/lihtc_development_linkage_member_decisions_2024.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../review_lihtc_development_linkage/output/lihtc_development_linkage_member_decisions_2024.parquet" ]; then ln -sf ../../../review_lihtc_development_linkage/output/lihtc_development_linkage_member_decisions_2024.parquet "$@"; fi

../input/lihtc_name_variant_linkage_decisions_2024.parquet: ../../../review_lihtc_name_variant_linkage/output/lihtc_name_variant_linkage_decisions_2024.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../review_lihtc_name_variant_linkage/output/lihtc_name_variant_linkage_decisions_2024.parquet" ]; then ln -sf ../../../review_lihtc_name_variant_linkage/output/lihtc_name_variant_linkage_decisions_2024.parquet "$@"; fi

../input/lihtc_name_variant_linkage_member_decisions_2024.parquet: ../../../review_lihtc_name_variant_linkage/output/lihtc_name_variant_linkage_member_decisions_2024.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../review_lihtc_name_variant_linkage/output/lihtc_name_variant_linkage_member_decisions_2024.parquet" ]; then ln -sf ../../../review_lihtc_name_variant_linkage/output/lihtc_name_variant_linkage_member_decisions_2024.parquet "$@"; fi

../input/lihtc_single_address_question_reviews.parquet: ../../../review_lihtc_single_address/output/lihtc_single_address_question_reviews.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../review_lihtc_single_address/output/lihtc_single_address_question_reviews.parquet" ]; then ln -sf ../../../review_lihtc_single_address/output/lihtc_single_address_question_reviews.parquet "$@"; fi

../input/lihtc_single_address_member_partitions.parquet: ../../../review_lihtc_single_address/output/lihtc_single_address_member_partitions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../review_lihtc_single_address/output/lihtc_single_address_member_partitions.parquet" ]; then ln -sf ../../../review_lihtc_single_address/output/lihtc_single_address_member_partitions.parquet "$@"; fi

../input/lihtc_identical_address_set_reviews.parquet: ../../../review_lihtc_identical_address_sets/output/lihtc_identical_address_set_reviews.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../review_lihtc_identical_address_sets/output/lihtc_identical_address_set_reviews.parquet" ]; then ln -sf ../../../review_lihtc_identical_address_sets/output/lihtc_identical_address_set_reviews.parquet "$@"; fi

../input/lihtc_identical_address_set_proposed_member_mapping.parquet: ../../../review_lihtc_identical_address_sets/output/lihtc_identical_address_set_proposed_member_mapping.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../review_lihtc_identical_address_sets/output/lihtc_identical_address_set_proposed_member_mapping.parquet" ]; then ln -sf ../../../review_lihtc_identical_address_sets/output/lihtc_identical_address_set_proposed_member_mapping.parquet "$@"; fi

../input/lihtc_mixed_site_identity_question_reviews.parquet: ../../../review_lihtc_mixed_site_identity/output/lihtc_mixed_site_identity_question_reviews.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../review_lihtc_mixed_site_identity/output/lihtc_mixed_site_identity_question_reviews.parquet" ]; then ln -sf ../../../review_lihtc_mixed_site_identity/output/lihtc_mixed_site_identity_question_reviews.parquet "$@"; fi

../input/lihtc_mixed_site_identity_member_partitions.parquet: ../../../review_lihtc_mixed_site_identity/output/lihtc_mixed_site_identity_member_partitions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../review_lihtc_mixed_site_identity/output/lihtc_mixed_site_identity_member_partitions.parquet" ]; then ln -sf ../../../review_lihtc_mixed_site_identity/output/lihtc_mixed_site_identity_member_partitions.parquet "$@"; fi

../input/lihtc_cross_development_address_decisions.parquet: ../../../review_lihtc_cross_development_addresses/output/lihtc_cross_development_address_decisions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../review_lihtc_cross_development_addresses/output/lihtc_cross_development_address_decisions.parquet" ]; then ln -sf ../../../review_lihtc_cross_development_addresses/output/lihtc_cross_development_address_decisions.parquet "$@"; fi

../input/lihtc_cross_development_address_member_decisions.parquet: ../../../review_lihtc_cross_development_addresses/output/lihtc_cross_development_address_member_decisions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../review_lihtc_cross_development_addresses/output/lihtc_cross_development_address_member_decisions.parquet" ]; then ln -sf ../../../review_lihtc_cross_development_addresses/output/lihtc_cross_development_address_member_decisions.parquet "$@"; fi

../input/lihtc_cross_development_address_question_reviews_round2.parquet: ../../../review_lihtc_cross_development_addresses_round2/output/lihtc_cross_development_address_question_reviews_round2.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../review_lihtc_cross_development_addresses_round2/output/lihtc_cross_development_address_question_reviews_round2.parquet" ]; then ln -sf ../../../review_lihtc_cross_development_addresses_round2/output/lihtc_cross_development_address_question_reviews_round2.parquet "$@"; fi

../input/lihtc_cross_development_address_member_partitions_round2.parquet: ../../../review_lihtc_cross_development_addresses_round2/output/lihtc_cross_development_address_member_partitions_round2.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../review_lihtc_cross_development_addresses_round2/output/lihtc_cross_development_address_member_partitions_round2.parquet" ]; then ln -sf ../../../review_lihtc_cross_development_addresses_round2/output/lihtc_cross_development_address_member_partitions_round2.parquet "$@"; fi

../input/lihtc_singleton_identity_scope_question_reviews.parquet: ../../../review_lihtc_singleton_identity_scope/output/lihtc_singleton_identity_scope_question_reviews.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../review_lihtc_singleton_identity_scope/output/lihtc_singleton_identity_scope_question_reviews.parquet" ]; then ln -sf ../../../review_lihtc_singleton_identity_scope/output/lihtc_singleton_identity_scope_question_reviews.parquet "$@"; fi

../input/lihtc_singleton_identity_scope_member_partitions.parquet: ../../../review_lihtc_singleton_identity_scope/output/lihtc_singleton_identity_scope_member_partitions.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../../review_lihtc_singleton_identity_scope/output/lihtc_singleton_identity_scope_member_partitions.parquet" ]; then ln -sf ../../../review_lihtc_singleton_identity_scope/output/lihtc_singleton_identity_scope_member_partitions.parquet "$@"; fi

link-inputs: \
	../input/lihtc_development_2024_low_income_share_adjudicated.parquet \
	../input/lihtc_project_episode_2024_low_income_share_adjudicated.parquet \
	../input/lihtc_development_site_2024_low_income_share_adjudicated.parquet \
	../input/lihtc_development_linkage_decisions_2024.parquet \
	../input/lihtc_development_linkage_member_decisions_2024.parquet \
	../input/lihtc_name_variant_linkage_decisions_2024.parquet \
	../input/lihtc_name_variant_linkage_member_decisions_2024.parquet \
	../input/lihtc_single_address_question_reviews.parquet \
	../input/lihtc_single_address_member_partitions.parquet \
	../input/lihtc_identical_address_set_reviews.parquet \
	../input/lihtc_identical_address_set_proposed_member_mapping.parquet \
	../input/lihtc_mixed_site_identity_question_reviews.parquet \
	../input/lihtc_mixed_site_identity_member_partitions.parquet \
	../input/lihtc_cross_development_address_decisions.parquet \
	../input/lihtc_cross_development_address_member_decisions.parquet \
	../input/lihtc_cross_development_address_question_reviews_round2.parquet \
	../input/lihtc_cross_development_address_member_partitions_round2.parquet \
	../input/lihtc_singleton_identity_scope_question_reviews.parquet \
	../input/lihtc_singleton_identity_scope_member_partitions.parquet

include ../../../generic.make
