# Historical Census geocoding audit

This task and its raw September 11, 2026 responses are retained for research
history. They are **outside the production build**. The current main dataset uses
HUD coordinates only; no Census fallback or comparison selects observations.

The archive contains three deterministic batches of at most 10,000 queryable
new-construction addresses. It used Public_AR_ACS2025 and Census2020_ACS2025.
Raw responses remain unchanged under data_raw/census_geocoder/2026-09-11. Of the
997 source rows without HUD coordinates, 427 were queryable and 72 received exact,
same-state matches. Those points are not included in the current location dataset.
Census matches are address-range points, not verified building footprints.

After root `make` prepares HUD inputs, `make -C tasks/geocode_lihtc/code` can
reproduce this audit from saved responses. Task Makefile targets list request,
response, parsing and input-link dependencies. Parsing checks submitted IDs and
addresses and the archive checksum. No source refresh occurs without a new vintage.
Missing source responses require network access through request_census.sh; ordinary
production builds neither read responses nor send geocoding requests.

Source: https://geocoding.geo.census.gov/geocoder/Geocoding_Services_API.html
