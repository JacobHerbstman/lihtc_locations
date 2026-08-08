all: ../output/lihtc_property_2024_files.csv

../output/lihtc_property_2024_files.csv: validate_lihtc_property.py \
		../../../data_raw/hud_lihtc_property/2024/lihtcpub.zip \
		../input/source_catalog.csv \
		release_manifest.csv | ../output
	python3 $<

../../../data_raw/hud_lihtc_property/2024/lihtcpub.zip: fetch_lihtc_property.py \
		../input/source_catalog.csv \
		release_manifest.csv | ../../../data_raw/hud_lihtc_property/2024
	python3 $<

../input/source_catalog.csv: ../../source_registry/output/source_catalog.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/source_catalog.csv

../../../data_raw/hud_lihtc_property/2024:
	mkdir -p $@

include ../../generic.make
