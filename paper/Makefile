.DEFAULT_GOAL := all
.PHONY: all data
all: data paper.pdf

data:
	$(MAKE) -C ..

paper.pdf: paper.tex | data
	pdflatex -halt-on-error -interaction=nonstopmode paper.tex
