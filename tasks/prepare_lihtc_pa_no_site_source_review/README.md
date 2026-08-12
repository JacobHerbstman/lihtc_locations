# Prepare Pennsylvania No-Site PHFA Source Review

This task screens the 120 final Pennsylvania developments in the no-retained-
site review queue against the frozen 2026-08-12 Pennsylvania Housing Finance
Agency (PHFA) Rental Housing Inventory snapshot. It uses only an exact match
between normalized final development name and the left-hand property-name
field extracted from every one of the 66 county PDFs.

The task creates a complete 120-question ledger, a row-level ledger of exact
PHFA name matches, and a compact count table. Each output remains
`not_adjudicated` and `not_approved`.

The raw snapshot includes `manifest.sha256`. The script reads that manifest,
requires exactly the 66 expected PDFs plus the retrieved source HTML, and
verifies every file hash before extracting any text.

The current PHFA inventory identifies properties funded by PHFA at some point
or properties for which PHFA administers Section 8. It is first-source
candidate evidence only. In particular, it does not establish that a listed
address is the historical address, complete physical scope, or a valid
replacement for an absent LIHTC site. A second, genuinely independent source
read and a row-level decision are required before any address can be used.

The task neither changes the final LIHTC data nor creates a site, address,
geocoding query, or acceptance decision. It deliberately does not use fuzzy,
contained-name, city-only, or unit-only matching.

Run `make` from `code/`.
