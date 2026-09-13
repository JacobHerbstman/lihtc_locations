# Assign LIHTC tracts

This task consumes the unchanged HUD location sample, national Census demographics
and native tract/place polygons through explicit Makefile symlinks.

1. `assign_lihtc_tracts.R YEAR` assigns every HUD point to each tract snapshot.
2. `assign_lihtc_places.R` assigns those same points to 2024 Census places nationally.
3. `join_tract_demographics.R` creates one row per HUD ID with separately prefixed
   latest_ and baseline_ fields. Baseline ends strictly before placed-in-service.
4. `count_lihtc_tracts.R` starts with every Census tract observation and adds counts,
   including zero-project tracts. Known-unit Ns remain explicit.

Point coordinates and the main LIHTC sample are unchanged. Source HUD tract IDs
and disagreements remain in the geography links. Ambiguous/unmatched assignments
have missing context, not deleted projects. No nearest polygon, address search,
manual building decision or cross-boundary count interpolation enters production.

See [definitions and data structure](../../CENSUS_PLAN.md).
