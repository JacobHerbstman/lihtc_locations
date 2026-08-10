SHELL := /bin/bash
.DEFAULT_GOAL := paper

.PHONY: all paper setup sources lihtc-data prepare-lihtc-data audit-lihtc-data \
	build-lihtc-development audit-lihtc-development \
	adjudicate-lihtc-development audit-lihtc-development-linkage \
	adjudicate-lihtc-name-variants audit-lihtc-name-variants \
	audit-lihtc-geocoding-readiness \
	audit-lihtc-cross-development-addresses \
	prepare-lihtc-cross-development-address-review \
	review-lihtc-cross-development-addresses

all: paper

paper: tasks/setup_environment/output/system_requirements.txt tasks/setup_environment/output/R_packages.txt
	$(MAKE) -C paper

setup: tasks/setup_environment/output/system_requirements.txt tasks/setup_environment/output/R_packages.txt

sources: tasks/source_registry/output/source_catalog.csv

lihtc-data: tasks/fetch_lihtc_property/output/lihtc_property_2024_files.csv

prepare-lihtc-data: \
	tasks/prepare_lihtc_property/output/lihtc_property_2024_raw_text.parquet \
	tasks/prepare_lihtc_multisite/output/lihtc_multisite_2024_raw_text.parquet

audit-lihtc-data: tasks/audits/audit_lihtc_property/output/audit_summary.md

build-lihtc-development: \
	tasks/build_lihtc_development/output/lihtc_development_2024.parquet \
	tasks/build_lihtc_development/output/lihtc_project_episode_2024.parquet \
	tasks/build_lihtc_development/output/lihtc_development_site_2024.parquet

audit-lihtc-development: tasks/audits/audit_lihtc_development/output/audit_summary.md

adjudicate-lihtc-development: \
	tasks/apply_lihtc_development_linkage_review/output/lihtc_development_2024_adjudicated.parquet \
	tasks/apply_lihtc_development_linkage_review/output/lihtc_project_episode_2024_adjudicated.parquet \
	tasks/apply_lihtc_development_linkage_review/output/lihtc_development_site_2024_adjudicated.parquet

audit-lihtc-development-linkage: \
	tasks/audits/audit_lihtc_development_linkage_review/output/audit_summary.md

adjudicate-lihtc-name-variants: \
	tasks/apply_lihtc_name_variant_linkage_review/output/lihtc_development_2024_name_adjudicated.parquet \
	tasks/apply_lihtc_name_variant_linkage_review/output/lihtc_project_episode_2024_name_adjudicated.parquet \
	tasks/apply_lihtc_name_variant_linkage_review/output/lihtc_development_site_2024_name_adjudicated.parquet

audit-lihtc-name-variants: \
	tasks/audits/audit_lihtc_name_variant_linkage_review/output/audit_summary.md

audit-lihtc-geocoding-readiness: \
	tasks/audits/audit_lihtc_geocoding_readiness/output/audit_summary.md

audit-lihtc-cross-development-addresses: \
	tasks/audits/audit_lihtc_cross_development_addresses/output/audit_summary.md

prepare-lihtc-cross-development-address-review: \
	tasks/prepare_lihtc_cross_development_address_review/output/audit_summary.md

review-lihtc-cross-development-addresses: \
	tasks/review_lihtc_cross_development_addresses/output/review_summary.md

tasks/setup_environment/output/system_requirements.txt: tasks/setup_environment/code/system_requirements.sh
	$(MAKE) -C tasks/setup_environment/code ../output/system_requirements.txt

tasks/setup_environment/output/R_packages.txt: tasks/setup_environment/code/packages.R tasks/setup_environment/output/system_requirements.txt
	$(MAKE) -C tasks/setup_environment/code ../output/R_packages.txt

tasks/source_registry/output/source_catalog.csv: tasks/source_registry/code/source_catalog.csv
	$(MAKE) -C tasks/source_registry/code ../output/source_catalog.csv

tasks/fetch_lihtc_property/output/lihtc_property_2024_files.csv: \
		tasks/fetch_lihtc_property/code/fetch_lihtc_property.py \
		tasks/fetch_lihtc_property/code/validate_lihtc_property.py \
		tasks/fetch_lihtc_property/code/release_manifest.csv \
		tasks/source_registry/output/source_catalog.csv
	$(MAKE) -C tasks/fetch_lihtc_property/code ../output/lihtc_property_2024_files.csv

