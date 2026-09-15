include ../../../shared/code/shell_functions.make
.DEFAULT_GOAL := all
all: ../output/evidence.csv ../output/approval_routes.csv ../output/city_comparison.csv ../output/city_comparison.png ../output/diagnostics.html ../output/summary.tex

include ../../../shared/code/generic.make

../input/locus_city_text.csv: ../../local_control/output/locus_city_text.csv | ../input
	ln -sf $< $@

../input/cities.csv: ../../placement_gradients/code/cities.csv | ../input
	ln -sf $< $@

../input/models.csv: ../../placement_gradients/output/models.csv | ../input
	ln -sf $< $@

../input/sf_hcd_2023.pdf: ../../../../data_raw/approval_rules/2026-09-15/sf_hcd_2023.pdf | ../input
	ln -sf $< $@

../../../../data_raw/approval_rules/2026-09-15/sf_hcd_2023.pdf: | ../temp
	mkdir -p ../../../../data_raw/approval_rules/2026-09-15
	curl --fail --location --retry 3 'https://sfplanning.org/sites/default/files/documents/housing-for-all/housingelement-HCD-housing-policy-and-practice-review-102423.pdf' -o ../temp/sf_hcd_2023.pdf
	echo 'cdc3c0e7769a5dbf3c7287a1be2dd8776e82789e73cc2104de96b85d0f4b1b98  ../temp/sf_hcd_2023.pdf' | shasum -a 256 -c -
	mv ../temp/sf_hcd_2023.pdf $@

../input/seattle_ord126741.pdf: ../../../../data_raw/approval_rules/2026-09-15/seattle_ord126741.pdf | ../input
	ln -sf $< $@

../../../../data_raw/approval_rules/2026-09-15/seattle_ord126741.pdf: | ../temp
	mkdir -p ../../../../data_raw/approval_rules/2026-09-15
	curl --fail --location --retry 3 'https://clerk.seattle.gov/~archives/Ordinances/Ord_126741.pdf' -o ../temp/seattle_ord126741.pdf
	echo 'f30f4b6da85eeb39221da964d28091b06add6a042a46c322790bc3f78a1c6100  ../temp/seattle_ord126741.pdf' | shasum -a 256 -c -
	mv ../temp/seattle_ord126741.pdf $@

../input/boston_article80_proposal_2025.pdf: ../../../../data_raw/approval_rules/2026-09-15/boston_article80_proposal_2025.pdf | ../input
	ln -sf $< $@

../../../../data_raw/approval_rules/2026-09-15/boston_article80_proposal_2025.pdf: | ../temp
	mkdir -p ../../../../data_raw/approval_rules/2026-09-15
	curl --fail --location --retry 3 'https://www.bostonplans.org/getattachment/f078b57f-df0b-443e-bdb8-2f1f5aa3a5ea' -o ../temp/boston_article80_proposal_2025.pdf
	echo 'bfbec2c0bdea83cd164ec6bb753261d33819f72d8259fded1aae3a3f53a76914  ../temp/boston_article80_proposal_2025.pdf' | shasum -a 256 -c -
	mv ../temp/boston_article80_proposal_2025.pdf $@

../output/evidence.csv: build_evidence.R \
    evidence_notes.csv \
    sources.csv \
    ../input/locus_city_text.csv \
    evidence/boston_board_2022_web.txt \
    evidence/haa_court_web.txt \
    evidence/la_site_plan_web.txt \
    evidence/nyc_handbook_web.txt \
    evidence/seattle_2025_web.txt \
    ../input/sf_hcd_2023.pdf \
    ../input/seattle_ord126741.pdf \
    ../input/boston_article80_proposal_2025.pdf \
    ../../../shared/code/save_data.R \
    Makefile | ../output ../report
	$(R) $<

../output/approval_routes.csv: build_routes.R \
    route_coding.csv \
    city_coding.csv \
    ../input/cities.csv \
    ../output/evidence.csv \
    ../../../shared/code/save_data.R \
    Makefile | ../output ../report
	$(R) $<

../output/city_comparison.csv: compare_cities.R \
    city_coding.csv \
    ../input/models.csv \
    ../../../shared/code/save_data.R \
    Makefile | ../output ../report
	$(R) $<

../output/city_comparison.png: plot_comparison.R \
    ../output/city_comparison.csv \
    Makefile | ../output
	$(R) $<

../output/diagnostics.html: write_report.R \
    ../output/approval_routes.csv \
    ../output/city_comparison.csv \
    ../output/evidence.csv \
    ../output/city_comparison.png \
    ../README.md \
    Makefile | ../output
	$(R) $<

../output/summary.tex: summarize_tex.R \
    ../output/city_comparison.csv \
    Makefile | ../output
	$(R) $<
