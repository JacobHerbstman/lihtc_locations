all: logbook.pdf

logbook.pdf: logbook.tex ../tasks/build_lihtc/output/summary.tex
	pdflatex -halt-on-error -interaction=nonstopmode logbook.tex
