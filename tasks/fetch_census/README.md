# Fetch national Census sources

This task owns the ACS state-response archives, NHGIS national table/boundary
archives, and Census price-index workbook in data_raw. The Makefile lists each
source family and calls its source-specific script. JSON selections describe actual
NHGIS API queries, not Make dispatch. `acs_variables.csv` lists the requested ACS
fields. Every state/DC tract is requested; no LIHTC filter enters acquisition.

Run through root make. Existing snapshots are reused. Private R environment variables
CENSUS_API_KEY and IPUMS_API_KEY authenticate requests and are omitted from logs.
Responses are checked before replacing a source target. NHGIS codebooks travel
inside its archives. Reports record extract numbers and source fingerprints.
NHGIS raw archives are excluded from Git under its redistribution terms.

See [definitions and source links](../../CENSUS_PLAN.md).
