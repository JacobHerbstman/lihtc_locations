# Main-project variable dictionary

`output/projects.csv` has 28,456 rows and 31 columns. One row is one original
HUD project ID classified as new construction and carrying HUD coordinates.
Every row keeps its own date and hedonics. Empty CSV cells mean missing, never zero.
Read IDs and ZIP codes as text, for example from the repository root:

```r
projects <- data.table::fread(
  "tasks/build_lihtc/output/projects.csv", na.strings = "",
  colClasses = c(hud_id = "character", state_project_id = "character", zip = "character")
)
```

The saved-file report infers types from CSV and may call ZIP integer. Preserve
leading zeros when reading it. Source definitions below are from the dictionary
inside the unchanged 2024 HUD ZIP. A year is not inferred from digits in an ID.

| Variable | Meaning |
| --- | --- |
| `hud_id` | Unique row key: original HUD ID. No address-based deduplication occurs. |
| `project_name` | Trimmed HUD PROJECT. |
| `state_project_id` | Trimmed HUD STATE_ID, not nationally unique. |
| `street` | This record's standardized PROJ_ADD. |
| `city` | Uppercase, trimmed, whitespace-collapsed PROJ_CTY. |
| `state` | PROJ_ST, two-letter code, 50 states and DC. |
| `zip` | First five digits of PROJ_ZIP, otherwise missing; not part of address matching. |
| `pis_year` | YR_PIS, placed-in-service year in 1987–2024; missing is allowed. Not a groundbreaking date. |
| `allocation_year` | YR_ALLOC in 1987–2024; separate from the main timing variable. |
| `total_units` | Reported N_UNITS; positive integer or missing. |
| `low_income_units` | Reported LI_UNITS; nonnegative integer or missing, cannot exceed known total units. |
| `bedrooms_0` | N_0BR: number of efficiency units, not number of bedrooms. |
| `bedrooms_1` | N_1BR: number of one-bedroom units. |
| `bedrooms_2` | N_2BR: number of two-bedroom units. |
| `bedrooms_3` | N_3BR: number of three-bedroom units. |
| `bedrooms_4` | N_4BR: labeled number of four-bedroom units in HUD's dictionary. |
| `credit_type` | CREDIT: 1=30% present value, 2=70% present value, 3=both, 4=TCEP only. Treat as categorical. |
| `target_family` | TRGT_FAM recoded to 1=yes, 0=no, missing=not indicated. |
| `target_elderly` | TRGT_ELD recoded to 1=yes, 0=no, missing=not indicated. |
| `target_disabled` | TRGT_DIS recoded to 1=yes, 0=no, missing=not indicated. |
| `longitude` | This record's HUD LONGITUDE, decimal degrees. |
| `latitude` | This record's HUD LATITUDE, decimal degrees; primary project point. |
| `address_key` | Standardized state/city/street for the repeat-address diagnostic; unresolved text gets a separate UNRESOLVED:HUD_ID key. Not a parcel ID. |
| `address_resolved` | TRUE if standardized state/city/street supports a shared address key; FALSE uses a separate HUD-ID key. Does not affect coordinate acceptance. |
| `scattered_site` | SCATTERED_SITE_CD: 1=yes, 2=no, missing=unknown. Original code for this record. Diagnostic only. |
| `resyndicated` | RESYNDICATION_CD: 1=yes, 2=no, missing=unknown. Original code for this record. Diagnostic only. |
| `units_conflict` | This record reports low-income units above total units; cleaned low-income count is missing. |
| `bedrooms_conflict` | This record's bedroom breakdown contradicts known total units; cleaned bedroom fields are missing. |
| `bedrooms_consistent` | All five cleaned bedroom counts are known and sum to known total units. Use for a complete bedroom mix. FALSE also covers incomplete data, not just errors. |
| `records_at_address` | Number of source TYPE=1 rows at the standardized address, including records with missing HUD coordinates. Unresolved HUD-ID keys necessarily have one. |
| `repeated_address` | TRUE if more than one source TYPE=1 row shares this standardized address; diagnostic only. |

Bedroom fields retain valid partial information. An absent category does not imply
zero. If known counts exceed total units, or all five counts are present but their
sum differs from total units, the breakdown becomes missing. A conflict or missing
hedonic never removes the location. HUD targeting source codes are 1=yes, 2=no,
0/blank=not indicated; the main-file binary coding differs deliberately.

`project_records.csv` retains all 29,453 original TYPE=1 HUD IDs, raw date/unit/
bedroom/targeting fields, adjusted unit counts, source notes, HUD coordinates and
address flags. `selected` is exactly HUD-coordinate availability;
`exclusion_reason` is retained or missing_hud_coordinates. Join it to the main file
by unique `hud_id` to trace the original record. There is no one-to-many provenance
expansion and no cross-record consensus. Original raw values remain in this table
and in the unchanged source workbook.

`sample_sizes.csv` records one named availability condition per row, with N,
missing-from-master count and available percent. `summary_statistics.csv` gives
project-weighted N, missing, mean, sample SD, min, p25, median, p75 and max for each
numeric characteristic; quantiles use R's default type 7. `category_counts.csv`
gives one row per observed category (including Missing), its count, all-project
N, known N, percent of all and percent among known. Actual analyses report their
own Ns. Credit codes are categorical; they are not averaged numerically.
