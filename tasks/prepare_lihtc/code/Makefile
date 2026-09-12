SHELL = bash
include ../../shared/code/shell_functions.make

all: ../output/projects.csv

include ../../shared/code/generic.make

../output/projects.csv: prepare_lihtc.R ../temp/LIHTCPUB.xlsx ../../shared/code/save_data.R Makefile | \
    ../output ../report
	$(R) $<

../temp/LIHTCPUB.xlsx: ../input/lihtcpub.zip Makefile | ../temp
	echo 'e07acee706174b276f89596d614ac5699efa9848659e5834fdfb5198fa0a7288  ../input/lihtcpub.zip' | shasum -a 256 -c -
	unzip -p $< LIHTCPUB.xlsx > $@

../input/lihtcpub.zip: ../../../data_raw/hud_lihtc_property/2024/lihtcpub.zip | ../input
	ln -sf $< $@

# The saved source is immutable. Download only when this exact snapshot is absent.
../../../data_raw/hud_lihtc_property/2024/lihtcpub.zip: | download_hud.sh ../temp
	bash download_hud.sh
