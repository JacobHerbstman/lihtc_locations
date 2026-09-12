# Census state boundaries, 2024

Publisher: U.S. Census Bureau, 2024 cartographic boundary shapefile at 1:20 million.
Downloaded September 12, 2026 from:
https://www2.census.gov/geo/tiger/GENZ2024/shp/cb_2024_us_state_20m.zip

SHA-256: `7bc773d83c01b6df69b8aada9c2b5983d97f22f4551947cc5c00b87c663223ef`

The immutable ZIP is used only to draw state outlines in
`tasks/audits/state_diagnostics`. Its download_states.sh downloads to temporary storage
and verifies the checksum before replacing the destination. No boundary geometry
is used to classify projects or change locations. Puerto Rico is omitted from
the maps to match the 50-state-and-DC research sample.
