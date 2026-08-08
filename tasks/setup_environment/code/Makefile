SHELL := bash

all: ../output/system_requirements.txt ../output/R_packages.txt

../output/system_requirements.txt: system_requirements.sh | ../output
	bash $<

../output/R_packages.txt: packages.R ../output/system_requirements.txt | ../output
	Rscript $<

link-inputs:

include ../../generic.make
