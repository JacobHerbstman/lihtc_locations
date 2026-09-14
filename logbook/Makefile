all: logbook.pdf

logbook.pdf: logbook.tex reset_summary.tex corroboration_summary.tex corroboration_exclusions.png \
    hud_default_summary.tex hud_default_exclusions.png first_address_summary.tex \
    ../tasks/build_lihtc/output/summary.tex ../tasks/audits/external_benchmarks/output/checks.txt \
    ../tasks/audits/external_benchmarks/README.md \
    ../tasks/audits/state_diagnostics/output/type_missing_pct.png \
    ../tasks/audits/state_diagnostics/output/coordinates_missing_pct.png \
    ../tasks/audits/state_diagnostics/output/project_characteristics.png \
    ../tasks/audits/state_diagnostics/output/state_summary.csv \
    ../tasks/audits/census_diagnostics/output/summary.tex \
    ../tasks/audits/census_diagnostics/output/1714000_income.png \
    ../tasks/audits/nyc_homeownership/output/summary.tex \
    ../tasks/audits/nyc_homeownership/output/rates_main.png \
    ../tasks/audits/nyc_homeownership/output/rates_same_2000.png \
    ../tasks/audits/nyc_homeownership/output/placement_maps.png \
    ../tasks/audits/placement_gradients/output/summary.tex \
    ../tasks/audits/placement_gradients/output/gradients.png
	pdflatex -halt-on-error -interaction=nonstopmode logbook.tex
