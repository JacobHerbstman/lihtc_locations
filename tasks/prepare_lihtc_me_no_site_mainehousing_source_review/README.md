# Prepare Maine No-Site MaineHousing Source Review

This task screens the 41 final Maine developments in the no-retained-site
review queue against the frozen 2026-08-12 MaineHousing subsidized-apartment
directory. MaineHousing is the state's housing finance agency. The directory
is a collection of 16 official county PDFs linked from its official source
page, and lists affordable apartments developed with government financing.

The script requires every frozen source byte to match `source_manifest.csv`
before it extracts text. It creates candidates only where a final development
name exactly equals a normalized property-name line in a PDF. For each such
candidate it records the PDF page/line, linked source URL and hash, an
immediately following possible address line, and whether the nearby city
heading and displayed total units agree. This is candidate evidence only.

No fuzzy matching is run: the PDFs are formatted listings rather than a
structured statewide property table, so name-distance matching would not add
reliable source fields or an appropriate uniqueness contract. Every output is
`not_adjudicated` and `not_approved`. The task does not create or change a
site, address, geocoding query, or acceptance decision. Any eventual use
would require a separate independent source and row-level review of historical
identity and physical-site scope.

Run `make` from `code/`.