tasks/prepare_lihtc_property/output/lihtc_property_2024_raw_text.parquet: \
		tasks/prepare_lihtc_property/code/prepare_lihtc_property.R \
		tasks/fetch_lihtc_property/output/lihtc_property_2024_files.csv \
		data_raw/hud_lihtc_property/2024/lihtcpub.zip
	$(MAKE) -C tasks/prepare_lihtc_property/code ../output/lihtc_property_2024_raw_text.parquet

tasks/prepare_lihtc_multisite/output/lihtc_multisite_2024_raw_text.parquet: \
		tasks/prepare_lihtc_multisite/code/prepare_lihtc_multisite.R \
		tasks/fetch_lihtc_property/output/lihtc_property_2024_files.csv \
		data_raw/hud_lihtc_property/2024/lihtcpub.zip
	$(MAKE) -C tasks/prepare_lihtc_multisite/code ../output/lihtc_multisite_2024_raw_text.parquet

tasks/audits/audit_lihtc_property/output/audit_summary.md: \
		tasks/audits/audit_lihtc_property/code/audit_lihtc_property.R \
		tasks/audits/audit_lihtc_property/code/dictionary_claims.csv \
		tasks/audits/audit_lihtc_property/code/inspect_workbook_xml.py \
		tasks/fetch_lihtc_property/output/lihtc_property_2024_files.csv \
		tasks/prepare_lihtc_property/output/lihtc_property_2024_raw_text.parquet \
		data_raw/hud_lihtc_property/2024/lihtcpub.zip
	$(MAKE) -C tasks/audits/audit_lihtc_property/code ../output/audit_summary.md

tasks/build_lihtc_development/output/lihtc_development_2024.parquet: \
		tasks/build_lihtc_development/code/build_lihtc_development.R \
		tasks/prepare_lihtc_property/output/lihtc_property_2024_raw_text.parquet \
		tasks/prepare_lihtc_multisite/output/lihtc_multisite_2024_raw_text.parquet
	$(MAKE) -C tasks/build_lihtc_development/code ../output/lihtc_development_2024.parquet

tasks/build_lihtc_development/output/lihtc_project_episode_2024.parquet \
tasks/build_lihtc_development/output/lihtc_development_site_2024.parquet: \
		tasks/build_lihtc_development/output/lihtc_development_2024.parquet
	@test -f $@

tasks/audits/audit_lihtc_development/output/audit_summary.md: \
		tasks/audits/audit_lihtc_development/code/audit_lihtc_development.R \
		tasks/build_lihtc_development/output/lihtc_development_2024.parquet \
		tasks/build_lihtc_development/output/lihtc_project_episode_2024.parquet \
		tasks/build_lihtc_development/output/lihtc_development_site_2024.parquet
	$(MAKE) -C tasks/audits/audit_lihtc_development/code ../output/audit_summary.md

tasks/review_lihtc_development_linkage/output/lihtc_development_linkage_decisions_2024.parquet: \
		tasks/review_lihtc_development_linkage/code/validate_lihtc_development_linkage.R \
		tasks/review_lihtc_development_linkage/code/development_linkage_decisions.csv \
		tasks/review_lihtc_development_linkage/code/development_linkage_member_decisions.csv \
		tasks/build_lihtc_development/output/lihtc_development_2024.parquet \
		tasks/build_lihtc_development/output/lihtc_project_episode_2024.parquet
	$(MAKE) -C tasks/review_lihtc_development_linkage/code ../output/lihtc_development_linkage_decisions_2024.parquet

tasks/review_lihtc_development_linkage/output/lihtc_development_linkage_member_decisions_2024.parquet: \
		tasks/review_lihtc_development_linkage/output/lihtc_development_linkage_decisions_2024.parquet
	@test -f $@

