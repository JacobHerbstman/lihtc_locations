# Selected-project variable dictionary

Both `projects.csv` and `confident_projects.csv` have the same 41 columns. Empty CSV fields mean missing; they
are not zero. HUD IDs, state project IDs, and ZIP codes should be read as text.
For example, from the repository root:

```r
projects <- data.table::fread(
  "tasks/build_lihtc/output/confident_projects.csv",
  na.strings = "",
  colClasses = c(hud_id = "character", state_project_id = "character", zip = "character")
)
```

The saved-file report infers column types when rereading a CSV, so it calls ZIP
integer; that is not an instruction to discard leading zeros. Other numeric
category codes below are categories, not quantities. Source field names refer
to the Data sheet of the pinned `LIHTCPUB.xlsx`. Category definitions are from
the `LIHTC Data Dictionary 2024.pdf` inside the same source ZIP.

## Identifiers and address

| Variable | Meaning and source |
| --- | --- |
| `hud_id` | Unique row key. Source HUD ID, or smallest HUD ID among tied earliest records. The embedded digits do not supply the project's date. |
| `project_name` | Trimmed HUD `PROJECT`; consensus among earliest ties, blank on disagreement. |
| `state_project_id` | Trimmed HUD `STATE_ID`; state-defined ID, not assumed nationally unique. Consensus among ties. |
| `street` | Standardized HUD `PROJ_ADD`; the representative record's primary street text. |
| `city` | Uppercase, trimmed, whitespace-collapsed HUD `PROJ_CTY`. |
| `state` | HUD `PROJ_ST`, two-letter code; 50 states and DC. |
| `zip` | First five digits of trimmed HUD `PROJ_ZIP`, otherwise missing; retained as text. Does not decide the address group. |
| `source_hud_ids` | Sorted semicolon-separated HUD IDs of all earliest tied records contributing to this row; singleton ID if no tie. Later records remain in `project_records.csv`. |

## Dates and basic characteristics

| Variable | Meaning and source |
| --- | --- |
| `pis_year` | Reported placed-in-service year, HUD `YR_PIS`, restricted to 1987–2024. This dates the observation; it is not an observed groundbreaking or completion date. Never missing in the dated file. |
| `allocation_year` | HUD `YR_ALLOC`, restricted to 1987–2024; descriptive only, consensus among ties. |
| `total_units` | HUD `N_UNITS`, total project units reported by the housing finance agency. Positive integer or missing; consensus among ties, never summed across records. |
| `low_income_units` | HUD `LI_UNITS`, reported low-income project units. Nonnegative integer or missing. Blank when inconsistent with total units or tied records. Zero is retained. |
| `bedrooms_0` | HUD `N_0BR`, number of efficiency units. |
| `bedrooms_1` | HUD `N_1BR`, number of 1-bedroom units. |
| `bedrooms_2` | HUD `N_2BR`, number of 2-bedroom units. |
| `bedrooms_3` | HUD `N_3BR`, number of 3-bedroom units. |
| `bedrooms_4` | HUD `N_4BR`, labeled number of 4-bedroom units. This replaces the earlier `bedrooms_4plus` label with identical values. |
| `credit_type` | HUD `CREDIT`: 1 = 30 percent present value; 2 = 70 percent present value; 3 = both; 4 = TCEP only. Consensus among ties. |
| `target_family` | HUD `TRGT_FAM`: 1 = yes, 2 = no, 0 or blank = not indicated. Consensus among ties. |
| `target_elderly` | HUD `TRGT_ELD`: 1 = yes, 2 = no, 0 or blank = not indicated. Consensus among ties. |
| `target_disabled` | HUD `TRGT_DIS`: 1 = yes, 2 = no, 0 or blank = not indicated. Consensus among ties. |

The five bedroom fields count units, not bedrooms or people. They are all blank
unless the complete nonnegative integer breakdown sums to `total_units`. A blank
targeting flag is not evidence that the project does not target that group.

