include ../../shared/code/shell_functions.make
all: ../output/packages.txt

../output/packages.txt: packages.R Makefile | ../output
	$(R) $<

include ../../shared/code/generic.make
