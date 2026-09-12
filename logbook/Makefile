all: logbook.pdf

logbook.pdf: logbook.tex reset_summary.tex ../tasks/build_lihtc/output/summary.tex ../tasks/audits/external_benchmarks/report/checks.txt ../tasks/audits/external_benchmarks/README.md ../tasks/audits/state_diagnostics/output/type_missing_pct.png ../tasks/audits/state_diagnostics/output/confidence_loss_pct.png ../tasks/audits/state_diagnostics/report/state_summary.txt
	pdflatex -halt-on-error -interaction=nonstopmode logbook.tex
