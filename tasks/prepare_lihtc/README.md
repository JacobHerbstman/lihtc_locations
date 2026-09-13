# Prepare new-construction LIHTC projects

Read the original HUD 2024 release, keep type 1 (new construction) in the 50
states and DC, and retain one row per HUD ID. Accept the classification unless
there is concrete conflicting evidence. No older development links or manual
adjudications enter this task. Missing hedonics do not remove locations.

The pinned archive was retrieved August 8, 2026 from
https://www.huduser.gov/lihtc/lihtcpub.zip and is kept unchanged in data_raw.
Its SHA-256 is e07acee706174b276f89596d614ac5699efa9848659e5834fdfb5198fa0a7288.
The workbook has 55,345 rows and 80 columns. The included dictionary still prints
1987–2023 in its year domain; this 2024 release is parsed through 2024.
8888/9999 are missing-status codes, not years. Source unit fields are retained;
HUD's adjusted fields are not silently substituted. Coordinates remain source
coordinates and are used by default downstream. A numbered street address is
required only to form a shared address key, not to retain an available HUD location.

output/projects.csv retains all 29,453 new-construction records. Standardized
addresses preserve house-number ranges and unit/suite text; they are not parcel
IDs. Incomplete or obviously nonphysical addresses retain separate HUD-ID keys. Run make in code against prepared inputs; root make guarantees all
upstream freshness. The root source-acquisition rule retrieves only the pinned
vintage and fails rather than accepting a changed rolling download.

No filter uses NONPROG: HUD defines that field as no longer monitored for
compliance, not never having received LIHTC. Historical construction remains in scope.

The Makefile explicitly declares the source ZIP, its input symlink, extraction,
and output CSV. download_hud.sh handles acquisition of a missing pinned snapshot.
SaveData writes the metadata report when the CSV is saved.

Valid partial bedroom counts remain; contradictory breakdowns become missing,
with raw counts preserved. Targeting fields preserve the original code and derive
1=yes, 0=no, missing=unknown indicators. No missing date or characteristic filters
these 29,453 rows. Census geocoding is outside the production build.
