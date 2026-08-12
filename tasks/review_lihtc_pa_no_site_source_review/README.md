# Review Pennsylvania No-Site Source Candidates

This task records the second-read disposition of exactly the 17 Pennsylvania
no-site developments with an exact PHFA property-name match, agreeing city and
total-unit count, and a numeric candidate address. It validates the frozen
PHFA preparation output, the structured source manifest, and every byte of the
frozen 2026-08-12 second-read source snapshot before writing a validated
Parquet ledger.

This is an evidence ledger, not a site-repair task. Three candidate addresses
are corroborated, but they are neither applied nor accepted. They still require
a later independent acceptance decision about physical scope. The six
scope-conflict or incomplete-scope rows and eight unresolved rows likewise
create no site, address, geocoding query, or approval.

Every frozen-source row carries the exact source URL and SHA-256 plus a concise
evidence statement and page or HTML-line locator. Every no-result search row
carries the executed HTTPS search URL, review date, and explicit exclusion
notes. A no-result search is not affirmative evidence.

Only 17 of 120 Pennsylvania no-site questions are covered here; the remaining
103 questions have not received this source review. The ledger may not be
used to generalize a match rate or infer an address for them.

Run `make` from `code/`.
