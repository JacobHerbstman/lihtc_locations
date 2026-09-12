../../../../data_raw/census_boundaries/2024/cb_2024_us_state_20m.zip: source.make | ../temp
	mkdir -p ../../../../data_raw/census_boundaries/2024
	curl -L --fail --silent --show-error --max-time 90 https://www2.census.gov/geo/tiger/GENZ2024/shp/cb_2024_us_state_20m.zip -o ../temp/states.zip
	echo '7bc773d83c01b6df69b8aada9c2b5983d97f22f4551947cc5c00b87c663223ef  ../temp/states.zip' | shasum -a 256 -c -
	mv ../temp/states.zip $@
