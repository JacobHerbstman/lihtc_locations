include ../../../shared/code/shell_functions.make
.DEFAULT_GOAL := all
all: ../output/locus_city_text.csv ../output/locus_city_coverage.csv ../output/coverage.tex \
    ../output/diagnostics.html ../output/governments.csv ../output/metro_fragmentation.csv \
    ../output/metro_comparison.csv ../output/metro_correlations.csv ../output/metro_gradients.png \
    ../output/metro_diagnostics.html ../output/metro_summary.tex

include ../../../shared/code/generic.make

../output/locus_city_text.csv: extract_locus.R city_keys.csv source_hashes.csv ../input/cities.csv \
    ../input/train-00000-of-00008.parquet ../input/train-00001-of-00008.parquet \
    ../input/train-00002-of-00008.parquet ../input/train-00003-of-00008.parquet \
    ../input/train-00004-of-00008.parquet ../input/train-00005-of-00008.parquet \
    ../input/train-00006-of-00008.parquet ../input/train-00007-of-00008.parquet \
    ../../../shared/code/save_data.R Makefile | ../output ../report
	$(R) $<

../output/locus_city_coverage.csv: summarize_coverage.R ../output/locus_city_text.csv ../input/cities.csv \
    ../../../shared/code/save_data.R Makefile | ../output ../report
	$(R) $<

../output/coverage.tex: summarize_coverage_tex.R ../output/locus_city_coverage.csv Makefile | ../output
	$(R) $<

../output/diagnostics.html: write_report.R ../output/locus_city_coverage.csv ../output/locus_city_text.csv \
    ../README.md ../MEASUREMENT_PLAN.md Makefile | ../output
	$(R) $<

../input/cities.csv: ../../placement_gradients/code/cities.csv | ../input
	ln -sf $< $@

../input/train-%.parquet: ../../../../../local_laws/data_raw/locus_v1/20260507/train-%.parquet | ../input
	ln -sf $< $@

../output/governments.csv: build_metro_governments.R ../input/cities.csv ../input/govt_units_2022.ZIP \
    ../input/list1_2020.xls ../input/list2_2020.xls ../../../shared/code/save_data.R Makefile | ../output ../report ../temp
	$(R) $<

../output/metro_fragmentation.csv: summarize_metros.R ../output/governments.csv ../input/cities.csv \
    ../input/list1_2020.xls ../input/co-est2021-alldata.csv ../../../shared/code/save_data.R Makefile | ../output ../report
	$(R) $<

../input/govt_units_2022.ZIP: ../../../../data_raw/census_governments/2026-09-15/govt_units_2022.ZIP | ../input
	ln -sf $< $@

../input/list1_2020.xls: ../../../../data_raw/census_governments/2026-09-15/list1_2020.xls | ../input
	ln -sf $< $@

../input/list2_2020.xls: ../../../../data_raw/census_governments/2026-09-15/list2_2020.xls | ../input
	ln -sf $< $@

../input/co-est2021-alldata.csv: ../../../../data_raw/census_governments/2026-09-15/co-est2021-alldata.csv | ../input
	ln -sf $< $@


../output/metro_comparison.csv: compare_metros.R ../output/metro_fragmentation.csv ../input/models.csv \
    ../../../shared/code/save_data.R Makefile | ../output ../report
	$(R) $<

../output/metro_correlations.csv: correlate_metros.R ../output/metro_comparison.csv \
    ../../../shared/code/save_data.R Makefile | ../output ../report
	$(R) $<

../output/metro_gradients.png: plot_metros.R ../output/metro_comparison.csv Makefile | ../output
	$(R) $<

../input/models.csv: ../../placement_gradients/output/models.csv | ../input
	ln -sf $< $@


../output/metro_diagnostics.html: write_metro_report.R ../output/metro_fragmentation.csv \
    ../output/metro_comparison.csv ../output/metro_correlations.csv ../output/metro_gradients.png Makefile | ../output
	$(R) $<

../output/metro_summary.tex: summarize_metros_tex.R ../output/metro_fragmentation.csv \
    ../output/metro_correlations.csv Makefile | ../output
	$(R) $<
