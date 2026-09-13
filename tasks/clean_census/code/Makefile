include ../../shared/code/shell_functions.make
.DEFAULT_GOAL := all
ACS_YEARS = 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022 2023 2024
TRACT_YEARS = 1980 1990 2000 2010 2020 2024
all: ../output/tract_demographics.csv ../output/price_index.csv ../output/historical_tracts.csv \
    $(addprefix ../output/acs_,$(addsuffix .csv,$(ACS_YEARS))) \
    $(addprefix ../output/tracts_,$(addsuffix .gpkg,$(TRACT_YEARS))) ../output/places_2024.gpkg

include ../../shared/code/generic.make
# Keep prepared input symlinks when GNU Make resolves a file-family rule.
.PRECIOUS: ../input/%.zip ../input/acs5_%.tar.gz

../output/price_index.csv: clean_price_index.R ../input/annual-index-value_annual-percent-change.xls \
    ../../shared/code/save_data.R Makefile | ../output ../report
	$(R) $<

../output/acs_%.csv: clean_acs.R ../input/acs5_%.tar.gz ../input/acs_variables.csv \
    ../../shared/code/save_data.R Makefile | ../output ../report ../temp
	$(R) clean_acs.R $*

../output/historical_tracts.csv: clean_nhgis.R ../input/tables.zip \
    ../../shared/code/save_data.R Makefile | ../output ../report ../temp
	$(R) $<

../output/tract_demographics.csv: combine_census.R ../output/price_index.csv ../output/historical_tracts.csv \
    $(addprefix ../output/acs_,$(addsuffix .csv,$(ACS_YEARS))) \
    ../../shared/code/save_data.R Makefile | ../output ../report
	$(R) $<

../output/tracts_%.gpkg: prepare_boundaries.R ../input/tracts_%.zip Makefile | ../output ../report ../temp
	$(R) prepare_boundaries.R tracts $*

../output/places_2024.gpkg: prepare_boundaries.R ../input/places_2024.zip Makefile | ../output ../report ../temp
	$(R) prepare_boundaries.R places 2024

../input/acs5_%.tar.gz: ../../../data_raw/census_acs/2026-09-13/acs5_%.tar.gz | ../input
	ln -sf $< $@

../input/acs_variables.csv: ../../fetch_census/code/acs_variables.csv | ../input
	ln -sf $< $@

../input/%.zip: ../../../data_raw/nhgis/2026-09-13/%.zip | ../input
	ln -sf $< $@

../input/annual-index-value_annual-percent-change.xls: ../../../data_raw/price_indexes/2026-09-13/annual-index-value_annual-percent-change.xls | ../input
	ln -sf $< $@