## Coordinates and scope

| Variable | Meaning and source |
| --- | --- |
| `longitude` | Chosen primary point, decimal degrees, east positive/west negative; HUD `LONGITUDE` first, Census fallback otherwise. Consensus among ties. |
| `latitude` | Chosen primary point, decimal degrees north; HUD `LATITUDE` first, Census fallback otherwise. Consensus among ties. |
| `location_source` | Representative record's chosen source: `HUD`, `Census ACS2025`, or `missing`. The dated file has only the first two. |
| `location_status` | Representative record's comparison with Census; diagnostic, not the inclusion rule. Values described below. |
| `location_available` | TRUE when the representative has valid HUD coordinates or an exact, same-state Census fallback. Broader-file provisional Census points can be present while this flag is FALSE. |
| `address_resolved` | TRUE if address text supports a shared state/city/street key; FALSE if the record instead has its own unresolved HUD-ID key. FALSE does not invalidate a HUD point. |
| `scattered_site` | HUD `SCATTERED_SITE_CD`: 1 = yes, 2 = no, blank = unknown; consensus among ties. Any affirmative earliest flag excludes the group from the dated file. |
| `resyndicated` | HUD `RESYNDICATION_CD`: 1 = yes, 2 = no, blank = unknown; consensus among ties. Any affirmative earliest flag excludes the group from the dated file. |

`location_status` values are `census_hud_agree` (same state and within the
500-meter diagnostic threshold), `coordinate_disagreement`, `state_disagreement`,
`hud_only_unconfirmed`, `census_exact_no_hud_comparison`, `inexact_census_match`,
`scattered_primary_point_only`, and `no_location`. “Unconfirmed” is inherited
comparison terminology and is not an exclusion for a valid HUD point.

## Selection and diagnostic flags

| Variable | Meaning |
| --- | --- |
| `units_conflict` | TRUE if any contributing earliest row reports low-income units above total units, or consensus counts violate that condition. The cleaned low-income count becomes missing. |
| `bedrooms_consistent` | TRUE if the complete cleaned bedroom breakdown sums to cleaned total units and contains only nonnegative integers. Otherwise all bedroom counts are blank. |
| `records_at_address` | Number of source new-construction records at the address key, including later records. Unresolved HUD-ID keys necessarily have one. |
| `first_record_count` | Number of records tied at the selected earliest year; one for a singleton. |
| `selection_status` | `single_new_construction_record`, `earliest_at_repeated_address`, or `first_of_tied_records` in these selected tables. |
| `repeat_address_review` | TRUE when more than one new-construction record shares the key. A compatibility name for an automatic flag; no manual queue and no extra exclusion. |
| `construction_review` | TRUE when the representative source row has a resyndication flag. The final selection checks every tied earliest row, not only this flag. |
| `usable_location` | Selected first address with accepted, agreeing coordinates for every earliest record, and no affirmative scattered-site/resyndication flag. Does not require a year. |
| `confident_first` | `usable_location` plus observed 1987–2024 `pis_year`. TRUE for every row in `confident_projects.csv`; the filter defining that file. |
| `corroborated_first` | Would pass the former universal Census-corroboration rule; diagnostic comparison only. Does not select the current sample. |
| `exclusion_reason` | `retained` for the dated file; otherwise one primary reason according to the priority in the task README. Additional flags may coexist. |
| `tied_characteristics_disagree` | TRUE if at least one consensus field has disagreeing nonmissing values across earliest tied rows. Affected fields are blanked; this flag itself does not exclude a location. |

For audit joins, `project_records.csv` has one row per original HUD ID and includes
the address key, original date and unit fields, source HUD coordinates, Census
responses, representative ID, and selection flags. Joining it to the primary file
on `hud_id` retrieves the representative row. To inspect every earliest contributor,
split `source_hud_ids` and join those IDs to the record table; that intentionally
creates multiple source rows per selected project, so do not sum project totals
after that join.
