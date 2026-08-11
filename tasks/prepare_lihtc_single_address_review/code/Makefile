SHELL := /bin/bash
.DEFAULT_GOAL := all

R := Rscript

.PHONY: all link-inputs

all: \
	../output/lihtc_single_address_identity_questions.parquet \
	../output/lihtc_single_address_identity_question_members.parquet \
	../output/lihtc_single_address_identity_question_pairs.parquet

../output/lihtc_single_address_identity_questions.parquet: \
		prepare_lihtc_single_address_review.R \
		../input/lihtc_development_2024_identical_address_adjudicated.parquet \
		../input/lihtc_project_episode_2024_identical_address_adjudicated.parquet \
		../input/lihtc_development_site_2024_identical_address_adjudicated.parquet | ../output
	$(R) $<

../output/lihtc_single_address_identity_question_members.parquet \
../output/lihtc_single_address_identity_question_pairs.parquet: \
		../output/lihtc_single_address_identity_questions.parquet
	@test -f $@

../input/lihtc_development_2024_identical_address_adjudicated.parquet: \
		../../apply_lihtc_identical_address_set_review/output/lihtc_development_2024_identical_address_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_identical_address_set_review/output/lihtc_development_2024_identical_address_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_identical_address_set_review/output/lihtc_development_2024_identical_address_adjudicated.parquet "$@"; \
	fi

../input/lihtc_project_episode_2024_identical_address_adjudicated.parquet: \
		../../apply_lihtc_identical_address_set_review/output/lihtc_project_episode_2024_identical_address_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_identical_address_set_review/output/lihtc_project_episode_2024_identical_address_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_identical_address_set_review/output/lihtc_project_episode_2024_identical_address_adjudicated.parquet "$@"; \
	fi

../input/lihtc_development_site_2024_identical_address_adjudicated.parquet: \
		../../apply_lihtc_identical_address_set_review/output/lihtc_development_site_2024_identical_address_adjudicated.parquet | ../input
	@if [ "$$(readlink "$@")" != "../../apply_lihtc_identical_address_set_review/output/lihtc_development_site_2024_identical_address_adjudicated.parquet" ]; then \
		ln -sf ../../apply_lihtc_identical_address_set_review/output/lihtc_development_site_2024_identical_address_adjudicated.parquet "$@"; \
	fi

link-inputs: \
	../input/lihtc_development_2024_identical_address_adjudicated.parquet \
	../input/lihtc_project_episode_2024_identical_address_adjudicated.parquet \
	../input/lihtc_development_site_2024_identical_address_adjudicated.parquet

include ../../generic.make
