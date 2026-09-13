# Main-project variable dictionary

`output/projects.csv` has 27,210 rows and 34 columns. One row represents the first
HUD new-construction record at a standardized primary address (or a separate HUD
ID where address identity is unresolved). Empty CSV cells mean missing, never zero.
Read identifiers and ZIP as text, for example from the repository root:

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
| `hud_id` | Unique row key: original HUD ID, smallest ID for an earliest-year tie. |
| `project_name` | Trimmed HUD PROJECT; consensus among earliest ties. |
| `state_project_id` | Trimmed HUD STATE_ID; consensus among ties, not nationally unique. |
| `street` | Representative's standardized PROJ_ADD. |
| `city` | Uppercase, trimmed, whitespace-collapsed PROJ_CTY. |
| `state` | PROJ_ST, two-letter code, 50 states and DC. |
| `zip` | First five digits of PROJ_ZIP, otherwise missing; not part of address matching. |
| `pis_year` | YR_PIS, placed-in-service year in 1987–2024; missing is allowed. Not a groundbreaking date. |
| `allocation_year` | YR_ALLOC in 1987–2024; separate from the main timing variable, consensus among ties. |
| `total_units` | Reported N_UNITS; positive integer or missing, consensus among ties. |
| `low_income_units` | Reported LI_UNITS; nonnegative integer or missing, cannot exceed known total units; consensus among ties. |
| `bedrooms_0` | N_0BR: number of efficiency units, not number of bedrooms. |
| `bedrooms_1` | N_1BR: number of one-bedroom units. |
| `bedrooms_2` | N_2BR: number of two-bedroom units. |
| `bedrooms_3` | N_3BR: number of three-bedroom units. |
| `bedrooms_4` | N_4BR: labeled number of four-bedroom units in HUD's dictionary. |
| `credit_type` | CREDIT: 1=30% present value, 2=70% present value, 3=both, 4=TCEP only; consensus among ties. Treat as categorical. |
| `target_family` | TRGT_FAM recoded to 1=yes, 0=no, missing=not indicated; consensus among ties. |
| `target_elderly` | TRGT_ELD recoded to 1=yes, 0=no, missing=not indicated; consensus among ties. |
| `target_disabled` | TRGT_DIS recoded to 1=yes, 0=no, missing=not indicated; consensus among ties. |
| `longitude` | Representative's HUD LONGITUDE, decimal degrees; never Census or averaged across records. |
| `latitude` | Representative's HUD LATITUDE, decimal degrees; primary project point. |
| `address_resolved` | TRUE if standardized state/city/street supports a shared address key; FALSE uses a separate HUD-ID key. Does not affect coordinate acceptance. |
| `scattered_site` | SCATTERED_SITE_CD: 1=yes, 2=no, missing=unknown. Any yes among earliest ties is retained; otherwise representative's code. Diagnostic only. |
| `resyndicated` | RESYNDICATION_CD: 1=yes, 2=no, missing=unknown. Any yes among earliest ties is retained; otherwise representative's code. Diagnostic only. |
| `units_conflict` | Low-income units exceed total units in a contributing record or after consensus; cleaned low-income count is missing. |
| `bedrooms_conflict` | A contributing or consensus breakdown contradicts known total units; cleaned bedroom fields are missing. |
| `bedrooms_consistent` | All five cleaned bedroom counts are known and sum to known total units. Use for a complete bedroom mix. FALSE also covers incomplete data, not just errors. |
| `records_at_address` | Number of source TYPE=1 rows at the standardized address, including later rows. Unresolved HUD-ID keys necessarily have one. |
| `first_record_count` | Number of records tied at the earliest year, or one for a singleton. |
| `selection_status` | single_new_construction_record, earliest_at_repeated_address, or first_of_tied_records. |
| `tied_coordinates_disagree` | More than one distinct available HUD point among earliest tied rows. Flag only; representative's point remains. |
| `source_hud_ids` | Sorted semicolon-separated IDs of all earliest contributors; later records remain in project_records.csv. |
| `tied_characteristics_disagree` | At least one consensus characteristic has conflicting nonmissing values across earliest rows. Affected fields are blanked. |

Bedroom fields retain valid partial information. An absent category does not imply
zero. If known counts exceed total units, or all five counts are present but their
sum differs from total units, the breakdown becomes missing. A conflict or missing
hedonic never removes the location. HUD targeting source codes are 1=yes, 2=no,
0/blank=not indicated; the main-file binary coding differs deliberately.

`project_records.csv` retains all original TYPE=1 HUD IDs, raw date/unit/bedroom/
targeting fields, adjusted unit counts, source notes, HUD coordinates, address keys,
representative IDs, `keep_first`, `selected` and `exclusion_reason`. Join by unique
HUD ID to trace the representative. Splitting `source_hud_ids` yields multiple
contributors per selected row; do not sum project units after expanding that join.

`sample_sizes.csv` contains one row per named availability condition, its N,
missing-from-master count and available percent. Joint conditions require all named
fields on the same observation. Actual analyses should report their own Ns.
