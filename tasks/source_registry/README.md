# Source Registry

Copies the version-controlled catalog of official data sources that have a
defined role in the proposed production pipeline.

Input: `code/source_catalog.csv`.

Output: `source_catalog.csv`, a stable task output for downstream acquisition
and cleaning tasks.

The HUD property archive uses a rolling URL. The 2024 release is acquired by
`tasks/fetch_lihtc_property`, which forces HTTP/1.1 to avoid HUD's HTTP/2 web
application firewall challenge and validates the download against a committed
release checksum. Future releases require an explicit manifest update.
