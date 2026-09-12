# LIHTC project locations, version 1.0.0

Locked September 12, 2026, before further exploratory analysis. Git tag:
`lihtc-v1.0.0`. This release fixes the source vintage, selection rules, variables,
and saved data. Future corrections require a new version and a stated reason;
do not replace these files after seeing exploratory results.

Start with **confident_projects.csv**: 25,832 dated new-construction project
locations, with 25,763 HUD points and 69 exact Census fallback points. One row is
one selected primary-address record, identified by `hud_id`. This is not a parcel
inventory, a count of separate buildings, or complete national construction.

## Files

| File | Purpose |
| --- | --- |
| `confident_projects.csv` | Fixed sample for dated exploratory analysis; 25,832 rows and 41 columns. |
| `projects.csv` | All 28,196 first-address choices, including excluded and undated choices; same columns. |
| `codebook.md` | Variable meanings, source fields, category codes, and reading instructions. |
| `report/confident_projects.txt`, `report/projects.txt` | Copies of the producing task's metadata reports. |
| `environment.txt` | R, package, Make, and system versions used for this release. |
| `verification.md` | Checks performed and their limits. |
| `SHA256SUMS` | Fingerprints of these frozen files. |
| `rebuild.sha256` | Fingerprints of raw sources and pipeline datasets, relative to the repository root. |

These CSVs are exact copies of the same-named files in
`tasks/build_lihtc/output/`. That task remains their producer. `make` rebuilds
task outputs but never writes into this release directory. All 29,453 source
new-construction records remain traceable in the rebuilt `project_records.csv`;
the original workbook remains unchanged in `data_raw`.

## Fixed rules, in the order applied

1. **Source and scope.** Use the pinned HUD 2024 release, downloaded August 8,
   2026. Keep the 50 states and DC and HUD `TYPE=1`. Accept that classification;
   do not infer new construction from a missing type. No building-specific
   corrections, external searches, or manual adjudications determine inclusion.
   `NONPROG` does not exclude a project: no longer monitored does not mean it
   never received LIHTC.
2. **Dates and counts.** Use HUD's reported placed-in-service year (`YR_PIS`),
   not allocation year, as the time variable. Keep derived years in 1987–2024;
   blank missing-status codes 8888/9999 and values outside the window. The source
   has 49 new-construction records dated 2025; their derived years become missing,
   while their source values remain. Never impute a year from a HUD ID. Use
   reported units (`N_UNITS`, `LI_UNITS`), not HUD's adjusted counts. Blank
   negative or noninteger counts and zero total units; retain zero low-income
   units. If low-income units exceed total units, blank the low-income count.
3. **Address identity.** Uppercase and trim street and city, collapse whitespace,
   remove periods and commas from street, and replace the whole words STREET,
   AVENUE, ROAD, BOULEVARD, DRIVE, LANE, COURT, PLACE, PARKWAY, HIGHWAY, NORTH,
   SOUTH, EAST, WEST with ST, AVE, RD, BLVD, DR, LN, CT, PL, PKWY, HWY, N, S, E, W.
   Keep number ranges and apartment/suite text. The key is state + city + street;
   ZIP and project name do not decide identity. Address queries require a street
   starting with digits, no PO BOX/POST OFFICE/SCATTERED/VARIOUS text or semicolon
   or ampersand, and a city or five-digit ZIP. Records that fail this rule, or
   lack a city, get separate `UNRESOLVED:` + HUD-ID keys. They may still retain
   a HUD point; we have not established that they are distinct physical addresses.
4. **Location source.** Use HUD latitude/longitude when both are numeric and
   latitude is 18–72, longitude is −180–180, and longitude is nonzero. These are
   broad numerical checks, not verification against state boundaries. Require no
   house number or Census confirmation for a HUD point. Without one, accept
   only an exact Census match in the reported state. Use archived September 11,
   2026 responses with benchmark `Public_AR_ACS2025` and geography vintage
   `Census2020_ACS2025`. The archive includes earlier queries of 27,831 addresses;
   no new query is needed to reproduce this release. HUD–Census distances above
   500 meters are diagnostic only and do not replace or exclude a HUD point.
5. **First address.** Within the new-construction records at each address key,
   keep the earliest placed-in-service year. A singleton stays in the broad
   table even if undated. At a repeated address, any missing year makes ordering
   uncertain, so select none. For an earliest-year tie, the smallest HUD ID labels
   the group and `source_hud_ids` preserves every tied ID. Use each characteristic's
   single distinct nonmissing value; blank it when nonmissing values disagree.
   Never add units across repeat records. Later phases at the same address are
   omitted by this definition, not declared errors. Earlier rehabilitation or
   other financing types do not enter this ordering.