tasks/apply_lihtc_development_linkage_review/output/lihtc_development_2024_adjudicated.parquet: \
		tasks/apply_lihtc_development_linkage_review/code/apply_lihtc_development_linkage_review.R \
		tasks/build_lihtc_development/output/lihtc_development_2024.parquet \
		tasks/build_lihtc_development/output/lihtc_project_episode_2024.parquet \
		tasks/build_lihtc_development/output/lihtc_development_site_2024.parquet \
		tasks/review_lihtc_development_linkage/output/lihtc_development_linkage_decisions_2024.parquet \
		tasks/review_lihtc_development_linkage/output/lihtc_development_linkage_member_decisions_2024.parquet
	$(MAKE) -C tasks/apply_lihtc_development_linkage_review/code ../output/lihtc_development_2024_adjudicated.parquet

tasks/apply_lihtc_development_linkage_review/output/lihtc_project_episode_2024_adjudicated.parquet \
tasks/apply_lihtc_development_linkage_review/output/lihtc_development_site_2024_adjudicated.parquet: \
		tasks/apply_lihtc_development_linkage_review/output/lihtc_development_2024_adjudicated.parquet
	@test -f $@

tasks/audits/audit_lihtc_development_linkage_review/output/audit_summary.md: \
		tasks/audits/audit_lihtc_development_linkage_review/code/audit_lihtc_development_linkage_review.R \
		tasks/apply_lihtc_development_linkage_review/output/lihtc_development_2024_adjudicated.parquet \
		tasks/apply_lihtc_development_linkage_review/output/lihtc_project_episode_2024_adjudicated.parquet \
		tasks/apply_lihtc_development_linkage_review/output/lihtc_development_site_2024_adjudicated.parquet \
		tasks/build_lihtc_development/output/lihtc_project_episode_2024.parquet \
		tasks/review_lihtc_development_linkage/output/lihtc_development_linkage_decisions_2024.parquet \
		tasks/review_lihtc_development_linkage/output/lihtc_development_linkage_member_decisions_2024.parquet
	$(MAKE) -C tasks/audits/audit_lihtc_development_linkage_review/code ../output/audit_summary.md

tasks/review_lihtc_name_variant_linkage/output/lihtc_name_variant_linkage_decisions_2024.parquet: \
		tasks/review_lihtc_name_variant_linkage/code/validate_lihtc_name_variant_linkage.R \
		tasks/review_lihtc_name_variant_linkage/code/name_variant_linkage_decisions.csv \
		tasks/review_lihtc_name_variant_linkage/code/name_variant_linkage_member_decisions.csv \
		tasks/apply_lihtc_development_linkage_review/output/lihtc_development_2024_adjudicated.parquet \
		tasks/apply_lihtc_development_linkage_review/output/lihtc_project_episode_2024_adjudicated.parquet
	$(MAKE) -C tasks/review_lihtc_name_variant_linkage/code ../output/lihtc_name_variant_linkage_decisions_2024.parquet

tasks/review_lihtc_name_variant_linkage/output/lihtc_name_variant_linkage_member_decisions_2024.parquet: \
		tasks/review_lihtc_name_variant_linkage/output/lihtc_name_variant_linkage_decisions_2024.parquet
	@test -f $@

tasks/apply_lihtc_name_variant_linkage_review/output/lihtc_development_2024_name_adjudicated.parquet: \
		tasks/apply_lihtc_name_variant_linkage_review/code/apply_lihtc_name_variant_linkage_review.R \
		tasks/apply_lihtc_development_linkage_review/output/lihtc_development_2024_adjudicated.parquet \
		tasks/apply_lihtc_development_linkage_review/output/lihtc_project_episode_2024_adjudicated.parquet \
		tasks/apply_lihtc_development_linkage_review/output/lihtc_development_site_2024_adjudicated.parquet \
		tasks/prepare_lihtc_multisite/output/lihtc_multisite_2024_raw_text.parquet \
		tasks/review_lihtc_name_variant_linkage/output/lihtc_name_variant_linkage_decisions_2024.parquet \
		tasks/review_lihtc_name_variant_linkage/output/lihtc_name_variant_linkage_member_decisions_2024.parquet
	$(MAKE) -C tasks/apply_lihtc_name_variant_linkage_review/code ../output/lihtc_development_2024_name_adjudicated.parquet

