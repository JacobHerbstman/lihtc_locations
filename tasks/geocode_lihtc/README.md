# Read archived Census address matches

The September 11 archive contains the earlier submissions of every queryable
new-construction address to the free Census batch geocoder. Three deterministic
batches of at most 10,000 records used the
published Public_AR_ACS2025 benchmark and Census2020_ACS2025 geography vintage.
The requests were defined September 11, 2026. Rebuilding the frozen release reads
these responses and sends no new queries. Only exact, same-state matches for
missing HUD coordinates supply production fallback points. These are address-range matches,
not parcel or rooftop verification. Current address evidence does not establish
historical site boundaries. Census 2020 tract codes are location checks, not a
choice of historical neighborhood measures for the analysis.

Raw responses are frozen and tracked in data_raw/census_geocoder/2026-09-11.
Unchanged builds and fresh clones reuse them. Parsing checks every submitted
address against the current query fields; changing an address fails rather than
silently using stale results. A refresh requires a new dated source snapshot.
The order-only request prerequisite creates a missing source but never refreshes
an existing frozen capture merely because a generated query has a newer mtime. Each response is validated against its submitted IDs before
publishing; failed/partial transfers remain temporary. Missing ZIP is allowed
when street, city, and state exist. No address is expanded or manufactured.

output/geocodes.csv has one row per submitted HUD project and preserves match
type, state, coordinates, tract, and matched address. Unqueryable projects remain
in the upstream table and return through the final left join. Root make is the
end-to-end build; task-local make uses prepared inputs.
Source: https://geocoding.geo.census.gov/geocoder/Geocoding_Services_API.html

HUD coordinates now take priority in production. An exact Census match in the
reported state is a fallback when HUD coordinates are absent. Existing Census
comparisons are diagnostics, not universal inclusion requirements. The Makefile
lists request and response files and their input links; request_census.sh holds
the API call. Existing archived responses are reused unchanged. SaveData writes
the dataset report when geocodes.csv is saved.
