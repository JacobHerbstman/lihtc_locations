include ../../shared/code/shell_functions.make
.DEFAULT_GOAL := all
ACS_YEARS = 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022 2023 2024
TRACT_YEARS = 1980 1990 2000 2010 2020 2024
all: $(addprefix ../../../data_raw/census_acs/2026-09-13/acs5_, $(addsuffix .tar.gz,$(ACS_YEARS))) \
    ../../../data_raw/nhgis/2026-09-13/tables.zip \
    $(addprefix ../../../data_raw/nhgis/2026-09-13/tracts_, $(addsuffix .zip,$(TRACT_YEARS))) \
    ../../../data_raw/nhgis/2026-09-13/places_2024.zip \
    ../../../data_raw/price_indexes/2026-09-13/annual-index-value_annual-percent-change.xls

include ../../shared/code/generic.make

../../../data_raw/nhgis/2026-09-13/%.zip: nhgis_%.json | download_nhgis.R ../temp ../report
	$(R) download_nhgis.R $*

../../../data_raw/census_acs/2026-09-13/acs5_%.tar.gz: acs_variables.csv | download_acs.R ../temp ../report
	$(R) download_acs.R $*

../../../data_raw/price_indexes/2026-09-13/annual-index-value_annual-percent-change.xls: | ../temp
	mkdir -p ../../../data_raw/price_indexes/2026-09-13
	curl --fail --location --retry 3 https://www2.census.gov/programs-surveys/demo/tables/p60/286/annual-index-value_annual-percent-change.xls -o ../temp/annual-index-value_annual-percent-change.xls
	$(R) -e 'stopifnot(nrow(readxl::read_excel("../temp/annual-index-value_annual-percent-change.xls")) > 70L)'
	mv ../temp/annual-index-value_annual-percent-change.xls $@
