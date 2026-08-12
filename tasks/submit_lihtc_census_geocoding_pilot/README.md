# Submit Census geocoding pilot

This task parses the immutable Census responses produced from the frozen
457-row pilot at the official `geographies/addressbatch` endpoint with
`Public_AR_Census2020` and `Census2020_Census2020`. It makes no network call.

Attempt 1 is preserved at
`data_raw/census_geocoder/2026-08-12/attempt_01/` as a failed format attempt:
its header was treated by Census as an extra `No_Match` record. Attempt 2 is a
headerless re-submission of the same frozen manifest and is saved in
`attempt_02/`. Both directories contain submitted input, raw response, and
retrieval record. They are immutable raw prerequisites, not active download
targets. The retrieval record stores the endpoint, benchmark, vintage, UTC
time, input checksum/count, and response checksum/bytes.

The parser requires exactly one unique returned row for every frozen batch ID, checks the raw-response hash against metadata, and stops on a matched state-FIPS disagreement. It does not approve any query for production use.
