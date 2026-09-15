include ../../shared/code/shell_functions.make
.DEFAULT_GOAL := all
all: ../output/source_inventory.csv

include ../../shared/code/generic.make

../../../data_raw/census_governments/2026-09-15/govt_units_2022.ZIP: Makefile | ../temp
	mkdir -p ../../../data_raw/census_governments/2026-09-15
	curl --fail --location --retry 3 https://www2.census.gov/programs-surveys/gus/datasets/2022/govt_units_2022.ZIP -o ../temp/govt_units_2022.ZIP
	echo '3ef3d93c91697b00d4d53384176dc584db9dacbd0f0a23e45657f0a3a1058c28  ../temp/govt_units_2022.ZIP' | shasum -a 256 -c -
	mv ../temp/govt_units_2022.ZIP $@

../../../data_raw/census_governments/2026-09-15/list1_2020.xls: Makefile | ../temp
	mkdir -p ../../../data_raw/census_governments/2026-09-15
	curl --fail --location --retry 3 https://www2.census.gov/programs-surveys/metro-micro/geographies/reference-files/2020/delineation-files/list1_2020.xls -o ../temp/list1_2020.xls
	echo '95b389487efcd818d71ba2a992e1edd43af93228e70c2a9634fd152acb345409  ../temp/list1_2020.xls' | shasum -a 256 -c -
	mv ../temp/list1_2020.xls $@

../../../data_raw/census_governments/2026-09-15/list2_2020.xls: Makefile | ../temp
	mkdir -p ../../../data_raw/census_governments/2026-09-15
	curl --fail --location --retry 3 https://www2.census.gov/programs-surveys/metro-micro/geographies/reference-files/2020/delineation-files/list2_2020.xls -o ../temp/list2_2020.xls
	echo 'be3a0aa2499d032d5b8125635569b946ba15b7d71ea0776f415c93c2b77c83af  ../temp/list2_2020.xls' | shasum -a 256 -c -
	mv ../temp/list2_2020.xls $@

../../../data_raw/census_governments/2026-09-15/co-est2021-alldata.csv: Makefile | ../temp
	mkdir -p ../../../data_raw/census_governments/2026-09-15
	curl --fail --location --retry 3 https://www2.census.gov/programs-surveys/popest/datasets/2020-2021/counties/totals/co-est2021-alldata.csv -o ../temp/co-est2021-alldata.csv
	echo '684883133405a88edbd43156382ccd7771fe1d6608b7ea1b992cb28bb6d31c83  ../temp/co-est2021-alldata.csv' | shasum -a 256 -c -
	mv ../temp/co-est2021-alldata.csv $@

../output/source_inventory.csv: report_sources.R Makefile ../../shared/code/save_data.R \
    ../../../data_raw/census_governments/2026-09-15/govt_units_2022.ZIP \
    ../../../data_raw/census_governments/2026-09-15/list1_2020.xls \
    ../../../data_raw/census_governments/2026-09-15/list2_2020.xls \
    ../../../data_raw/census_governments/2026-09-15/co-est2021-alldata.csv | ../output ../report
	$(R) $<
