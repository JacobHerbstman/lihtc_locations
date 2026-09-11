data_raw/hud_lihtc_property/2024/lihtcpub.zip:
	mkdir -p data_raw/hud_lihtc_property/2024
	curl --http1.1 --fail --location --silent --show-error https://www.huduser.gov/lihtc/lihtcpub.zip -o data_raw/hud_lihtc_property/2024/lihtcpub.zip.partial
	echo 'e07acee706174b276f89596d614ac5699efa9848659e5834fdfb5198fa0a7288  data_raw/hud_lihtc_property/2024/lihtcpub.zip.partial' | shasum -a 256 -c -
	mv data_raw/hud_lihtc_property/2024/lihtcpub.zip.partial $@
