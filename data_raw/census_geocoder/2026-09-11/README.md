# Census address-response snapshot

Retrieved September 11, 2026 by posting the 27,831 queryable new-construction
addresses from the pinned HUD release to the Census addressbatch endpoint.
Benchmark: Public_AR_ACS2025. Geography vintage: Census2020_ACS2025.
The code and exact multipart parameters are in
`tasks/geocode_lihtc/code/request_census.sh`. Batch size is 10,000, sorted by
HUD ID. Responses are unchanged source bytes and include submitted address text.

These files are tracked so rebuilding does not depend on the service returning
identical bytes later. Parsing verifies the submitted IDs and addresses against
the current input. An address or benchmark refresh should use a new dated
snapshot, not overwrite this one. Missing snapshots can be retrieved by Make;
that is a new retrieval, whose checksum must be compared with this record.
