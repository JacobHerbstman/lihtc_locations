include ../../../shared/code/shell_functions.make
all: ../report/checks.txt

../report/checks.txt: compare_hud.R ../input/LIHTCPUB.xlsx ../input/project_records.csv Makefile | ../report
	$(R) $<

../input/LIHTCPUB.xlsx: ../../../prepare_lihtc/temp/LIHTCPUB.xlsx | ../input
	ln -sf $< $@

../input/project_records.csv: ../../../build_lihtc/output/project_records.csv | ../input
	ln -sf $< $@

link-inputs: ../input/LIHTCPUB.xlsx ../input/project_records.csv
include ../../../shared/code/generic.make
