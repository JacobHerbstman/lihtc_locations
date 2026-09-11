../../../data_raw/census_geocoder/2026-09-11/response_%.csv: | ../temp/request_%.csv ../../../data_raw/census_geocoder/2026-09-11 ../temp
	curl --fail --silent --show-error --connect-timeout 30 --max-time 600 -F addressFile=@../temp/request_$*.csv -F benchmark=Public_AR_ACS2025 -F vintage=Census2020_ACS2025 https://geocoding.geo.census.gov/geocoder/geographies/addressbatch -o ../temp/response_$*.csv
	$(R) validate_response.R $*
	mv ../temp/response_$*.csv $@

../../../data_raw/census_geocoder/2026-09-11:
	mkdir -p $@
