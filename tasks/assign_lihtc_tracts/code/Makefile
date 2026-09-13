include ../../shared/code/shell_functions.make
.DEFAULT_GOAL := all
TRACT_YEARS = 1980 1990 2000 2010 2020 2024
all: $(addprefix ../output/lihtc_tracts_,$(addsuffix .csv,$(TRACT_YEARS))) \
    ../output/lihtc_places.csv ../output/projects_with_tracts.csv ../output/tract_lihtc_counts.csv

include ../../shared/code/generic.make
.PRECIOUS: ../input/tracts_%.gpkg

../output/lihtc_tracts_%.csv: assign_lihtc_tracts.R ../input/projects.csv ../input/tracts_%.gpkg \
    ../../shared/code/save_data.R Makefile | ../output ../report
	$(R) assign_lihtc_tracts.R $*

../output/lihtc_places.csv: assign_lihtc_places.R ../input/projects.csv ../input/places_2024.gpkg \
    ../../shared/code/save_data.R Makefile | ../output ../report
	$(R) $<

../output/projects_with_tracts.csv: join_tract_demographics.R ../input/projects.csv \
    ../input/tract_demographics.csv ../output/lihtc_places.csv \
    $(addprefix ../output/lihtc_tracts_,$(addsuffix .csv,$(TRACT_YEARS))) \
    ../../shared/code/save_data.R Makefile | ../output ../report
	$(R) $<

../output/tract_lihtc_counts.csv: count_lihtc_tracts.R ../input/tract_demographics.csv \
    ../output/projects_with_tracts.csv ../../shared/code/save_data.R Makefile | ../output ../report
	$(R) $<

../input/projects.csv: ../../build_lihtc/output/projects.csv | ../input
	ln -sf $< $@

../input/tract_demographics.csv: ../../clean_census/output/tract_demographics.csv | ../input
	ln -sf $< $@

../input/tracts_%.gpkg: ../../clean_census/output/tracts_%.gpkg | ../input
	ln -sf $< $@

../input/places_2024.gpkg: ../../clean_census/output/places_2024.gpkg | ../input
	ln -sf $< $@
