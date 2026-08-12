# Prepare Census geocoding pilot

This task freezes a small, deterministic Census batch input. It makes no network request.

The input population is the 83,734 locally prepared development-scoped queries. A query is eligible because its street string survived local address review; it is not presumed correct. The pilot is an address-validation exercise, not an analysis sample.

The script reduces the address-component crosswalk to one record per query and carries a representative HUD coordinate only as comparison evidence. It stratifies by state, baseline-versus-reviewed address basis, one-versus-multiple source sites, and whether any associated component has a HUD coordinate. Each nonempty stratum contributes up to two queries, and each state is capped at 24. Query selection uses a transparent integer hash of the stable query ID, with the ID breaking any hash tie.

The official Census batch format is `unique ID, street address, city, state, ZIP`; the documented batch maximum is 10,000 records. The submitted CSV is deliberately headerless: Census otherwise treats a header row as an address. The Parquet manifest preserves the column schema. The downstream submission task uses `Public_AR_Census2020` with `Census2020_Census2020`, retains the unmodified response, verifies all returned IDs against the manifest, and validates matches before any tract assignment. The batch response never overwrites the frozen input.

Source: <https://geocoding.geo.census.gov/geocoder/Geocoding_Services_API.html>