tasks/apply_lihtc_name_variant_linkage_review/output/lihtc_project_episode_2024_name_adjudicated.parquet \
tasks/apply_lihtc_name_variant_linkage_review/output/lihtc_development_site_2024_name_adjudicated.parquet: \
		tasks/apply_lihtc_name_variant_linkage_review/output/lihtc_development_2024_name_adjudicated.parquet
	@test -f $@

tasks/audits/audit_lihtc_name_variant_linkage_review/output/audit_summary.md: \
		tasks/audits/audit_lihtc_name_variant_linkage_review/code/audit_lihtc_name_variant_linkage_review.R \
		tasks/apply_lihtc_development_linkage_review/output/lihtc_development_2024_adjudicated.parquet \
		tasks/apply_lihtc_development_linkage_review/output/lihtc_project_episode_2024_adjudicated.parquet \
		tasks/apply_lihtc_development_linkage_review/output/lihtc_development_site_2024_adjudicated.parquet \
		tasks/apply_lihtc_name_variant_linkage_review/output/lihtc_development_2024_name_adjudicated.parquet \
		tasks/apply_lihtc_name_variant_linkage_review/output/lihtc_project_episode_2024_name_adjudicated.parquet \
		tasks/apply_lihtc_name_variant_linkage_review/output/lihtc_development_site_2024_name_adjudicated.parquet \
		tasks/review_lihtc_name_variant_linkage/output/lihtc_name_variant_linkage_decisions_2024.parquet \
		tasks/review_lihtc_name_variant_linkage/output/lihtc_name_variant_linkage_member_decisions_2024.parquet
	$(MAKE) -C tasks/audits/audit_lihtc_name_variant_linkage_review/code ../output/audit_summary.md

tasks/audits/audit_lihtc_geocoding_readiness/output/audit_summary.md: \
		tasks/audits/audit_lihtc_geocoding_readiness/code/audit_lihtc_geocoding_readiness.R \
		tasks/apply_lihtc_name_variant_linkage_review/output/lihtc_project_episode_2024_name_adjudicated.parquet \
		tasks/apply_lihtc_name_variant_linkage_review/output/lihtc_development_site_2024_name_adjudicated.parquet \
		tasks/prepare_lihtc_multisite/output/lihtc_multisite_2024_raw_text.parquet
	$(MAKE) -C tasks/audits/audit_lihtc_geocoding_readiness/code ../output/audit_summary.md

tasks/audits/audit_lihtc_cross_development_addresses/output/audit_summary.md: \
		tasks/audits/audit_lihtc_cross_development_addresses/code/audit_lihtc_cross_development_addresses.R \
		tasks/audits/audit_lihtc_geocoding_readiness/output/lihtc_site_geocoding_readiness.parquet \
		tasks/apply_lihtc_name_variant_linkage_review/output/lihtc_development_2024_name_adjudicated.parquet \
		tasks/apply_lihtc_name_variant_linkage_review/output/lihtc_project_episode_2024_name_adjudicated.parquet
	$(MAKE) -C tasks/audits/audit_lihtc_cross_development_addresses/code ../output/audit_summary.md

tasks/prepare_lihtc_cross_development_address_review/output/audit_summary.md: \
		tasks/prepare_lihtc_cross_development_address_review/code/prepare_lihtc_cross_development_address_review.R \
		tasks/audits/audit_lihtc_cross_development_addresses/output/lihtc_cross_development_pairs.parquet \
		tasks/apply_lihtc_name_variant_linkage_review/output/lihtc_development_2024_name_adjudicated.parquet \
		tasks/review_lihtc_name_variant_linkage/output/lihtc_name_variant_linkage_decisions_2024.parquet
	$(MAKE) -C tasks/prepare_lihtc_cross_development_address_review/code ../output/audit_summary.md

tasks/review_lihtc_cross_development_addresses/output/review_summary.md: \
		tasks/review_lihtc_cross_development_addresses/code/validate_lihtc_cross_development_addresses.R \
		tasks/review_lihtc_cross_development_addresses/code/cross_development_address_decisions.csv \
		tasks/prepare_lihtc_cross_development_address_review/output/lihtc_cross_development_identity_questions.parquet \
		tasks/prepare_lihtc_cross_development_address_review/output/lihtc_cross_development_identity_question_members.parquet
	$(MAKE) -C tasks/review_lihtc_cross_development_addresses/code ../output/review_summary.md
