#!/bin/bash
set -euo pipefail
# Run from tasks/geocode_lihtc/code; argument is the batch number, 1, 2, or 3.
batch="${1:?Supply a batch number}"
case "$batch" in 1|2|3) ;; *) exit 1 ;; esac
mkdir -p ../../../data_raw/census_geocoder/2026-09-11
curl --fail --silent --show-error --connect-timeout 30 --max-time 600 \
  -F "addressFile=@../temp/request_${batch}.csv" \
  -F benchmark=Public_AR_ACS2025 -F vintage=Census2020_ACS2025 \
  https://geocoding.geo.census.gov/geocoder/geographies/addressbatch \
  -o "../temp/response_${batch}.csv"
Rscript validate_response.R "$batch"
mv "../temp/response_${batch}.csv" "../../../data_raw/census_geocoder/2026-09-11/response_${batch}.csv"
