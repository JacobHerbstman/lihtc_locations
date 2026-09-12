#!/bin/bash
set -euo pipefail
# Run from tasks/audits/state_diagnostics/code.
mkdir -p ../../../../data_raw/census_boundaries/2024
curl --fail --location --silent --show-error --max-time 90 \
  https://www2.census.gov/geo/tiger/GENZ2024/shp/cb_2024_us_state_20m.zip -o ../temp/states.zip
printf '%s\n' '7bc773d83c01b6df69b8aada9c2b5983d97f22f4551947cc5c00b87c663223ef  ../temp/states.zip' | shasum -a 256 -c -
mv ../temp/states.zip ../../../../data_raw/census_boundaries/2024/cb_2024_us_state_20m.zip