6. **Final dated sample.** Require an accepted location for every tied earliest
   record, exactly agreeing chosen coordinates among those records, and a valid
   placed-in-service year. Exclude a group if any earliest record is flagged
   scattered-site or resyndicated (`1`). Blank flags do not count as affirmative
   flags. These scope exclusions avoid assigning project totals to one site or
   treating an identified repeat financing as new construction. Neither repeat
   addresses alone nor unresolved address text cause a further exclusion.
7. **Hedonics.** Missing or inconsistent hedonics never remove a location. After
   tie consensus, require all five bedroom counts to be nonnegative integers
   summing to reported total units; otherwise blank the entire bedroom breakdown.
   Recheck low-income units against total units. Preserve original values in the
   record table/workbook. `bedrooms_4` maps to HUD `N_4BR`, labeled “4-bedroom
   units” in the pinned dictionary; the former `bedrooms_4plus` label was corrected
   without changing any value.

## Exact sample accounting

| Step | Records |
| --- | ---: |
| HUD new construction in 50 states and DC | 29,453 |
| Later or nonrepresentative same-year records | −1,176 |
| Records at repeated addresses with uncertain year ordering | −81 |
| First-address choices | 28,196 |
| Missing year | −942 |
| Resyndication flag | −109 |
| Scattered-site flag | −448 |
| Conflicting coordinates among earliest ties | −2 |
| No location | −749 |
| Only an inexact Census fallback | −114 |
| **Final dated sample** | **25,832** |

The exclusions after first selection are mutually exclusive, assigned in the
order shown. A record may have additional flags. Of 997 source records without
valid HUD coordinates, 427 have queryable addresses; only 72 receive an accepted
Census fallback. After first-address selection and the other restrictions, 69
of those fallback points enter the final sample. Queryable does not mean matched.

The final sample contains 1,730,065 reported total units, excluding missing counts
from the sum. It retains 249 projects without total units and 6,469 without a
complete consistent bedroom breakdown. The count of projects is always the row
count, regardless of hedonic missingness.

## What this version does not establish

Missing construction type affects 7,071 of 54,928 HUD records in the 50 states
and DC, and its frequency differs substantially across states. Available locations
and the scope exclusions also differ across states. These are documented coverage
limitations, not resolved by the freeze. State and state-year diagnostics remain
in `tasks/audits/state_diagnostics/output/` and their dataset hashes are recorded.

There are 882 retained records with unresolved address identities, and 1,310
retained HUD–Census distance disagreements above 500 meters. Neither source proves
a building footprint. A known external classification conflict for Oconee Park
remains documented in the external benchmark audit; the fixed rule makes no
ID-specific exception. A frozen, replicable selected sample is not a certification
of every HUD source value. No complete financing history or parcel matching is
part of this release.

## Reproduce and check the lock

Use Git tag `lihtc-v1.0.0`, including the tracked raw snapshots. With the recorded
R packages available, run `make` at the repository root. `make setup` supplies
missing packages but does not pin their versions; the exact versions used are
recorded in `environment.txt`. Packages and the operating system are not vendored.

The data path runs in this order:

| Order | Script, run from its task's `code/` directory | Saved result |
| --- | --- | --- |
| 1 | `tasks/prepare_lihtc/code/prepare_lihtc.R` after checked ZIP extraction | `prepare_lihtc/output/projects.csv` |
| 2 | `tasks/geocode_lihtc/code/parse_responses.R` after archived-response checksum checks | `geocode_lihtc/output/geocodes.csv` |
| 3 | `tasks/build_lihtc/code/build_lihtc.R 500` | `build_lihtc/output/project_records.csv` |
| 4 | `tasks/build_lihtc/code/select_projects.R` | `build_lihtc/output/projects.csv` |
| 5 | `tasks/build_lihtc/code/select_confident.R` | `build_lihtc/output/confident_projects.csv` |

The explicit root Makefile also produces exclusion accounting, the existing
coverage diagnostics, external benchmark checks, and the logbook. The download
scripts run only if a pinned source is absent. Restoring the same dated archive
is preferable to asking a changing remote service to return identical bytes.

From the repository root, after `make`:

```sh
shasum -a 256 -c releases/v1.0.0/rebuild.sha256
cmp tasks/build_lihtc/output/confident_projects.csv releases/v1.0.0/confident_projects.csv
cmp tasks/build_lihtc/output/projects.csv releases/v1.0.0/projects.csv
```

To check the frozen directory alone, run from `releases/v1.0.0/`:

```sh
shasum -a 256 -c SHA256SUMS
```

Subsequent analysis should read the frozen `confident_projects.csv` through an
explicit input symlink. Any future sample restriction belongs in that analysis,
with its own stated reason; it must not rewrite this release.
