all: logbook.pdf

logbook.pdf: logbook.tex reset_summary.tex corroboration_summary.tex corroboration_exclusions.png \
    hud_default_summary.tex hud_default_exclusions.png \
    ../tasks/build_lihtc/output/summary.tex ../tasks/audits/external_benchmarks/output/checks.txt \
    ../tasks/audits/external_benchmarks/README.md \
    ../tasks/audits/state_diagnostics/output/type_missing_pct.png \
    ../tasks/audits/state_diagnostics/output/coordinates_missing_pct.png \
    ../tasks/audits/state_diagnostics/output/state_summary.csv
	pdflatex -halt-on-error -interaction=nonstopmode logbook.tex
