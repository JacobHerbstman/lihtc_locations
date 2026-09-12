include ../../../shared/code/shell_functions.make
all: ../output/checks.txt

../output/checks.txt: compare_hud.R ../input/LIHTCPUB.xlsx ../input/project_records.csv Makefile | ../output
	$(R) $<

../input/LIHTCPUB.xlsx: ../../../prepare_lihtc/temp/LIHTCPUB.xlsx | ../input
	ln -sf $< $@

../input/project_records.csv: ../../../build_lihtc/output/project_records.csv | ../input
	ln -sf $< $@

include ../../../shared/code/generic.make
