# Census geocoding pilot snapshots

These files are immutable responses from the official Census batch geocoder:

- Endpoint: `https://geocoding.geo.census.gov/geocoder/geographies/addressbatch`
- Benchmark: `Public_AR_Census2020`
- Vintage: `Census2020_Census2020`
- Retrieval date: 2026-08-12

Attempt 1 submitted a 457-address CSV with a header. Census treated the header
as a 458th address, so that response is preserved as a failed format attempt.
Attempt 2 submitted the same frozen manifest without a header and returned
exactly the 457 expected identifiers.

Each attempt contains the exact submitted input, unmodified response, and a
retrieval record with its UTC time, row count, byte count, and MD5 checksums.
No result in either attempt is automatically approved for analysis.
