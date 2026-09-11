include ../../shared/code/shell_functions.make
all: ../output/projects.csv ../report/projects.txt

../output/projects.csv: prepare_lihtc.R ../temp/LIHTCPUB.xlsx Makefile | ../output
	$(R) $<

../report/projects.txt: ../output/projects.csv ../../shared/code/report.R | ../report
	$(R) ../../shared/code/report.R $< $@

../temp/LIHTCPUB.xlsx: ../input/lihtcpub.zip source.make | ../temp
	echo 'e07acee706174b276f89596d614ac5699efa9848659e5834fdfb5198fa0a7288  ../input/lihtcpub.zip' | shasum -a 256 -c -
	unzip -p $< LIHTCPUB.xlsx > $@

../input/lihtcpub.zip: ../../../data_raw/hud_lihtc_property/2024/lihtcpub.zip | ../input
	ln -sf $< $@

link-inputs: ../input/lihtcpub.zip
include ../../shared/code/generic.make
