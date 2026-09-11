all: logbook.pdf

logbook.pdf: logbook.tex ../tasks/build_lihtc/output/summary.tex ../tasks/audits/external_benchmarks/report/checks.txt ../tasks/audits/external_benchmarks/README.md
	pdflatex -halt-on-error -interaction=nonstopmode logbook.tex
