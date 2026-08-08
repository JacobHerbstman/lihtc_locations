# Fetch LIHTC Property Data

Downloads HUD's complete 2024 LIHTC property archive from the official rolling
URL and writes a deterministic file inventory after validating its checksum,
archive members, workbook schema, and project count.

Input: the source registry and `code/release_manifest.csv`.

Raw output: `data_raw/hud_lihtc_property/2024/lihtcpub.zip`.

The verified raw ZIP is committed to the repository. It was retrieved on
August 8, 2026 from <https://www.huduser.gov/lihtc/lihtcpub.zip>.

Task output: `lihtc_property_2024_files.csv`.

HUD's web application firewall challenges command-line HTTP/2 requests. The
fetch script therefore forces HTTP/1.1 and sends normal browser identification
headers. The 2024 archive is pinned by SHA-256, so a future change at the
rolling URL fails rather than silently replacing the research vintage.

HUD does not expose a year-specific URL for this release. The committed ZIP is
therefore the immutable replication copy. The fetch task is a fail-closed way
to recreate it only while HUD's rolling URL still serves the pinned bytes.
